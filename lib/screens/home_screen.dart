import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/animals.dart';
import '../data/stages.dart';
import '../models/monster_state.dart';
import '../models/profile.dart';
import '../services/analytics.dart';
import '../version.dart';
import '../widgets/cheer_character.dart';
import '../widgets/monster_display.dart';
import '../widgets/stage_tracker.dart';

/// The guided task loop: Idle -> Working -> Evolving -> Idle.
enum _Phase { idle, working, evolving }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  /// Minimum seconds the user must "work" before Ready unlocks.
  static const int _minTaskSeconds = 10;

  /// Seconds of work after which we cheerfully nudge the user to wrap up.
  /// ~5 minutes is about the practical limit to finish a single task.
  static const int _alarmSeconds = 5 * 60; // 300

  /// How long the evolution celebration plays before returning to Idle.
  static const int _evolveSeconds = 3;

  static const List<String> _idleCheers = <String>[
    "Ready to crush a task? 💪",
    "What are we tackling next?",
    "Let's make progress!",
    "Your monster's counting on you!",
  ];
  static const List<String> _workingCheers = <String>[
    "You've got this — keep going!",
    "Focus mode: ON 🔥",
    "Every second counts!",
    "Stay with it, almost there!",
  ];
  static const List<String> _evolveCheers = <String>[
    "WOOHOO! 🎉",
    "Incredible work!",
    "Level up! ⭐",
    "That's how it's done!",
  ];

  final AudioPlayer _player = AudioPlayer();
  // Separate player so the wrap-up alarm can't be cut off by (or cut off) the
  // evolve sound if the two ever overlap.
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final Random _rng = Random();

  _Phase _phase = _Phase.idle;
  int _elapsed = 0; // seconds since Start, during the working phase
  bool _alarmFired = false; // true once the 5-minute wrap-up nudge has played
  int _triggerCount = 0; // drives the monster evolve animation
  late String _cheerMessage = _pick(_idleCheers);

  Timer? _workTimer;
  Timer? _evolveTimer;

  bool get _ready => _elapsed >= _minTaskSeconds;

  String _pick(List<String> list) => list[_rng.nextInt(list.length)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player.setReleaseMode(ReleaseMode.stop);
    _alarmPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _workTimer?.cancel();
    _evolveTimer?.cancel();
    _player.dispose();
    _alarmPlayer.dispose();
    unawaited(_setWakelock(false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A browser screen wake lock is auto-released whenever the page/app is
    // hidden (e.g. on mobile Firefox/Chrome when you switch tabs or apps). When
    // we come back to the foreground mid-task, re-assert it so the screen keeps
    // staying awake.
    if (state == AppLifecycleState.resumed && _phase == _Phase.working) {
      unawaited(_setWakelock(true));
    }
  }

  void _onStart() {
    _workTimer?.cancel();
    analytics.logEvent('task_started', <String, Object>{
      'stage': context.read<MonsterState>().currentStage,
    });
    setState(() {
      _phase = _Phase.working;
      _elapsed = 0;
      _alarmFired = false;
      _cheerMessage = _pick(_workingCheers);
    });
    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed++;
        if (!_alarmFired && _elapsed >= _alarmSeconds) {
          _alarmFired = true;
          _fireWrapUpAlarm();
        }
      });
    });
    unawaited(_setWakelock(true));
  }

  Future<void> _onReady() async {
    if (_phase != _Phase.working || !_ready) return;
    _workTimer?.cancel();
    final taskSeconds = _elapsed;

    final monster = context.read<MonsterState>();
    await monster.evolve();
    if (!mounted) return;

    analytics.logEvent('evolution', <String, Object>{
      'stage': monster.currentStage,
      'prestige_count': monster.prestigeCount,
      'task_seconds': taskSeconds,
      'is_prestige': monster.lastWasPrestige ? 1 : 0,
    });

    setState(() {
      _phase = _Phase.evolving;
      _triggerCount++;
      _cheerMessage = _pick(_evolveCheers);
    });
    unawaited(HapticFeedback.heavyImpact());
    unawaited(_playSound());

    _evolveTimer?.cancel();
    _evolveTimer = Timer(const Duration(seconds: _evolveSeconds), () {
      if (!mounted) return;
      unawaited(_setWakelock(false));
      setState(() {
        _phase = _Phase.idle;
        _cheerMessage = _pick(_idleCheers);
      });
    });
  }

  /// The cheerful 5-minute nudge: chime + buzz + an upbeat "wrap it up"
  /// message, prompting the user to finish and hit READY.
  void _fireWrapUpAlarm() {
    _cheerMessage = "Time's up — hit READY! 🎉";
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_playAlarm());
  }

  Future<void> _playAlarm() async {
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.play(AssetSource('audio/alarm.wav'));
    } catch (_) {
      // Sound is non-critical; never let an audio failure break the flow.
    }
  }

  Future<void> _playSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/evolve.wav'));
    } catch (_) {
      // Sound is non-critical; never let an audio failure break the flow.
    }
  }

  /// Keep the screen awake during a task so the timer + 5-minute nudge stay
  /// visible. Non-critical: a failure (e.g. a browser without Wake Lock
  /// support) must never break the flow.
  Future<void> _setWakelock(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (_) {}
  }

  Future<void> _confirmReset() async {
    final monster = context.read<MonsterState>();
    final hasPrestige = monster.prestigeCount > 0;

    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset progress?'),
        content: Text(
          hasPrestige
              ? 'Send your monster back to Stage 1. Keep your '
                    'Prestige ×${monster.prestigeCount}, or wipe everything?'
              : 'Send your monster back to Stage 1?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'cancel'),
            child: const Text('Cancel'),
          ),
          if (hasPrestige)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'wipe'),
              child: const Text('Reset everything'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'keep'),
            child: Text(hasPrestige ? 'Keep prestige' : 'Reset'),
          ),
        ],
      ),
    );

    if (!mounted || choice == null || choice == 'cancel') return;
    analytics.logEvent('reset', <String, Object>{
      'keep_prestige': choice == 'keep' ? 1 : 0,
    });
    await monster.reset(keepPrestige: choice == 'keep');
    if (!mounted) return;
    _returnToIdle();
  }

  /// Cancel any in-progress task and return the loop to Idle. Shared by reset
  /// and profile switching so a fresh user (or a fresh run) starts clean.
  void _returnToIdle() {
    _workTimer?.cancel();
    _evolveTimer?.cancel();
    unawaited(_setWakelock(false));
    setState(() {
      _phase = _Phase.idle;
      _elapsed = 0;
      _alarmFired = false;
      _cheerMessage = _pick(_idleCheers);
    });
  }

  /// The user switcher: pick a profile, add a new one, or edit/delete.
  Future<void> _openProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Consumer<MonsterState>(
            builder: (context, monster, _) {
              final profiles = monster.profiles;
              final activeId = monster.activeProfile.id;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Users',
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  for (final p in profiles)
                    ListTile(
                      leading: Text(
                        p.animal,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(p.name),
                      selected: p.id == activeId,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (p.id == activeId)
                            Icon(Icons.check_circle, color: scheme.primary),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () => _openProfileEditor(existing: p),
                          ),
                          if (profiles.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete',
                              onPressed: () => _confirmDeleteProfile(p),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _selectProfile(p.id);
                      },
                    ),
                  const Divider(height: 8),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Add user'),
                    onTap: () => _openProfileEditor(),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _selectProfile(String id) async {
    final monster = context.read<MonsterState>();
    if (id == monster.activeProfile.id) return;
    await monster.switchProfile(id);
    if (!mounted) return;
    analytics.logEvent('profile_switched', <String, Object>{
      'profile_count': monster.profiles.length,
    });
    _returnToIdle();
  }

  /// Create a new user or edit an existing one: a name field + an animal picker.
  Future<void> _openProfileEditor({Profile? existing}) async {
    final isEdit = existing != null;
    final result = await showDialog<_ProfileEditorResult>(
      context: context,
      builder: (_) => _ProfileEditorDialog(existing: existing),
    );
    if (!mounted || result == null) return;

    final monster = context.read<MonsterState>();
    if (isEdit) {
      final name = result.name.isEmpty ? existing.name : result.name;
      await monster.updateProfile(
        existing.id,
        name: name,
        animal: result.animal,
      );
    } else {
      final name = result.name.isEmpty
          ? 'Player ${monster.profiles.length + 1}'
          : result.name;
      await monster.addProfile(name, result.animal);
      if (!mounted) return;
      analytics.logEvent('profile_created', <String, Object>{
        'profile_count': monster.profiles.length,
      });
      _returnToIdle();
    }
  }

  Future<void> _confirmDeleteProfile(Profile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'Delete ${profile.name} and their monster progress? '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    final monster = context.read<MonsterState>();
    final wasActive = profile.id == monster.activeProfile.id;
    final ok = await monster.deleteProfile(profile.id);
    if (!mounted || !ok) return;
    analytics.logEvent('profile_deleted', <String, Object>{
      'profile_count': monster.profiles.length,
    });
    if (wasActive) _returnToIdle();
  }

  @override
  Widget build(BuildContext context) {
    final monster = context.watch<MonsterState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        // Taller than the 56px default so the logo can render at 80px
        // without cropping.
        toolbarHeight: 96,
        // Explicit foreground so the title + actions stay high-contrast on the
        // dark surface (the default icon colour was blending in).
        foregroundColor: scheme.onSurface,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Image.asset(
            'assets/images/habit-monster.png',
            height: 80,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            semanticLabel: 'Task Monster',
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              icon: Text(
                monster.activeProfile.animal,
                style: const TextStyle(fontSize: 20),
              ),
              label: Text(
                monster.activeProfile.name,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: _openProfileSheet,
              style: TextButton.styleFrom(
                foregroundColor: scheme.primary,
                // Keep long names from pushing Reset off the bar.
                maximumSize: const Size(140, double.infinity),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
              onPressed: _confirmReset,
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Spacer(),
                      MonsterDisplay(
                        emoji: emojiForStage(monster.currentStage),
                        triggerCount: _triggerCount,
                        isFinal: monster.lastWasPrestige,
                      ),
                      const SizedBox(height: 16),
                      StageTracker(
                        stage: monster.currentStage,
                        prestigeCount: monster.prestigeCount,
                      ),
                      const Spacer(),
                      _buildPhaseArea(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 4,
              child: Text(
                'v$kAppVersion',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseArea(BuildContext context) {
    final theme = Theme.of(context);

    switch (_phase) {
      case _Phase.idle:
        return Column(
          key: const ValueKey<String>('idle'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CheerCharacter(emoji: '📣', message: _cheerMessage),
            const SizedBox(height: 20),
            Text(
              'Are you ready to start your task?',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _actionButton(
              label: 'START',
              icon: Icons.play_arrow_rounded,
              onPressed: _onStart,
            ),
          ],
        );

      case _Phase.working:
        final remaining = (_minTaskSeconds - _elapsed).clamp(0, _minTaskSeconds);
        return Column(
          key: const ValueKey<String>('working'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CheerCharacter(
              emoji: _alarmFired ? '⏰' : '💪',
              message: _cheerMessage,
            ),
            const SizedBox(height: 20),
            Text(
              _formatTime(_elapsed),
              style: theme.textTheme.displaySmall?.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                fontWeight: FontWeight.bold,
                color: _alarmFired ? Colors.amber.shade700 : null,
              ),
            ),
            Text(
              _alarmFired ? 'Time to wrap up! 🎉' : 'Task in progress',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _alarmFired
                    ? Colors.amber.shade700
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: _alarmFired ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(height: 16),
            _actionButton(
              label: _ready ? "I'M READY!" : 'Ready in ${remaining}s',
              icon: _ready ? Icons.check_circle_rounded : Icons.hourglass_top,
              onPressed: _ready ? _onReady : null,
            ),
          ],
        );

      case _Phase.evolving:
        return Column(
          key: const ValueKey<String>('evolving'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CheerCharacter(emoji: '🎉', message: _cheerMessage),
            const SizedBox(height: 20),
            Text(
                  'Evolving…',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: Colors.amber),
          ],
        );
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 260,
      height: 64,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// The name + trimmed value returned by [_ProfileEditorDialog].
class _ProfileEditorResult {
  const _ProfileEditorResult(this.name, this.animal);
  final String name;
  final String animal;
}

/// Add/edit-user dialog. Owns its [TextEditingController] so it is disposed
/// safely with the dialog (avoiding a use-after-dispose during the close
/// animation).
class _ProfileEditorDialog extends StatefulWidget {
  const _ProfileEditorDialog({this.existing});

  final Profile? existing;

  @override
  State<_ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends State<_ProfileEditorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late String _animal = widget.existing?.animal ?? defaultAnimal;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(isEdit ? 'Edit user' : 'New user'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 20),
            const Text('Choose an animal'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final animal in animalIcons)
                  GestureDetector(
                    onTap: () => setState(() => _animal = animal),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: animal == _animal
                            ? scheme.primaryContainer
                            : null,
                        border: Border.all(
                          width: 2,
                          color: animal == _animal
                              ? scheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(animal, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ProfileEditorResult(_controller.text.trim(), _animal),
          ),
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
