import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

class ParentHomework extends StatefulWidget {
  final Map<String, dynamic> child;
  const ParentHomework({super.key, required this.child});

  @override
  State<ParentHomework> createState() => _ParentHomeworkState();
}

class _ParentHomeworkState extends State<ParentHomework> {
  late Map<String, dynamic> _childData;
  String _filter = 'all';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _childData = widget.child;
  }

  double _rw(double value, {double min = 0, double max = double.infinity}) =>
      value.w.clamp(min, max).toDouble();
  double _rh(double value, {double min = 0, double max = double.infinity}) =>
      value.h.clamp(min, max).toDouble();
  double _rr(double value, {double min = 0, double max = double.infinity}) =>
      value.r.clamp(min, max).toDouble();
  double _rs(double value, {double min = 0, double max = double.infinity}) =>
      value.sp.clamp(min, max).toDouble();

  Future<void> _handleRefresh() async {
    try {
      final res = await ApiClient().client.get('/parents/mobile/dashboard');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final children = res.data['data']['children'] as List;
        final updated = children.firstWhere(
          (c) => c['id'] == _childData['id'],
          orElse: () => null,
        );
        if (updated != null)
          setState(() => _childData = Map<String, dynamic>.from(updated));
      }
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  Future<void> _submitHomework(Map<String, dynamic> hw) async {
    if (_isUploading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(18.r),
          child: Row(
            children: [
              Expanded(
                child: _sourceButton(
                  label: 'تصوير',
                  icon: Icons.camera_alt_rounded,
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _sourceButton(
                  label: 'المعرض',
                  icon: Icons.photo_library_rounded,
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 78,
      );
      if (image == null || !mounted) return;
      setState(() => _isUploading = true);

      final bytes = await image.readAsBytes();
      final mime = image.name.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final fileUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      await ApiClient().client.post(
        '/homework/${hw['id']}/submit',
        data: {
          'studentId': _childData['id'],
          'fileUrl': fileUrl,
        },
      );

      await _handleRefresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفع الواجب للمعلم بنجاح',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر رفع الواجب، حاول مرة أخرى',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _sourceButton(
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FD),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 22.r),
            SizedBox(width: 8.w),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 15.sp, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    if (subject.contains('علوم') ||
        subject.contains('فيزياء') ||
        subject.contains('كيمياء')) {
      return Icons.menu_book_rounded;
    }
    if (subject.contains('عربي') || subject.contains('لغة'))
      return Icons.menu_book_rounded;
    return Icons.menu_book_rounded;
  }

  Color _getSubjectColor(String subject) {
    if (subject.contains('علوم')) return const Color(0xFF20C997);
    if (subject.contains('عربي') || subject.contains('لغة'))
      return const Color(0xFFFF7A1A);
    return const Color(0xFF38BDF8);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      const months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر'
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return 'غير محدد';
    }
  }

  List<dynamic> _filtered(List<dynamic> list) {
    if (_filter == 'done')
      return list.where((hw) => hw['isSubmitted'] == true).toList();
    if (_filter == 'pending')
      return list.where((hw) => hw['isSubmitted'] != true).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final pageWidth = MediaQuery.sizeOf(context).width.clamp(0, 430).toDouble();
    final homeworks = List<dynamic>.from(_childData['homeworks'] ?? []);
    final total = homeworks.length;
    final done = homeworks.where((hw) => hw['isSubmitted'] == true).length;
    final pending = total - done;
    final list = _filtered(homeworks);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF5FF),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HomeworkBgPainter())),
          SafeArea(
            bottom: false,
            child: Center(
              child: SizedBox(
                width: pageWidth,
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.primary,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                        _rw(18, min: 16, max: 22),
                        _rh(6, min: 4, max: 10),
                        _rw(18, min: 16, max: 22),
                        _rh(34, min: 28, max: 40)),
                    children: [
                      _pageHeader(isArabic),
                      SizedBox(height: _rh(22, min: 16, max: 26)),
                      Row(
                        children: [
                          Expanded(
                              child: _summaryCard('تم التسليم', '$done',
                                  const Color(0xFF00A77E))),
                          SizedBox(width: _rw(12, min: 10, max: 14)),
                          Expanded(
                              child: _summaryCard('قيد التنفيذ', '$pending',
                                  const Color(0xFFFF5C0A))),
                          SizedBox(width: _rw(12, min: 10, max: 14)),
                          Expanded(
                              child: _summaryCard('الإجمالي', '$total',
                                  const Color(0xFF8B3FE8))),
                        ],
                      ),
                      SizedBox(height: _rh(18, min: 14, max: 22)),
                      _filters(),
                      SizedBox(height: _rh(20, min: 16, max: 24)),
                      if (list.isEmpty)
                        _empty()
                      else
                        ...list.map((hw) =>
                            _homeworkCard(Map<String, dynamic>.from(hw))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pageHeader(bool isArabic) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isArabic ? 'الواجبات المدرسية' : 'School Homework',
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: _rs(29, min: 24, max: 32),
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF172033),
                  height: 1.15,
                ),
              ),
              SizedBox(height: _rh(3, min: 2, max: 5)),
              Text(
                isArabic
                    ? 'تتبع المهام اليومية و المواعيد النهائية'
                    : 'Track daily tasks and deadlines',
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: _rs(13, min: 11.5, max: 14),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: _rw(12, min: 10, max: 14)),
        _roundButton(Icons.chevron_right_rounded,
            onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _roundButton(IconData icon,
      {Color? color, bool dot = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _rr(48, min: 42, max: 52),
        height: _rr(48, min: 42, max: 52),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14.r,
                offset: Offset(0, 6.h)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon,
                color: color ?? const Color(0xFF172033),
                size: _rr(24, min: 21, max: 26)),
            if (dot)
              Positioned(
                top: 10.r,
                right: 10.r,
                child: Container(
                    width: 9.r,
                    height: 9.r,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFF3B57), shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      height: _rh(118, min: 104, max: 126),
      padding: EdgeInsets.all(_rr(16, min: 13, max: 18)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_rr(22, min: 18, max: 24)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 16.r,
              offset: Offset(0, 10.h))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                  fontSize: _rs(12, min: 11, max: 13),
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.82))),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: _rs(30, min: 27, max: 33),
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _filters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _filterChip('all', 'الكل'),
        SizedBox(width: 10.w),
        _filterChip('pending', 'قيد التنفيذ'),
        SizedBox(width: 10.w),
        _filterChip('done', 'تم التسليم'),
      ],
    );
  }

  Widget _filterChip(String id, String label) {
    final selected = _filter == id;
    return GestureDetector(
      onTap: () => setState(() => _filter = id),
      child: Container(
        height: _rh(44, min: 40, max: 48),
        padding: EdgeInsets.symmetric(horizontal: _rw(22, min: 18, max: 26)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B4CF6) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12.r,
                offset: Offset(0, 6.h))
          ],
        ),
        child: Text(label,
            style: GoogleFonts.cairo(
                fontSize: _rs(13, min: 12, max: 14),
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : AppColors.textMedium)),
      ),
    );
  }

  Widget _homeworkCard(Map<String, dynamic> hw) {
    final subject = hw['subjectNameAr'] ?? 'مادة عامة';
    final title = hw['title'] ?? '';
    final description = hw['description'] ?? '';
    final submitted = hw['isSubmitted'] == true;
    final color = _getSubjectColor(subject);

    return Container(
      margin: EdgeInsets.only(bottom: _rh(18, min: 14, max: 22)),
      padding: EdgeInsets.all(_rr(20, min: 16, max: 22)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(_rr(24, min: 20, max: 26)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF5147E8).withValues(alpha: 0.07),
              blurRadius: 20.r,
              offset: Offset(0, 10.h))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: _rr(58, min: 50, max: 62),
                height: _rr(58, min: 50, max: 62),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18.r)),
                child: Icon(_getSubjectIcon(subject),
                    color: color, size: _rr(27, min: 24, max: 29)),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(title,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                            fontSize: _rs(19, min: 17, max: 21),
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF172033))),
                    Text(subject,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                            fontSize: _rs(12, min: 11, max: 13),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMedium)),
                  ],
                ),
              ),
            ],
          ),
          if (description.toString().isNotEmpty) ...[
            SizedBox(height: 18.h),
            Text(description,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                    fontSize: _rs(14, min: 13, max: 15),
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium)),
          ],
          SizedBox(height: 18.h),
          Row(
            children: [
              if (submitted)
                _statusPill(
                    'تم التسليم', AppColors.emerald, Icons.check_circle_rounded)
              else
                _cameraButton(hw),
              const Spacer(),
              Text('الموعد: ${_formatDate(hw['dueDate'])}',
                  style: GoogleFonts.cairo(
                      fontSize: _rs(13, min: 12, max: 14),
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF172033))),
              SizedBox(width: 8.w),
              Icon(Icons.calendar_today_rounded,
                  color: AppColors.textMedium, size: 20.r),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cameraButton(Map<String, dynamic> hw) {
    return GestureDetector(
      onTap: () => _submitHomework(hw),
      child: Container(
        height: _rh(44, min: 40, max: 48),
        padding: EdgeInsets.symmetric(horizontal: _rw(18, min: 14, max: 20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text('تصوير',
                style: GoogleFonts.cairo(
                    fontSize: _rs(14, min: 13, max: 15),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF172033))),
            SizedBox(width: 8.w),
            Icon(Icons.camera_alt_rounded,
                color: const Color(0xFF172033), size: 20.r),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color color, IconData icon) {
    return Container(
      height: _rh(38, min: 34, max: 42),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(18.r)),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: _rs(13, min: 12, max: 14),
                  fontWeight: FontWeight.w900,
                  color: color)),
          SizedBox(width: 8.w),
          Icon(icon, color: color, size: 19.r),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 44.h),
      alignment: Alignment.center,
      child: Text('لا توجد واجبات هنا',
          style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textMedium)),
    );
  }
}

class _HomeworkBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = const Color(0xFFBDE4FF).withValues(alpha: 0.34);
    final purple = Paint()
      ..color = const Color(0xFFE3D5FF).withValues(alpha: 0.42);
    final line = Paint()
      ..color = const Color(0xFF8795AD).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(size.width * .8, size.height * .04), 86, purple);
    canvas.drawCircle(Offset(size.width * .2, size.height * .34), 105, blue);
    canvas.drawCircle(Offset(size.width * .82, size.height * .78), 120, purple);
    for (var i = 0; i < 6; i++) {
      final x = size.width * (.08 + i * .17);
      canvas.drawLine(Offset(x, size.height * .15),
          Offset(x + 44, size.height * .05), line);
      canvas.drawCircle(Offset(x + 18, size.height * (.24 + i * .1)), 20, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
