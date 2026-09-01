import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart';
import '../homework/teacher_homework.dart';
import '../grades/teacher_grades.dart';
import '../behavior/teacher_behavior.dart';
import '../tasks/teacher_tasks_screen.dart';
import '../messages/teacher_messages.dart';
import '../../../core/utils/profile_notifier.dart';
import '../../../core/utils/notification_notifier.dart';
import '../settings/teacher_settings.dart';
import '../notifications/teacher_notifications_screen.dart';

const List<Color> _teacherAccentGradient = [
  Color(0xFF1D4ED8),
  Color(0xFF7C3AED),
];

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMsg;

  String _teacherName = '';
  String? _teacherPhoto;

  Map<String, dynamic> _stats = {
    'totalStudents': 0,
    'finishedPeriods': '0/0',
    'absentStudents': 0,
  };

  List<dynamic> _schedule = [];
  List<dynamic> _homeworks = [];

  // Active sections handled sequentially now without tabs

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    ProfileNotifier.teacherPhoto.addListener(_onProfilePhotoChanged);
    ProfileNotifier.teacherName.addListener(_onProfileNameChanged);
  }

  @override
  void dispose() {
    ProfileNotifier.teacherPhoto.removeListener(_onProfilePhotoChanged);
    ProfileNotifier.teacherName.removeListener(_onProfileNameChanged);
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

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localName = prefs.getString('user_fullname') ?? '';
      final localPhoto = prefs.getString('user_photo');

      final response = await _apiClient.client.get('/teachers/mobile/dashboard');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final profile = data['profile'];
        String nameVal = localName;
        String? photoVal = localPhoto;

        if (profile != null) {
          nameVal = profile['fullName'] ?? localName;
          photoVal = profile['photo'];
          await prefs.setString('user_fullname', nameVal);
          if (photoVal != null) {
            await prefs.setString('user_photo', photoVal);
          } else {
            await prefs.remove('user_photo');
          }
          ProfileNotifier.teacherName.value = nameVal;
          ProfileNotifier.teacherPhoto.value = photoVal;
          ProfileNotifier.teacherPhone.value = profile['phone'] ?? '';
          ProfileNotifier.teacherEmail.value = profile['email'] ?? '';
          
          if (profile['jobTitle'] != null && profile['jobTitle'].toString().isNotEmpty) {
            await prefs.setString('teacher_job_title', profile['jobTitle']);
            ProfileNotifier.teacherJobTitle.value = profile['jobTitle'];
          }
        }

        setState(() {
          _teacherName = nameVal;
          _teacherPhoto = photoVal;
          _stats = data['stats'] ?? _stats;
          _schedule = data['schedule'] ?? [];
          _homeworks = data['homeworks'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = 'FAILED_LOAD';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'FAILED_CONN';
        _isLoading = false;
      });
    }
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
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: appScreenBackground(context),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF22C55E),
          ),
        ),
      );
    }

    if (_errorMsg != null) {
      final errorDisplay = _errorMsg == 'FAILED_LOAD'
          ? (isArabic ? 'فشل تحميل البيانات' : 'Failed to load data')
          : (isArabic ? 'فشل الاتصال بالخادم' : 'Failed to connect to server');
      return Scaffold(
        backgroundColor: appScreenBackground(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64.r, color: const Color(0xFF94A3B8)),
              SizedBox(height: 16.h),
              Text(
                errorDisplay,
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMsg = null;
                  });
                  _fetchDashboardData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  isArabic ? 'إعادة المحاولة' : 'Try Again',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Extract first two names
    String displayTeacherName = '';
    if (_teacherName.isNotEmpty) {
      final parts = _teacherName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        displayTeacherName = '${parts[0]} ${parts[1]}';
      } else {
        displayTeacherName = parts[0];
      }
    }

    return Scaffold(
      backgroundColor: appScreenBackground(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: const Color(0xFF22C55E),
          backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
            children: [
              // 1. Premium Header (Avatar, Greetings, Notification Bell)
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherSettings(),
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: EdgeInsets.all(1.5.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5.w),
                          ),
                          child: CircleAvatar(
                            radius: 24.r,
                            backgroundImage: _getProfileImageProvider(_teacherPhoto),
                          ),
                        ),
                        Positioned(
                          right: 2.w,
                          bottom: 2.h,
                          child: Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF12121E) : Colors.white, width: 1.5.w),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (() {
                            final hour = DateTime.now().hour;
                            if (hour < 12) {
                              return isArabic ? 'صباح الخير 👋' : 'Good morning 👋';
                            } else if (hour < 17) {
                              return isArabic ? 'طاب يومك 👋' : 'Good afternoon 👋';
                            } else {
                              return isArabic ? 'مساء الخير 👋' : 'Good evening 👋';
                            }
                          }()),
                          style: GoogleFonts.cairo(
                            color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF64748B),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          displayTeacherName,
                          style: GoogleFonts.cairo(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification icon inside round border box with badge
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherNotificationsScreen(),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 20.r),
                        ),
                        ListenableBuilder(
                          listenable: NotificationNotifier(),
                          builder: (context, _) {
                            final count = NotificationNotifier().unreadCount;
                            if (count == 0) return const SizedBox.shrink();
                            return Positioned(
                              top: -4.h,
                              right: -4.w,
                              child: Container(
                                padding: EdgeInsets.all(3.r),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16.r,
                                  minHeight: 16.r,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // 2. Hero Card (You've got N classes)
              _buildHeroProgressCard(isArabic),
              SizedBox(height: 24.h),

              // 3. Upcoming Class
              _buildSectionHeader(isArabic ? 'الحصة القادمة' : 'Upcoming Class'),
              SizedBox(height: 16.h),
              _buildUpcomingClassSection(isArabic),
              
              SizedBox(height: 28.h),

              // 4. Premium Quick Actions
              _buildSectionHeader(isArabic ? 'الإجراءات السريعة' : 'Quick Actions'),
              SizedBox(height: 16.h),
              _buildTaskManagementSection(isArabic),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 15.sp,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildHeroProgressCard(bool isArabic) {
    final parts = (_stats['finishedPeriods'] as String? ?? '0/0').split('/');
    final finishedCount = int.tryParse(parts.first) ?? 0;
    final totalCount = int.tryParse(parts.last) ?? 0;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _teacherAccentGradient,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 28.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'لديك $totalCount حصص اليوم' : "You've got $totalCount classes",
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                Text(
                  isArabic ? 'مستعد لإنهائها اليوم!' : 'Ready to finish today!',
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: Colors.white.withOpacity(0.82),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                // Progress checkmarks row
                if (totalCount > 0)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(totalCount, (index) {
                        if (index < finishedCount) {
                          return Container(
                            margin: EdgeInsets.only(left: 6.w),
                            width: 20.r,
                            height: 20.r,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _teacherAccentGradient,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, color: Colors.white, size: 10.r),
                          );
                        } else if (index == finishedCount) {
                          return Container(
                            margin: EdgeInsets.only(left: 6.w),
                            width: 20.r,
                            height: 20.r,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5.w),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            margin: EdgeInsets.only(left: 6.w),
                            width: 20.r,
                            height: 20.r,
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.cairo(
                                  color: Colors.white30,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                      }),
                    ),
                  )
                else
                  Text(
                    isArabic ? 'لا توجد حصص مجدولة اليوم' : 'No periods scheduled today',
                    style: GoogleFonts.cairo(color: Colors.white30, fontSize: 10.sp),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassSection(bool isArabic) {
    dynamic upcomingSlot;
    for (var slot in _schedule) {
      if (slot['isCurrent'] == true) {
        upcomingSlot = slot;
        break;
      }
    }
    if (upcomingSlot == null && _schedule.isNotEmpty) {
      upcomingSlot = _schedule.first;
    }

    if (upcomingSlot == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            isArabic ? 'انتهت جميع حصص اليوم' : 'All classes finished today',
            style: GoogleFonts.cairo(
              color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF64748B),
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _teacherAccentGradient,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 18.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upcomingSlot['className'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      (upcomingSlot['startTime'] != null && upcomingSlot['endTime'] != null)
                          ? '${upcomingSlot['startTime']} - ${upcomingSlot['endTime']}'
                          : (isArabic ? 'الحصة ${upcomingSlot['periodNumber']}' : 'Period ${upcomingSlot['periodNumber']}'),
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(color: Colors.white10, height: 1.h),
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 18.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upcomingSlot['subjectName'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isArabic ? 'المنهج الدراسي المعتمد' : 'Assigned syllabus topic',
                      style: GoogleFonts.cairo(
                        fontSize: 10.sp,
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Syllabus section removed per user request

  Widget _buildTaskManagementSection(bool isArabic) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PremiumServiceCard(
                isArabic ? 'الواجبات' : 'Homework',
                isArabic ? 'إدارة التكليفات' : 'Manage Tasks',
                Icons.assignment_rounded,
                const Color(0xFF3B82F6),
                const Color(0xFF1D4ED8),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherHomework())),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _PremiumServiceCard(
                isArabic ? 'الدرجات' : 'Grades',
                isArabic ? 'رصد النتائج' : 'Submit Results',
                Icons.analytics_rounded,
                const Color(0xFF10B981),
                const Color(0xFF047857),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherGrades())),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _PremiumServiceCard(
                isArabic ? 'السلوك' : 'Behavior',
                isArabic ? 'ملاحظات الطلاب' : 'Student Notes',
                Icons.psychology_rounded,
                const Color(0xFFF59E0B),
                const Color(0xFFB45309),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherBehavior())),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _PremiumServiceCard(
                isArabic ? 'المهام' : 'Tasks',
                isArabic ? 'مهمات الطلاب' : 'Student Tasks',
                Icons.emoji_events_rounded,
                const Color(0xFF8B5CF6),
                const Color(0xFF5B21B6),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherTasksScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PremiumServiceCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color colorLight, colorDark;
  final VoidCallback onTap;

  const _PremiumServiceCard(
    this.title, 
    this.subtitle, 
    this.icon, 
    this.colorLight, 
    this.colorDark, 
    this.onTap
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [colorDark.withOpacity(0.3), colorDark.withOpacity(0.1)] 
                : [colorLight, colorDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: isDark ? colorDark.withOpacity(0.15) : colorLight.withOpacity(0.3),
              blurRadius: 16.r,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(
            color: isDark ? colorLight.withOpacity(0.2) : Colors.white.withOpacity(0.2),
            width: 1.w,
          ),
        ),
        child: Stack(
          children: [
            // Background Watermark Icon
            Positioned(
              right: -10.w,
              bottom: -10.h,
              child: Icon(
                icon,
                size: 80.r,
                color: Colors.white.withOpacity(isDark ? 0.05 : 0.15),
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(icon, color: isDark ? colorLight : Colors.white, size: 20.r),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: isDark ? Colors.white60 : Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
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
