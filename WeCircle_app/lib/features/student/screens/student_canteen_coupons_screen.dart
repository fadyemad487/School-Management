import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/student_responsive.dart';
import '../widgets/student_canteen_section.dart';
import '../space/widgets/student1-3/animated_space_background.dart';

class StudentCanteenCouponsScreen extends StatelessWidget {
  const StudentCanteenCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF15264F),
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedSpaceBackground()),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: StudentResponsive.screenPadding(context).copyWith(top: 12.h, bottom: 8.h),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18.sp),
                        ),
                        Expanded(
                          child: Text(
                            'كوبونات الكانتين',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 18.sp,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 40.w),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: StudentResponsive.screenPadding(context).copyWith(top: 14.h, bottom: 24.h),
                      child: const StudentCanteenSection(),
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
