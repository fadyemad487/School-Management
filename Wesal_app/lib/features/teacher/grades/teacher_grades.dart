import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart';

class TeacherGrades extends StatefulWidget {
  const TeacherGrades({super.key});

  @override
  State<TeacherGrades> createState() => _TeacherGradesState();
}

class _TeacherGradesState extends State<TeacherGrades> {
  final ApiClient _apiClient = ApiClient();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = true;

  List<dynamic> _classes = [];
  List<dynamic> _exams = [];
  String? _selectedClassId;
  String? _selectedExamId;

  List<_GradeEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchData();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendNotificationWithSound({
    required String title,
    required String body,
  }) async {
    try {
      // Play notification sound
      await _audioPlayer.play(AssetSource('sounds/notification_bell.wav'));
      
      // Show notification with proper styling
      const androidDetails = AndroidNotificationDetails(
        'grades_notifications',
        'Grades Notifications',
        channelDescription: 'Notifications for grade updates',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      // Silently handle notification errors
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final classRes = await _apiClient.client.get('/teachers/mobile/classes');
      if (classRes.data['success'] == true) {
        _classes = classRes.data['data'] as List;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
        }
      }

      final examRes = await _apiClient.client.get('/exams');
      if (examRes.data['success'] == true) {
        _exams = examRes.data['data'] as List;
        if (_exams.isNotEmpty) {
          // Filter exams by selected class if possible
          _filterExamsAndSetDefault();
        }
      }

      _buildStudentEntries();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterExamsAndSetDefault() {
    // Pick class-specific exams first, otherwise all
    final classExams = _exams.where((e) => e['classId'] == _selectedClassId).toList();
    if (classExams.isNotEmpty) {
      _selectedExamId = classExams.first['id'];
    } else if (_exams.isNotEmpty) {
      _selectedExamId = _exams.first['id'];
    }
  }

  void _buildStudentEntries() {
    if (_selectedClassId == null) {
      _entries = [];
      return;
    }

    final cls = _classes.firstWhere(
      (c) => c['id'] == _selectedClassId,
      orElse: () => null,
    );

    if (cls == null) {
      _entries = [];
      return;
    }

    final students = cls['students'] as List? ?? [];
    _entries = students.map((s) => _GradeEntry(
      s['id'],
      s['name'] ?? 'طالب',
      s['number'] ?? 0,
      0, // default grade – will be loaded from exam results if available
      s['avatar'] ?? 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
    )).toList();
  }

  double get _average => _entries.isEmpty
      ? 0
      : _entries.map((e) => e.grade.toDouble()).reduce((a, b) => a + b) / _entries.length;
  int get _passCount => _entries.where((e) => e.grade >= 60).length;

  void _editGrade(int index) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: '${_entries[index].grade}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تحديث درجة الطالب',
                style: GoogleFonts.cairo(fontSize: 18.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
              ),
              SizedBox(height: 8.h),
              Text(
                _entries[index].name,
                style: GoogleFonts.cairo(fontSize: 14.sp, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 24.h),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 24.sp, fontWeight: FontWeight.w900, color: AppColors.primary),
                decoration: InputDecoration(
                  hintText: '00',
                  suffixText: '/ 100',
                  suffixStyle: GoogleFonts.cairo(fontSize: 16.sp, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF12121E) : AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final val = int.tryParse(ctrl.text);
                    if (val != null && val >= 0 && val <= 100) {
                      setState(() => _entries[index].grade = val);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: Text('حفظ التعديلات', style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _gradeColor(int grade) {
    if (grade >= 90) return AppColors.emerald;
    if (grade >= 75) return AppColors.primary;
    if (grade >= 60) return AppColors.amber;
    return AppColors.rose;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: appScreenBackground(context),
      appBar: AppBar(
        title: Text(
          'رصد الدرجات',
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
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _showPublishConfirmation,
            icon: Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 24.r),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Section
                Container(
                  color: isDark ? const Color(0xFF12121E) : Colors.white,
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        // Class filter
                        _buildDropdownChip(
                          context,
                          _classes.firstWhere((c) => c['id'] == _selectedClassId, orElse: () => {'name': 'اختر فصل'})['name'] ?? 'اختر فصل',
                          Icons.class_rounded,
                          _classes.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                            value: c['id'],
                            child: Text(c['name'] ?? '', style: GoogleFonts.cairo(fontSize: 13.sp)),
                          )).toList(),
                          _selectedClassId,
                          (v) {
                            setState(() {
                              _selectedClassId = v;
                              _filterExamsAndSetDefault();
                              _buildStudentEntries();
                            });
                          },
                        ),
                        SizedBox(width: 12.w),
                        // Exam filter
                        _buildDropdownChip(
                          context,
                          _exams.firstWhere((e) => e['id'] == _selectedExamId, orElse: () => {'name': 'اختر اختبار'})['name'] ?? 'اختر اختبار',
                          Icons.assignment_rounded,
                          _exams.map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                            value: e['id'],
                            child: Text(e['name'] ?? '', style: GoogleFonts.cairo(fontSize: 13.sp)),
                          )).toList(),
                          _selectedExamId,
                          (v) {
                            setState(() {
                              _selectedExamId = v;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: _entries.isEmpty
                      ? Center(child: Text('لا يوجد طلاب', style: GoogleFonts.cairo(color: AppColors.textMedium)))
                      : ListView(
                          padding: EdgeInsets.all(20.r),
                          children: [
                            // Stats Card
                            _buildStatsCard(context),
                            SizedBox(height: 24.h),

                            // List Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'درجات الطلاب',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  'اضغط للتعديل',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),

                            // Grades List
                            ..._entries.asMap().entries.map((entry) => _buildGradeCard(entry.value, entry.key)),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDropdownChip(
    BuildContext context,
    String display,
    IconData icon,
    List<DropdownMenuItem<String>> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : AppColors.background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.r, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium),
          SizedBox(width: 6.w),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              items: items,
              onChanged: onChanged,
              style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textDark),
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18.r, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('المتوسط', '${_average.toInt()}%', AppColors.primary),
              Container(width: 1.w, height: 40.h, color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
              _buildStatItem('نسبة النجاح', _entries.isNotEmpty ? '${((_passCount / _entries.length) * 100).toInt()}%' : '0%', AppColors.emerald),
              Container(width: 1.w, height: 40.h, color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
              _buildStatItem('الطلاب', '${_entries.length}', isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(fontSize: 20.sp, fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildGradeCard(_GradeEntry entry, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _gradeColor(entry.grade);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundImage: entry.avatar.startsWith('http')
                ? NetworkImage(entry.avatar)
                : const NetworkImage('https://cdn-icons-png.flaticon.com/512/149/149071.png') as ImageProvider,
            onBackgroundImageError: (_, __) {},
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'رقم التسلسل: ${entry.number}',
                  style: GoogleFonts.cairo(fontSize: 11.sp, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _editGrade(index),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Text(
                    '${entry.grade}',
                    style: GoogleFonts.cairo(fontSize: 18.sp, fontWeight: FontWeight.w900, color: color),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.edit_rounded, size: 14.r, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPublishConfirmation() async {
    if (_selectedExamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار اختبار أولاً', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare results payload
      final results = _entries.map((entry) => {
        'studentId': entry.id,
        'score': entry.grade,
        'absent': entry.grade == 0, // Mark as absent if score is 0
      }).toList();

      // Call API to save results (mobile endpoint)
      final response = await _apiClient.client.post(
        '/exams/mobile/$_selectedExamId/results',
        data: {'results': results},
      );

      if (response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, color: Colors.white),
                SizedBox(width: 12.w),
                Text('تم نشر النتائج وفتح الاطلاع للآباء', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              ],
            ),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
        );
        
        // Send notification with sound to parents
        final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
        final examName = _exams.firstWhere((e) => e['id'] == _selectedExamId, orElse: () => {'name': 'امتحان'})['name'] ?? 'امتحان';
        await _sendNotificationWithSound(
          title: isArabic ? '📊 نشر النتائج' : '📊 Grades Published',
          body: isArabic 
              ? 'تم نشر نتائج الامتحان: $examName'
              : 'Grades have been published for exam: $examName',
        );
      }
    } catch (e) {
      print('Error publishing results: $e');
      print('Selected exam ID: $_selectedExamId');
      print('Number of entries: ${_entries.length}');
      print('Results payload: ${_entries.map((entry) => {'studentId': entry.id, 'score': entry.grade}).toList()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12.w),
              Text('حدث خطأ في نشر النتائج', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ],
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _GradeEntry {
  final String id, name, avatar;
  final int number;
  int grade;
  _GradeEntry(this.id, this.name, this.number, this.grade, this.avatar);
}
