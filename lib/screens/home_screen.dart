import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../data/stages.dart';
import '../models/monster_state.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  /// Minimum seconds the user must "work" before Ready unlocks.
  static const int _minTaskSeconds = 10;

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
  final Random _rng = Random();

  _Phase _phase = _Phase.idle;
  int _elapsed = 0; // seconds since Start, during the working phase
  int _triggerCount = 0; // drives the monster evolve animation
  late String _cheerMessage = _pick(_idleCheers);

  Timer? _workTimer;
  Timer? _evolveTimer;

  bool get _ready => _elapsed >= _minTaskSeconds;

  String _pick(List<String> list) => list[_rng.nextInt(list.length)];

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    _evolveTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _onStart() {
    _workTimer?.cancel();
    setState(() {
      _phase = _Phase.working;
      _elapsed = 0;
      _cheerMessage = _pick(_workingCheers);
    });
    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });
  }

  Future<void> _onReady() async {
    if (_phase != _Phase.working || !_ready) return;
    _workTimer?.cancel();

    final monster = context.read<MonsterState>();
    await monster.evolve();
    if (!mounted) return;

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
      setState(() {
        _phase = _Phase.idle;
        _cheerMessage = _pick(_idleCheers);
      });
    });
  }

  Future<void> _playSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/evolve.wav'));
    } catch (_) {
      // Sound is non-critical; never let an audio failure break the flow.
    }
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
    await monster.reset(keepPrestige: choice == 'keep');
    if (!mounted) return;
    _workTimer?.cancel();
    _evolveTimer?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _elapsed = 0;
      _cheerMessage = _pick(_idleCheers);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monster = context.watch<MonsterState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // Explicit foreground so the title + actions stay high-contrast on the
        // dark surface (the default icon colour was blending in).
        foregroundColor: scheme.onSurface,
        title: const Text(
          'Task Monster',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: <Widget>[
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
        child: Center(
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
            CheerCharacter(emoji: '💪', message: _cheerMessage),
            const SizedBox(height: 20),
            Text(
              _formatTime(_elapsed),
              style: theme.textTheme.displaySmall?.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Task in progress',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
