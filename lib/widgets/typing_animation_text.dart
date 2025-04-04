import 'package:flutter/material.dart';
import 'dart:async';

class TypingAnimationText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration typingSpeed;
  final VoidCallback? onTypingComplete;

  const TypingAnimationText({
    super.key,
    required this.text,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 30),
    this.onTypingComplete,
  });

  @override
  TypingAnimationTextState createState() => TypingAnimationTextState();
}

class TypingAnimationTextState extends State<TypingAnimationText> {
  String _displayText = '';
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  @override
  void didUpdateWidget(TypingAnimationText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the text has changed, restart the animation
    if (oldWidget.text != widget.text) {
      _displayText = '';
      _currentIndex = 0;
      _startTypingAnimation();
    }
  }

  /// Get the current typing progress as a value between 0.0 and 1.0
  double getTypingProgress() {
    if (widget.text.isEmpty) return 1.0;
    return _currentIndex / widget.text.length;
  }

  void _startTypingAnimation() {
    // Cancel any existing timer
    _timer?.cancel();

    // Start the typing animation
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();

        // Notify when typing is complete
        if (widget.onTypingComplete != null) {
          widget.onTypingComplete!();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayText, style: widget.style);
  }
}
