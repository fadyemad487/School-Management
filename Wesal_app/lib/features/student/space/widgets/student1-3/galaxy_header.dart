import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
// import '../../app_theme.dart'; // Unused import removed

class GalaxyHeader extends StatelessWidget {
  final String studentName;
  final String heroRank;
  final int crystalBalance;
  final String avatarUrl;

  const GalaxyHeader({
    super.key,
    required this.studentName,
    required this.heroRank,
    required this.crystalBalance,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          // Avatar Section
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Scaffold.of(context).openDrawer();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Ring
                Container(
                      width: 85.r,
                      height: 85.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D2FF), Color(0xFF928DAB)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00D2FF).withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: Duration(seconds: 3),
                      color: Colors.white24,
                    ),

                // Avatar
                Container(
                  width: 75.r,
                  height: 75.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1B0044),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: ClipOval(
                    child: avatarUrl.contains('assets')
                        ? Image.asset(avatarUrl, fit: BoxFit.cover)
                        : Center(
                            child: Text(avatarUrl, style: TextStyle(fontSize: 40.sp)),
                          ),
                  ),
                ),

                // Floating sky accents
                ...List.generate(3, (index) {
                  return Positioned(
                    right: index == 0 ? 0 : null,
                    left: index == 1 ? 0 : null,
                    top: index == 2 ? 0 : null,
                    bottom: index == 0 ? 10 : null,
                    child:
                        Icon(Icons.cloud_rounded, color: Colors.white70, size: 14)
                            .animate(onPlay: (controller) => controller.repeat())
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.2, 1.2),
                              duration: Duration(seconds: 1 + index),
                            )
                            .fade(begin: 0.5, end: 1.0),
                  );
                }),
              ],
            ).animate().scale(
              duration: Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
            ),
          ),

          SizedBox(width: 15.w),

          // Cards Section
          Expanded(
            child: Column(
              children: [
                _buildGlassCard(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رتبة البطل',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            heroRank.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.wb_sunny_rounded,
                        color: Color(0xFFFFD166),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                _buildGlassCard(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رصيد الكريستال',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            crystalBalance.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.diamond_rounded,
                        color: Colors.purpleAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white12, width: 1),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 800))
        .slideX(begin: 0.2);
  }
}
