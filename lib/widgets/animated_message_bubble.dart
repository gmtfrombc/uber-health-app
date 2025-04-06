import 'package:flutter/material.dart';
import '../models/message.dart';
import 'typing_animation_text.dart';

class AnimatedMessageBubble extends StatelessWidget {
  final Message message;
  final bool animate;

  const AnimatedMessageBubble({
    super.key,
    required this.message,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isPatient = message.sender == 'patient';

    return Align(
      alignment: isPatient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isPatient
                  ? theme.colorScheme.primary.withAlpha(77)
                  : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isPatient
                    ? theme.colorScheme.primary.withAlpha(51)
                    : theme.dividerColor.withAlpha(51),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child:
            isPatient || !animate
                ? Text(
                  message.content,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 15,
                  ),
                )
                : TypingAnimationText(
                  text: message.content,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 15,
                  ),
                  typingSpeed: const Duration(milliseconds: 20),
                ),
      ),
    );
  }
}
