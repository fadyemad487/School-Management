import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';

class ParentTips extends StatelessWidget {
  const ParentTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'نصائح تربوية',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.bookmark_border_rounded,
                color: AppColors.textDark, size: 22.r),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Tip
            Padding(
              padding: EdgeInsets.all(20.r),
              child: _buildFeaturedTip(),
            ),

            // Video Tips Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'فيديوهات تعليمية',
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'عرض الكل',
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 180.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  _buildVideoCard(
                    'كيف تتعامل مع غضب طفلك؟',
                    '8:42 دقيقة',
                    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=250&fit=crop',
                  ),
                  _buildVideoCard(
                    'أساسيات التغذية السليمة',
                    '12:15 دقيقة',
                    'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=400&h=250&fit=crop',
                  ),
                ],
              ),
            ),

            // Categories
            SizedBox(height: 24.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  _buildCategoryChip('الكل', true),
                  _buildCategoryChip('صحة', false),
                  _buildCategoryChip('سلوك', false),
                  _buildCategoryChip('دراسة', false),
                  _buildCategoryChip('تطوير', false),
                ],
              ),
            ),

            // Articles List
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  _buildArticleCard(
                    '10 طرق لتحفيز طفلك على القراءة',
                    'تعليم',
                    '5 دقائق',
                    AppColors.primary,
                    Icons.menu_book_rounded,
                  ),
                  _buildArticleCard(
                    'أهمية النوم الكافي للنمو الذهني',
                    'صحة',
                    '6 دقائق',
                    AppColors.teal,
                    Icons.bedtime_rounded,
                  ),
                  _buildArticleCard(
                    'كيفية تنظيم وقت المذاكرة بفعالية',
                    'دراسة',
                    '4 دقائق',
                    AppColors.emerald,
                    Icons.schedule_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTip() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'نصيحة اليوم',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'شجّع طfلك على طرح الأسئلة دوماً',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'الأطفال الذين يشعرون بالحرية في طرح الأسئلة يطورون مهارات التفكير النقدي بشكل أسرع بكثير.',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13.sp,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.white, size: 16.r),
                    SizedBox(width: 6.w),
                    Text(
                      '3 دقائق للقراءة',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'اقرأ الآن',
                        style: GoogleFonts.cairo(
                          color: AppColors.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(String title, String duration, String image) {
    return Container(
      width: 240.w,
      margin: EdgeInsets.only(left: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                child: Image.network(
                  image,
                  height: 110.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28.r),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  duration,
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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

  Widget _buildArticleCard(
      String title, String category, String time, Color color, IconData icon) {
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
                  '$category • $time للقراءة',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textLight, size: 14.r),
        ],
      ),
    );
  }
}

