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
      final state = MonsterState();
      await state.load();

      for (var i = 0; i < kMaxStage - 1; i++) {
        await state.evolve();
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

  group('reset', () {
    test('keepPrestige returns to stage 1 but keeps prestige', () async {
      final state = MonsterState();
      await state.load();

      for (var i = 0; i < kMaxStage; i++) {
        await state.evolve();
      }
      await state.evolve(); // wrap -> stage 1, prestige 1
      expect(state.prestigeCount, 1);

      await state.reset(keepPrestige: true);

      expect(state.currentStage, 1);
      expect(state.prestigeCount, 1); // preserved
    });

    test('full wipe clears prestige too', () async {
      final state = MonsterState();
      await state.load();

      for (var i = 0; i < kMaxStage; i++) {
        await state.evolve();
      }
      await state.evolve();
      expect(state.prestigeCount, 1);

      await state.reset(keepPrestige: false);

      expect(state.currentStage, 1);
      expect(state.prestigeCount, 0);
    });
  });

  group('persistence', () {
    test('reloads stage and prestige from storage', () async {
      final first = MonsterState();
      await first.load();
      await first.evolve();
      await first.evolve(); // stage 3

      final second = MonsterState();
      await second.load();

      expect(second.currentStage, 3);
      expect(second.prestigeCount, 0);
    });
  });
}
