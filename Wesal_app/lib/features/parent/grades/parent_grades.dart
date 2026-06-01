import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';

class ParentGrades extends StatefulWidget {
  final Map<String, dynamic> child;
  const ParentGrades({super.key, required this.child});

  @override
  State<ParentGrades> createState() => _ParentGradesState();
}

class _ParentGradesState extends State<ParentGrades> {
  late Map<String, dynamic> _childData;

  @override
  void initState() {
    super.initState();
    _childData = widget.child;
  }

  Future<void> _handleRefresh() async {
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
  }

  IconData _getSubjectIcon(String subject) {
    if (subject.contains('رياضيات')) return Icons.functions_rounded;
    if (subject.contains('علوم') || subject.contains('فيزياء') || subject.contains('كيمياء')) return Icons.biotech_rounded;
    if (subject.contains('عربي') || subject.contains('لغة عربية')) return Icons.translate_rounded;
    if (subject.contains('انجليزي') || subject.contains('لغة إنجليزية')) return Icons.language_rounded;
    if (subject.contains('حاسب') || subject.contains('برمجة')) return Icons.computer_rounded;
    if (subject.contains('رسم') || subject.contains('فنية')) return Icons.palette_rounded;
    if (subject.contains('رياضة') || subject.contains('بدنية')) return Icons.sports_soccer_rounded;
    return Icons.menu_book_rounded;
  }

  Color _getSubjectColor(String subject) {
    if (subject.contains('رياضيات')) return AppColors.primary;
    if (subject.contains('علوم') || subject.contains('فيزياء') || subject.contains('كيمياء')) return AppColors.emerald;
    if (subject.contains('عربي') || subject.contains('لغة عربية')) return AppColors.amber;
    if (subject.contains('انجليزي') || subject.contains('لغة إنجليزية')) return AppColors.purple;
    if (subject.contains('حاسب') || subject.contains('برمجة')) return AppColors.teal;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final gpaStr = _childData['gpa']?.toString() ?? '3.92';
    final double gpaValue = double.tryParse(gpaStr) ?? 3.92;
    final percent = gpaValue / 4.0;
    
    final level = _childData['gradeLetterAr'] ?? 'ممتاز';
    final List<dynamic> academicPerformance = _childData['academicPerformance'] ?? [];
 
    final conduct = _childData['conduct'] ?? 'ممتاز';
    final homeroomTeacher = _childData['homeroomTeacher'] ?? 'معلم الفصل';
    
    String evaluationText = 'طفلكم متميز ومجتهد جداً في الحصة. لديه حضور مستمر وتفاعل مميز ومثالي مع زملائه.';
    if (conduct == 'جيد جداً') {
      evaluationText = 'طالب مجتهد وذو سلوك حسن وتفاعل جيد جداً في الحصة. يظهر رغبة مستمرة في التعلم والتطور.';
    } else if (conduct == 'مقبول') {
      evaluationText = 'يحتاج الطالب إلى مزيد من التركيز والمتابعة المستمرة لتحسين الأداء وتجنب تشتت الانتباه في الفصل.';
    } else if (conduct == 'ضعيف') {
      evaluationText = 'مستوى الطالب متراجع ويحتاج إلى خطة علاجية عاجلة ومتابعة يومية مكثفة من قبل ولي الأمر.';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'الدرجات والتقارير',
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
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium GPA Card
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 20.r,
                    offset: Offset(0, 10.h),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المعدل العام (GPA)',
                          style: GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '$gpaStr / 4.0',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'المستوى: $level',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildGPACircle(percent),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Performance by Subject
            Text(
              'أداء المواد الدراسية',
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 16.h),
            
            if (academicPerformance.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'لا توجد درجات مسجلة للمواد حالياً',
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: academicPerformance.map<Widget>((item) {
                  final subjectName = item['subjectNameAr'] ?? 'مادة عامة';
                  final double progress = item['progress'] != null ? double.tryParse(item['progress'].toString()) ?? 0.0 : 0.0;
                  final int score = item['score'] != null ? int.tryParse(item['score'].toString()) ?? 0 : 0;
                  final int maxScore = item['maxScore'] != null ? int.tryParse(item['maxScore'].toString()) ?? 100 : 100;
                  
                  return _buildSubjectGradeRow(
                    subjectName,
                    score,
                    maxScore,
                    progress,
                    _getSubjectColor(subjectName),
                    _getSubjectIcon(subjectName),
                  );
                }).toList(),
              ),
            SizedBox(height: 24.h),

            // Teacher Evaluation Section
            Text(
              'تقييم المعلم وملاحظات السلوك',
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 12.h),
            _buildEvaluationCard(
              homeroomTeacher,
              'مربّي الفصل / المعلم المشرف',
              evaluationText,
              _childData['gender'] == 'FEMALE'
                  ? 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop'
                  : 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop',
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildGPACircle(double percent) {
    return Container(
      width: 90.r,
      height: 90.r,
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 74.r,
            height: 74.r,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Text(
            '${(percent * 100).toInt()}%',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectGradeRow(
      String name, int score, int maxScore, double progress, Color color, IconData icon) {
    final percentageVal = maxScore > 0 ? (score / maxScore * 100).toInt() : 0;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 22.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'الدرجة: $score من أصل $maxScore',
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentageVal%',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(
      String teacher, String subject, String text, String image) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundImage: NetworkImage(image),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher,
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subject,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
