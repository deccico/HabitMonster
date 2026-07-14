import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/parent_lock_state.dart';
import '../widgets/pin_pad_dialog.dart';

/// The single seam where a grown-up approves an evolution.
///
/// Approval means entering the parent PIN, or — on devices with an enrolled
/// biometric reader — a fingerprint, offered inside the verify dialog with
/// the PIN pad always available as fallback.
class ParentGate {
  ParentGate._();

  /// Returns `true` when the evolution may proceed: immediately if the lock
  /// is off, otherwise after a correct PIN entry or a successful biometric
  /// read. Dismissing the dialog denies.
  static Future<bool> requestApproval(BuildContext context) async {
    final lock = context.read<ParentLockState>();
    if (!lock.enabled) return true;
    final pin = await showPinVerifyDialog(context);
    return pin != null;
  }
}
