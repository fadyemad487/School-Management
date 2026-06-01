import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/network/api_client.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  final ApiClient _apiClient = ApiClient();
  int _selectedChild = 0;
  bool _isLoading = true;
  List<dynamic> _children = [];
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchChildrenData();
  }

  Future<void> _fetchChildrenData() async {
    try {
      final response = await _apiClient.client.get('/parents/mobile/dashboard');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _children = data['children'] ?? [];
          _isLoading = false;
          _errorMsg = null;
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

  Widget _buildChildImage(String photo, double size, double iconSize) {
    if (photo.startsWith('data:image') || photo.startsWith('base64')) {
      final base64String = photo.contains('base64,') ? photo.split('base64,')[1] : photo;
      try {
        return Image.memory(
          base64Decode(base64String),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: iconSize, color: AppColors.textLight),
        );
      } catch (_) {
        return Icon(Icons.person, size: iconSize, color: AppColors.textLight);
      }
    }
    final fullUrl = photo.startsWith('/') 
        ? '${ApiClient.baseUrl.replaceAll('/api', '')}$photo' 
        : photo;
    return CachedNetworkImage(
      imageUrl: fullUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => Icon(Icons.person, size: iconSize, color: AppColors.textLight),
      errorWidget: (context, url, error) => Icon(Icons.person, size: iconSize, color: AppColors.textLight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_errorMsg != null) {
      final errorDisplay = _errorMsg == 'FAILED_LOAD'
          ? (isArabic ? 'فشل تحميل البيانات' : 'Failed to load data')
          : (isArabic ? 'فشل الاتصال بالخادم' : 'Failed to connect to server');
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, color: AppColors.rose, size: 48.r),
              SizedBox(height: 16.h),
              Text(
                errorDisplay,
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMsg = null;
                  });
                  _fetchChildrenData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  isArabic ? 'إعادة المحاولة' : 'Retry',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_children.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.child_care_rounded, color: AppColors.slate, size: 64.r),
              SizedBox(height: 16.h),
              Text(
                isArabic ? 'لا يوجد أطفال مرتبطين بولي الأمر' : 'No children linked to this parent',
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final child = _children[_selectedChild];
    final String childId = child['studentCode'] ?? child['rollNumber'] ?? child['id']?.toString().substring(0, 8) ?? '';
    final String childName = isArabic ? (child['nameAr'] ?? '') : (child['nameEn'] ?? child['nameAr'] ?? '');
    final String gradeName = child['gradeName'] ?? '';
    final String className = child['className'] ?? '';
    final String gradeClassText = isArabic 
        ? '$gradeName • $className' 
        : '$gradeName • $className';
    final String attendanceRate = child['attendanceRate'] ?? '100%';
    final String conduct = child['conduct'] ?? (isArabic ? 'ممتاز' : 'Excellent');
    final String gpa = child['gpa'] ?? '4.00';
    final String homeroomTeacher = child['homeroomTeacher'] ?? (isArabic ? 'غير محدد' : 'Not assigned');
    final String roomNumber = child['roomNumber'] ?? (isArabic ? 'غير محدد' : 'Not assigned');
    final String busRoute = child['busRoute'] ?? (isArabic ? 'لا يوجد' : 'No route');
    final List<dynamic> academicPerformance = child['academicPerformance'] as List<dynamic>? ?? [];

    final alternateColors = [
      AppColors.primary,
      AppColors.emerald,
      AppColors.purple,
      AppColors.orange,
    ];
    final childColor = alternateColors[_selectedChild % alternateColors.length];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchChildrenData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverAppBar(
            expandedHeight: 120.h,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                isArabic ? 'أطفالي' : 'My Children',
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                ),
              ),
              background: Container(color: isDark ? const Color(0xFF0F172A) : Colors.white),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Child Selector (Compact)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_children.length, (i) {
                      final c = _children[i];
                      final cName = isArabic ? (c['nameAr'] ?? '') : (c['nameEn'] ?? c['nameAr'] ?? '');
                      final selected = i == _selectedChild;
                      final activeColor = alternateColors[i % alternateColors.length];
                      return Padding(
                        padding: EdgeInsets.only(left: 12.w),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedChild = i),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(3.r),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? activeColor
                                        : Colors.transparent,
                                    width: 2.w,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 28.r,
                                  backgroundColor: isDark ? const Color(0xFF1E1E2C) : AppColors.slateLight,
                                  child: ClipOval(
                                    child: _buildChildImage(c['image'] ?? '', 56.r, 28.r),
                                  ),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                cName.split(' ')[0],
                                style: GoogleFonts.cairo(
                                  fontSize: 12.sp,
                                  fontWeight:
                                      selected ? FontWeight.w900 : FontWeight.w600,
                                  color: selected
                                      ? activeColor
                                      : (isDark ? const Color(0xFFA0A0C0) : AppColors.textLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 24.h),

                // Premium Student Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                    borderRadius: BorderRadius.circular(32.r),
                    border: isDark ? Border.all(color: const Color(0xFF2D2D3F), width: 1.w) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 20.r,
                        offset: Offset(0, 10.h),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header part of card
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              childColor,
                              childColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30.r),
                            topRight: Radius.circular(30.r),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(3.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 36.r,
                                backgroundColor: isDark ? const Color(0xFF1E1E2C) : AppColors.slateLight,
                                child: ClipOval(
                                  child: _buildChildImage(child['image'] ?? '', 72.r, 36.r),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    childName,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '#$childId',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      gradeClassText,
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stats row
                      Padding(
                        padding: EdgeInsets.all(20.r),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCardStat(
                              isArabic ? 'الحضور' : 'Attendance', 
                              attendanceRate,
                              Icons.calendar_today_rounded, 
                              AppColors.emerald,
                              isDark
                            ),
                            _buildCardStat(
                              isArabic ? 'السلوك' : 'Behavior', 
                              conduct,
                              Icons.favorite_rounded, 
                              AppColors.rose,
                              isDark
                            ),
                            _buildCardStat(
                              isArabic ? 'المعدل' : 'GPA', 
                              gpa,
                              Icons.analytics_rounded, 
                              AppColors.amber,
                              isDark
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),

                      // Detailed list info
                      Padding(
                        padding: EdgeInsets.all(20.r),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              Icons.school_rounded,
                              isArabic ? 'المعلمة الرئيسية' : 'Homeroom Teacher', 
                              homeroomTeacher,
                              isDark
                            ),
                            SizedBox(height: 12.h),
                            _buildInfoTile(
                              Icons.room_rounded, 
                              isArabic ? 'القاعة' : 'Room', 
                              roomNumber,
                              isDark
                            ),
                            SizedBox(height: 12.h),
                            _buildInfoTile(
                              Icons.directions_bus_rounded,
                              isArabic ? 'خط الباص' : 'Bus Route', 
                              busRoute,
                              isDark
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Performance Section
                _buildSectionHeader(isArabic ? 'الأداء الأكاديمي' : 'Academic Performance', isDark),
                SizedBox(height: 16.h),
                
                if (academicPerformance.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Text(
                        isArabic ? 'لا توجد درجات مسجلة بعد' : 'No grades recorded yet',
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(academicPerformance.length, (index) {
                    final subject = academicPerformance[index];
                    final String sName = isArabic 
                        ? (subject['subjectNameAr'] ?? '') 
                        : (subject['subjectNameEn'] ?? subject['subjectNameAr'] ?? '');
                    final double progress = (subject['progress'] as num?)?.toDouble() ?? 0.0;
                    
                    // Alternating subject progress indicator colors
                    final subjectColors = [AppColors.emerald, AppColors.primary, AppColors.amber];
                    final progressColor = subjectColors[index % subjectColors.length];

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _buildSubjectProgress(sName, progress, progressColor, isDark),
                    );
                  }),
                SizedBox(height: 100.h), // Safe spacing under cards for curved navigation bar
              ]),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStat(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.r),
        SizedBox(height: 6.h),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.slate, size: 18.r),
        SizedBox(width: 12.w),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded,
            color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight, size: 14.r),
      ],
    );
  }

  Widget _buildSubjectProgress(String label, double progress, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252538) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? const Color(0xFF1E1E2C) : color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8.h,
            ),
          ),
        ],
      ),
    );
  }
}

