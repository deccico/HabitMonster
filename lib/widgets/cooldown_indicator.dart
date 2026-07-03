import 'package:flutter/material.dart';

import '../data/stages.dart';

/// Feedback area showing the 1-minute cooldown (spec 1.4 / 1.3).
///
/// Displays a progress bar that fills as the cooldown elapses plus a
/// "Ready in Ns" countdown. When [remaining] is zero it shows a ready state.
class CooldownIndicator extends StatelessWidget {
  const CooldownIndicator({super.key, required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seconds = remaining.inSeconds;
    final isReady = remaining <= Duration.zero;
    // Fraction of the cooldown already elapsed (0 -> just pressed, 1 -> ready).
    final progress = isReady
        ? 1.0
        : (1 - remaining.inMilliseconds / (kCooldownSeconds * 1000))
              .clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: isReady
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isReady ? 'Ready to evolve!' : 'Ready in ${seconds}s',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isReady
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isReady ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
