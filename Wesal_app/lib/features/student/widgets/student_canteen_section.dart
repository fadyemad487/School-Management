import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../student_game_state.dart';
import '../utils/student_responsive.dart';

class StudentCanteenItem {
  final String name;
  final int pointsRequired;
  final String code;

  const StudentCanteenItem({
    required this.name,
    required this.pointsRequired,
    required this.code,
  });
}

const List<StudentCanteenItem> studentCanteenItems = [
  StudentCanteenItem(name: 'كوبون بـ 5 جنيه', pointsRequired: 600, code: 'W-CPN-05EGP'),
  StudentCanteenItem(name: 'كوبون بـ 10 جنيه', pointsRequired: 1200, code: 'W-CPN-10EGP'),
  StudentCanteenItem(name: 'كوبون بـ 15 جنيه', pointsRequired: 2400, code: 'W-CPN-15EGP'),
  StudentCanteenItem(name: 'كوبون بـ 20 جنيه', pointsRequired: 3600, code: 'W-CPN-20EGP'),
  StudentCanteenItem(name: 'كوبون بـ 30 جنيه', pointsRequired: 6000, code: 'W-CPN-30EGP'),
  StudentCanteenItem(name: 'كوبون بـ 50 جنيه', pointsRequired: 9600, code: 'W-CPN-50EGP'),
  StudentCanteenItem(name: 'كوبون بـ 75 جنيه', pointsRequired: 13200, code: 'W-CPN-75EGP'),
  StudentCanteenItem(name: 'كوبون بـ 100 جنيه', pointsRequired: 18000, code: 'W-CPN-100EGP'),
];

class StudentCanteenSection extends StatelessWidget {
  const StudentCanteenSection({super.key});

  void _showCouponDialog(BuildContext context, StudentCanteenItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مبروك يا بطل! 🎉',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            SizedBox(height: 10.h),
            Text(item.name, style: GoogleFonts.cairo(color: const Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 14.sp)),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
              child: Text(
                item.code,
                style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 12.sp, letterSpacing: 2),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'اعرض هذا الرمز لمسؤول كنتين المدرسة المالية 🎟️',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 10.sp),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('حسناً', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentGameState>(
      builder: (context, state, _) {
        return Padding(
          padding: StudentResponsive.screenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'كوبونات كنتين المدرسة المالية 💵',
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 12.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 1.35,
                ),
                itemCount: studentCanteenItems.length,
                itemBuilder: (context, index) {
                  final item = studentCanteenItems[index];
                  final unlocked = state.points >= item.pointsRequired;
                  return GestureDetector(
                    onTap: () {
                      if (unlocked) {
                        _showCouponDialog(context, item);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تحتاج ${item.pointsRequired} نقطة لفتح ${item.name}',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: unlocked ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: unlocked ? const Color(0xFF00D2FF) : Colors.white24,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(unlocked ? Icons.lock_open_rounded : Icons.lock_rounded, color: unlocked ? const Color(0xFF10B981) : Colors.white38, size: 18.sp),
                          Text(item.name, style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w800)),
                          Text(
                            unlocked ? 'متاح 🔓' : '${item.pointsRequired} نقطة',
                            style: TextStyle(color: unlocked ? const Color(0xFF00D2FF) : Colors.white54, fontSize: 9.sp),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
