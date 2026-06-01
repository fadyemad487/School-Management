import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedSpaceBackground extends StatelessWidget {
  const AnimatedSpaceBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF15264F), Color(0xFF244D78), Color(0xFF3D7696)],
            ),
          ),
        ),
        Positioned(
          top: -70,
          left: -55,
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFD166).withValues(alpha: 0.34),
                  const Color(0xFFFFE8A3).withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.96, 0.96),
                end: const Offset(1.04, 1.04),
                duration: 3.seconds,
              ),
        ),
        ...List.generate(10, (index) {
          final random = Random(index * 91 + 17);
          final x = random.nextDouble();
          final y = random.nextDouble();
          final width = random.nextDouble() * 86 + 88;
          final duration = (random.nextDouble() * 4 + 4).seconds;

          return Positioned(
            left: x * MediaQuery.of(context).size.width,
            top: y * MediaQuery.of(context).size.height,
            child: _CloudBlob(width: width),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveX(
                begin: -6,
                end: 6,
                duration: duration,
              ).fade(begin: 0.65, end: 0.95, duration: duration);
        }),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CloudBlob extends StatelessWidget {
  final double width;
  const _CloudBlob({required this.width});

  @override
  Widget build(BuildContext context) {
    final h = width * 0.5;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: h * 0.55,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            left: width * 0.08,
            top: h * 0.15,
            child: Container(
              width: width * 0.35,
              height: h * 0.45,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: width * 0.36,
            top: 0,
            child: Container(
              width: width * 0.32,
              height: h * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: width * 0.1,
            top: h * 0.15,
            child: Container(
              width: width * 0.28,
              height: h * 0.38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
