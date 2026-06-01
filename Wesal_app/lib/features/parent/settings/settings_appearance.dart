import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../onboarding/splash_screen.dart';

class SettingsAppearance extends StatefulWidget {
  const SettingsAppearance({super.key});

  @override
  State<SettingsAppearance> createState() => _SettingsAppearanceState();
}

class _SettingsAppearanceState extends State<SettingsAppearance> {
  String _selectedLanguage = 'ar';
  String _selectedTheme = 'light';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLanguage = WeCircleApp.getLocale(context).languageCode;
    final mode = WeCircleApp.getThemeMode(context);
    if (mode == ThemeMode.light) {
      _selectedTheme = 'light';
    } else if (mode == ThemeMode.dark) {
      _selectedTheme = 'dark';
    } else {
      _selectedTheme = 'system';
    }
  }

  Future<void> _updateTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme);
    ThemeMode mode;
    if (theme == 'light') {
      mode = ThemeMode.light;
    } else if (theme == 'dark') {
      mode = ThemeMode.dark;
    } else {
      mode = ThemeMode.system;
    }
    if (mounted) {
      WeCircleApp.setThemeMode(context, mode);
      setState(() {
        _selectedTheme = theme;
      });
    }
  }

  Future<void> _updateLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    if (mounted) {
      WeCircleApp.setLocale(context, Locale(lang));
      setState(() {
        _selectedLanguage = lang;
      });
      // Restart application flow by resetting the navigation stack to the SplashScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _selectedLanguage == 'ar';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).appBarTheme.iconTheme?.color ?? AppColors.textDark, size: 20.r),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'المظهر واللغة' : 'Appearance & Language',
          style: GoogleFonts.cairo(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.border, height: 1.h),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            Text(
              isArabic ? 'المظهر' : 'Theme Mode',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D3F) : AppColors.border),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.h),
                        )
                      ],
              ),
              child: Column(
                children: [
                  _buildRadioItem(
                    title: isArabic ? 'الوضع النهاري' : 'Light Mode',
                    value: 'light',
                    groupValue: _selectedTheme,
                    icon: Icons.light_mode_rounded,
                    onChanged: (val) => _updateTheme(val!),
                  ),
                  Divider(
                      height: 1.h, thickness: 1.h, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D3F) : AppColors.border),
                  _buildRadioItem(
                    title: isArabic ? 'الوضع الليلي' : 'Dark Mode',
                    value: 'dark',
                    groupValue: _selectedTheme,
                    icon: Icons.dark_mode_rounded,
                    onChanged: (val) => _updateTheme(val!),
                  ),
                  Divider(
                      height: 1.h, thickness: 1.h, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D3F) : AppColors.border),
                  _buildRadioItem(
                    title: isArabic ? 'تلقائي (حسب النظام)' : 'System Default',
                    value: 'system',
                    groupValue: _selectedTheme,
                    icon: Icons.settings_brightness_rounded,
                    onChanged: (val) => _updateTheme(val!),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Language Section
            Text(
              isArabic ? 'اللغة (Language)' : 'Language (اللغة)',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D3F) : AppColors.border),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.h),
                        )
                      ],
              ),
              child: Column(
                children: [
                  _buildRadioItem(
                    title: 'العربية (Arabic)',
                    value: 'ar',
                    groupValue: _selectedLanguage,
                    icon: Icons.language_rounded,
                    onChanged: (val) => _updateLanguage(val!),
                  ),
                  Divider(
                      height: 1.h, thickness: 1.h, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D3F) : AppColors.border),
                  _buildRadioItem(
                    title: 'English (الإنجليزية)',
                    value: 'en',
                    groupValue: _selectedLanguage,
                    icon: Icons.language_rounded,
                    onChanged: (val) => _updateLanguage(val!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioItem({
    required String title,
    required String value,
    required String groupValue,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight.withOpacity(0.2)
                    : (isDark ? const Color(0xFF12121A) : AppColors.background),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium),
                size: 22.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 15.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white : AppColors.textDark),
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
