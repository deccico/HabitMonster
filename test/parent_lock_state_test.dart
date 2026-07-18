import 'package:flutter_test/flutter_test.dart';
import 'package:task_monster/models/parent_lock_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('lock is off by default and rejects any PIN', () async {
    final lock = ParentLockState();
    await lock.load();
    expect(lock.enabled, isFalse);
    expect(lock.verify('0000'), isFalse);
  });

  test('enable/verify round-trip; wrong PIN rejected', () async {
    final lock = ParentLockState();
    await lock.load();
    await lock.enable('1234');
    expect(lock.enabled, isTrue);
    expect(lock.verify('1234'), isTrue);
    expect(lock.verify('4321'), isFalse);
  });

  test('PIN is stored salted and hashed, never in plaintext', () async {
    final lock = ParentLockState();
    await lock.load();
    await lock.enable('1234');

    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString('parentPinHash');
    final salt = prefs.getString('parentPinSalt');
    expect(hash, isNotNull);
    expect(hash, isNot(contains('1234')));
    expect(hash, hasLength(64)); // sha256 hex digest
    expect(salt, isNotEmpty);
  });

  test('state survives a reload (new instance, same prefs)', () async {
    final first = ParentLockState();
    await first.load();
    await first.enable('1234');

    final second = ParentLockState();
    await second.load();
    expect(second.enabled, isTrue);
    expect(second.verify('1234'), isTrue);
  });

  test('disable requires the correct PIN and wipes the stored hash', () async {
    final lock = ParentLockState();
    await lock.load();
    await lock.enable('1234');

    expect(await lock.disable('0000'), isFalse);
    expect(lock.enabled, isTrue);

    expect(await lock.disable('1234'), isTrue);
    expect(lock.enabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('parentPinHash'), isNull);
  });

  test(
    'disableApproved (biometric path) skips the PIN but wipes the hash',
    () async {
      final lock = ParentLockState();
      await lock.load();
      await lock.enable('1234');

      await lock.disableApproved();

      expect(lock.enabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('parentPinHash'), isNull);
    },
  );

  test('an enabled flag without a stored PIN loads as disabled', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'parentLockEnabled': true,
    });
    final lock = ParentLockState();
    await lock.load();
    expect(lock.enabled, isFalse);
  });

  test(
    'five wrong tries trigger the cooldown, blocking even the right PIN',
    () async {
      final lock = ParentLockState();
      await lock.load();
      await lock.enable('1234');

      for (var i = 0; i < ParentLockState.maxAttempts; i++) {
        expect(lock.verify('0000'), isFalse);
      }
      expect(lock.cooldownRemaining, greaterThan(0));
      expect(
        lock.verify('1234'),
        isFalse,
      ); // correct PIN blocked during cooldown
    },
  );
}
