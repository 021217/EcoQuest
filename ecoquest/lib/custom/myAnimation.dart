import 'package:flutter/material.dart';

// ✅ Blinking Text Widget
class MyAnimation extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const MyAnimation({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(seconds: 1), // ✅ Blinking speed
  });

  @override
  _MyAnimationState createState() => _MyAnimationState();
}

class _MyAnimationState extends State<MyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true); // ✅ Creates fade-in and fade-out effect

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Text(
            widget.text,
            style:
                widget.style ??
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

// ✅ Fade Transition Function
PageRouteBuilder fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // ✅ Improved Fade-Out Curve (Smooth exit)
      Animation<double> fadeOut = Tween(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeOutQuad)) // ✅ Better for fade-out
          .animate(secondaryAnimation);

      // ✅ Improved Fade-In Curve (Smooth entry)
      Animation<double> fadeIn = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)) // ✅ Better for fade-in
          .animate(animation);

      return Stack(
        children: [
          FadeTransition(
            opacity: fadeOut,
            child: Container(color: Colors.black),
          ),
          FadeTransition(opacity: fadeIn, child: child),
        ],
      );
    },
    transitionDuration: Duration(milliseconds: 1500), // ✅ Adjust speed
  );
}
