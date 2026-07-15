import 'package:flutter/material.dart';

import '../data/stages.dart';

/// Small progress indicator: "Stage X" (the total is deliberately hidden so
/// the evolution ladder feels endless), the stage's flavour name, and a
/// prestige chip once the user has rebirthed at least once (spec 1.4).
class StageTracker extends StatelessWidget {
  const StageTracker({
    super.key,
    required this.stage,
    required this.prestigeCount,
    required this.lineIndex,
  });

  final int stage;
  final int prestigeCount;

  /// Which evolution line the flavour name is read from.
  final int lineIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Long flavour names ("Celestial Firebird") must shrink to fit one
        // line: wrapping makes the home Column taller than the viewport on
        // small screens.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            nameForStage(stage, lineIndex),
            maxLines: 1,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Stage $stage',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (prestigeCount > 0) ...<Widget>[
          const SizedBox(height: 8),
          Chip(
            avatar: const Text('⭐', style: TextStyle(fontSize: 16)),
            label: Text('Prestige ×$prestigeCount'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}
