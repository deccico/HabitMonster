import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_monster/models/monster_state.dart';
import 'package:habit_monster/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the real HomeScreen through the Idle -> Working -> Evolving -> Idle
/// flow to confirm the guided loop is wired correctly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The audioplayers plugin has no native side in tests; stub its channels.
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

  // wakelock_plus has no native side in tests; stub its channel too.
  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/wakelock'),
    (call) async => null,
  );

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

  // Cancels the periodic ticker / animation timers before the framework's
  // pending-timer check at teardown.
  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  }

  testWidgets('idle shows the prompt and a Start button', (tester) async {
    await pumpApp(tester);

    expect(find.text('Are you ready to start your task?'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(find.text('Stage 1 / 20'), findsOneWidget);
    // Reset control is present and labelled in the app bar.
    expect(find.widgetWithText(TextButton, 'Reset'), findsOneWidget);
    // The active profile button shows the default user's name.
    expect(find.widgetWithText(TextButton, 'Player 1'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('profile switcher adds a user and switches the active name', (
    tester,
  ) async {
    await pumpApp(tester);

    // Open the switcher sheet from the app-bar profile button.
    await tester.tap(find.widgetWithText(TextButton, 'Player 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Users'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Add user'), findsOneWidget);

    // Add a new user via the editor dialog.
    await tester.tap(find.widgetWithText(ListTile, 'Add user'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('New user'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // The app bar now shows the newly-created, now-active user.
    expect(find.widgetWithText(TextButton, 'Sam'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Player 1'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('Start -> 10s wait -> Ready -> evolve -> back to Start', (
    tester,
  ) async {
    final state = await pumpApp(tester);

    // Start the task; Ready is present but locked.
    await tester.tap(find.text('START'));
    await tester.pump();
    expect(find.textContaining('Ready in'), findsOneWidget);
    expect(state.currentStage, 1); // no evolution yet

    // Advance the 10-second task timer one tick at a time.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text("I'M READY!"), findsOneWidget);

    // Press Ready -> evolution happens, phase becomes Evolving.
    await tester.tap(find.text("I'M READY!"));
    await tester.pump();
    expect(state.currentStage, 2);
    expect(find.text('Stage 2 / 20'), findsOneWidget);
    expect(find.text('Evolving…'), findsOneWidget);

    // After the 3-second celebration we return to Idle.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('START'), findsOneWidget);
    expect(find.text('Are you ready to start your task?'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('Ready is ignored before the 10s gate', (tester) async {
    final state = await pumpApp(tester);

    await tester.tap(find.text('START'));
    await tester.pump(const Duration(seconds: 5));

    // Still locked: the ready label is absent, so tapping the disabled button
    // must not evolve.
    expect(find.text("I'M READY!"), findsNothing);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(state.currentStage, 1);

    await teardownTree(tester);
  });

  testWidgets('fires the cheerful wrap-up nudge at the 5-minute mark', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('START'));
    await tester.pump();

    // Well before 5 minutes: normal working state, no nudge.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Task in progress'), findsOneWidget);
    expect(find.text('Time to wrap up! 🎉'), findsNothing);

    // Advance to the 5-minute (300s) mark, one tick at a time.
    for (var i = 30; i < 300; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // The nudge is now showing: amber "wrap up" subtext + upbeat message,
    // and the working timer keeps running (Ready stays available).
    expect(find.text('Time to wrap up! 🎉'), findsOneWidget);
    expect(find.text('Task in progress'), findsNothing);
    expect(find.text("Time's up — hit READY! 🎉"), findsOneWidget);
    expect(find.text("I'M READY!"), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('reset button confirms then returns to Stage 1', (tester) async {
    final state = await pumpApp(tester);

    // Evolve once via the full flow so we have progress to reset.
    await tester.tap(find.text('START'));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.text("I'M READY!"));
    await tester.pump(const Duration(seconds: 3));
    expect(state.currentStage, 2);

    // Open the reset dialog and confirm. (pumpAndSettle can't be used: the
    // cheer mascot animates continuously, so the tree never settles.)
    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Reset progress?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pump();

    expect(state.currentStage, 1);
    expect(find.text('START'), findsOneWidget); // back to idle

    await teardownTree(tester);
  });
}
