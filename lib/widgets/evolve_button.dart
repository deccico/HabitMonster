import 'package:flutter/material.dart';

/// The prominent central "Evolve" action button (spec 1.4).
///
/// [onPressed] is null while on cooldown, which both disables the button and
/// greys it out. When disabled it shows the remaining seconds so the lockout is
/// obvious (spec 1.3).
class EvolveButton extends StatelessWidget {
  const EvolveButton({
    super.key,
    required this.onPressed,
    required this.remainingSeconds,
    required this.isFinalStage,
  });

  /// Called on tap; null disables the button (during cooldown).
  final VoidCallback? onPressed;
  final int remainingSeconds;
  final bool isFinalStage;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final label = enabled
        ? (isFinalStage ? 'PRESTIGE!' : 'EVOLVE')
        : 'Locked · ${remainingSeconds}s';

    return SizedBox(
      width: 260,
      height: 64,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(enabled ? Icons.bolt : Icons.lock_clock),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
