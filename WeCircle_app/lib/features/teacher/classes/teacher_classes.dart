import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart';
import '../teacher_main.dart';
import '../../../core/network/socket_service.dart';
import 'dart:async';

class TeacherClasses extends StatefulWidget {
  const TeacherClasses({super.key});

  @override
  State<TeacherClasses> createState() => _TeacherClassesState();
}

class _TeacherClassesState extends State<TeacherClasses> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMsg;
  List<dynamic> _classes = [];
  int _selectedClassIndex = 0;

  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _fetchClasses();

    _socketSubscription = SocketService().onEvent.listen((eventData) {
      if (eventData['event'] == 'student:updated' || eventData['event'] == 'dashboard:update') {
        if (mounted) {
          _fetchClasses();
        }
      }
    });

  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await _apiClient.client.get('/teachers/mobile/classes');
      if (response.data['success'] == true) {
        setState(() {
          _classes = response.data['data'] ?? [];
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
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: appScreenBackground(context),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
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
                  _fetchClasses();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
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

    if (_classes.isEmpty) {
      return Scaffold(
        backgroundColor: appScreenBackground(context),
        appBar: AppBar(
          title: Text(
            isArabic ? 'فصولي' : 'My Classes',
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          backgroundColor: appScreenBackground(context),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onPressed: () {
              final mainState = context.findAncestorStateOfType<TeacherMainState>();
              if (mainState != null) {
                mainState.setTab(0);
              }
            },
          ),
        ),
        body: Center(
          child: Text(
            isArabic ? 'لا توجد فصول دراسية مسجلة لك حالياً' : 'No classrooms assigned to you',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    final currentClass = _classes[_selectedClassIndex];
    final studentsList = currentClass['students'] as List<dynamic>? ?? [];
    
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626)
    ];
    final classColor = colors[_selectedClassIndex % colors.length];

    return Scaffold(
      backgroundColor: appScreenBackground(context),
      appBar: AppBar(
        title: Text(
          isArabic ? 'فصولي' : 'My Classes',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: appScreenBackground(context),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () {
            final mainState = context.findAncestorStateOfType<TeacherMainState>();
            if (mainState != null) {
              mainState.setTab(0);
            }
          },
        ),
      ),
      body: SafeArea(
            child: Column(
              children: [
                // Class Selection Tab Bar
                Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.only(bottom: 16.h, top: 8.h),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: List.generate(_classes.length, (i) {
                        final c = _classes[i];
                        final isSelected = _selectedClassIndex == i;
                        return _buildClassChip(c['name'] ?? '', isSelected, i, colors[i % colors.length]);
                      }),
                    ),
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchClasses,
                    color: const Color(0xFF2563EB),
                    backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                      children: [
                        // Class Overview Card
                        _buildClassOverview(currentClass, classColor, isArabic),
                        SizedBox(height: 24.h),

                        // Student list header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isArabic ? 'قائمة الطلاب' : 'Students List',
                              style: GoogleFonts.cairo(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              isArabic ? '${studentsList.length} طالب' : '${studentsList.length} Students',
                              style: GoogleFonts.cairo(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Students List
                        if (studentsList.isEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: Center(
                              child: Text(
                                isArabic ? 'لا يوجد طلاب في هذا فصل' : 'No students in this class',
                                style: GoogleFonts.cairo(
                                  fontSize: 13.sp,
                                  color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        else
                          ...studentsList.map((s) => _buildStudentCard(s, classColor, isArabic)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildClassChip(String label, bool isSelected, int index, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedClassIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(left: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? const Color(0xFF1E1E2C) : Colors.white.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : (isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE2E8F0)),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 8.r,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? Colors.white : (isDark ? const Color(0xFFA0A0C0) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildClassOverview(dynamic cls, Color color, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(isDark ? 0.25 : 0.12), color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(isDark ? 0.4 : 0.2), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8.r,
            offset: const Offset(0, 2),
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
                    cls['name'] ?? '',
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cls['subject'] ?? '',
                    style: GoogleFonts.cairo(
                      color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF475569),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(
                  '92%',
                  style: GoogleFonts.cairo(
                    color: color,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildClassStatItem(Icons.people_alt_rounded, '${cls['studentCount'] ?? 0}', isArabic ? 'طالب' : 'Student', color),
              Container(width: 1.w, height: 20.h, color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE2E8F0)),
              _buildClassStatItem(Icons.star_rounded, isArabic ? 'الأول' : '1st', isArabic ? 'الترتيب' : 'Rank', color),
              Container(width: 1.w, height: 20.h, color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE2E8F0)),
              _buildClassStatItem(Icons.trending_up_rounded, '+5%', isArabic ? 'النمو' : 'Growth', color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassStatItem(IconData icon, String value, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF475569), size: 14.r),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: isDark ? const Color(0xFFA0A0C0).withOpacity(0.7) : const Color(0xFF64748B),
            fontSize: 8.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(dynamic student, Color color, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatar = student['avatar'] as String?;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8.r,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(1.5.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 18.r,
              backgroundImage: avatar != null && avatar.isNotEmpty
                  ? NetworkImage(avatar)
                  : const NetworkImage('https://cdn-icons-png.flaticon.com/512/149/149071.png'),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  isArabic ? 'رقم الطالب: #${student['number']}' : 'Student No: #${student['number']}',
                  style: GoogleFonts.cairo(
                    fontSize: 9.sp,
                    color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white : const Color(0xFF94A3B8), size: 14.r),
          ),
        ],
      ),
    );
  }
}
