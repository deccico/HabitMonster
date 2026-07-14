import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/animals.dart';
import '../data/stages.dart';
import 'profile.dart';

/// Holds and persists monster progress for the active user profile.
///
/// The device can hold several [Profile]s, each with its own independent
/// progress (current stage 1..kMaxStage + a prestige counter). All state is persisted
/// via [SharedPreferences]:
///
///  * `profiles`        — JSON list of every profile (id, name, animal).
///  * `activeProfileId` — id of the profile currently in play.
///  * `stage_<id>`      — that profile's current stage.
///  * `prestige_<id>`   — that profile's prestige count.
///
/// Timing of when an evolution is allowed is driven by the UI phase machine
/// (start task -> wait -> ready), so this model has no cooldown logic of its
/// own.
class MonsterState extends ChangeNotifier {
  static const String _kProfiles = 'profiles';
  static const String _kActiveId = 'activeProfileId';

  // Legacy single-monster keys, migrated into the first profile on first load.
  static const String _kLegacyStage = 'currentStage';
  static const String _kLegacyPrestige = 'prestigeCount';

  final List<Profile> _profiles = <Profile>[];
  String _activeId = '';

  int _currentStage = 1;
  int _prestigeCount = 0;

  /// Re-entrancy guard so a single evolution can't advance two stages.
  bool _isEvolving = false;

  /// Whether the most recent [evolve] wrapped from the final stage back to 1.
  /// The UI reads this to play a bigger "prestige" celebration.
  bool _lastWasPrestige = false;

  int get currentStage => _currentStage;
  int get prestigeCount => _prestigeCount;
  bool get lastWasPrestige => _lastWasPrestige;

  /// True when the monster is at the final stage.
  bool get isFinalStage => _currentStage >= kMaxStage;

  /// All saved profiles (never empty after [load]).
  List<Profile> get profiles => List<Profile>.unmodifiable(_profiles);

  /// The profile currently in play.
  Profile get activeProfile =>
      _profiles.firstWhere((Profile p) => p.id == _activeId);

  String _stageKey(String id) => 'stage_$id';
  String _prestigeKey(String id) => 'prestige_$id';

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Load persisted profiles + the active profile's progress. Safe to call
  /// once at startup. Handles first-run and migration from the old
  /// single-monster layout.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _profiles.clear();
    final raw = prefs.getString(_kProfiles);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        _profiles.add(Profile.fromJson(item as Map<String, dynamic>));
      }
    }

    if (_profiles.isEmpty) {
      // First run OR migration from the single-monster install: seed one
      // profile, carrying over any legacy progress so nothing is lost.
      final id = _newId();
      _profiles.add(Profile(id: id, name: 'Player 1', animal: defaultAnimal));
      final legacyStage = (prefs.getInt(_kLegacyStage) ?? 1).clamp(1, kMaxStage);
      final legacyPrestige = prefs.getInt(_kLegacyPrestige) ?? 0;
      _activeId = id;
      await prefs.setInt(_stageKey(id), legacyStage);
      await prefs.setInt(_prestigeKey(id), legacyPrestige);
      await _persistProfiles();
    } else {
      final storedActive = prefs.getString(_kActiveId);
      _activeId =
          (storedActive != null && _profiles.any((p) => p.id == storedActive))
          ? storedActive
          : _profiles.first.id;
    }

    await _loadActiveProgress();
    notifyListeners();
  }

  Future<void> _loadActiveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStage = (prefs.getInt(_stageKey(_activeId)) ?? 1).clamp(
      1,
      kMaxStage,
    );
    _prestigeCount = prefs.getInt(_prestigeKey(_activeId)) ?? 0;
    _lastWasPrestige = false;
  }

  /// Advance the active profile one stage, wrapping to a prestige at the final stage.
  ///
  /// Returns `true` if the evolution happened, `false` if an evolution was
  /// already in flight. On success the new state is persisted and listeners
  /// are notified.
  Future<bool> evolve() async {
    if (_isEvolving) return false;
    _isEvolving = true;
    try {
      if (_currentStage >= kMaxStage) {
        _currentStage = 1;
        _prestigeCount += 1;
        _lastWasPrestige = true;
      } else {
        _currentStage += 1;
        _lastWasPrestige = false;
      }
      notifyListeners();
      await _persist();
      return true;
    } finally {
      _isEvolving = false;
    }
  }

  /// Manually reset the active profile's progress back to Stage 1.
  ///
  /// When [keepPrestige] is true the lifetime prestige count is preserved
  /// (a "start this run over" reset); otherwise everything is wiped to a
  /// brand-new state.
  Future<void> reset({required bool keepPrestige}) async {
    _currentStage = 1;
    _lastWasPrestige = false;
    if (!keepPrestige) _prestigeCount = 0;
    notifyListeners();
    await _persist();
  }

  /// Switch the active profile and load its progress.
  Future<void> switchProfile(String id) async {
    if (id == _activeId || !_profiles.any((Profile p) => p.id == id)) return;
    _activeId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveId, _activeId);
    await _loadActiveProgress();
    notifyListeners();
  }

  /// Create a new profile (fresh at Stage 1) and switch to it.
  Future<Profile> addProfile(String name, String animal) async {
    final profile = Profile(id: _newId(), name: name, animal: animal);
    _profiles.add(profile);
    await _persistProfiles();
    await switchProfile(profile.id);
    return profile;
  }

  /// Rename a profile and/or change its animal icon.
  Future<void> updateProfile(String id, {String? name, String? animal}) async {
    final profile = _profiles.firstWhere((Profile p) => p.id == id);
    if (name != null) profile.name = name;
    if (animal != null) profile.animal = animal;
    await _persistProfiles();
    notifyListeners();
  }

  /// Delete a profile and its progress. Never removes the last profile.
  ///
  /// Returns `true` if the profile was deleted. If the active profile is
  /// removed, the first remaining profile becomes active.
  Future<bool> deleteProfile(String id) async {
    if (_profiles.length <= 1) return false;
    final index = _profiles.indexWhere((Profile p) => p.id == id);
    if (index < 0) return false;

    _profiles.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stageKey(id));
    await prefs.remove(_prestigeKey(id));
    await _persistProfiles();

    if (_activeId == id) {
      _activeId = _profiles.first.id;
      await prefs.setString(_kActiveId, _activeId);
      await _loadActiveProgress();
    }
    notifyListeners();
    return true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stageKey(_activeId), _currentStage);
    await prefs.setInt(_prestigeKey(_activeId), _prestigeCount);
  }

  Future<void> _persistProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kProfiles,
      jsonEncode(_profiles.map((Profile p) => p.toJson()).toList()),
    );
    await prefs.setString(_kActiveId, _activeId);
  }
}
