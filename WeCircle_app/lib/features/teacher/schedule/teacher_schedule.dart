import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart';

class TeacherSchedule extends StatefulWidget {
  const TeacherSchedule({super.key});

  @override
  State<TeacherSchedule> createState() => _TeacherScheduleState();
}

class _TeacherScheduleState extends State<TeacherSchedule> with TickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMsg;
  List<dynamic> _slots = [];
  int _selectedDay = DateTime.now().weekday % 7; // 0=Sun

  final List<String> _daysAr = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  final List<String> _daysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  final List<Color> _periodColors = [
    const Color(0xFF3b82f6),
    const Color(0xFF8b5cf6),
    const Color(0xFF10b981),
    const Color(0xFFf97316),
    const Color(0xFFef4444),
    const Color(0xFF06b6d4),
    const Color(0xFFec4899),
    const Color(0xFF14b8a6),
  ];

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    try {
      final response = await _apiClient.client.get('/timetable/mobile/my-schedule');
      if (response.data['success'] == true) {
        setState(() {
          _slots = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = 'FAILED';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'CONN_ERROR';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _todaySlots {
    return _slots.where((s) => s['day'] == _selectedDay).toList()
      ..sort((a, b) => (a['periodNumber'] ?? 0).compareTo(b['periodNumber'] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = isArabic ? _daysAr : _daysEn;

    return Scaffold(
      backgroundColor: appScreenBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                      ),
                      child: Icon(
                        isArabic ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
                        size: 18.sp,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'الجدول الأسبوعي' : 'My Schedule',
                          style: GoogleFonts.cairo(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1e293b),
                          ),
                        ),
                        Text(
                          isArabic ? 'حصصك اليومية' : 'Your daily periods',
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // ── Day Selector ──────────────────────────
            SizedBox(
              height: 56.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final isActive = _selectedDay == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(colors: [Color(0xFF3b82f6), Color(0xFF8b5cf6)])
                            : null,
                        color: isActive ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isActive ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade200),
                        ),
                        boxShadow: isActive
                            ? [BoxShadow(color: const Color(0xFF3b82f6).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          days[i],
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                            color: isActive ? Colors.white : (isDark ? Colors.white54 : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 16.h),

            // ── Content ──────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMsg != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_off_rounded, size: 48.sp, color: Colors.grey),
                              SizedBox(height: 12.h),
                              Text(
                                isArabic ? 'فشل تحميل الجدول' : 'Failed to load schedule',
                                style: GoogleFonts.cairo(fontSize: 16.sp, color: Colors.grey),
                              ),
                              SizedBox(height: 8.h),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _errorMsg = null;
                                  });
                                  _fetchSchedule();
                                },
                                child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                              ),
                            ],
                          ),
                        )
                      : _todaySlots.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.free_breakfast_rounded, size: 56.sp, color: Colors.grey[300]),
                                  SizedBox(height: 12.h),
                                  Text(
                                    isArabic ? 'لا توجد حصص اليوم' : 'No periods today',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white54 : Colors.grey[400],
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    isArabic ? 'استمتع بيومك! 🎉' : 'Enjoy your day! 🎉',
                                    style: GoogleFonts.cairo(fontSize: 14.sp, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                              itemCount: _todaySlots.length,
                              itemBuilder: (_, index) {
                                final slot = _todaySlots[index];
                                final periodColor = _periodColors[index % _periodColors.length];
                                final subjectName = slot['subject']?['name'] ?? (isArabic ? 'مادة' : 'Subject');
                                final className = slot['class']?['name'] ?? '';
                                final periodNum = slot['periodNumber'] ?? (index + 1);
                                final startTime = slot['startTime'] ?? '';
                                final endTime = slot['endTime'] ?? '';
                                final room = slot['room'] ?? '';

                                return Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                                    ),
                                    boxShadow: [
                                      if (!isDark)
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Color accent bar
                                      Container(
                                        width: 5.w,
                                        height: 90.h,
                                        decoration: BoxDecoration(
                                          color: periodColor,
                                          borderRadius: BorderRadius.only(
                                            topLeft: isArabic ? Radius.zero : Radius.circular(20.r),
                                            bottomLeft: isArabic ? Radius.zero : Radius.circular(20.r),
                                            topRight: isArabic ? Radius.circular(20.r) : Radius.zero,
                                            bottomRight: isArabic ? Radius.circular(20.r) : Radius.zero,
                                          ),
                                        ),
                                      ),
                                      // Period number badge
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                                        child: Container(
                                          width: 42.w,
                                          height: 42.w,
                                          decoration: BoxDecoration(
                                            color: periodColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(14.r),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$periodNum',
                                              style: GoogleFonts.cairo(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w900,
                                                color: periodColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Info
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 14.h),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subjectName,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Row(
                                                children: [
                                                  if (className.isNotEmpty) ...[
                                                    Icon(Icons.school_rounded, size: 13.sp, color: Colors.grey),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      className,
                                                      style: GoogleFonts.cairo(fontSize: 12.sp, color: Colors.grey[500]),
                                                    ),
                                                    SizedBox(width: 12.w),
                                                  ],
                                                  if (room.isNotEmpty) ...[
                                                    Icon(Icons.room_rounded, size: 13.sp, color: Colors.grey),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      room,
                                                      style: GoogleFonts.cairo(fontSize: 12.sp, color: Colors.grey[500]),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Time
                                      if (startTime.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(left: 8.w, right: 16.w),
                                          child: Column(
                                            children: [
                                              Text(
                                                startTime,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: periodColor,
                                                ),
                                              ),
                                              if (endTime.isNotEmpty) ...[
                                                Container(
                                                  width: 1,
                                                  height: 14.h,
                                                  color: Colors.grey.withOpacity(0.3),
                                                ),
                                                Text(
                                                  endTime,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12.sp,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
