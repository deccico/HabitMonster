import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_monster/models/monster_state.dart';
import 'package:habit_monster/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the real HomeScreen to confirm the evolve -> lockout flow works
/// end-to-end at the widget layer (spec 1.4 UI + 2.6 rapid double-tap).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The audioplayers plugin has no native side in tests; stub its method
  // channels so player creation and playback are harmless no-ops.
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in const <String>[
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
      return null;
    });
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<MonsterState> pumpApp(WidgetTester tester) async {
    final state = MonsterState();
    await state.load();
    await tester.pumpWidget(
      ChangeNotifierProvider<MonsterState>.value(
        value: state,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    return state;
  }

  testWidgets('shows starting stage and an enabled Evolve button', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Task Monster'), findsOneWidget);
    expect(find.text('Stage 1 / 20'), findsOneWidget);
    expect(find.text('EVOLVE'), findsOneWidget);
  });

  testWidgets('tapping Evolve advances one stage and locks the button', (
    tester,
  ) async {
    final state = await pumpApp(tester);

    await tester.tap(find.text('EVOLVE'));
    await tester.pump(); // process the async evolve + setState

    expect(state.currentStage, 2);
    expect(find.text('Stage 2 / 20'), findsOneWidget);

    // Button is now locked: label switches to the countdown and taps no-op.
    expect(find.text('EVOLVE'), findsNothing);
    expect(find.textContaining('Locked'), findsOneWidget);

    // Rapid second tap while locked must not advance again (spec 2.6).
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(state.currentStage, 2);

    // Tear down the tree so the periodic ticker and evolution animation are
    // cancelled before the framework's pending-timer check.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('reset button confirms then returns to Stage 1', (tester) async {
    final state = await pumpApp(tester);

    await tester.tap(find.text('EVOLVE'));
    await tester.pump();
    expect(state.currentStage, 2);

    // Open the reset dialog from the app bar.
    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pumpAndSettle();
    expect(find.text('Reset progress?'), findsOneWidget);

    // Confirm (no prestige yet, so the single action is labelled "Reset").
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pump();

    expect(state.currentStage, 1);
    expect(state.onCooldown, isFalse); // cooldown cleared, button re-enabled
    expect(find.text('Stage 1 / 20'), findsOneWidget);
    expect(find.text('EVOLVE'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
