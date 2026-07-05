import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists the app-wide parental lock.
///
/// When enabled, an evolution needs a grown-up to enter a 4-digit PIN (see
/// `ParentGate`). The PIN is stored as `sha256(salt:pin)` in
/// [SharedPreferences] under keys shared by every profile:
///
///  * `parentLockEnabled` — whether the gate is active.
///  * `parentPinHash`     — hex digest of the salted PIN.
///  * `parentPinSalt`     — random 16-byte salt, base64url.
///
/// This is a friction gate for kids, not real security: clearing the site's
/// storage clears the lock too.
class ParentLockState extends ChangeNotifier {
  static const String _kEnabled = 'parentLockEnabled';
  static const String _kPinHash = 'parentPinHash';
  static const String _kPinSalt = 'parentPinSalt';

  /// Consecutive wrong tries before the cooldown kicks in.
  static const int maxAttempts = 5;

  /// How long the keypad stays locked after [maxAttempts] wrong tries.
  static const Duration cooldown = Duration(seconds: 30);

  bool _enabled = false;
  String _hash = '';
  String _salt = '';

  int _failedAttempts = 0;
  DateTime? _cooldownUntil;

  bool get enabled => _enabled;

  /// Seconds left in the wrong-PIN cooldown; 0 when input is allowed.
  int get cooldownRemaining {
    final until = _cooldownUntil;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left > 0 ? left : 0;
  }

  /// Load the persisted lock. Safe to call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hash = prefs.getString(_kPinHash) ?? '';
    _salt = prefs.getString(_kPinSalt) ?? '';
    // A lock without a stored PIN can never be opened — treat it as off.
    _enabled = (prefs.getBool(_kEnabled) ?? false) && _hash.isNotEmpty;
    notifyListeners();
  }

  /// Turn the lock on with a freshly chosen [pin].
  Future<void> enable(String pin) async {
    final rng = Random.secure();
    _salt = base64UrlEncode(List<int>.generate(16, (_) => rng.nextInt(256)));
    _hash = _digest(_salt, pin);
    _enabled = true;
    _failedAttempts = 0;
    _cooldownUntil = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, true);
    await prefs.setString(_kPinHash, _hash);
    await prefs.setString(_kPinSalt, _salt);
    notifyListeners();
  }

  /// Turn the lock off. Requires the current [pin]; returns `false` (and
  /// leaves the lock on) when it doesn't match. Wipes the stored PIN so
  /// re-enabling always sets a fresh one.
  Future<bool> disable(String pin) async {
    if (!verify(pin)) return false;
    _enabled = false;
    _hash = '';
    _salt = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, false);
    await prefs.remove(_kPinHash);
    await prefs.remove(_kPinSalt);
    notifyListeners();
    return true;
  }

  /// Check a PIN attempt. Tracks consecutive failures and enforces the
  /// cooldown (attempts during the cooldown always fail).
  bool verify(String pin) {
    if (cooldownRemaining > 0) return false;
    if (_hash.isNotEmpty && _digest(_salt, pin) == _hash) {
      _failedAttempts = 0;
      _cooldownUntil = null;
      return true;
    }
    _failedAttempts += 1;
    if (_failedAttempts >= maxAttempts) {
      _failedAttempts = 0;
      _cooldownUntil = DateTime.now().add(cooldown);
    }
    return false;
  }

  String _digest(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
