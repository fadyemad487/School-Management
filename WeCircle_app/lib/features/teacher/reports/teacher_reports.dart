import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart';
import '../teacher_main.dart';

class TeacherReports extends StatefulWidget {
  const TeacherReports({super.key});

  @override
  State<TeacherReports> createState() => _TeacherReportsState();
}

class _TeacherReportsState extends State<TeacherReports> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMsg;
  Map<String, dynamic> _reportsData = {};

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final res = await _apiClient.client.get('/teachers/mobile/reports');
      if (res.data['success'] == true) {
        setState(() {
          _reportsData = res.data['data'] ?? {};
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: appScreenBackground(context),
      appBar: AppBar(
        title: Text(
          isArabic ? 'التقارير والتحليلات' : 'Reports & Analytics',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: appScreenBackground(context),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.textDark),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textDark),
          onPressed: () {
            final mainState = context.findAncestorStateOfType<TeacherMainState>();
            if (mainState != null) {
              mainState.setTab(0);
            }
          },
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMsg != null) {
      final errorDisplay = _errorMsg == 'FAILED_LOAD'
          ? (isArabic ? 'فشل تحميل البيانات' : 'Failed to load data')
          : (isArabic ? 'فشل الاتصال بالخادم' : 'Failed to connect to server');
      return Center(
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
                _fetchReports();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReports,
      color: AppColors.primary,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Overview Banner
            _buildOverviewBanner(context),
            SizedBox(height: 24.h),

            // Performance Metrics
            _SectionTitle(title: isArabic ? 'مؤشرات الأداء' : 'Performance Metrics'),
            SizedBox(height: 16.h),
            _buildAttendanceSection(context),
            SizedBox(height: 24.h),

            // Grade Distribution
            _SectionTitle(title: isArabic ? 'توزيع مستويات الطلاب' : 'Student Grade Distribution'),
            SizedBox(height: 16.h),
            _buildGradeDistributionChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewBanner(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final overview = _reportsData['overview'] ?? {};
    
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تقرير الأداء: ${overview['className'] ?? ''}' : 'Performance: ${overview['className'] ?? ''}',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLargeStat(isArabic ? 'المتوسط' : 'Average', '%${overview['generalAverage'] ?? 0}', Icons.analytics_rounded),
              Container(width: 1.w, height: 32.h, color: Colors.white.withOpacity(0.2)),
              _buildLargeStat(isArabic ? 'الحضور' : 'Attendance', '%${overview['attendanceRate'] ?? 0}', Icons.verified_user_rounded),
              Container(width: 1.w, height: 32.h, color: Colors.white.withOpacity(0.2)),
              _buildLargeStat(isArabic ? 'التقدم' : 'Progress', '+%${overview['progress'] ?? 0}', Icons.trending_up_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20.r),
        SizedBox(height: 2.h),
        Text(value, style: GoogleFonts.cairo(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900)),
        Text(label, style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.8), fontSize: 9.sp, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildAttendanceSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final metrics = _reportsData['metrics'] ?? {};

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: Column(
        children: [
          _buildAttendanceBar(context, isArabic ? 'الحضور الفعلي' : 'Actual Attendance', (metrics['actualAttendance'] ?? 0.0) as double, AppColors.emerald),
          SizedBox(height: 16.h),
          _buildAttendanceBar(context, isArabic ? 'تسليم الواجبات' : 'Homework Submissions', (metrics['homeworkSubmissions'] ?? 0.0) as double, AppColors.primary),
          SizedBox(height: 16.h),
          _buildAttendanceBar(context, isArabic ? 'المشاركة الصفية' : 'Class Participation', (metrics['classParticipation'] ?? 0.0) as double, AppColors.amber),
        ],
      ),
    );
  }

  Widget _buildAttendanceBar(BuildContext context, String label, double percent, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textDark)),
            Text('${(percent * 100).toInt()}%', style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        SizedBox(height: 8.h),
        LinearPercentIndicator(
          lineHeight: 6.h,
          percent: percent,
          backgroundColor: color.withOpacity(0.1),
          progressColor: color,
          barRadius: Radius.circular(3.r),
          padding: EdgeInsets.zero,
          animation: true,
        ),
      ],
    );
  }

  Widget _buildGradeDistributionChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final grades = _reportsData['grades'] ?? {};

    return Container(
      height: 190.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30.r,
                sections: [
                  _chartSection((grades['excellent'] ?? 0).toDouble(), AppColors.primary),
                  _chartSection((grades['veryGood'] ?? 0).toDouble(), AppColors.emerald),
                  _chartSection((grades['good'] ?? 0).toDouble(), AppColors.amber),
                  _chartSection((grades['acceptable'] ?? 0).toDouble(), Colors.blue),
                  _chartSection((grades['weak'] ?? 0).toDouble(), AppColors.rose),
                ],
              ),
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(context, isArabic ? 'امتياز' : 'Excellent', AppColors.primary),
                _buildLegendItem(context, isArabic ? 'جيد جداً' : 'Very Good', AppColors.emerald),
                _buildLegendItem(context, isArabic ? 'جيد' : 'Good', AppColors.amber),
                _buildLegendItem(context, isArabic ? 'مقبول' : 'Acceptable', Colors.blue),
                _buildLegendItem(context, isArabic ? 'ضعيف' : 'Weak', AppColors.rose),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _chartSection(double value, Color color) {
    return PieChartSectionData(
      value: value > 0 ? value : 0.01, // Prevent 0 from throwing error in chart
      title: '',
      color: color,
      radius: 40.r,
      badgeWidget: Text('${value.toInt()}%', style: GoogleFonts.cairo(fontSize: 8.sp, fontWeight: FontWeight.w900, color: Colors.white)),
      badgePositionPercentageOffset: 0.6,
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Container(width: 10.r, height: 10.r, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 8.w),
          Text(label, style: GoogleFonts.cairo(fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.textDark),
    );
  }
}

