import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/student_responsive.dart';

class StudentNavItem {
  final IconData icon;
  final String label;

  const StudentNavItem({required this.icon, required this.label});
}

/// Shared bottom navigation for student dashboards (safe-area aware).
class StudentBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<StudentNavItem> items;

  const StudentBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = StudentResponsive.isCompact(context) ? 68.h : 75.h;

    return SizedBox(
      height: 110.h + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomInset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: barHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(35.r),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected ? Colors.white : Colors.white38,
                            size: StudentResponsive.isCompact(context) ? 22.sp : 24.sp,
                          ),
                          SizedBox(height: 3.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white38,
                                fontSize: StudentResponsive.isCompact(context) ? 9.sp : 10.sp,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOutQuad);
  }
}
