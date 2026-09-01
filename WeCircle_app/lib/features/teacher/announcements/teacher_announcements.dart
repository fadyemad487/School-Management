import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import 'package:intl/intl.dart';

class TeacherAnnouncements extends StatefulWidget {
  const TeacherAnnouncements({super.key});

  @override
  State<TeacherAnnouncements> createState() => _TeacherAnnouncementsState();
}

class _TeacherAnnouncementsState extends State<TeacherAnnouncements> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;

  String _annType = 'عام';
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final List<String> _selectedClasses = [];
  
  List<dynamic> _availableClasses = [];
  List<_Ann> _announcements = [];
  
  final List<Map<String, dynamic>> _types = [
    {'label': 'عام', 'icon': Icons.campaign_rounded, 'color': AppColors.primary},
    {'label': 'اختبار', 'icon': Icons.assignment_late_rounded, 'color': AppColors.rose},
    {'label': 'واجب', 'icon': Icons.edit_calendar_rounded, 'color': AppColors.amber},
    {'label': 'نشاط', 'icon': Icons.groups_rounded, 'color': AppColors.emerald},
    {'label': 'إجازة', 'icon': Icons.event_available_rounded, 'color': Colors.blue},
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final classRes = await _apiClient.client.get('/teachers/mobile/classes');
      if (classRes.data['success'] == true) {
        _availableClasses = classRes.data['data'] as List;
        if (_availableClasses.isNotEmpty && _selectedClasses.isEmpty) {
          _selectedClasses.add(_availableClasses.first['id']);
        }
      }

      final annRes = await _apiClient.client.get('/announcements');
      if (annRes.data['success'] == true) {
        final List anns = annRes.data['data'];
        _announcements = anns.map((a) {
          final date = DateTime.parse(a['createdAt']);
          final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);
          final title = a['title'] ?? 'إعلان';
          
          // Determine type from title or default to 'عام'
          String type = 'عام';
          Color color = AppColors.primary;
          if (title.contains('اختبار')) { type = 'اختبار'; color = AppColors.rose; }
          else if (title.contains('واجب')) { type = 'واجب'; color = AppColors.amber; }
          else if (title.contains('نشاط')) { type = 'نشاط'; color = AppColors.emerald; }

          return _Ann(
            title,
            a['body'] ?? '',
            type,
            dateStr,
            color
          );
        }).toList();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: appScreenBackground(context),
      appBar: AppBar(
        title: Text(
          'إعلانات المركز',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: appScreenBackground(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Header Stats or Recent pinned
              Container(
                color: isDark ? const Color(0xFF12121E) : Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    _buildTypeFilter(context, 'الكل', true),
                    _buildTypeFilter(context, 'الاختبارات', false),
                    _buildTypeFilter(context, 'الأنشطة', false),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(20.r),
                  children: [
                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'أحدث الإعلانات',
                          style: GoogleFonts.cairo(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        Text(
                          'تم الإرسال لـ ${_availableClasses.length} فصول',
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Announcements List
                    if (_announcements.isEmpty)
                      Center(child: Text('لا يوجد إعلانات', style: GoogleFonts.cairo(color: AppColors.textMedium)))
                    else
                      ..._announcements.map((a) => _buildAnnCard(a)),
                  ],
                ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAnnSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: Text(
          'إعلان جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTypeFilter(BuildContext context, String label, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E1E2C) : AppColors.background),
        borderRadius: BorderRadius.circular(12.r),
        border: isSelected ? null : Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          color: isSelected ? Colors.white : (isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium),
        ),
      ),
    );
  }

  Widget _buildAnnCard(_Ann ann) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: ann.color.withOpacity(0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: ann.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    ann.type == 'اختبار' ? Icons.assignment_late_rounded : ann.type == 'واجب' ? Icons.edit_calendar_rounded : Icons.campaign_rounded,
                    color: ann.color,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ann.type,
                      style: GoogleFonts.cairo(fontSize: 11.sp, fontWeight: FontWeight.w900, color: ann.color),
                    ),
                    Text(
                      ann.date,
                      style: GoogleFonts.cairo(fontSize: 10.sp, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz_rounded, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ann.title,
                  style: GoogleFonts.cairo(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.textDark),
                ),
                SizedBox(height: 6.h),
                Text(
                  ann.body,
                  style: GoogleFonts.cairo(fontSize: 13.sp, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium, height: 1.6, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAnnSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        ),
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border, borderRadius: BorderRadius.circular(2)))),
            SizedBox(height: 24.h),
            Text('نشر إعلان جديد', style: GoogleFonts.cairo(fontSize: 20.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
            SizedBox(height: 24.h),

            _buildLabel(context, 'اختر الفصول المستهدفة'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableClasses.map((c) {
                  bool isSelected = _selectedClasses.contains(c['id']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) _selectedClasses.remove(c['id']);
                        else _selectedClasses.add(c['id']);
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 8.w),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF12121E) : AppColors.background),
                        borderRadius: BorderRadius.circular(12.r),
                        border: isSelected ? null : Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                      ),
                      child: Text(c['name'], style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : (isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium))),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 24.h),
            _buildLabel(context, 'نوع الإعلان'),
            Row(
              children: _types.map((t) {
                bool isSelected = _annType == t['label'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _annType = t['label']),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: isSelected ? t['color'] : (isDark ? const Color(0xFF12121E) : t['color'].withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          Icon(t['icon'], color: isSelected ? Colors.white : t['color'], size: 20.r),
                          SizedBox(height: 4.h),
                          Text(t['label'], style: GoogleFonts.cairo(fontSize: 11.sp, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : t['color'])),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 24.h),
            _buildLabel(context, 'محتوى الإعلان'),
            TextField(
              controller: _titleCtrl,
              style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'عنوان الإعلان البارز',
                hintStyle: GoogleFonts.cairo(color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight),
                filled: true,
                fillColor: isDark ? const Color(0xFF12121E) : AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              style: GoogleFonts.cairo(fontSize: 14.sp, color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'اكتب تفاصيل الإعلان هنا...',
                hintStyle: GoogleFonts.cairo(color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight),
                filled: true,
                fillColor: isDark ? const Color(0xFF12121E) : AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text('إرسال لجميع المستهدفين', style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(label, style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textDark)),
    );
  }

  Future<void> _submitAnnouncement() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال عنوان ومحتوى الإعلان')));
      return;
    }

    Navigator.pop(context); // Close bottom sheet
    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.client.post('/announcements', data: {
        'title': '[$_annType] $title',
        'body': body,
        'audience': _selectedClasses.isNotEmpty ? _selectedClasses.join(',') : 'all',
      });

      if (res.data['success'] == true) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _showSuccessFeedback();
        _fetchData();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إرسال الإعلان')));
    }
  }

  void _showSuccessFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نشر الإعلان بنجاح في فصولك المختارة ✓', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }
}

class _Ann {
  final String title, body, type, date;
  final Color color;
  const _Ann(this.title, this.body, this.type, this.date, this.color);
}
