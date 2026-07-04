import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/stages.dart';
import '../models/monster_state.dart';
import '../widgets/cooldown_indicator.dart';
import '../widgets/evolve_button.dart';
import '../widgets/monster_display.dart';
import '../widgets/stage_tracker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();

  /// UI-only ticker that refreshes the countdown once a second. The cooldown is
  /// still derived from the saved timestamp on every rebuild, so this timer is
  /// purely cosmetic and safe to miss ticks while backgrounded (spec 2.3).
  Timer? _ticker;

  /// Increments on every successful evolution to replay the monster animation.
  int _triggerCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player.setReleaseMode(ReleaseMode.stop);
    _startTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On resume, recompute the remaining cooldown from the persisted timestamp
    // and make sure the ticker is running (spec 2.6 "app closed during
    // cooldown").
    if (state == AppLifecycleState.resumed) {
      _startTicker();
      if (mounted) setState(() {});
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _onEvolvePressed() async {
    final monster = context.read<MonsterState>();
    final didEvolve = await monster.evolve();
    if (!didEvolve || !mounted) return;

    // Reward feedback (spec 1.3 / 2.5). Audio is triggered by this direct user
    // interaction, so browser autoplay policies allow it (spec 2.6).
    setState(() => _triggerCount++);
    unawaited(HapticFeedback.heavyImpact());
    unawaited(_playSound());
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
    if (mounted) setState(_startTicker);
  }

  Future<void> _playSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/evolve.wav'));
    } catch (_) {
      // Sound is non-critical; never let an audio failure break evolution.
    }
  }

  @override
  Widget build(BuildContext context) {
    final monster = context.watch<MonsterState>();
    final remaining = monster.remainingCooldown();
    final ready = remaining <= Duration.zero;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Task Monster',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset progress',
            onPressed: _confirmReset,
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
                  const SizedBox(height: 24),
                  StageTracker(
                    stage: monster.currentStage,
                    prestigeCount: monster.prestigeCount,
                  ),
                  const Spacer(),
                  EvolveButton(
                    onPressed: ready ? _onEvolvePressed : null,
                    remainingSeconds: remaining.inSeconds,
                    isFinalStage: monster.isFinalStage,
                  ),
                  const SizedBox(height: 20),
                  CooldownIndicator(remaining: remaining),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
