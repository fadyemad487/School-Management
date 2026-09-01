import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import 'settings_account.dart';
import 'settings_notifications.dart';
import 'settings_privacy.dart';
import 'settings_appearance.dart';
import '../../auth/auth_service.dart';
import '../../auth/login_screen.dart';
import '../../../core/utils/profile_notifier.dart';

class TeacherSettings extends StatefulWidget {
  const TeacherSettings({super.key});

  @override
  State<TeacherSettings> createState() => _TeacherSettingsState();
}

class _TeacherSettingsState extends State<TeacherSettings> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _teacherName = '';
  String? _teacherPhoto;
  String _teacherPhone = '';
  String _teacherEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    ProfileNotifier.teacherPhoto.addListener(_onProfileChanged);
    ProfileNotifier.teacherName.addListener(_onProfileChanged);
    ProfileNotifier.teacherPhone.addListener(_onProfileChanged);
    ProfileNotifier.teacherEmail.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileNotifier.teacherPhoto.removeListener(_onProfileChanged);
    ProfileNotifier.teacherName.removeListener(_onProfileChanged);
    ProfileNotifier.teacherPhone.removeListener(_onProfileChanged);
    ProfileNotifier.teacherEmail.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {
        _teacherPhoto = ProfileNotifier.teacherPhoto.value;
        _teacherName = ProfileNotifier.teacherName.value ?? _teacherName;
        _teacherPhone = ProfileNotifier.teacherPhone.value ?? _teacherPhone;
        _teacherEmail = ProfileNotifier.teacherEmail.value ?? _teacherEmail;
      });
    }
  }

  ImageProvider _getProfileImageProvider(String? photo) {
    if (photo == null || photo.isEmpty) {
      return const NetworkImage(
          'https://cdn-icons-png.flaticon.com/512/149/149071.png');
    }
    if (photo.startsWith('data:image') || photo.startsWith('base64')) {
      final base64String =
          photo.contains('base64,') ? photo.split('base64,')[1] : photo;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return const NetworkImage(
            'https://cdn-icons-png.flaticon.com/512/149/149071.png');
      }
    }
    return NetworkImage(photo);
  }

  Future<void> _fetchProfile() async {
    try {
      final response =
          await _apiClient.client.get('/teachers/mobile/dashboard');
      if (!mounted) return;
      if (response.data['success'] == true) {
        final profile = response.data['data']['profile'];
        setState(() {
          _teacherName = profile['fullName'] ?? 'المعلم';
          _teacherPhoto = profile['photo'];
          _teacherPhone = profile['phone'] ?? '';
          _teacherEmail = profile['email'] ?? '';
          _isLoading = false;
        });
        ProfileNotifier.teacherPhoto.value = profile['photo'];
        ProfileNotifier.teacherName.value = profile['fullName'];
        ProfileNotifier.teacherPhone.value = profile['phone'];
        ProfileNotifier.teacherEmail.value = profile['email'];
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final defaultName = isArabic ? 'المعلم' : 'Teacher';
    final displayName = _teacherName.isEmpty
        ? (_isLoading
            ? (isArabic ? 'جاري التحميل...' : 'Loading...')
            : defaultName)
        : _teacherName;
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
          isArabic ? 'الإعدادات' : 'Settings',
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
            // User Profile Summary
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                    color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundImage: _getProfileImageProvider(_teacherPhoto),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.cairo(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        Text(
                          _teacherPhone.isNotEmpty
                              ? _teacherPhone
                              : (isArabic
                                  ? 'لا يوجد رقم هاتف'
                                  : 'No phone number'),
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Settings Categories
            _buildSettingsSection(
              title: isArabic ? 'الحساب' : 'Account',
              items: [
                _SettingsItem(
                  icon: Icons.person_outline_rounded,
                  title: isArabic ? 'إعدادات الحساب' : 'Account Settings',
                  subtitle: isArabic
                      ? 'تعديل الاسم الكامل، رقم الجوال والصورة لتطبيقك'
                      : 'Edit full name, phone number & profile photo',
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primaryLight.withOpacity(0.1),
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SettingsAccount(
                                  currentName: displayName,
                                  currentPhone: _teacherPhone,
                                  currentEmail: _teacherEmail,
                                  currentPhoto: _teacherPhoto,
                                )));
                    if (!mounted) return;
                    _fetchProfile();
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),

            _buildSettingsSection(
              title: isArabic ? 'التفضيلات' : 'Preferences',
              items: [
                _SettingsItem(
                  icon: Icons.notifications_none_rounded,
                  title: isArabic ? 'الإشعارات' : 'Notifications',
                  subtitle: isArabic
                      ? 'التحكم في إشعارات المدرسة والرسائل والطلبات'
                      : 'Control school notifications, messages & requests',
                  iconColor: AppColors.orange,
                  bgColor: AppColors.orangeLight,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsNotifications())),
                ),
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: isArabic ? 'المظهر واللغة' : 'Appearance & Language',
                  subtitle: isArabic
                      ? 'الوضع الليلي / النهاري وتغيير لغة التطبيق'
                      : 'Dark/Light mode & change app language',
                  iconColor: AppColors.purple,
                  bgColor: AppColors.purpleLight,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsAppearance())),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            _buildSettingsSection(
              title: isArabic ? 'الأمان' : 'Security',
              items: [
                _SettingsItem(
                  icon: Icons.security_rounded,
                  title: isArabic ? 'الخصوصية والأمان' : 'Privacy & Security',
                  subtitle: isArabic
                      ? 'تغيير كلمة المرور، ربط الحساب، والأجهزة المسجلة'
                      : 'Change password, account link & registered devices',
                  iconColor: AppColors.emerald,
                  bgColor: AppColors.emeraldLight,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsPrivacy())),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () async {
                  final authService = AuthService();
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roseLight,
                  foregroundColor: AppColors.rose,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(color: AppColors.rose.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 22.r),
                    SizedBox(width: 8.w),
                    Text(
                      isArabic ? 'تسجيل الخروج' : 'Log Out',
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      {required String title, required List<_SettingsItem> items}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 12.h),
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
                color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              )
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  item,
                  if (!isLast)
                    Divider(
                        height: 1.h,
                        thickness: 1.h,
                        color:
                            isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                        indent: 70.w),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: bgColor,
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textLight, size: 14.r),
          ],
        ),
      ),
    );
  }
}
