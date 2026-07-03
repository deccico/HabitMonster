import 'package:flutter_test/flutter_test.dart';
import 'package:habit_monster/data/stages.dart';
import 'package:habit_monster/models/monster_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Fresh in-memory prefs for every test.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('evolution', () {
    test('starts at stage 1 with no prestige', () async {
      final state = MonsterState();
      await state.load();
      expect(state.currentStage, 1);
      expect(state.prestigeCount, 0);
      expect(state.canEvolve, isTrue);
    });

    test('increments the stage by one', () async {
      final state = MonsterState();
      await state.load();

      final ok = await state.evolve();

      expect(ok, isTrue);
      expect(state.currentStage, 2);
      expect(state.prestigeCount, 0);
      expect(state.lastWasPrestige, isFalse);
    });

    test('wraps from stage 20 to 1 and increments prestige', () async {
      // Advance to stage 20 using a moving clock so the cooldown never blocks.
      var now = DateTime(2026);
      final state = MonsterState(clock: () => now);
      await state.load();

      for (var i = 0; i < kMaxStage - 1; i++) {
        await state.evolve();
        now = now.add(const Duration(minutes: 2));
      }
      expect(state.currentStage, kMaxStage);
      expect(state.isFinalStage, isTrue);

      final ok = await state.evolve();

      expect(ok, isTrue);
      expect(state.currentStage, 1);
      expect(state.prestigeCount, 1);
      expect(state.lastWasPrestige, isTrue);
    });
  });

  group('cooldown', () {
    test('blocks a second evolve within 60 seconds', () async {
      var now = DateTime(2026);
      final state = MonsterState(clock: () => now);
      await state.load();

      expect(await state.evolve(), isTrue);
      expect(state.currentStage, 2);

      // 30s later: still locked.
      now = now.add(const Duration(seconds: 30));
      expect(state.onCooldown, isTrue);
      expect(state.canEvolve, isFalse);
      expect(await state.evolve(), isFalse);
      expect(state.currentStage, 2);
    });

    test('re-enables after the cooldown elapses', () async {
      var now = DateTime(2026);
      final state = MonsterState(clock: () => now);
      await state.load();

      await state.evolve();
      now = now.add(const Duration(seconds: kCooldownSeconds + 1));

      expect(state.onCooldown, isFalse);
      expect(state.remainingCooldown(), Duration.zero);
      expect(await state.evolve(), isTrue);
      expect(state.currentStage, 3);
    });

    test('remainingCooldown counts down from 60s', () async {
      var now = DateTime(2026);
      final state = MonsterState(clock: () => now);
      await state.load();

      await state.evolve();
      expect(state.remainingCooldown().inSeconds, kCooldownSeconds);

      now = now.add(const Duration(seconds: 45));
      expect(state.remainingCooldown().inSeconds, kCooldownSeconds - 45);
    });
  });

  group('persistence', () {
    test('reloads stage, prestige and cooldown from storage', () async {
      final fixedNow = DateTime(2026, 1, 1, 12);

      // First session: evolve once, then simulate reaching stage 20 wrap.
      final first = MonsterState(clock: () => fixedNow);
      await first.load();
      await first.evolve(); // stage 2, timestamp = fixedNow

      // Second session: a brand new instance restores the saved state.
      final second = MonsterState(
        clock: () => fixedNow.add(const Duration(seconds: 20)),
      );
      await second.load();

      expect(second.currentStage, 2);
      expect(second.lastEvolutionTime, fixedNow);
      // 20s elapsed of the 60s cooldown -> ~40s remain, still locked.
      expect(second.onCooldown, isTrue);
      expect(second.remainingCooldown().inSeconds, kCooldownSeconds - 20);
    });
  });
}
