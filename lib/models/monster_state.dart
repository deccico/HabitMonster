import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/stages.dart';

/// Holds and persists all monster progress (spec 2.2 / 2.3).
///
/// State is intentionally minimal: the current stage (1..20), the timestamp of
/// the last evolution, and a prestige counter. The cooldown is *always* derived
/// from [lastEvolutionTime] via [remainingCooldown] rather than a running
/// counter, so it survives the app being suspended or closed (spec 2.3 timer
/// note, spec 2.6 "app closed during cooldown").
class MonsterState extends ChangeNotifier {
  MonsterState({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// Injectable clock so cooldown logic is deterministic in tests.
  final DateTime Function() _clock;

  static const String _kStage = 'currentStage';
  static const String _kLastMillis = 'lastEvolutionMillis';
  static const String _kPrestige = 'prestigeCount';

  int _currentStage = 1;
  DateTime? _lastEvolutionTime;
  int _prestigeCount = 0;

  /// Re-entrancy guard against rapid double-taps (spec 2.6).
  bool _isEvolving = false;

  /// Whether the most recent [evolve] wrapped from stage 20 back to 1.
  /// The UI reads this to play a bigger "prestige" celebration.
  bool _lastWasPrestige = false;

  int get currentStage => _currentStage;
  DateTime? get lastEvolutionTime => _lastEvolutionTime;
  int get prestigeCount => _prestigeCount;
  bool get lastWasPrestige => _lastWasPrestige;

  /// True when the monster is at the final stage (spec 2.3).
  bool get isFinalStage => _currentStage >= kMaxStage;

  /// Time left before the button re-enables; [Duration.zero] once elapsed.
  Duration remainingCooldown() {
    final last = _lastEvolutionTime;
    if (last == null) return Duration.zero;
    final remaining =
        const Duration(seconds: kCooldownSeconds) - _clock().difference(last);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get onCooldown => remainingCooldown() > Duration.zero;

  /// Whether an evolution is currently allowed.
  bool get canEvolve => !_isEvolving && !onCooldown;

  /// Load persisted progress from local storage (spec 2.5). Safe to call once
  /// at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStage = (prefs.getInt(_kStage) ?? 1).clamp(1, kMaxStage);
    _prestigeCount = prefs.getInt(_kPrestige) ?? 0;
    final millis = prefs.getInt(_kLastMillis);
    _lastEvolutionTime =
        millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
    notifyListeners();
  }

  /// Advance the monster one stage, wrapping to a prestige at stage 20.
  ///
  /// Returns `true` if the evolution happened, `false` if it was blocked by the
  /// cooldown or an in-flight evolution (rapid double-tap). On success the new
  /// state is persisted and listeners are notified immediately so the button
  /// disables on the very first registered tap.
  Future<bool> evolve() async {
    if (!canEvolve) return false;
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
      _lastEvolutionTime = _clock();
      notifyListeners();
      await _persist();
      return true;
    } finally {
      _isEvolving = false;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStage, _currentStage);
    await prefs.setInt(_kPrestige, _prestigeCount);
    final last = _lastEvolutionTime;
    if (last != null) {
      await prefs.setInt(_kLastMillis, last.millisecondsSinceEpoch);
    }
  }
}
