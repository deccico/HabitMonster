import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/parent_lock_state.dart';
import '../services/biometric_gate.dart';

const int _pinLength = 4;

/// Ask a grown-up to approve: fingerprint first (when the device has one —
/// the OS prompt opens immediately), with the parent PIN as the fallback
/// behind "Use PIN instead".
///
/// Resolves to the PIN string once entered, or the empty string when the
/// approval came from a successful biometric read (callers that need the PIN
/// itself, e.g. disabling the lock, still get it from PIN entry; gate callers
/// just check for non-null), or `null` if dismissed.
Future<String?> showPinVerifyDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _PinPadDialog(mode: _PinMode.verify),
  );
}

/// What the setup dialog resolved to: the chosen PIN plus whether a
/// fingerprint may approve in place of it.
typedef PinSetupResult = ({String pin, bool allowBiometric});

/// Let a grown-up choose a new parent PIN (entered twice to confirm) and —
/// when the device has a fingerprint reader — whether fingerprint approval
/// is allowed. Resolves to the choices, or `null` if dismissed.
Future<PinSetupResult?> showPinSetupDialog(BuildContext context) {
  return showDialog<PinSetupResult>(
    context: context,
    builder: (_) => const _PinPadDialog(mode: _PinMode.setup),
  );
}

enum _PinMode { verify, setup }

class _PinPadDialog extends StatefulWidget {
  const _PinPadDialog({required this.mode});

  final _PinMode mode;

  @override
  State<_PinPadDialog> createState() => _PinPadDialogState();
}

class _PinPadDialogState extends State<_PinPadDialog> {
  String _entered = '';

  /// True once the biometric reader is confirmed present + enrolled (and,
  /// in verify mode, allowed by the lock's setup choice).
  bool _bioAvailable = false;

  /// Verify mode: the fingerprint leads and the keypad is the fallback,
  /// revealed only by "Use PIN instead". Always true in setup mode and on
  /// devices without a reader.
  bool _showPinPad = true;

  /// Setup only: the parent's choice for the "allow fingerprint" switch.
  bool _allowBiometric = true;

  /// Setup happens in two passes: choose, then confirm.
  String? _firstPass;

  /// Bumped on every rejected entry so the dots re-run their shake effect.
  int _shakeTick = 0;

  String? _message;
  Timer? _cooldownTicker;

