import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Thin seam around `local_auth` fingerprint/biometric approval.
///
/// The PIN pad stays the source of truth and permanent fallback; biometrics
/// are just a faster "yes" on devices that have a reader. On web (no plugin)
/// and on any plugin failure this reports unavailable/denied rather than
/// throwing, so the PIN flow is never blocked. Tests inject a fake subclass.
class BiometricGate {
  BiometricGate([this._auth]);

  final LocalAuthentication? _auth;

  LocalAuthentication? get _plugin {
    if (kIsWeb) return null;
    return _auth ?? LocalAuthentication();
  }

  /// Whether a biometric reader is present, enrolled, and usable.
  Future<bool> get available async {
    final auth = _plugin;
    if (auth == null) return false;
    try {
      if (!await auth.canCheckBiometrics) return false;
      return (await auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false; // Missing plugin (tests/desktop) or device error.
    }
  }

  /// Prompt for a biometric approval. Returns `true` only on success.
  Future<bool> authenticate(String reason) async {
    final auth = _plugin;
    if (auth == null) return false;
    try {
      return await auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
