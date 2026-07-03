import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// The large centre-stage monster (spec 1.4).
///
/// Rendered as an emoji (per the emoji-only asset decision). The dramatic
/// flash / shake / scale feedback (spec 1.3 / 2.5) is driven by [triggerCount]:
/// each evolution increments it, which swaps the [Animate] widget's key and
/// replays the entrance animation from the start. A final-stage evolution plays
/// a bigger, longer celebration.
class MonsterDisplay extends StatelessWidget {
  const MonsterDisplay({
    super.key,
    required this.emoji,
    required this.triggerCount,
    required this.isFinal,
  });

  final String emoji;
  final int triggerCount;
  final bool isFinal;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      emoji,
      style: const TextStyle(fontSize: 140, height: 1.1),
    );

    // Keying by triggerCount forces a fresh Animate on every evolution so the
    // effects replay. triggerCount == 0 means "initial load, no celebration".
    if (triggerCount == 0) return child;

    final effects = <Effect<dynamic>>[
      ScaleEffect(
        begin: const Offset(0.7, 0.7),
        end: const Offset(1, 1),
        duration: (isFinal ? 500 : 320).ms,
        curve: Curves.elasticOut,
      ),
      ShakeEffect(
        duration: (isFinal ? 700 : 400).ms,
        hz: isFinal ? 8 : 5,
        rotation: isFinal ? 0.08 : 0.05,
      ),
      ShimmerEffect(
        duration: (isFinal ? 900 : 500).ms,
        color: isFinal ? Colors.amber : Colors.white,
      ),
    ];

    return child.animate(key: ValueKey<int>(triggerCount)).addEffects(effects);
  }
}
