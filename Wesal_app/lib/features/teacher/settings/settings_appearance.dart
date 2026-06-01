import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

class SettingsAppearance extends StatefulWidget {
  const SettingsAppearance({super.key});

  @override
  State<SettingsAppearance> createState() => _SettingsAppearanceState();
}

class _SettingsAppearanceState extends State<SettingsAppearance> {
  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.textDark, size: 20.r),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'المظهر واللغة' : 'Appearance & Language',
          style: GoogleFonts.cairo(
            color: isDark ? Colors.white : AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
            height: 1.h,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode Selection
            Text(
              isArabic ? 'وضع المظهر' : 'Theme Mode',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildThemeOption(
                      title: isArabic ? 'فاتح' : 'Light',
                      isSelected: !isDark,
                      icon: Icons.light_mode_rounded,
                      onTap: () {
                        if (isDark) {
                          WeCircleApp.setThemeMode(context, ThemeMode.light);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildThemeOption(
                      title: isArabic ? 'داكن' : 'Dark',
                      isSelected: isDark,
                      icon: Icons.dark_mode_rounded,
                      onTap: () {
                        if (!isDark) {
                          WeCircleApp.setThemeMode(context, ThemeMode.dark);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

            // Language Selection
            Text(
              isArabic ? 'لغة التطبيق' : 'App Language',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildLanguageRow(
                    title: 'العربية',
                    subtitle: 'Arabic',
                    isSelected: isArabic,
                    onTap: () {
                      if (!isArabic) {
                        WeCircleApp.setLocale(context, const Locale('ar'));
                      }
                    },
                  ),
                  Divider(
                    height: 1.h,
                    thickness: 1.h,
                    color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                  ),
                  _buildLanguageRow(
                    title: 'English',
                    subtitle: 'الانجليزية',
                    isSelected: !isArabic,
                    onTap: () {
                      if (isArabic) {
                        WeCircleApp.setLocale(context, const Locale('en'));
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : (isDark ? const Color(0xFF1E1E2C) : AppColors.background),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5.w,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 24.r,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? const Color(0xFFA0A0C0) : AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14.r,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
