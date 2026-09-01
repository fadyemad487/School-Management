import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HeroMissionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? imagePath;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const HeroMissionCard({
    super.key,
    required this.title,
    this.icon,
    this.imagePath,
    required this.color,
    this.isActive = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Button size – fits inside the galaxy path circles
    final double size = 78.r;

    final Widget button = GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Animated glow ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 22,
                  spreadRadius: 6,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.12, 1.12),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
              ),

          // Mission image as a round button
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: ClipOval(
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                    )
                  : Icon(icon, size: 36.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return button;
  }
}
