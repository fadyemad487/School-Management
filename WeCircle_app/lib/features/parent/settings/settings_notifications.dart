import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

class SettingsNotifications extends StatefulWidget {
  const SettingsNotifications({super.key});

  @override
  State<SettingsNotifications> createState() => _SettingsNotificationsState();
}

class _SettingsNotificationsState extends State<SettingsNotifications> {
  bool _allNotifications = true;
  bool _attendance = true;
  bool _homework = true;
  bool _behavior = true;
  bool _grades = true;
  bool _bus = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allNotifications = prefs.getBool('notif_all') ?? true;
      _attendance = prefs.getBool('notif_attendance') ?? true;
      _homework = prefs.getBool('notif_homework') ?? true;
      _behavior = prefs.getBool('notif_behavior') ?? true;
      _grades = prefs.getBool('notif_grades') ?? true;
      _bus = prefs.getBool('notif_bus') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          isArabic ? 'إعدادات الإشعارات' : 'Notification Settings',
          style: GoogleFonts.cairo(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? AppColors.textDark,
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
            // Master Switch
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'تفعيل الإشعارات' : 'Enable Notifications',
                          style: GoogleFonts.cairo(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        Text(
                          isArabic ? 'تشغيل أو إيقاف كافة الإشعارات' : 'Turn all notifications on or off',
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: _allNotifications,
                    activeColor: AppColors.primary,
                    onChanged: (val) async {
                      setState(() {
                        _allNotifications = val;
                        if (!val) {
                          _attendance = false;
                          _homework = false;
                          _behavior = false;
                          _grades = false;
                          _bus = false;
                        }
                      });
                      await _savePreference('notif_all', val);
                      if (!val) {
                        await _savePreference('notif_attendance', false);
                        await _savePreference('notif_homework', false);
                        await _savePreference('notif_behavior', false);
                        await _savePreference('notif_grades', false);
                        await _savePreference('notif_bus', false);
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Specific Settings
            Text(
              isArabic ? 'حدد الإشعارات التي تود تلقيها' : 'Select notifications you wish to receive',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
              ),
            ),
            SizedBox(height: 12.h),
            Opacity(
              opacity: _allNotifications ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: !_allNotifications,
                child: Container(
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
                      _buildToggleItem(
                        title: isArabic ? 'الحضور والغياب' : 'Attendance & Absence',
                        subtitle: isArabic 
                            ? 'احصل على إشعارات عند حضور أو انصراف طفلك'
                            : 'Receive alerts when your child arrives or departs',
                        value: _attendance,
                        onChanged: (val) async {
                          setState(() => _attendance = val);
                          await _savePreference('notif_attendance', val);
                        },
                      ),
                      Divider(
                          height: 1.h,
                          thickness: 1.h,
                          color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                      _buildToggleItem(
                        title: isArabic ? 'الواجبات المدرسية' : 'School Homework',
                        subtitle: isArabic
                            ? 'إشعارات عند إضافة أو الموعد النهائي للواجب'
                            : 'Alerts when homework is added or near its deadline',
                        value: _homework,
                        onChanged: (val) async {
                          setState(() => _homework = val);
                          await _savePreference('notif_homework', val);
                        },
                      ),
                      Divider(
                          height: 1.h,
                          thickness: 1.h,
                          color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                      _buildToggleItem(
                        title: isArabic ? 'السلوك والملاحظات' : 'Behavior & Notes',
                        subtitle: isArabic
                            ? 'عند تسجيل تنمر أو مشكلة أو ملاحظة إيجابية'
                            : 'Alerts for recorded behavior, issues, or positive remarks',
                        value: _behavior,
                        onChanged: (val) async {
                          setState(() => _behavior = val);
                          await _savePreference('notif_behavior', val);
                        },
                      ),
                      Divider(
                          height: 1.h,
                          thickness: 1.h,
                          color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                      _buildToggleItem(
                        title: isArabic ? 'الدرجات والنتائج' : 'Grades & Results',
                        subtitle: isArabic
                            ? 'عند رصد المعلم لدرجة جديدة'
                            : 'Alerts when teachers input a new test score',
                        value: _grades,
                        onChanged: (val) async {
                          setState(() => _grades = val);
                          await _savePreference('notif_grades', val);
                        },
                      ),
                      Divider(
                          height: 1.h,
                          thickness: 1.h,
                          color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                      _buildToggleItem(
                        title: isArabic ? 'تتبع الباص' : 'Bus Tracking',
                        subtitle: isArabic
                            ? 'إشعارات باقتراب الباص من المنزل'
                            : 'Alerts when the school bus is approaching home',
                        value: _bus,
                        onChanged: (val) async {
                          setState(() => _bus = val);
                          await _savePreference('notif_bus', val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          CupertinoSwitch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
