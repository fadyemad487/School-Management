import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../widgets/student1-3/animated_space_background.dart';
import '../../../student_game_state.dart';
import '../../../utils/student_achievements_data.dart';
import '../../../utils/student_responsive.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: const Color(0xFF03001C),
        child: Stack(
          children: [
            const AnimatedSpaceBackground(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Text(
                      'صندوق أوسمة البطل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Consumer<StudentGameState>(
                      builder: (context, gs, _) {
                        final compact = StudentResponsive.isCompact(context);
                        return GridView.builder(
                          padding: StudentResponsive.screenPadding(context).copyWith(top: 8.h, bottom: StudentResponsive.scrollBottomPadding(context)),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: compact ? 10.w : 14.w,
                            mainAxisSpacing: compact ? 10.h : 14.h,
                            childAspectRatio: compact ? 0.78 : 0.85,
                          ),
                          itemCount: studentAchievementBadges.length,
                          itemBuilder: (context, index) {
                            final badge = studentAchievementBadges[index];
                            final progress = gs.progressForBadge(badge);
                            final total = badge.gameId == 'legend' ? 1 : badge.maxLevel;
                            final locked = gs.isBadgeLocked(badge);
                            final ratio = total == 0 ? 0.0 : (progress / total).clamp(0.0, 1.0);

                            return Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: locked ? 0.04 : 0.08),
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(color: badge.color.withValues(alpha: locked ? 0.2 : 0.6)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(badge.icon, style: TextStyle(fontSize: 28.sp)),
                                  SizedBox(height: 8.h),
                                  Text(
                                    badge.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: locked ? Colors.white38 : Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  LinearProgressIndicator(
                                    value: ratio,
                                    backgroundColor: Colors.white12,
                                    color: badge.color,
                                    minHeight: 6.h,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    locked ? 'مقفول 🔒' : '$progress / $total',
                                    style: TextStyle(color: badge.color, fontSize: 9.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (index * 80).ms);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
