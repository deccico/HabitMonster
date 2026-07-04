import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A little mascot that cheers the user on: a bouncing emoji character with a
/// speech bubble. The [emoji] and [message] are supplied by the screen so the
/// mascot can react to each phase (idle / working / evolving).
class CheerCharacter extends StatelessWidget {
  const CheerCharacter({
    super.key,
    required this.emoji,
    required this.message,
  });

  final String emoji;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(emoji, style: const TextStyle(fontSize: 52))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -8,
              duration: 700.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(width: 12),
        Flexible(
          child: _SpeechBubble(
            // Re-key on the message so a new bubble pops in when it changes.
            key: ValueKey<String>(message),
            child: Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    ).animate().fadeIn(duration: 250.ms).scaleXY(begin: 0.9, end: 1);
  }
}
