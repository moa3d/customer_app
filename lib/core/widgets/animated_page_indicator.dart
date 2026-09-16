import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedPageIndicator extends StatefulWidget {
  const AnimatedPageIndicator({super.key});

  @override
  State<AnimatedPageIndicator> createState() => _AnimatedPageIndicatorState();
}

class _AnimatedPageIndicatorState extends State<AnimatedPageIndicator> {
  int _activeIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _activeIndex = (_activeIndex + 1) % 3;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFFF5630);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final bool isActive = index == _activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          height: isActive ? 14 : 10,
          width: isActive ? 14 : 10,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: ShapeDecoration(
            color: orangeColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            shadows: [
              BoxShadow(
                color: orangeColor.withValues(alpha: 0.7),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      }),
    );
  }
}