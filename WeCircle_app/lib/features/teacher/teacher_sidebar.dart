import 'dart:convert';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../auth/login_screen.dart';
import '../auth/auth_service.dart';
import 'homework/teacher_homework.dart';
import 'grades/teacher_grades.dart';
import 'behavior/teacher_behavior.dart';
import 'announcements/teacher_announcements.dart';
import 'schedule/teacher_schedule.dart';
import '../../core/utils/profile_notifier.dart';
import '../../core/widgets/app_background.dart';
import 'settings/teacher_settings.dart';

class TeacherSidebar extends StatefulWidget {
  final Function(int) onTabSelected;
  final int currentIndex;

  const TeacherSidebar({
    super.key,
    required this.onTabSelected,
    required this.currentIndex,
  });

  @override
  State<TeacherSidebar> createState() => _TeacherSidebarState();
}

class _TeacherSidebarState extends State<TeacherSidebar> {
  String _teacherName = '';
  String? _teacherPhoto;
  String _teacherJobTitle = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    ProfileNotifier.teacherPhoto.addListener(_onProfilePhotoChanged);
    ProfileNotifier.teacherName.addListener(_onProfileNameChanged);
    ProfileNotifier.teacherJobTitle.addListener(_onProfileJobTitleChanged);
  }

  @override
  void dispose() {
    ProfileNotifier.teacherPhoto.removeListener(_onProfilePhotoChanged);
    ProfileNotifier.teacherName.removeListener(_onProfileNameChanged);
    ProfileNotifier.teacherJobTitle.removeListener(_onProfileJobTitleChanged);
    super.dispose();
  }

  void _onProfilePhotoChanged() {
    if (mounted) {
      setState(() {
        _teacherPhoto = ProfileNotifier.teacherPhoto.value;
      });
    }
  }

  void _onProfileNameChanged() {
    if (mounted) {
      setState(() {
        _teacherName = ProfileNotifier.teacherName.value ?? _teacherName;
      });
    }
  }

  void _onProfileJobTitleChanged() {
    if (mounted) {
      setState(() {
        _teacherJobTitle = ProfileNotifier.teacherJobTitle.value ?? _teacherJobTitle;
      });
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherName = prefs.getString('user_fullname') ?? '';
      _teacherPhoto = prefs.getString('user_photo');
      _teacherJobTitle = prefs.getString('teacher_job_title') ?? '';
    });
  }

  ImageProvider _getProfileImageProvider(String? photo) {
    if (photo == null || photo.isEmpty) {
      return const NetworkImage('https://cdn-icons-png.flaticon.com/512/149/149071.png');
    }
    if (photo.startsWith('data:image') || photo.startsWith('base64')) {
      final base64String = photo.contains('base64,') ? photo.split('base64,')[1] : photo;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return const NetworkImage('https://cdn-icons-png.flaticon.com/512/149/149071.png');
      }
    }
    if (photo.startsWith('/uploads') || photo.startsWith('uploads')) {
      final cleanPath = photo.startsWith('/') ? photo : '/$photo';
      return NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}$cleanPath');
    }
    return NetworkImage(photo);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    // Extract first two names for display
    String displayTeacherName = '';
    if (_teacherName.isNotEmpty) {
      final parts = _teacherName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        displayTeacherName = '${parts[0]} ${parts[1]}';
      } else {
        displayTeacherName = parts[0];
      }
    }

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: appScreenBackground(context),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Premium Header (Profile & Close button)
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherSettings(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFF1F5F9), width: 1.h)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(1.5.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF22C55E), width: 1.5.w),
                      ),
                      child: CircleAvatar(
                        radius: 26.r,
                        backgroundImage: _getProfileImageProvider(_teacherPhoto),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTeacherName,
                            style: GoogleFonts.cairo(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _teacherJobTitle.isNotEmpty 
                                ? '$_teacherJobTitle 🎖️' 
                                : (isArabic ? 'معلم WeCircle المتميز 🎖️' : 'Distinguished WeCircle Teacher 🎖️'),
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF22C55E),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF64748B), size: 24.r),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Navigation items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
                children: [
                  // Core tabs Section
                  _buildSectionHeader(isArabic ? 'أقسام التطبيق الرئيسية' : 'Main Application Sections'),
                  _buildSidebarItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: isArabic ? 'الرئيسية' : 'Home',
                    index: 0,
                  ),
                  _buildSidebarItem(
                    icon: Icons.trending_up_rounded,
                    activeIcon: Icons.trending_up_rounded,
                    label: isArabic ? 'فصولي' : 'My Classes',
                    index: 1,
                  ),
                  _buildSidebarItem(
                    icon: Icons.qr_code_scanner_rounded,
                    activeIcon: Icons.qr_code_scanner_rounded,
                    label: isArabic ? 'دفتر الحضور والغياب' : 'Attendance Book',
                    index: 2,
                  ),
                  _buildSidebarItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    label: isArabic ? 'تقارير الأداء والإحصائيات' : 'Performance Reports',
                    index: 3,
                  ),
                  _buildSidebarItem(
                    icon: Icons.forum_outlined,
                    activeIcon: Icons.forum_rounded,
                    label: isArabic ? 'الرسائل والمحادثات' : 'Messages & Chats',
                    index: 4,
                  ),

                  SizedBox(height: 24.h),

                  // Quick Access Section (Homework, Grades, Behavior, Announcements)
                  _buildSectionHeader(isArabic ? 'اختصارات سريعة' : 'Quick Actions'),
                  _buildQuickActionItem(
                    icon: Icons.calendar_month_outlined,
                    label: isArabic ? 'جدولي اليومي' : 'My Schedule',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherSchedule()));
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.assignment_outlined,
                    label: isArabic ? 'إضافة واجب منزلي جديد' : 'Add New Homework',
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherHomework()));
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.analytics_outlined,
                    label: isArabic ? 'رصد درجات اختبارات الفصل' : 'Record Class Grades',
                    color: const Color(0xFF059669),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherGrades()));
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.psychology_outlined,
                    label: isArabic ? 'ملاحظة سلوك' : 'Record Behavior',
                    color: const Color(0xFFD97706),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherBehavior()));
                    },
                  ),
                ],
              ),
            ),

            // 3. Footer (Logout)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFF1F5F9), width: 1.h)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () async {
                        final auth = AuthService();
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      icon: Icon(Icons.logout_rounded, color: const Color(0xFFEF4444), size: 18.r),
                      label: Text(
                        isArabic ? 'تسجيل الخروج' : 'Logout',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFFEF4444),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 11.sp,
          color: isDark ? const Color(0xFFA0A0C0).withOpacity(0.7) : const Color(0xFF94A3B8),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = widget.currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        widget.onTabSelected(index);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF15803D).withOpacity(0.2) : const Color(0xFFDCFCE7)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF15803D) : (isDark ? const Color(0xFFA0A0C0) : const Color(0xFF64748B)),
              size: 20.r,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.bold,
                  color: isSelected ? const Color(0xFF15803D) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 6.r,
                height: 6.r,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 18.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF94A3B8), size: 12.r),
          ],
        ),
      ),
    );
  }
}
