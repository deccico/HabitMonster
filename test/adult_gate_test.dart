import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_monster/models/parent_lock_state.dart';
import 'package:task_monster/services/adult_gate.dart';
import 'package:task_monster/services/biometric_gate.dart';

/// No-fingerprint test double so the PIN dialog renders without the plugin.
class _NoBiometrics extends BiometricGate {
  @override
  Future<bool> get available async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}

/// The adult gate guards external links (Play Families policy): a correct
/// arithmetic answer opens the gate, anything else keeps it shut, and with
/// the parent lock enabled the PIN pad takes over as the gate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Pumps a screen whose button opens the gate and records the outcome.
  Future<void Function()> pumpGateHarness(
    WidgetTester tester, {
    required ParentLockState lock,
    required void Function(bool) onResult,
  }) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ParentLockState>.value(value: lock),
          Provider<BiometricGate>.value(value: _NoBiometrics()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );
    return () async {
      onResult(await AdultGate.requestApproval(ctx));
    };
  }

  testWidgets('correct answer approves', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showAdultChallengeDialog(context, a: 6, b: 7);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(find.text('6 × 7 = ?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '42');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Grown-ups only'), findsNothing);
  });

  testWidgets('wrong answer keeps the gate shut; cancel denies', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showAdultChallengeDialog(context, a: 8, b: 9);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '68');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Still open, error shown, no verdict yet.
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(find.text('Not quite — try again'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('lock disabled: requestApproval shows the challenge', (
    tester,
  ) async {
    final results = <bool>[];
    final open = await pumpGateHarness(
      tester,
      lock: ParentLockState(),
      onResult: results.add,
    );

    open();
    await tester.pumpAndSettle();
    expect(find.text('Grown-ups only'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(results, <bool>[false]);
  });

  testWidgets('lock enabled: requestApproval asks for the PIN instead', (
    tester,
  ) async {
    final lock = ParentLockState();
    await lock.enable('1234');
    final results = <bool>[];
    final open = await pumpGateHarness(
      tester,
      lock: lock,
      onResult: results.add,
    );

    open();
    await tester.pumpAndSettle();
    expect(find.text('Ask a grown-up! 🔒'), findsOneWidget);
    expect(find.text('Grown-ups only'), findsNothing);
  });
}
