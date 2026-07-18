import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/parent_lock_state.dart';
import '../widgets/pin_pad_dialog.dart';

/// The seam in front of anything that leaves the app (external links).
///
/// Google Play's Families policy requires off-app links to sit behind a gate
/// a child can't casually pass. When the parent lock is enabled the PIN (or
/// fingerprint) is that gate; otherwise an age-neutral arithmetic challenge
/// is shown.
class AdultGate {
  AdultGate._();

  /// Returns `true` when the link may open: after a correct PIN entry when
  /// the parent lock is on, otherwise after solving the arithmetic challenge.
  /// Dismissing either dialog denies.
  static Future<bool> requestApproval(BuildContext context) async {
    final lock = context.read<ParentLockState>();
    if (lock.enabled) {
      final pin = await showPinVerifyDialog(context);
      return pin != null;
    }
    final passed = await showAdultChallengeDialog(context);
    return passed ?? false;
  }
}

/// Age-neutral gate: solve a single-digit multiplication to continue.
/// [a] and [b] are injectable for tests; callers normally leave them random.
Future<bool?> showAdultChallengeDialog(
  BuildContext context, {
  int? a,
  int? b,
}) {
  final rng = Random();
  return showDialog<bool>(
    context: context,
    builder: (_) => AdultChallengeDialog(
      a: a ?? 3 + rng.nextInt(7),
      b: b ?? 3 + rng.nextInt(7),
    ),
  );
}

class AdultChallengeDialog extends StatefulWidget {
  const AdultChallengeDialog({super.key, required this.a, required this.b});

  final int a;
  final int b;

  @override
  State<AdultChallengeDialog> createState() => _AdultChallengeDialogState();
}

class _AdultChallengeDialogState extends State<AdultChallengeDialog> {
  final TextEditingController _answer = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _check() {
    if (int.tryParse(_answer.text.trim()) == widget.a * widget.b) {
      Navigator.pop(context, true);
    } else {
      setState(() => _wrong = true);
      _answer.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grown-ups only'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'This opens a link outside the app.\n'
            'Ask a grown-up to answer:',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.a} × ${widget.b} = ?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _check(),
            decoration: InputDecoration(
              hintText: 'Answer',
              errorText: _wrong ? 'Not quite — try again' : null,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _check, child: const Text('Continue')),
      ],
    );
  }
}
