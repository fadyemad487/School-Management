import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart';
import '../teacher_main.dart';

class TeacherAttendance extends StatefulWidget {
  const TeacherAttendance({super.key});

  @override
  State<TeacherAttendance> createState() => _TeacherAttendanceState();
}

class _TeacherAttendanceState extends State<TeacherAttendance> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;

  String? _selectedClassId;
  List<dynamic> _classes = [];
  List<_AttStudent> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.client.get('/teachers/mobile/classes');
      if (res.data['success'] == true) {
        _classes = res.data['data'] as List;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
          _loadStudentsForClass(_selectedClassId!);
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _loadStudentsForClass(String classId) {
    final cls = _classes.firstWhere((c) => c['id'] == classId, orElse: () => null);
    if (cls != null) {
      final stds = cls['students'] as List;
      _students = stds.map((s) => _AttStudent(
        s['id'],
        s['name'],
        AttStatus.present, // Default to present
        s['avatar'],
      )).toList();
    } else {
      _students = [];
    }
  }

  int get _presentCount => _students.where((s) => s.status == AttStatus.present).length;
  int get _absentCount => _students.where((s) => s.status == AttStatus.absent).length;
  int get _lateCount => _students.where((s) => s.status == AttStatus.late).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: appScreenBackground(context),
      appBar: AppBar(
        title: Text(
          isArabic ? 'تسجيل الحضور' : 'Record Attendance',
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Class Selection
              Container(
                color: isDark ? const Color(0xFF12121E) : Colors.white,
                padding: EdgeInsets.only(bottom: 16.h),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: _classes.map((c) {
                      final isSelected = _selectedClassId == c['id'];
                      return _buildClassChip(c['name'], c['id'], isSelected);
                    }).toList(),
                  ),
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppColors.primary,
                  backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20.r),
                    children: [
                      // Attendance Summary Card
                      _buildSummaryCard(),
                      SizedBox(height: 24.h),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isArabic ? 'قائمة الطلاب اليوم' : "Today's Student List",
                            style: GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          Text(
                            isArabic ? 'رتب حسب الرقم' : 'Sort by No.',
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Students List
                      if (_students.isEmpty)
                        Center(child: Text('لا يوجد طلاب', style: GoogleFonts.cairo(color: AppColors.textMedium)))
                      else
                        ..._students.map((s) => _StudentAttCard(
                              student: s,
                              onStatusChange: (status) => setState(() => s.status = status),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildClassChip(String label, String id, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedClassId = id;
          _loadStudentsForClass(id);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(left: 12.w),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E1E2C) : Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: isSelected ? null : Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border, width: 1.w),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? Colors.white : (isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    double total = _students.length.toDouble();
    double attendanceRate = total > 0 ? (_presentCount + _lateCount) / total : 0;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryHeaderItem(isArabic ? 'الكل' : 'Total', '${_students.length}', isDark ? Colors.white : AppColors.textMedium),
              _buildSummaryHeaderItem(isArabic ? 'حاضر' : 'Present', '$_presentCount', AppColors.emerald),
              _buildSummaryHeaderItem(isArabic ? 'غائب' : 'Absent', '$_absentCount', AppColors.rose),
              _buildSummaryHeaderItem(isArabic ? 'متأخر' : 'Late', '$_lateCount', AppColors.amber),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: LinearProgressIndicator(
                    value: attendanceRate,
                    minHeight: 6.h,
                    backgroundColor: isDark ? const Color(0xFF12121E) : AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '${(attendanceRate * 100).toInt()}%',
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeaderItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h), // Increased bottom padding to prevent hiding behind main nav bar
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10.r,
            offset: Offset(0, -4.h),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitAttendance,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 0,
        ),
        child: Text(
          isArabic ? 'حفظ وإرسال الإشعارات' : 'Save & Send Notifications',
          style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_selectedClassId == null || _students.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> records = _students.map((s) {
        String statusStr = 'PRESENT';
        if (s.status == AttStatus.absent) statusStr = 'ABSENT';
        if (s.status == AttStatus.late) statusStr = 'LATE';
        return {
          'studentId': s.id,
          'status': statusStr,
        };
      }).toList();

      final res = await _apiClient.client.post('/attendance/bulk', data: {
        'date': DateTime.now().toIso8601String(),
        'classId': _selectedClassId,
        'records': records,
      });

      if (res.data['success'] == true) {
        _showConfirmation(context);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء حفظ الحضور')));
    }
  }

  void _showConfirmation(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12.w),
            Text(
              isArabic ? 'تم حفظ حضور الفصل بنجاح' : 'Class attendance saved successfully',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }
}

enum AttStatus { present, absent, late }

class _AttStudent {
  final String id, name, avatar;
  AttStatus status;
  _AttStudent(this.id, this.name, this.status, this.avatar);
}

class _StudentAttCard extends StatelessWidget {
  final _AttStudent student;
  final ValueChanged<AttStatus> onStatusChange;
  const _StudentAttCard({required this.student, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundImage: student.avatar.startsWith('http') 
                ? NetworkImage(student.avatar) 
                : (student.avatar.startsWith('/') ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${student.avatar}') : const NetworkImage('https://cdn-icons-png.flaticon.com/512/149/149071.png')) as ImageProvider,
            onBackgroundImageError: (_, __) {},
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              student.name,
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              _AttBtn(Icons.check_rounded, AppColors.emerald,
                  student.status == AttStatus.present,
                  () => onStatusChange(AttStatus.present)),
              SizedBox(width: 8.w),
              _AttBtn(Icons.watch_later_rounded, AppColors.amber,
                  student.status == AttStatus.late,
                  () => onStatusChange(AttStatus.late)),
              SizedBox(width: 8.w),
              _AttBtn(Icons.close_rounded, AppColors.rose,
                  student.status == AttStatus.absent,
                  () => onStatusChange(AttStatus.absent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _AttBtn(this.icon, this.color, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6.r,
                    offset: Offset(0, 3.h),
                  )
                ]
              : null,
        ),
        child: Icon(icon, size: 16.r, color: active ? Colors.white : color),
      ),
    );
  }
}

