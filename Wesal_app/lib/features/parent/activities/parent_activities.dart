import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';

class ParentActivities extends StatelessWidget {
  const ParentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'الأنشطة والفعاليات',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20.r),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Events Carousel
            SizedBox(height: 20.h),
            SizedBox(
              height: 180.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  _buildFeaturedCard(
                    'المهرجان الرياضي السنوي',
                    '25 مارس 2024',
                    'https://images.unsplash.com/photo-1502224562085-639556652f33?w=500&h=300&fit=crop',
                    AppColors.primary,
                  ),
                  _buildFeaturedCard(
                    'معرض الفنون التشكيلية',
                    '30 مارس 2024',
                    'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=500&h=300&fit=crop',
                    AppColors.purple,
                  ),
                ],
              ),
            ),

            // Filter Chips
            SizedBox(height: 24.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  _buildFilterChip('الكل', true),
                  _buildFilterChip('أكاديمي', false),
                  _buildFilterChip('رحلات', false),
                  _buildFilterChip('رياضة', false),
                  _buildFilterChip('مسابقات', false),
                ],
              ),
            ),

            // Activity List
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'قائمة الأنشطة',
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildActivityItem(
                    'رحلة استكشافية للمتحف الوطني',
                    'التاريخ والآثار',
                    '22 مارس',
                    'قيد التسجيل',
                    AppColors.emerald,
                    Icons.museum_rounded,
                  ),
                  _buildActivityItem(
                    'ندوة الأمن السيبراني للطلاب',
                    'توعية تقنية',
                    '24 مارس',
                    'قريباً',
                    AppColors.primary,
                    Icons.security_rounded,
                  ),
                  _buildActivityItem(
                    'بطولة الشطرنج المدرسية',
                    'ألعاب ذكاء',
                    '28 مارس',
                    'متاح',
                    AppColors.amber,
                    Icons.grid_4x4_rounded,
                  ),
                ],
              ),
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(String title, String date, String image, Color color) {
    return Container(
      width: 0.75.sw,
      margin: EdgeInsets.only(left: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        image: DecorationImage(
          image: NetworkImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'فعالية كبرى',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              date,
              style: GoogleFonts.cairo(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: isSelected ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppColors.textMedium,
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String category, String date, String status, Color color, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: color, size: 24.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$category • $date',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              status,
              style: GoogleFonts.cairo(
                color: color,
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

