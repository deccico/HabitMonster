import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_monster/data/stages.dart';
import 'package:task_monster/models/monster_state.dart';
import 'package:task_monster/models/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Random whose nextInt returns a fixed sequence (repeating the last value),
/// making line rolls deterministic in tests.
class _SequenceRandom implements Random {
  _SequenceRandom(this._values);

  final List<int> _values;
  int _i = 0;

  @override
  int nextInt(int max) {
    final v = _values[_i.clamp(0, _values.length - 1)];
    _i++;
    return v % max;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

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

    test('wraps from the final stage to 1 and increments prestige', () async {
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

  group('evolution lines', () {
    test('first load assigns a valid line and persists it', () async {
      final state = MonsterState();
      await state.load();

      expect(state.lineIndex, inInclusiveRange(0, kEvolutionLines.length - 1));

      // The rolled line survives a reload rather than re-rolling.
      final second = MonsterState();
      await second.load();
      expect(second.lineIndex, state.lineIndex);
    });

    test('prestige wrap rolls a different line but keeps prestige', () async {
      final state = MonsterState();
      await state.load();
      final before = state.lineIndex;

      for (var i = 0; i < kMaxStage; i++) {
        await state.evolve();
      }

      expect(state.currentStage, 1);
      expect(state.prestigeCount, 1);
      expect(state.lineIndex, isNot(before));
      expect(state.lineIndex, inInclusiveRange(0, kEvolutionLines.length - 1));
    });

    test('reset rolls a different line', () async {
      final state = MonsterState();
      await state.load();
      final before = state.lineIndex;

      await state.reset(keepPrestige: true);

      expect(state.lineIndex, isNot(before));
    });

    test('each profile keeps its own line', () async {
      // Inject a fixed-sequence Random so the two profiles are guaranteed to
      // land on different lines.
      final state = MonsterState(random: _SequenceRandom(<int>[0, 2]));
      await state.load();
      final first = state.activeProfile.id;
      expect(state.lineIndex, 0);

      await state.addProfile('Sam', '🐼');
      expect(state.lineIndex, 2);

      await state.switchProfile(first);
      expect(state.lineIndex, 0);
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

  group('profiles', () {
    test('first run creates a single default profile at stage 1', () async {
      final state = MonsterState();
      await state.load();

      expect(state.profiles, hasLength(1));
      expect(state.activeProfile.name, 'Player 1');
      expect(state.currentStage, 1);
      expect(state.prestigeCount, 0);
    });

    test(
      'migrates legacy single-monster progress into the first profile',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'currentStage': 3,
          'prestigeCount': 1,
        });

        final state = MonsterState();
        await state.load();

        expect(state.profiles, hasLength(1));
        expect(state.currentStage, 3);
        expect(state.prestigeCount, 1);
      },
    );

    test('each profile keeps independent progress', () async {
      final state = MonsterState();
      await state.load();
      final first = state.activeProfile.id;

      // Advance the default profile to stage 3.
      await state.evolve();
      await state.evolve();
      expect(state.currentStage, 3);

      // A new profile starts fresh and does not disturb the first.
      final sam = await state.addProfile('Sam', '🐼');
      expect(state.activeProfile.id, sam.id);
      expect(state.currentStage, 1);

      await state.evolve(); // Sam -> stage 2

      // Switching back restores the first profile's progress.
      await state.switchProfile(first);
      expect(state.currentStage, 3);

      await state.switchProfile(sam.id);
      expect(state.currentStage, 2);
    });

    test('active profile and progress survive a reload', () async {
      final first = MonsterState();
      await first.load();
      final sam = await first.addProfile('Sam', '🐼');
      await first.evolve(); // Sam -> stage 2

      final second = MonsterState();
      await second.load();

      expect(second.profiles, hasLength(2));
      expect(second.activeProfile.id, sam.id); // active pointer persisted
      expect(second.currentStage, 2);
    });

    test('updateProfile renames and re-animals', () async {
      final state = MonsterState();
      await state.load();
      final id = state.activeProfile.id;

      await state.updateProfile(id, name: 'Alex', animal: '🦁');

      expect(state.activeProfile.name, 'Alex');
      expect(state.activeProfile.animal, '🦁');
    });

    test(
      'deleteProfile removes it and its progress, refusing the last one',
      () async {
        final state = MonsterState();
        await state.load();
        final first = state.activeProfile.id;
        final sam = await state.addProfile('Sam', '🐼');
        await state.evolve(); // Sam -> stage 2

        // Delete the active (Sam) -> falls back to the first profile.
        final deleted = await state.deleteProfile(sam.id);
        expect(deleted, isTrue);
        expect(state.profiles, hasLength(1));
        expect(state.activeProfile.id, first);

        // Sam's progress keys are gone: re-adding a profile starts fresh.
        final reloaded = MonsterState();
        await reloaded.load();
        expect(reloaded.profiles.any((Profile p) => p.id == sam.id), isFalse);

        // The last remaining profile cannot be deleted.
        final refused = await state.deleteProfile(first);
        expect(refused, isFalse);
        expect(state.profiles, hasLength(1));
      },
    );
  });
}
