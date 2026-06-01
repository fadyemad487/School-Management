import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../main.dart';

class TeacherBehavior extends StatefulWidget {
  const TeacherBehavior({super.key});

  @override
  State<TeacherBehavior> createState() => _TeacherBehaviorState();
}

class _TeacherBehaviorState extends State<TeacherBehavior> {
  final ApiClient _apiClient = ApiClient();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const double _maxContentWidth = 430;
  static const List<String> _weekDays = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
  ];
  static const List<String> _monthWeeks = [
    'الأسبوع الأول',
    'الأسبوع الثاني',
    'الأسبوع الثالث',
    'الأسبوع الرابع',
  ];

  String? _selectedStudentId;
  String? _selectedClassId;
  String? _selectedFilterClassId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  NoteType _selectedType = NoteType.positive;
  List<String> _selectedTraits = [];
  List<_ClassInfo> _classes = [];
  List<_StudentInfo> _students = [];

  final _noteCtrl = TextEditingController();
  final Map<String, TextEditingController> _weeklyPositiveCtrls = {
    for (final day in _weekDays) day: TextEditingController(),
  };
  final Map<String, TextEditingController> _weeklyNegativeCtrls = {
    for (final day in _weekDays) day: TextEditingController(),
  };
  final List<TextEditingController> _recommendationCtrls =
      List.generate(4, (_) => TextEditingController());
  final Map<String, TextEditingController> _monthlyPositiveCtrls = {
    for (final week in _monthWeeks) week: TextEditingController(),
  };
  final Map<String, TextEditingController> _monthlyNegativeCtrls = {
    for (final week in _monthWeeks) week: TextEditingController(),
  };
  final Map<String, String> _monthlyStatuses = {
    for (final week in _monthWeeks) week: 'مستقر',
  };

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
    _noteCtrl.dispose();
    _audioPlayer.dispose();
    for (final c in _weeklyPositiveCtrls.values) {
      c.dispose();
    }
    for (final c in _weeklyNegativeCtrls.values) {
      c.dispose();
    }
    for (final c in _recommendationCtrls) {
      c.dispose();
    }
    for (final c in _monthlyPositiveCtrls.values) {
      c.dispose();
    }
    for (final c in _monthlyNegativeCtrls.values) {
      c.dispose();
    }
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
        'behavior_reports',
        'Behavior Reports',
        channelDescription: 'Notifications for behavior reports',
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

  Future<void> _fetchData({bool preserveSelection = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final classRes = await _apiClient.client.get('/teachers/mobile/classes');
      if (!mounted) return;

      if (classRes.data['success'] == true) {
        final classes = classRes.data['data'] as List;
        final allClasses = <_ClassInfo>[];
        final allStudents = <_StudentInfo>[];

        for (final cls in classes) {
          final clsId = cls['id']?.toString() ?? '';
          allClasses.add(_ClassInfo(clsId, (cls['name'] ?? 'فصل').toString()));
          for (final s in (cls['students'] as List? ?? [])) {
            allStudents.add(_StudentInfo(
              s['id']?.toString() ?? '',
              clsId,
              (s['name'] ?? 'طالب').toString(),
            ));
          }
        }

        _classes = allClasses;
        _students = allStudents;
        if (_classes.isNotEmpty) {
          if (!preserveSelection || _selectedFilterClassId == null) {
            _selectedFilterClassId = _classes.first.id;
          }
          final classStudents = _students
              .where((s) => s.classId == _selectedFilterClassId)
              .toList();
          if (classStudents.isNotEmpty &&
              !classStudents.any((s) => s.id == _selectedStudentId)) {
            _selectedStudentId = classStudents.first.id;
            _selectedClassId = classStudents.first.classId;
          } else if (classStudents.isEmpty) {
            _selectedStudentId = null;
            _selectedClassId = _selectedFilterClassId;
          }
        }
      }
    } catch (_) {
      // Keep current empty state.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReport() async {
    if (_selectedStudentId == null || _selectedClassId == null) {
      _showSnack('الرجاء اختيار طالب');
      return;
    }

    final payload = _buildSubmissionPayload();
    if (payload == null) {
      _showSnack('الرجاء إضافة ملاحظة');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _apiClient.client.post('/behavior', data: {
        'studentId': _selectedStudentId,
        'classId': _selectedClassId,
        'type': payload.type.name.toUpperCase(),
        'traits': payload.traits,
        'notes': payload.notes,
      });

      if (response.data['success'] == true) {
        _clearCurrentPeriodFields();
        if (mounted) {
          setState(() {});
          _showSnack('تم إرسال التقرير بنجاح', color: AppColors.emerald);
          
          // Send professional notification with sound to parent
          final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
          final student = _students
              .where((s) => s.id == _selectedStudentId)
              .cast<_StudentInfo?>()
              .firstWhere((s) => s != null, orElse: () => null);
          
          await _sendNotificationWithSound(
            title: isArabic ? '🔔 تقرير سلوكي جديد' : '🔔 New Behavior Report',
            body: isArabic 
                ? 'تم إرسال تقرير سلوكي جديد للطالب: ${student?.name ?? "طفلك"}'
                : 'A new behavior report has been sent for student: ${student?.name ?? "your child"}',
          );
        }
      }
    } catch (_) {
      _showSnack('فشل إرسال التقرير', color: AppColors.rose);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  _BehaviorSubmission? _buildSubmissionPayload() {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        if (_selectedTraits.isEmpty && _noteCtrl.text.trim().isEmpty) {
          return null;
        }
        return _BehaviorSubmission(
          type: _selectedType,
          traits: _selectedTraits.isEmpty
              ? [_typeLabel(_selectedType)]
              : List<String>.from(_selectedTraits),
          notes: _noteCtrl.text.trim(),
        );
      case ReportPeriod.weekly:
        final parts = <String>[];
        for (final day in _weekDays) {
          final positive = _weeklyPositiveCtrls[day]!.text.trim();
          final negative = _weeklyNegativeCtrls[day]!.text.trim();
          if (positive.isNotEmpty || negative.isNotEmpty) {
            parts.add(
                '$day: إيجابيات: ${positive.isEmpty ? '-' : positive} | سلبيات: ${negative.isEmpty ? '-' : negative}');
          }
        }
        final recommendations = _recommendationCtrls
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();
        if (parts.isEmpty && recommendations.isEmpty) return null;
        if (recommendations.isNotEmpty) {
          parts.add('خطة العلاج والتوصيات: ${recommendations.join(' | ')}');
        }
        return _BehaviorSubmission(
          type: NoteType.followup,
          traits: const ['تقرير أسبوعي'],
          notes: parts.join('\n'),
        );
      case ReportPeriod.monthly:
        final parts = <String>[];
        for (final week in _monthWeeks) {
          final positive = _monthlyPositiveCtrls[week]!.text.trim();
          final negative = _monthlyNegativeCtrls[week]!.text.trim();
          final status = _monthlyStatuses[week] ?? 'مستقر';
          if (positive.isNotEmpty || negative.isNotEmpty) {
            parts.add(
                '$week ($status): الإيجابيات: ${positive.isEmpty ? '-' : positive} | التنبيهات: ${negative.isEmpty ? '-' : negative}');
          }
        }
        if (parts.isEmpty) return null;
        return _BehaviorSubmission(
          type: NoteType.followup,
          traits: const ['تقرير شهري'],
          notes: parts.join('\n'),
        );
    }
  }

  void _clearCurrentPeriodFields() {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        _noteCtrl.clear();
        _selectedTraits.clear();
        break;
      case ReportPeriod.weekly:
        for (final c in _weeklyPositiveCtrls.values) {
          c.clear();
        }
        for (final c in _weeklyNegativeCtrls.values) {
          c.clear();
        }
        for (final c in _recommendationCtrls) {
          c.clear();
        }
        break;
      case ReportPeriod.monthly:
        for (final c in _monthlyPositiveCtrls.values) {
          c.clear();
        }
        for (final c in _monthlyNegativeCtrls.values) {
          c.clear();
        }
        break;
    }
  }

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final pageWidth =
        math.min(MediaQuery.sizeOf(context).width, _maxContentWidth);

    return Scaffold(
      backgroundColor: appScreenBackground(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5147E8)),
            )
          : Stack(
              children: [
                Positioned.fill(
                    child: CustomPaint(painter: _ReportBgPainter())),
                SafeArea(
                  bottom: false,
                  child: Center(
                    child: SizedBox(
                      width: pageWidth,
                      child: Column(
                        children: [
                          _buildHeader(isArabic),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                _rw(20, min: 16, max: 22),
                                _rh(8, min: 6, max: 10),
                                _rw(20, min: 16, max: 22),
                                _rh(118, min: 100, max: 128),
                              ),
                              child: Column(
                                children: [
                                  _buildTabs(isArabic),
                                  SizedBox(height: _rh(22, min: 16, max: 24)),
                                  _buildReportCard(isArabic),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: SizedBox(width: pageWidth, child: _bottomActions()),
                  ),
                ),
              ],
            ),
    );
  }

  double _rw(double value, {double min = 0, double max = double.infinity}) =>
      value.w.clamp(min, max).toDouble();
  double _rh(double value, {double min = 0, double max = double.infinity}) =>
      value.h.clamp(min, max).toDouble();
  double _rr(double value, {double min = 0, double max = double.infinity}) =>
      value.r.clamp(min, max).toDouble();
  double _rs(double value, {double min = 0, double max = double.infinity}) =>
      value.sp.clamp(min, max).toDouble();

  Widget _buildHeader(bool isArabic) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _rw(22, min: 18, max: 24),
        _rh(16, min: 12, max: 18),
        _rw(22, min: 18, max: 24),
        _rh(8, min: 4, max: 10),
      ),
      child: Row(
        children: [
          _circleButton(
            icon: isArabic
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              isArabic ? 'بوابة تحرير التقارير' : 'Report Editing Portal',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: _rs(25, min: 21, max: 26),
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF172033),
              ),
            ),
          ),
          SizedBox(width: _rr(50, min: 42, max: 50)),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _rr(50, min: 42, max: 50),
        height: _rr(50, min: 42, max: 50),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: Offset(0, _rh(8, min: 5, max: 8)),
            ),
          ],
        ),
        child: Icon(icon,
            color: const Color(0xFF172033), size: _rr(30, min: 26, max: 32)),
      ),
    );
  }

  Widget _buildTabs(bool isArabic) {
    final tabs = [
      _TabData(isArabic ? 'يومي' : 'Daily', Icons.calendar_today_rounded,
          ReportPeriod.daily),
      _TabData(isArabic ? 'أسبوعي' : 'Weekly', Icons.calendar_month_rounded,
          ReportPeriod.weekly),
      _TabData(isArabic ? 'شهري' : 'Monthly', Icons.insert_chart_rounded,
          ReportPeriod.monthly),
    ];

    return Row(
      children: tabs.map((tab) {
        final selected = tab.period == _selectedPeriod;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _rw(5, min: 4, max: 5)),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = tab.period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: _rh(82, min: 70, max: 86),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF5147E8) : Colors.white,
                  borderRadius:
                      BorderRadius.circular(_rr(18, min: 15, max: 18)),
                  boxShadow: [
                    BoxShadow(
                      color: (selected ? const Color(0xFF5147E8) : Colors.black)
                          .withValues(alpha: selected ? 0.22 : 0.05),
                      blurRadius: selected ? 20 : 14,
                      offset: Offset(0, _rh(8, min: 5, max: 10)),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab.icon,
                        color:
                            selected ? Colors.white : const Color(0xFF64748B),
                        size: _rr(23, min: 20, max: 24)),
                    SizedBox(height: _rh(7, min: 5, max: 8)),
                    Text(
                      tab.label,
                      style: GoogleFonts.cairo(
                        fontSize: _rs(14, min: 12, max: 15),
                        fontWeight: FontWeight.w800,
                        color:
                            selected ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportCard(bool isArabic) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_rr(24, min: 20, max: 24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: Offset(0, _rh(12, min: 8, max: 12)),
          ),
        ],
      ),
      child: Column(
        children: [
          _cardHeader(isArabic),
          _divider(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _rw(22, min: 16, max: 22),
              _rh(28, min: 20, max: 28),
              _rw(22, min: 16, max: 22),
              _rh(30, min: 22, max: 30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _sectionTitle(isArabic
                    ? 'أولاً: اختيار الطالب'
                    : 'First: Select Student'),
                SizedBox(height: _rh(18, min: 12, max: 20)),
                _classSelector(isArabic),
                SizedBox(height: _rh(18, min: 12, max: 20)),
                _studentSelector(isArabic),
                SizedBox(height: _rh(28, min: 18, max: 30)),
                _divider(),
                SizedBox(height: _rh(26, min: 18, max: 28)),
                _sectionTitle(isArabic
                    ? 'ثانياً: إدخال بيانات التقرير'
                    : 'Second: Report Details'),
                SizedBox(height: _rh(18, min: 12, max: 20)),
                _detailsContent(isArabic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardHeader(bool isArabic) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _rw(22, min: 16, max: 22),
        _rh(22, min: 16, max: 24),
        _rw(22, min: 16, max: 22),
        _rh(18, min: 12, max: 20),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_document,
              color: const Color(0xFF5147E8), size: _rr(32, min: 27, max: 34)),
          SizedBox(width: _rw(12, min: 9, max: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _reportTitle(isArabic),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: _rs(17, min: 15, max: 18),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF172033),
                  ),
                ),
                Text(
                  isArabic
                      ? 'المعلم هو المسؤول عن دقة هذه البيانات'
                      : 'The teacher is responsible for these details',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: _rs(11.5, min: 10, max: 12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _reportTitle(bool isArabic) {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return isArabic ? 'تحرير التقرير اليومي الرسمي' : 'Edit Daily Report';
      case ReportPeriod.weekly:
        return isArabic
            ? 'تحرير التقرير الأسبوعي الرسمي'
            : 'Edit Weekly Report';
      case ReportPeriod.monthly:
        return isArabic ? 'تحرير التقرير الشهري الرسمي' : 'Edit Monthly Report';
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
        fontSize: _rs(20, min: 17, max: 20),
        fontWeight: FontWeight.w900,
        color: const Color(0xFF5044DF),
      ),
    );
  }

  Widget _classSelector(bool isArabic) {
    if (_classes.isEmpty) {
      return _emptyBox(isArabic ? 'لا توجد فصول' : 'No classes');
    }
    final first = _classes.take(3).toList();
    final second = _classes.skip(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _groupLabel(isArabic ? 'صفوف ( 1 - 3 )' : 'Classes (1 - 3)'),
        SizedBox(height: _rh(10, min: 7, max: 10)),
        _classGrid(first),
        if (second.isNotEmpty) ...[
          SizedBox(height: _rh(18, min: 12, max: 18)),
          _groupLabel(isArabic ? 'صفوف ( 4 - 6 )' : 'Classes (4 - 6)'),
          SizedBox(height: _rh(10, min: 7, max: 10)),
          _classGrid(second),
        ],
      ],
    );
  }

  Widget _groupLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: _rs(13, min: 11, max: 13),
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
      ),
    );
  }

  Widget _classGrid(List<_ClassInfo> classes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = _rw(12, min: 8, max: 12);
        final itemWidth = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: _rh(14, min: 10, max: 14),
          alignment: WrapAlignment.end,
          children: classes.map((cls) {
            final selected = cls.id == _selectedFilterClassId;
            return GestureDetector(
              onTap: () => _selectClass(cls),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: itemWidth,
                height: _rh(74, min: 58, max: 74),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF5147E8) : Colors.white,
                  borderRadius:
                      BorderRadius.circular(_rr(13, min: 10, max: 13)),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF5147E8)
                        : const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  cls.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: _rs(16.5, min: 14, max: 17),
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _studentSelector(bool isArabic) {
    final classStudents =
        _students.where((s) => s.classId == _selectedFilterClassId).toList();
    if (classStudents.isEmpty) {
      return _emptyBox(isArabic ? 'لا يوجد طلاب في هذا الفصل' : 'No students');
    }
    return Wrap(
      spacing: _rw(10, min: 7, max: 10),
      runSpacing: _rh(10, min: 7, max: 10),
      alignment: WrapAlignment.end,
      children: classStudents.map((student) {
        final selected = student.id == _selectedStudentId;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedStudentId = student.id;
            _selectedClassId = student.classId;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: BoxConstraints(
              minWidth: _rw(92, min: 78, max: 92),
              maxWidth: _rw(138, min: 112, max: 138),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: _rw(14, min: 10, max: 14),
              vertical: _rh(10, min: 7, max: 10),
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF625DF3) : Colors.white,
              borderRadius: BorderRadius.circular(_rr(13, min: 10, max: 13)),
              border: Border.all(
                color: selected
                    ? const Color(0xFF625DF3)
                    : const Color(0xFFE5E7EB),
                width: 1.2,
              ),
            ),
            child: Text(
              student.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: _rs(14, min: 12, max: 14),
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _selectClass(_ClassInfo cls) {
    setState(() {
      _selectedFilterClassId = cls.id;
      final classStudents =
          _students.where((s) => s.classId == cls.id).toList();
      if (classStudents.isNotEmpty) {
        _selectedStudentId = classStudents.first.id;
        _selectedClassId = classStudents.first.classId;
      } else {
        _selectedStudentId = null;
        _selectedClassId = cls.id;
      }
    });
  }

  Widget _detailsContent(bool isArabic) {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return _dailyDetails(isArabic);
      case ReportPeriod.weekly:
        return _weeklyDetails(isArabic);
      case ReportPeriod.monthly:
        return _monthlyDetails(isArabic);
    }
  }

  Widget _dailyDetails(bool isArabic) {
    return Column(
      children: [
        Row(
          children: [
            _typeChip(NoteType.positive),
            SizedBox(width: _rw(8, min: 6, max: 8)),
            _typeChip(NoteType.followup),
            SizedBox(width: _rw(8, min: 6, max: 8)),
            _typeChip(NoteType.negative),
          ],
        ),
        SizedBox(height: _rh(12, min: 8, max: 12)),
        Row(
          children: [
            _typeBadge(),
            SizedBox(width: _rw(12, min: 8, max: 12)),
            Expanded(child: _traitDropdown(isArabic)),
          ],
        ),
        SizedBox(height: _rh(14, min: 10, max: 14)),
        _textField(_noteCtrl, isArabic ? 'الوصف التفصيلي' : 'Details'),
        SizedBox(height: _rh(22, min: 14, max: 24)),
        TextButton.icon(
          onPressed: () => setState(() {
            _noteCtrl.clear();
            _selectedTraits.clear();
            _selectedType = NoteType.positive;
          }),
          icon: Icon(Icons.add_circle_outline_rounded,
              size: _rr(24, min: 21, max: 26), color: const Color(0xFF5147E8)),
          label: Text(
            isArabic ? 'إضافة ملاحظة يومية أخرى' : 'Add Another Daily Note',
            style: GoogleFonts.cairo(
              fontSize: _rs(17, min: 14, max: 18),
              fontWeight: FontWeight.w900,
              color: const Color(0xFF5147E8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeChip(NoteType type) {
    final selected = _selectedType == type;
    final color = _typeColor(type);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedType = type;
          _selectedTraits.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: _rh(40, min: 34, max: 40),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(_rr(10, min: 8, max: 10)),
            border: Border.all(
              color: selected ? color : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            _typeLabel(type),
            style: GoogleFonts.cairo(
              fontSize: _rs(12, min: 10.5, max: 12),
              fontWeight: FontWeight.w900,
              color: selected ? color : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeBadge() {
    final color = _typeColor(_selectedType);
    return Container(
      width: _rw(64, min: 54, max: 64),
      height: _rh(48, min: 40, max: 48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(_rr(10, min: 8, max: 10)),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        _typeLabel(_selectedType),
        style: GoogleFonts.cairo(
          fontSize: _rs(12, min: 10.5, max: 12),
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _traitDropdown(bool isArabic) {
    final traits = _availableTraits();
    final selected =
        _selectedTraits.isNotEmpty && traits.contains(_selectedTraits.first)
            ? _selectedTraits.first
            : null;
    return Container(
      height: _rh(54, min: 46, max: 54),
      padding: EdgeInsets.symmetric(horizontal: _rw(14, min: 10, max: 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(_rr(10, min: 8, max: 10)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Text(
            isArabic ? 'المشاركة الصفية' : 'Class Participation',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: _rs(14, min: 12, max: 14),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: _rr(23, min: 20, max: 24), color: const Color(0xFF6B7280)),
          items: traits
              .map((trait) => DropdownMenuItem<String>(
                    value: trait,
                    child: Text(trait, style: GoogleFonts.cairo()),
                  ))
              .toList(),
          onChanged: (trait) {
            if (trait == null) return;
            setState(() => _selectedTraits = [trait]);
          },
        ),
      ),
    );
  }

  Widget _weeklyDetails(bool isArabic) {
    return Column(
      children: [
        ..._weekDays.map((day) => Padding(
              padding: EdgeInsets.only(bottom: _rh(18, min: 14, max: 18)),
              child: _periodCard(
                title: day,
                children: [
                  _textField(_weeklyPositiveCtrls[day]!,
                      isArabic ? 'ملاحظات إيجابية' : 'Positive notes'),
                  SizedBox(height: _rh(10, min: 8, max: 10)),
                  _textField(_weeklyNegativeCtrls[day]!,
                      isArabic ? 'ملاحظات سلبية' : 'Negative notes'),
                ],
              ),
            )),
        SizedBox(height: _rh(8, min: 6, max: 10)),
        Align(
          alignment: Alignment.centerRight,
          child: _sectionTitle(isArabic
              ? 'خطة العلاج والتوصيات:'
              : 'Treatment Plan & Recommendations:'),
        ),
        SizedBox(height: _rh(14, min: 10, max: 14)),
        ...List.generate(
          _recommendationCtrls.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: _rh(10, min: 8, max: 10)),
            child: _textField(
              _recommendationCtrls[index],
              isArabic ? 'توصية ${index + 1}' : 'Recommendation ${index + 1}',
              minLines: 1,
              maxLines: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _monthlyDetails(bool isArabic) {
    return Column(
      children: _monthWeeks
          .map((week) => Padding(
                padding: EdgeInsets.only(bottom: _rh(18, min: 14, max: 18)),
                child: _periodCard(
                  title: week,
                  trailing: _statusDropdown(week),
                  children: [
                    _textField(_monthlyPositiveCtrls[week]!,
                        isArabic ? 'أهم الإيجابيات' : 'Key positives'),
                    SizedBox(height: _rh(10, min: 8, max: 10)),
                    _textField(_monthlyNegativeCtrls[week]!,
                        isArabic ? 'أهم التنبيهات' : 'Key alerts'),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _periodCard({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_rr(14, min: 10, max: 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_rr(14, min: 11, max: 14)),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (trailing != null) trailing,
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: _rs(16, min: 14, max: 16),
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF172033),
                ),
              ),
            ],
          ),
          SizedBox(height: _rh(12, min: 9, max: 12)),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int minLines = 2,
    int maxLines = 3,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: GoogleFonts.cairo(
          color: const Color(0xFF9CA3AF),
          fontSize: _rs(13, min: 11.5, max: 13),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _rw(14, min: 10, max: 14),
          vertical: _rh(14, min: 10, max: 14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rr(10, min: 8, max: 10)),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rr(10, min: 8, max: 10)),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rr(10, min: 8, max: 10)),
          borderSide: const BorderSide(color: Color(0xFF5147E8), width: 1.3),
        ),
      ),
      style: GoogleFonts.cairo(
        fontSize: _rs(13, min: 11.5, max: 13),
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  Widget _statusDropdown(String week) {
    return SizedBox(
      width: _rw(112, min: 92, max: 112),
      height: _rh(34, min: 30, max: 34),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _monthlyStatuses[week],
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: _rr(22, min: 18, max: 22), color: const Color(0xFF475569)),
          items: const ['مستقر', 'تحسن', 'يحتاج متابعة']
              .map((status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status, style: GoogleFonts.cairo()),
                  ))
              .toList(),
          onChanged: (status) {
            if (status == null) return;
            setState(() => _monthlyStatuses[week] = status);
          },
        ),
      ),
    );
  }

  Widget _bottomActions() {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Container(
      padding: EdgeInsets.fromLTRB(
        _rw(20, min: 14, max: 20),
        _rh(16, min: 10, max: 16),
        _rw(20, min: 14, max: 20),
        _rh(22, min: 12, max: 22),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: Offset(0, -_rh(8, min: 5, max: 8)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _rh(58, min: 50, max: 58),
                child: ElevatedButton.icon(
                  onPressed: _previewReport,
                  icon: Icon(Icons.remove_red_eye_outlined,
                      color: Colors.white, size: _rr(24, min: 20, max: 25)),
                  label: Text(
                    isArabic ? 'معاينة التقرير النهائي' : 'Preview Report',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _buttonStyle(),
                  ),
                  style: _buttonDecoration(const Color(0xFF625DF3)),
                ),
              ),
            ),
            SizedBox(width: _rw(14, min: 10, max: 14)),
            Expanded(
              child: SizedBox(
                height: _rh(58, min: 50, max: 58),
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: _rr(18, min: 16, max: 18),
                          height: _rr(18, min: 16, max: 18),
                          child: const CircularProgressIndicator(
                              strokeWidth: 2.3, color: Colors.white),
                        )
                      : Icon(Icons.send_rounded,
                          color: Colors.white, size: _rr(24, min: 20, max: 25)),
                  label: Text(
                    isArabic ? 'إرسال التقرير الآن' : 'Send Report Now',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _buttonStyle(),
                  ),
                  style: _buttonDecoration(const Color(0xFF152238)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _buttonStyle() => GoogleFonts.cairo(
        fontSize: _rs(15, min: 12.5, max: 15),
        fontWeight: FontWeight.w900,
        color: Colors.white,
      );

  ButtonStyle _buttonDecoration(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      disabledBackgroundColor: color.withValues(alpha: 0.65),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_rr(17, min: 14, max: 17)),
      ),
    );
  }

  void _previewReport() {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final student = _students
        .where((s) => s.id == _selectedStudentId)
        .cast<_StudentInfo?>()
        .firstWhere((s) => s != null, orElse: () => null);
    final cls = _classes
        .where((c) => c.id == _selectedClassId)
        .cast<_ClassInfo?>()
        .firstWhere((c) => c != null, orElse: () => null);
    final payload = _buildSubmissionPayload();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: _rr(16, min: 12, max: 16),
            right: _rr(16, min: 12, max: 16),
            bottom: _rr(16, min: 12, max: 16),
          ),
          padding: EdgeInsets.all(_rr(22, min: 16, max: 22)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_rr(24, min: 20, max: 24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: _rw(40, min: 30, max: 40),
                  height: _rh(4, min: 3, max: 4),
                  margin: EdgeInsets.only(bottom: _rh(16, min: 12, max: 16)),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(_rr(10, min: 8, max: 10)),
                  ),
                ),
              ),
              Text(
                isArabic ? 'معاينة التقرير النهائي' : 'Report Preview',
                style: GoogleFonts.cairo(
                  fontSize: _rs(20, min: 17, max: 20),
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF5044DF),
                ),
              ),
              SizedBox(height: _rh(16, min: 12, max: 18)),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _previewRow('الطالب', student?.name ?? '-'),
                      _previewRow('الفصل', cls?.name ?? '-'),
                      _previewRow('نوع التقرير', _periodLabel(_selectedPeriod)),
                      _previewRow('البند', payload?.traits.join(', ') ?? '-'),
                      _previewRow(
                          'الوصف',
                          payload == null || payload.notes.isEmpty
                              ? '-'
                              : payload.notes),
                      SizedBox(height: _rh(14, min: 10, max: 16)),
                      SizedBox(
                        width: double.infinity,
                        height: _rh(52, min: 46, max: 52),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: _buttonDecoration(const Color(0xFF625DF3)),
                          child: Text('تم', style: _buttonStyle()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: _rh(10, min: 8, max: 10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: _rs(11, min: 10, max: 12),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF9CA3AF))),
          SizedBox(height: _rh(4, min: 3, max: 4)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: _rw(14, min: 10, max: 14),
              vertical: _rh(11, min: 8, max: 12),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(_rr(12, min: 10, max: 12)),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: _rs(13, min: 11.5, max: 13),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _availableTraits() {
    switch (_selectedType) {
      case NoteType.positive:
        return ['المشاركة الصفية', 'التعاون الرائع', 'مجتهد', 'منضبط', 'محترم'];
      case NoteType.negative:
        return [
          'الخناق مع الأصدقاء',
          'غير منضبط',
          'تأخر',
          'فوضوي',
          'يحتاج توجيه'
        ];
      case NoteType.followup:
        return ['متابعة سلوكية', 'يحتاج دعم', 'تحسن ملحوظ', 'توجيه إضافي'];
    }
  }

  String _typeLabel(NoteType type) {
    switch (type) {
      case NoteType.positive:
        return 'إيجابي';
      case NoteType.negative:
        return 'سلبي';
      case NoteType.followup:
        return 'متابعة';
    }
  }

  Color _typeColor(NoteType type) {
    switch (type) {
      case NoteType.positive:
        return AppColors.emerald;
      case NoteType.negative:
        return AppColors.rose;
      case NoteType.followup:
        return AppColors.amber;
    }
  }

  String _periodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return 'يومي';
      case ReportPeriod.weekly:
        return 'أسبوعي';
      case ReportPeriod.monthly:
        return 'شهري';
    }
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: _rh(18, min: 12, max: 18)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(_rr(12, min: 10, max: 12)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: _rs(14, min: 12, max: 14),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB));
}

class _ClassInfo {
  final String id;
  final String name;

  const _ClassInfo(this.id, this.name);
}

class _StudentInfo {
  final String id;
  final String classId;
  final String name;

  const _StudentInfo(this.id, this.classId, this.name);
}

class _BehaviorSubmission {
  final NoteType type;
  final List<String> traits;
  final String notes;

  const _BehaviorSubmission({
    required this.type,
    required this.traits,
    required this.notes,
  });
}

class _TabData {
  final String label;
  final IconData icon;
  final ReportPeriod period;

  const _TabData(this.label, this.icon, this.period);
}

enum ReportPeriod { daily, weekly, monthly }

enum NoteType { positive, negative, followup }

class _ReportBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEAF5FF), Color(0xFFF6F1FF), Color(0xFFEFF8FF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    _blob(
        canvas,
        Offset(size.width * 0.18, size.height * 0.22),
        Size(size.width * 0.58, size.height * 0.23),
        const Color(0xFFC7E6F7).withValues(alpha: 0.42));
    _blob(
        canvas,
        Offset(size.width * 0.78, size.height * 0.08),
        Size(size.width * 0.44, size.height * 0.18),
        const Color(0xFFDCD4FF).withValues(alpha: 0.40));

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.13);
    _drawCompass(
        canvas, Offset(size.width * 0.30, size.height * 0.12), 48, line);
    _drawLeaf(canvas, Offset(size.width * 0.55, size.height * 0.72), 70, line);
    _drawGear(canvas, Offset(size.width * 0.22, size.height * 0.72), 46, line);
  }

  void _blob(Canvas canvas, Offset center, Size size, Color color) {
    final path = Path()
      ..moveTo(center.dx - size.width * 0.45, center.dy)
      ..cubicTo(
          center.dx - size.width * 0.38,
          center.dy - size.height * 0.48,
          center.dx + size.width * 0.02,
          center.dy - size.height * 0.55,
          center.dx + size.width * 0.25,
          center.dy - size.height * 0.32)
      ..cubicTo(
          center.dx + size.width * 0.58,
          center.dy - size.height * 0.02,
          center.dx + size.width * 0.38,
          center.dy + size.height * 0.44,
          center.dx - size.width * 0.02,
          center.dy + size.height * 0.48)
      ..cubicTo(
          center.dx - size.width * 0.40,
          center.dy + size.height * 0.52,
          center.dx - size.width * 0.58,
          center.dy + size.height * 0.25,
          center.dx - size.width * 0.45,
          center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCompass(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.62, paint);
    final path = Path()
      ..moveTo(center.dx + radius * 0.16, center.dy - radius * 0.54)
      ..lineTo(center.dx - radius * 0.12, center.dy + radius * 0.12)
      ..lineTo(center.dx + radius * 0.50, center.dy - radius * 0.16)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawLeaf(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - size * 0.45, center.dy + size * 0.10)
      ..cubicTo(
          center.dx - size * 0.05,
          center.dy - size * 0.50,
          center.dx + size * 0.42,
          center.dy - size * 0.34,
          center.dx + size * 0.48,
          center.dy - size * 0.06)
      ..cubicTo(
          center.dx + size * 0.24,
          center.dy + size * 0.28,
          center.dx - size * 0.14,
          center.dy + size * 0.35,
          center.dx - size * 0.45,
          center.dy + size * 0.10);
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(center.dx - size * 0.42, center.dy + size * 0.10),
        Offset(center.dx + size * 0.42, center.dy - size * 0.08), paint);
  }

  void _drawGear(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius * 0.58, paint);
    canvas.drawCircle(center, radius * 0.22, paint);
    for (int i = 0; i < 8; i++) {
      final angle = i * 0.785398;
      canvas.drawLine(
        Offset(center.dx + radius * 0.68 * math.cos(angle),
            center.dy + radius * 0.68 * math.sin(angle)),
        Offset(center.dx + radius * 0.92 * math.cos(angle),
            center.dy + radius * 0.92 * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