  bool get _isSetup => widget.mode == _PinMode.setup;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    // Verify mode also honors the choice made at setup; setup mode only
    // needs the reader to exist to offer the switch.
    if (!_isSetup && !context.read<ParentLockState>().biometricAllowed) return;
    final available = await context.read<BiometricGate>().available;
    if (!mounted || !available) return;
    setState(() {
      _bioAvailable = true;
      // Fingerprint first at the gate; the keypad becomes the fallback.
      if (!_isSetup) _showPinPad = false;
    });
    if (!_isSetup) unawaited(_onFingerprint());
  }

  Future<void> _onFingerprint() async {
    final ok = await context.read<BiometricGate>().authenticate(
      'A parent needs to approve this',
    );
    if (!mounted) return;
    if (!ok) {
      // Cancelled or unrecognized: stay on the fingerprint view so the icon
      // can retry, with the PIN fallback still one tap away.
      setState(() => _message = 'Fingerprint not recognized — try again');
      return;
    }
    // Empty string = "approved without typing the PIN"; callers only check
    // for non-null.
    Navigator.pop(context, '');
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    super.dispose();
  }

  /// Keep rebuilding once a second while the cooldown runs so the countdown
  /// in the message stays current.
  void _watchCooldown(ParentLockState lock) {
    _cooldownTicker?.cancel();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (lock.cooldownRemaining == 0) {
          _cooldownTicker?.cancel();
          _message = null;
        }
      });
    });
  }

  void _onDigit(String digit, ParentLockState lock) {
    if (_entered.length >= _pinLength) return;
    if (!_isSetup && lock.cooldownRemaining > 0) return;
    setState(() => _entered += digit);
    if (_entered.length == _pinLength) _submit(lock);
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _reject(String message) {
    setState(() {
      _entered = '';
      _shakeTick++;
      _message = message;
    });
  }

  void _submit(ParentLockState lock) {
    if (_isSetup) {
      if (_firstPass == null) {
        setState(() {
          _firstPass = _entered;
          _entered = '';
          _message = null;
        });
      } else if (_entered == _firstPass) {
        Navigator.pop(context, (
          pin: _entered,
          allowBiometric: _bioAvailable && _allowBiometric,
        ));
      } else {
        _firstPass = null;
        _reject("PINs didn't match — start over");
      }
      return;
    }

    final pin = _entered;
    if (lock.verify(pin)) {
      Navigator.pop(context, pin);
    } else if (lock.cooldownRemaining > 0) {
      _reject('Too many tries!');
      _watchCooldown(lock);
    } else {
      _reject('Wrong PIN — try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<ParentLockState>();
    final scheme = Theme.of(context).colorScheme;
    final coolingDown = !_isSetup && lock.cooldownRemaining > 0;

    final String title;
    final String subtitle;
    if (!_isSetup) {
      title = 'Ask a grown-up! 🔒';
      subtitle = 'A parent needs to approve this.';
    } else if (_firstPass == null) {
      title = 'Set parent PIN';
      subtitle = 'Choose a 4-digit PIN.';
    } else {
      title = 'Confirm PIN';
      subtitle = 'Enter the same PIN again.';
    }

    return AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      // Scrollable so the keypad (plus the fingerprint button when present)
      // never overflows on short screens.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (!_showPinPad) ...<Widget>[
              // Fingerprint leads; tapping the icon re-runs the prompt.
              IconButton(
                onPressed: _onFingerprint,
                iconSize: 56,
                icon: Icon(Icons.fingerprint, color: scheme.primary),
                tooltip: 'Use fingerprint',
              ),
              Text(
                'Tap to scan a fingerprint',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              SizedBox(
                height: 24,
                child: Center(
                  child: Text(
                    _message ?? '',
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _showPinPad = true;
                  _message = null;
                }),
                child: const Text('Use PIN instead'),
              ),
            ] else ...<Widget>[
            Row(
                  key: ValueKey<int>(_shakeTick),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (var i = 0; i < _pinLength; i++)
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _entered.length
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                        ),
                      ),
                  ],
                )
                .animate(target: _shakeTick > 0 ? 1 : 0)
                .shake(hz: 6, duration: 400.ms),
            SizedBox(
              height: 24,
              child: Center(
                child: Text(
                  coolingDown
                      ? 'Too many tries — wait ${lock.cooldownRemaining}s'
                      : (_message ?? ''),
                  style: TextStyle(color: scheme.error, fontSize: 12),
                ),
              ),
            ),
            for (final row in const <List<String>>[
              <String>['1', '2', '3'],
              <String>['4', '5', '6'],
              <String>['7', '8', '9'],
              <String>['', '0', '<'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (final key in row)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: key.isEmpty
                            ? const SizedBox(width: 60, height: 52)
                            : SizedBox(
                                width: 60,
                                height: 52,
                                child: key == '<'
                                    ? IconButton(
                                        onPressed: _onBackspace,
                                        icon: const Icon(
                                          Icons.backspace_outlined,
                                        ),
                                        tooltip: 'Delete',
                                      )
                                    : FilledButton.tonal(
                                        onPressed: coolingDown
                                            ? null
                                            : () => _onDigit(key, lock),
                                        style: FilledButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: const TextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                        child: Text(key),
                                      ),
                              ),
                      ),
                  ],
                ),
              ),
            if (_isSetup && _bioAvailable)
              SwitchListTile(
                value: _allowBiometric,
                onChanged: (v) => setState(() => _allowBiometric = v),
                title: const Text(
                  'Allow fingerprint approval',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Any fingerprint enrolled on this device can approve',
                  style: TextStyle(fontSize: 11),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
