import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';

class ParentAttendance extends StatefulWidget {
  final Map<String, dynamic> child;
  const ParentAttendance({super.key, required this.child});

  @override
  State<ParentAttendance> createState() => _ParentAttendanceState();
}

class _ParentAttendanceState extends State<ParentAttendance> {
  late Map<String, dynamic> _childData;
  int _selectedFilter = 0; // 0: All, 1: Present, 2: Absent, 3: Late

  @override
  void initState() {
    super.initState();
    _childData = widget.child;
  }

  String _formatLogDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final daysInArabic = [
        "", // Padding to make 1-indexed
        "الاثنين",
        "الثلاثاء",
        "الأربعاء",
        "الخميس",
        "الجمعة",
        "السبت",
        "الأحد",
      ];
      final monthsInArabic = [
        "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
      ];
      final dayName = daysInArabic[date.weekday];
      final monthName = monthsInArabic[date.month - 1];
      return '$dayName • ${date.day} $monthName';
    } catch (_) {
      return dateStr;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PRESENT': return 'حاضر';
      case 'ABSENT': return 'غائب';
      case 'LATE': return 'متأخر';
      case 'EXCUSED': return 'مأذون';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PRESENT': return AppColors.emerald;
      case 'ABSENT': return AppColors.rose;
      case 'LATE': return AppColors.amber;
      case 'EXCUSED': return AppColors.primary;
      default: return AppColors.textMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = _childData['attendanceLogs'] as List<dynamic>? ?? [];
    final presentCount = logs.where((l) => l['status'] == 'PRESENT').length;
    final absentCount = logs.where((l) => l['status'] == 'ABSENT').length;
    final lateCount = logs.where((l) => l['status'] == 'LATE').length;
    final rate = _childData['attendanceRate']?.toString() ?? '100%';

    final filteredLogs = logs.where((l) {
      if (_selectedFilter == 0) return true;
      if (_selectedFilter == 1) return l['status'] == 'PRESENT';
      if (_selectedFilter == 2) return l['status'] == 'ABSENT';
      if (_selectedFilter == 3) return l['status'] == 'LATE';
      return true;
    }).toList();

    final now = DateTime.now();
    final monthsInArabic = [
      "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
      "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
    ];
    final currentMonthName = monthsInArabic[now.month - 1];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'تقرير الحضور',
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
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            final res = await ApiClient().client.get('/parents/mobile/dashboard');
            if (res.data['success'] == true) {
              final children = res.data['data']['children'] as List;
              final updated = children.firstWhere(
                (c) => c['id'] == _childData['id'],
                orElse: () => null,
              );
              if (updated != null) {
                setState(() {
                  _childData = updated;
                });
              }
            }
          } catch (e) {
            debugPrint('Refresh error: $e');
          }
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Summary Card
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نسبة الحضور الحالية',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            rate,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.show_chart_rounded,
                            color: Colors.white, size: 32.r),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('حاضر', '$presentCount', AppColors.emerald),
                      _buildMiniStat('غائب', '$absentCount', AppColors.rose),
                      _buildMiniStat('متأخر', '$lateCount', AppColors.amber),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Mini Calendar Section
            Text(
              '$currentMonthName ${now.year}',
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 12.h),
            _AttendanceCalendar(logs: logs),
            SizedBox(height: 24.h),

            // History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سجل الحضور والغياب',
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'تصفية',
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(0, 'الكل'),
                  _buildFilterChip(1, 'حاضر'),
                  _buildFilterChip(2, 'غائب'),
                  _buildFilterChip(3, 'متأخر'),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // History List
            if (filteredLogs.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 48.r, color: AppColors.textLight.withOpacity(0.5)),
                      SizedBox(height: 12.h),
                      Text(
                        'لا توجد سجلات مطابقة للتصفية',
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: filteredLogs.map<Widget>((log) {
                  final dateStr = log['date'] as String? ?? '';
                  final status = log['status'] as String? ?? 'PRESENT';
                  final timeIn = log['timeIn'] as String? ?? '-';

                  return _buildHistoryItem(
                    _formatLogDate(dateStr),
                    timeIn,
                    _getStatusText(status),
                    _getStatusColor(status),
                  );
                }).toList(),
              ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      width: 90.w,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final selected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        margin: EdgeInsets.only(left: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String date, String time, String status, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'غائب' ? Icons.close_rounded : status == 'متأخر' ? Icons.access_time_rounded : Icons.check_rounded,
              color: color,
              size: 20.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  time == '-' ? 'لم يتم تسجيل وصول' : 'وقت الوصول: $time',
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
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              status,
              style: GoogleFonts.cairo(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCalendar extends StatelessWidget {
  final List<dynamic> logs;
  const _AttendanceCalendar({required this.logs});

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    // Sunday (7) -> index 0
    // Monday (1) -> index 1
    // ...
    // Saturday (6) -> index 6
    final int emptySpacesBefore = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final int totalGridItems = emptySpacesBefore + daysInMonth;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']
                .map((d) => Text(d, style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.textLight, fontWeight: FontWeight.w800)))
                .toList(),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: totalGridItems,
            itemBuilder: (context, index) {
              if (index < emptySpacesBefore) {
                return const SizedBox.shrink();
              }
              final day = index - emptySpacesBefore + 1;
              
              Color dotColor = Colors.transparent;
              final dayLog = logs.firstWhere((l) {
                final dateStr = l['date'] as String?;
                if (dateStr == null) return false;
                try {
                  final date = DateTime.parse(dateStr).toLocal();
                  return date.year == now.year && date.month == now.month && date.day == day;
                } catch (_) {
                  return false;
                }
              }, orElse: () => null);

              if (dayLog != null) {
                final status = dayLog['status'] as String?;
                if (status == 'PRESENT') dotColor = AppColors.emerald;
                else if (status == 'ABSENT') dotColor = AppColors.rose;
                else if (status == 'LATE') dotColor = AppColors.amber;
                else if (status == 'EXCUSED') dotColor = AppColors.primary;
              }

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.slateLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMedium,
                      ),
                    ),
                    if (dotColor != Colors.transparent)
                      Positioned(
                        bottom: 4.h,
                        child: Container(
                          width: 4.r,
                          height: 4.r,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppColors.emerald, 'حاضر'),
              SizedBox(width: 16.w),
              _buildLegend(AppColors.rose, 'غائب'),
              SizedBox(width: 16.w),
              _buildLegend(AppColors.amber, 'متأخر'),
            ],
          ),
        ],
      ),
    );
  }
}
