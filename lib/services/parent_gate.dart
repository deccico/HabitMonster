import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/parent_lock_state.dart';
import '../widgets/pin_pad_dialog.dart';

/// The single seam where a grown-up approves an evolution.
///
/// Today approval means entering the parent PIN. When the Android/iOS builds
/// ship, this is the one place to try `local_auth` biometrics first and fall
/// back to the PIN dialog.
class ParentGate {
  ParentGate._();

  /// Returns `true` when the evolution may proceed: immediately if the lock
  /// is off, otherwise after a correct PIN entry. Dismissing the dialog
  /// denies.
  static Future<bool> requestApproval(BuildContext context) async {
    final lock = context.read<ParentLockState>();
    if (!lock.enabled) return true;
    final pin = await showPinVerifyDialog(context);
    return pin != null;
  }
}
