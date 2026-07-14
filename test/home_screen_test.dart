import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_monster/models/monster_state.dart';
import 'package:habit_monster/models/parent_lock_state.dart';
import 'package:habit_monster/screens/home_screen.dart';
import 'package:habit_monster/services/update_checker.dart';
import 'package:habit_monster/version.dart';
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

  // Clipboard (SystemChannels.platform) has no host in tests either; without
  // a stub, Clipboard.setData never completes.
  messenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => null,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  late ParentLockState lockState;
  late UpdateChecker updateChecker;
  String? deployedVersion; // what the fake version.json fetch reports

  Future<MonsterState> pumpApp(WidgetTester tester) async {
    final state = MonsterState();
    await state.load();
    lockState = ParentLockState();
    await lockState.load();
    deployedVersion = null;
    updateChecker = UpdateChecker(fetchVersion: () async => deployedVersion);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MonsterState>.value(value: state),
          ChangeNotifierProvider<ParentLockState>.value(value: lockState),
          ChangeNotifierProvider<UpdateChecker>.value(value: updateChecker),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    return state;
  }

  /// Taps the given digits on the PIN keypad, pumping between taps.
  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.widgetWithText(FilledButton, digit));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500)); // shake animation
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
    expect(find.text('Stage 1'), findsOneWidget);
    // Reset control is present in the app bar (icon-only, with a tooltip).
    expect(find.byTooltip('Reset'), findsOneWidget);
    expect(find.byIcon(Icons.restart_alt), findsOneWidget);
    // The active profile button shows the default user's name.
    expect(find.widgetWithText(TextButton, 'Player 1'), findsOneWidget);
    // The version badge is shown.
    expect(find.text('v$kAppVersion'), findsOneWidget);

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
    expect(find.text('Stage 2'), findsOneWidget);
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

  testWidgets('parent lock gates Ready behind the PIN dialog', (tester) async {
    final state = await pumpApp(tester);
    await lockState.enable('1234');
    await tester.pump();

    // Complete a task and press Ready -> the grown-up dialog appears and the
    // stage must NOT advance yet.
    await tester.tap(find.text('START'));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.text("I'M READY!"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Ask a grown-up! 🔒'), findsOneWidget);
    expect(state.currentStage, 1);

    // Wrong PIN: rejected, dialog stays, still stage 1.
    await enterPin(tester, '9999');
    expect(find.text('Wrong PIN — try again'), findsOneWidget);
    expect(find.text('Ask a grown-up! 🔒'), findsOneWidget);
    expect(state.currentStage, 1);

    // Correct PIN: approved, evolution runs.
    await enterPin(tester, '1234');
    await tester.pump();
    expect(state.currentStage, 2);
    expect(find.text('Evolving…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await teardownTree(tester);
  });

  testWidgets('dismissing the parent dialog keeps the task running', (
    tester,
  ) async {
    final state = await pumpApp(tester);
    await lockState.enable('1234');
    await tester.pump();

    await tester.tap(find.text('START'));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.text("I'M READY!"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Cancel: no evolution, and Ready is still available for a retry.
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(state.currentStage, 1);
    expect(find.text("I'M READY!"), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('parent lock is enabled from the header lock icon', (
    tester,
  ) async {
    await pumpApp(tester);

    // The header shows an open lock while the lock is off.
    expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock_open_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Choose and confirm a PIN.
    expect(find.text('Set parent PIN'), findsOneWidget);
    await enterPin(tester, '1234');
    expect(find.text('Confirm PIN'), findsOneWidget);
    await enterPin(tester, '1234');
    await tester.pump();

    expect(lockState.enabled, isTrue);
    expect(lockState.verify('1234'), isTrue);
    // Icon reflects the enabled state.
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.byIcon(Icons.lock_open_outlined), findsNothing);

    // The users sheet no longer hosts the toggle.
    await tester.tap(find.widgetWithText(TextButton, 'Player 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Parent lock'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('info menu opens About, Support, and Credits dialogs', (
    tester,
  ) async {
    await pumpApp(tester);

    Future<void> openMenu() async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> openEntry(String title) async {
      await tester.tap(find.widgetWithText(ListTile, title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> closeDialog() async {
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }

    // The kebab button opens a sheet listing the three entries.
    await openMenu();
    expect(
      find.widgetWithText(ListTile, 'About Task Monster'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ListTile, 'Support'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Credits'), findsOneWidget);

    // About: the kid-friendly pitch plus the app version.
    await openEntry('About Task Monster');
    expect(find.text('About Task Monster 🐾'), findsOneWidget);
    expect(
      find.textContaining('turns everyday tasks into an adventure'),
      findsOneWidget,
    );
    expect(find.text('Version v$kAppVersion'), findsOneWidget);
    await closeDialog();

    // Support: shows the contact email and copies it to the clipboard.
    await openMenu();
    await openEntry('Support');
    expect(find.textContaining('hello@darumatic.com'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Copy email'));
    // Extra pumps: the async clipboard write resolves, then the snackbar
    // animates in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Email address copied!'), findsOneWidget); // snackbar
    await tester.pump(const Duration(seconds: 5)); // let the snackbar expire

    // Credits.
    await openMenu();
    await openEntry('Credits');
    expect(find.text('CREATED BY'), findsOneWidget);
    expect(find.text('Adrian Deccico'), findsOneWidget);
    await closeDialog();

    await teardownTree(tester);
  });

  testWidgets('update banner appears when a newer deploy is detected', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('✨ A new version is ready!'), findsNothing);

    deployedVersion = '99.0.0';
    await updateChecker.check();
    await tester.pump();

    expect(find.text('✨ A new version is ready!'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Update'), findsOneWidget);
    // Tapping Update must not crash (the reload is a no-op off web).
    await tester.tap(find.widgetWithText(FilledButton, 'Update'));
    await tester.pump();

    await teardownTree(tester);
  });
}
