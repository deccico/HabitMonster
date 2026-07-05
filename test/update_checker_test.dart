import 'package:flutter_test/flutter_test.dart';
import 'package:habit_monster/services/update_checker.dart';
import 'package:habit_monster/version.dart';

void main() {
  test('no update when the deployed version matches the compiled one', () async {
    final checker = UpdateChecker(fetchVersion: () async => kAppVersion);
    await checker.check();
    expect(checker.updateAvailable, isFalse);
  });

  test('flags an update (and notifies) when versions differ', () async {
    final checker = UpdateChecker(fetchVersion: () async => '99.0.0');
    var notified = 0;
    checker.addListener(() => notified++);
    await checker.check();
    expect(checker.updateAvailable, isTrue);
    expect(notified, 1);

    // Further checks are a no-op once the prompt is up.
    await checker.check();
    expect(notified, 1);
  });

  test('fetch failures and null versions are ignored', () async {
    final failing = UpdateChecker(
      fetchVersion: () async => throw Exception('offline'),
    );
    await failing.check();
    expect(failing.updateAvailable, isFalse);

    final empty = UpdateChecker(fetchVersion: () async => null);
    await empty.check();
    expect(empty.updateAvailable, isFalse);
  });
}
