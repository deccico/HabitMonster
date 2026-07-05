import 'package:flutter_test/flutter_test.dart';
import 'package:habit_monster/data/stages.dart';
import 'package:habit_monster/widgets/stage_tracker.dart';
import 'package:flutter/material.dart';

void main() {
  group('stage data consistency', () {
    // stageEmojis/stageNames are parallel lists and kMaxStage is an
    // independent constant; a mismatch either throws a range error at
    // runtime or silently makes high stages unreachable.
    test('both lists have exactly kMaxStage entries', () {
      expect(stageEmojis.length, kMaxStage);
      expect(stageNames.length, kMaxStage);
    });

    test('no duplicate emoji or names', () {
      expect(stageEmojis.toSet().length, stageEmojis.length);
      expect(stageNames.toSet().length, stageNames.length);
    });

    test('lookups clamp out-of-range stages instead of throwing', () {
      expect(emojiForStage(0), stageEmojis.first);
      expect(emojiForStage(kMaxStage + 5), stageEmojis.last);
      expect(nameForStage(0), stageNames.first);
      expect(nameForStage(kMaxStage + 5), stageNames.last);
    });
  });

  group('StageTracker label', () {
    Future<void> pumpTracker(
      WidgetTester tester, {
      required int stage,
      required int prestigeCount,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageTracker(stage: stage, prestigeCount: prestigeCount),
          ),
        ),
      );
    }

    testWidgets('shows an open-ended "Stage N" with no total', (tester) async {
      await pumpTracker(tester, stage: 7, prestigeCount: 0);
      expect(find.text('Stage 7'), findsOneWidget);
      expect(find.textContaining('/'), findsNothing);
      expect(find.textContaining('Prestige'), findsNothing);
    });

    testWidgets('shows the prestige chip after a rebirth', (tester) async {
      await pumpTracker(tester, stage: 1, prestigeCount: 2);
      expect(find.text('Stage 1'), findsOneWidget);
      expect(find.text('Prestige ×2'), findsOneWidget);
    });
  });
}
