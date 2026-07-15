import 'package:flutter_test/flutter_test.dart';
import 'package:habit_monster/data/stages.dart';
import 'package:habit_monster/widgets/stage_tracker.dart';
import 'package:flutter/material.dart';

void main() {
  group('stage data consistency', () {
    // Each line's emoji/name lists are parallel and kMaxStage is an
    // independent constant; a mismatch either throws a range error at
    // runtime or silently makes high stages unreachable.
    test('every line has exactly kMaxStage emoji and names', () {
      for (final line in kEvolutionLines) {
        expect(line.emojis.length, kMaxStage, reason: line.name);
        expect(line.names.length, kMaxStage, reason: line.name);
      }
    });

    test('no duplicate emoji or names within a line', () {
      for (final line in kEvolutionLines) {
        expect(
          line.emojis.toSet().length,
          line.emojis.length,
          reason: line.name,
        );
        expect(line.names.toSet().length, line.names.length, reason: line.name);
      }
    });

    test('every line starts from the identical mystery egg', () {
      // All lines must share stage 1 so a fresh egg gives away nothing about
      // which creature is inside.
      for (final line in kEvolutionLines) {
        expect(line.emojis.first, '🥚', reason: line.name);
        expect(line.names.first, 'Mystery Egg', reason: line.name);
      }
    });

    test('lines diverge at every stage after the egg', () {
      // The random line roll is only visible if the lines actually look
      // different: past stage 1, no two lines may show the same emoji at the
      // same stage (regression test — 🐣/🦎/🦕/🦖 used to repeat across lines,
      // so every fresh egg looked identical for its first stages).
      for (var stage = 2; stage <= kMaxStage; stage++) {
        final emojisAtStage = kEvolutionLines
            .map((line) => line.emojis[stage - 1])
            .toList();
        expect(
          emojisAtStage.toSet().length,
          emojisAtStage.length,
          reason: 'duplicate emoji at stage $stage: $emojisAtStage',
        );
      }
    });

    test('lookups clamp out-of-range stages and lines instead of throwing', () {
      final first = kEvolutionLines.first;
      final last = kEvolutionLines.last;
      expect(emojiForStage(0, 0), first.emojis.first);
      expect(emojiForStage(kMaxStage + 5, 0), first.emojis.last);
      expect(nameForStage(0, 0), first.names.first);
      expect(nameForStage(kMaxStage + 5, 0), first.names.last);
      // Line index is clamped too (e.g. stale prefs from a removed line).
      expect(emojiForStage(1, -3), first.emojis.first);
      expect(nameForStage(kMaxStage, 99), last.names.last);
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
            body: StageTracker(
              stage: stage,
              prestigeCount: prestigeCount,
              lineIndex: 0,
            ),
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

    testWidgets('long flavour names shrink instead of wrapping', (
      tester,
    ) async {
      // A wrapped name makes the whole home Column taller than a small
      // viewport (regression: 1px RenderFlex overflow whenever the rolled
      // line had a long name). Render the longest name in the data inside a
      // tight box and check the tracker gets no taller than with a short
      // name — wrapping onto a second line would add a full line of height,
      // while scaling down to fit can only shrink it.
      var longLine = 0;
      var longStage = 1;
      var longest = 0;
      for (var l = 0; l < kEvolutionLines.length; l++) {
        for (var s = 0; s < kMaxStage; s++) {
          final len = kEvolutionLines[l].names[s].length;
          if (len > longest) {
            longest = len;
            longLine = l;
            longStage = s + 1;
          }
        }
      }

      Future<double> trackerHeight(int stage, int lineIndex) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 150,
                  child: StageTracker(
                    stage: stage,
                    prestigeCount: 0,
                    lineIndex: lineIndex,
                  ),
                ),
              ),
            ),
          ),
        );
        return tester.getSize(find.byType(StageTracker)).height;
      }

      final withShortName = await trackerHeight(1, 0); // 'Mystery Egg'
      final withLongName = await trackerHeight(longStage, longLine);
      expect(withLongName, lessThanOrEqualTo(withShortName));
    });
  });
}
