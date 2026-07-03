import 'package:flutter/material.dart';

import '../data/stages.dart';

/// Small progress indicator: "Stage X / 20", the stage's flavour name, and a
/// prestige chip once the user has rebirthed at least once (spec 1.4).
class StageTracker extends StatelessWidget {
  const StageTracker({
    super.key,
    required this.stage,
    required this.prestigeCount,
  });

  final int stage;
  final int prestigeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          nameForStage(stage),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Stage $stage / $kMaxStage',
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
