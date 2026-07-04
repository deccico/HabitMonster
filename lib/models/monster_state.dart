import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/stages.dart';

/// Holds and persists monster progress.
///
/// State is intentionally minimal: the current stage (1..20) and a prestige
/// counter, both persisted via [SharedPreferences]. Timing of when an evolution
/// is allowed is driven by the UI phase machine (start task -> wait -> ready),
/// so this model has no cooldown logic of its own.
class MonsterState extends ChangeNotifier {
  static const String _kStage = 'currentStage';
  static const String _kPrestige = 'prestigeCount';

  int _currentStage = 1;
  int _prestigeCount = 0;

  /// Re-entrancy guard so a single evolution can't advance two stages.
  bool _isEvolving = false;

  /// Whether the most recent [evolve] wrapped from stage 20 back to 1.
  /// The UI reads this to play a bigger "prestige" celebration.
  bool _lastWasPrestige = false;

  int get currentStage => _currentStage;
  int get prestigeCount => _prestigeCount;
  bool get lastWasPrestige => _lastWasPrestige;

  /// True when the monster is at the final stage.
  bool get isFinalStage => _currentStage >= kMaxStage;

  /// Load persisted progress from local storage. Safe to call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStage = (prefs.getInt(_kStage) ?? 1).clamp(1, kMaxStage);
    _prestigeCount = prefs.getInt(_kPrestige) ?? 0;
    notifyListeners();
  }

  /// Advance the monster one stage, wrapping to a prestige at stage 20.
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

  /// Manually reset progress back to Stage 1.
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

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStage, _currentStage);
    await prefs.setInt(_kPrestige, _prestigeCount);
  }
}
