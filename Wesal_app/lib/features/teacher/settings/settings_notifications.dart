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
  bool _enableAll = true;
  bool _enableMessages = true;
  bool _enableAnnouncements = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableAll = prefs.getBool('notif_all') ?? true;
      _enableMessages = prefs.getBool('notif_messages') ?? true;
      _enableAnnouncements = prefs.getBool('notif_announcements') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'notif_all') {
        _enableAll = value;
        if (!value) {
          _enableMessages = false;
          _enableAnnouncements = false;
          prefs.setBool('notif_messages', false);
          prefs.setBool('notif_announcements', false);
        } else {
          _enableMessages = true;
          _enableAnnouncements = true;
          prefs.setBool('notif_messages', true);
          prefs.setBool('notif_announcements', true);
        }
      } else {
        if (key == 'notif_messages') _enableMessages = value;
        if (key == 'notif_announcements') _enableAnnouncements = value;
        if (_enableMessages || _enableAnnouncements) {
          _enableAll = true;
          prefs.setBool('notif_all', true);
        } else {
          _enableAll = false;
          prefs.setBool('notif_all', false);
        }
      }
    });
  }

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
          isArabic ? 'إعدادات الإشعارات' : 'Notification Settings',
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
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
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
                  _buildToggleRow(
                    title: isArabic ? 'تفعيل الإشعارات' : 'Enable Notifications',
                    subtitle: isArabic ? 'استلام جميع التنبيهات من الإدارة والصفوف' : 'Receive all alerts from administration & classes',
                    value: _enableAll,
                    onChanged: (val) => _savePreference('notif_all', val),
                    icon: Icons.notifications_active_rounded,
                    iconColor: AppColors.primary,
                  ),
                  SizedBox(height: 16.h),
                  Divider(
                    height: 1.h,
                    thickness: 1.h,
                    color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                  ),
                  SizedBox(height: 16.h),
                  _buildToggleRow(
                    title: isArabic ? 'إشعارات الرسائل والمحادثات' : 'Message Notifications',
                    subtitle: isArabic ? 'التنبيه عند استقبال رسائل جديدة من أولياء الأمور' : 'Alert when receiving new parent messages',
                    value: _enableMessages,
                    onChanged: _enableAll ? (val) => _savePreference('notif_messages', val) : null,
                    icon: Icons.forum_rounded,
                    iconColor: AppColors.purple,
                  ),
                  SizedBox(height: 16.h),
                  Divider(
                    height: 1.h,
                    thickness: 1.h,
                    color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                  ),
                  SizedBox(height: 16.h),
                  _buildToggleRow(
                    title: isArabic ? 'إشعارات الإعلانات والطلبات' : 'Announcements & Requests',
                    subtitle: isArabic ? 'إعلانات المدرسة والأنشطة الإدارية' : 'School announcements & admin notifications',
                    value: _enableAnnouncements,
                    onChanged: _enableAll ? (val) => _savePreference('notif_announcements', val) : null,
                    icon: Icons.campaign_rounded,
                    iconColor: AppColors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onChanged != null;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 22.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
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
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
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
