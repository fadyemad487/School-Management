import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GalaxyProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const GalaxyProgress({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'GALAXY JOURNEY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Container(
          height: 50.h,
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Progress Track
              Container(
                height: 12.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.white12),
                ),
              ),

              // Animated Progress Bar
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 12.h,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E2DE2).withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ).animate().shimmer(duration: 2.seconds, color: Colors.white38);
                }
              ),

              // Moving Rocket
              LayoutBuilder(
                builder: (context, constraints) {
                  return Positioned(
                    left: (constraints.maxWidth * progress) - 20.w,
                    child: Transform.rotate(
                      angle: 0.5,
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .shake(hz: 2, offset: const Offset(1, 1))
                     .then()
                     .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1)),
                  );
                }
              ),

              // Target Star
              const Positioned(
                right: 0,
                child: Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
              ).animate(onPlay: (c) => c.repeat())
               .scale(duration: 1.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
               .fade(begin: 0.5, end: 1.0),
            ],
          ),
        ),
        
        // XP Text
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XP: ${(progress * 1000).toInt()}', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              const Text('NEXT LVL: 1000', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
