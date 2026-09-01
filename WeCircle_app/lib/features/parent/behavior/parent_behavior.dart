import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

class ParentBehavior extends StatefulWidget {
  const ParentBehavior({super.key});

  @override
  State<ParentBehavior> createState() => _ParentBehaviorState();
}

class _ParentBehaviorState extends State<ParentBehavior> {
  final ApiClient _apiClient = ApiClient();
  final GlobalKey _reportKey = GlobalKey();
  static const double _maxContentWidth = 430;

  bool _isLoading = true;
  bool _isSavingPdf = false;
  ReportPeriod? _selectedPeriod;
  List<_BehaviorReport> _reports = [];
  _ChildInfo? _selectedChild;
  StreamSubscription? _socketSubscription;
  String _schoolName = 'أكاديمية WeCircle التعليمية';
  String _today = '';

  @override
  void initState() {
    super.initState();
    _fetchBehaviorReports();
    _setupWebSocketListener();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _setupWebSocketListener() {
    _socketSubscription = SocketService().onEvent.listen((eventData) async {
      final event = eventData['event'] ?? '';
      final data = eventData['data'];
      if (event == 'behavior:created' || event == 'notification:new') {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');
        final recipientId = data is Map ? data['recipientId'] : null;
        if (recipientId == null || recipientId == userId) {
          _fetchBehaviorReports();
        }
      }
    });
  }

  Future<void> _fetchBehaviorReports() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      _schoolName = prefs.getString('school_name') ?? _schoolName;

      final results = await Future.wait([
        _apiClient.client.get('/parents/mobile/dashboard'),
        _apiClient.client.get('/behavior/parent'),
      ]);

      final dashboard = results[0];
      if (dashboard.data['success'] == true) {
        final data = dashboard.data['data'] as Map;
        _today = data['todayFormatted'] ?? _formatFullDate(DateTime.now());
        final children = (data['children'] as List? ?? [])
            .map((child) => _ChildInfo.fromJson(child as Map))
            .toList();
        _selectedChild ??= children.isNotEmpty ? children.first : null;
      }

      final behavior = results[1];
      if (behavior.data['success'] == true) {
        _reports = (behavior.data['data'] as List)
            .map((report) => _BehaviorReport.fromJson(report as Map))
            .toList();
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching behavior reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final pageWidth =
        math.min(MediaQuery.sizeOf(context).width, _maxContentWidth);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5147E8)),
            )
          : Stack(
              children: [
                Positioned.fill(
                    child: CustomPaint(painter: _ParentBgPainter())),
                SafeArea(
                  bottom: false,
                  child: RefreshIndicator(
                    onRefresh: _fetchBehaviorReports,
                    color: const Color(0xFF5147E8),
                    child: Center(
                      child: SizedBox(
                        width: pageWidth,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            _rw(20, min: 16, max: 22),
                            _rh(10, min: 8, max: 12),
                            _rw(20, min: 16, max: 22),
                            _selectedPeriod == null
                                ? _rh(34, min: 24, max: 38)
                                : _rh(112, min: 98, max: 122),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(isArabic),
                              SizedBox(height: _rh(14, min: 10, max: 16)),
                              _buildIntro(isArabic),
                              SizedBox(height: _rh(20, min: 14, max: 22)),
                              _buildTabs(isArabic),
                              SizedBox(height: _rh(30, min: 22, max: 32)),
                              if (_selectedPeriod == null)
                                _buildWaitingCard(isArabic)
                              else
                                RepaintBoundary(
                                  key: _reportKey,
                                  child: _buildOfficialReport(isArabic),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_selectedPeriod != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        width: pageWidth,
                        child: _buildPdfButton(isArabic),
                      ),
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
    return Row(
      children: [
        _backButton(isArabic),
        SizedBox(width: _rw(12, min: 9, max: 14)),
        Expanded(
          child: Text(
            isArabic ? 'تقارير السلوك' : 'Behavior Reports',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: _rs(25, min: 21, max: 26),
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF172033),
            ),
          ),
        ),
      ],
    );
  }

  Widget _backButton(bool isArabic) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: _rr(46, min: 40, max: 46),
        height: _rr(46, min: 40, max: 46),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.07),
              blurRadius: 18,
              offset: Offset(0, _rh(8, min: 5, max: 8)),
            ),
          ],
        ),
        child: Icon(
          isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          color: const Color(0xFF172033),
          size: _rr(25, min: 22, max: 26),
        ),
      ),
    );
  }

  Widget _buildIntro(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          isArabic ? 'تتبع سلوك طفلك وانضباطه' : 'Track your child behavior',
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            fontSize: _rs(14, min: 12, max: 14),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        SizedBox(height: _rh(16, min: 10, max: 16)),
        Text(
          isArabic ? 'اختر نوع التقرير' : 'Choose report type',
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            fontSize: _rs(13, min: 11, max: 13),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF172033),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isArabic) {
    final tabs = [
      _PeriodTab(isArabic ? 'يومي' : 'Daily', Icons.calendar_today_rounded,
          ReportPeriod.daily),
      _PeriodTab(isArabic ? 'أسبوعي' : 'Weekly', Icons.calendar_month_rounded,
          ReportPeriod.weekly),
      _PeriodTab(isArabic ? 'شهري' : 'Monthly', Icons.insert_chart_rounded,
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
                height: _rh(58, min: 50, max: 62),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF5147E8) : Colors.white,
                  borderRadius:
                      BorderRadius.circular(_rr(18, min: 15, max: 18)),
                  boxShadow: [
                    BoxShadow(
                      color: (selected ? const Color(0xFF5147E8) : Colors.black)
                          .withValues(alpha: selected ? 0.20 : 0.05),
                      blurRadius: selected ? 18 : 12,
                      offset: Offset(0, _rh(8, min: 5, max: 8)),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab.label,
                      style: GoogleFonts.cairo(
                        fontSize: _rs(12.5, min: 11, max: 13),
                        fontWeight: FontWeight.w800,
                        color:
                            selected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(width: _rw(7, min: 5, max: 7)),
                    Icon(
                      tab.icon,
                      size: _rr(18, min: 16, max: 18),
                      color: selected ? Colors.white : const Color(0xFF64748B),
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

  Widget _buildWaitingCard(bool isArabic) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _rw(28, min: 22, max: 34),
        vertical: _rh(48, min: 38, max: 56),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_rr(26, min: 22, max: 28)),
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
          Container(
            width: _rr(84, min: 72, max: 88),
            height: _rr(84, min: 72, max: 88),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(_rr(20, min: 17, max: 22)),
            ),
            child: Icon(Icons.bar_chart_rounded,
                color: const Color(0xFF625DF3),
                size: _rr(42, min: 36, max: 44)),
          ),
          SizedBox(height: _rh(26, min: 18, max: 28)),
          Text(
            isArabic ? 'بانتظار اختيارك' : 'Waiting for your choice',
            style: GoogleFonts.cairo(
              fontSize: _rs(22, min: 18, max: 22),
              fontWeight: FontWeight.w900,
              color: const Color(0xFF172033),
            ),
          ),
          SizedBox(height: _rh(14, min: 10, max: 14)),
          Text(
            isArabic
                ? 'يرجى اختيار نوع التقرير من الأعلى لعرض تفاصيل سلوك الطالب'
                : 'Choose a report type above to view behavior details',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: _rs(14, min: 12, max: 14),
              height: 1.7,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialReport(bool isArabic) {
    final reports = _filteredReports();
    final student = _selectedChild ?? _childFromReports(reports);
    final positiveCount = reports.where((r) => r.type == 'POSITIVE').length;
    final negativeCount = reports.where((r) => r.type == 'NEGATIVE').length;
    final total = math.max(1, positiveCount + negativeCount);
    final positivePct = ((positiveCount / total) * 100).round();
    final negativePct = ((negativeCount / total) * 100).round();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_rr(20, min: 17, max: 22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: Offset(0, _rh(10, min: 7, max: 10)),
          ),
        ],
      ),
      child: Column(
        children: [
          _reportSchoolHeader(isArabic),
          _divider(),
          _reportIdentity(isArabic, student, reports),
          _divider(),
          _reportLog(isArabic, reports),
          _divider(),
          _reportStats(isArabic, positivePct, negativePct),
          _divider(),
          _reportFooter(isArabic),
        ],
      ),
    );
  }

  Widget _reportSchoolHeader(bool isArabic) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _rw(18, min: 14, max: 18),
        _rh(18, min: 14, max: 18),
        _rw(18, min: 14, max: 18),
        _rh(16, min: 12, max: 16),
      ),
      child: Row(
        children: [
          Container(
            width: _rr(48, min: 42, max: 50),
            height: _rr(48, min: 42, max: 50),
            decoration: const BoxDecoration(
              color: Color(0xFF172033),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_rounded,
                color: Colors.white, size: _rr(25, min: 22, max: 25)),
          ),
          SizedBox(width: _rw(12, min: 9, max: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _schoolName,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: _rs(16, min: 14, max: 16),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF172033),
                  ),
                ),
                Text(
                  isArabic
                      ? 'قسم شؤون الطلاب والانضباط'
                      : 'Student Affairs & Conduct',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: _rs(11, min: 10, max: 11),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportIdentity(
      bool isArabic, _ChildInfo? student, List<_BehaviorReport> reports) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _rw(22, min: 16, max: 22),
        _rh(22, min: 16, max: 22),
        _rw(22, min: 16, max: 22),
        _rh(20, min: 16, max: 20),
      ),
      child: Column(
        children: [
          Text(
            _officialTitle(isArabic),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: _rs(17, min: 15, max: 17),
              fontWeight: FontWeight.w900,
              color: const Color(0xFF172033),
              decoration: TextDecoration.underline,
              decorationThickness: 1.2,
            ),
          ),
          SizedBox(height: _rh(22, min: 16, max: 22)),
          _infoRow(
              isArabic ? 'اسم الطالب:' : 'Student:',
              student?.name ??
                  (reports.isNotEmpty ? reports.first.studentName : '-')),
          _infoRow(isArabic ? 'التاريخ:' : 'Date:', _today),
          _infoRow(
            isArabic ? 'الرقم الأكاديمي:' : 'Academic ID:',
            student?.code ??
                (reports.isNotEmpty
                    ? (reports.first.studentCode ??
                        reports.first.studentIdShort)
                    : '-'),
          ),
        ],
      ),
    );
  }

  Widget _reportLog(bool isArabic, List<_BehaviorReport> reports) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _rw(18, min: 14, max: 18),
        _rh(18, min: 14, max: 18),
        _rw(18, min: 14, max: 18),
        _rh(18, min: 14, max: 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            isArabic ? 'السجل التفصيلي المعتمد:' : 'Approved Detailed Log:',
            style: GoogleFonts.cairo(
              fontSize: _rs(13, min: 12, max: 13),
              fontWeight: FontWeight.w900,
              color: const Color(0xFF172033),
            ),
          ),
          SizedBox(height: _rh(14, min: 10, max: 14)),
          if (reports.isEmpty)
            _emptyReport(isArabic)
          else
            ...reports.map((report) => _buildLogItem(report)),
        ],
      ),
    );
  }

  Widget _buildLogItem(_BehaviorReport report) {
    final positive = report.type == 'POSITIVE';
    final negative = report.type == 'NEGATIVE';
    final color = positive
        ? AppColors.emerald
        : negative
            ? AppColors.rose
            : AppColors.amber;
    final label = positive
        ? 'إيجابي'
        : negative
            ? 'سلبي'
            : report.period == ReportPeriod.weekly
                ? 'أسبوعي'
                : report.period == ReportPeriod.monthly
                    ? 'شهري'
                    : 'متابعة';

    return Container(
      margin: EdgeInsets.only(bottom: _rh(12, min: 9, max: 12)),
      padding: EdgeInsets.all(_rr(14, min: 11, max: 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_rr(12, min: 10, max: 12)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _rw(10, min: 8, max: 10),
                  vertical: _rh(4, min: 3, max: 4),
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(_rr(7, min: 6, max: 7)),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: _rs(10, min: 9, max: 10),
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Expanded(
                flex: 4,
                child: Text(
                  report.title,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: _rs(14, min: 12.5, max: 14),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF172033),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _rh(10, min: 7, max: 10)),
          Text(
            report.description,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: _rs(12, min: 10.5, max: 12),
              height: 1.65,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: _rh(10, min: 7, max: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(report.time,
                  style: _metaStyle(), textDirection: TextDirection.rtl),
              SizedBox(width: _rw(5, min: 4, max: 5)),
              Icon(Icons.access_time_rounded,
                  size: _rr(12, min: 10, max: 12),
                  color: const Color(0xFF94A3B8)),
              SizedBox(width: _rw(14, min: 10, max: 14)),
              Flexible(
                child: Text(report.teacherName,
                    overflow: TextOverflow.ellipsis, style: _metaStyle()),
              ),
              SizedBox(width: _rw(5, min: 4, max: 5)),
              Icon(Icons.person_outline_rounded,
                  size: _rr(12, min: 10, max: 12),
                  color: const Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _metaStyle() => GoogleFonts.cairo(
        fontSize: _rs(10, min: 9, max: 10),
        fontWeight: FontWeight.w600,
        color: const Color(0xFF94A3B8),
      );

  Widget _reportStats(bool isArabic, int positivePct, int negativePct) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _rw(20, min: 15, max: 20),
        vertical: _rh(18, min: 14, max: 18),
      ),
      child: Column(
        children: [
          _percentRow(isArabic ? 'نسبة السلوك الإيجابي:' : 'Positive behavior:',
              '$positivePct%', AppColors.emerald),
          SizedBox(height: _rh(10, min: 7, max: 10)),
          _percentRow(isArabic ? 'نسبة الملاحظات السلبية:' : 'Negative notes:',
              '$negativePct%', AppColors.rose),
        ],
      ),
    );
  }

  Widget _reportFooter(bool isArabic) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _rw(20, min: 15, max: 20),
        _rh(16, min: 12, max: 16),
        _rw(20, min: 15, max: 20),
        _rh(20, min: 15, max: 20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _signatureLine('ختم المدرسة')),
              SizedBox(width: _rw(28, min: 18, max: 28)),
              Expanded(child: _signatureLine('توقيع مدير المدرسة')),
            ],
          ),
          SizedBox(height: _rh(14, min: 10, max: 14)),
          Text(
            isArabic
                ? 'صدر هذا التقرير من النظام ويتم اعتماده من إدارة المدرسة.'
                : 'This report was generated by the school system.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: _rs(9.5, min: 8.5, max: 10),
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: _rh(8, min: 6, max: 8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: _rs(13.5, min: 12, max: 13.5),
                fontWeight: FontWeight.w900,
                color: const Color(0xFF172033),
              ),
            ),
          ),
          SizedBox(width: _rw(6, min: 4, max: 6)),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: _rs(13, min: 11.5, max: 13),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF172033),
            ),
          ),
        ],
      ),
    );
  }

  Widget _percentRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: _rw(58, min: 48, max: 58),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: _rh(5, min: 4, max: 5)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(_rr(8, min: 7, max: 8)),
          ),
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: _rs(13, min: 11, max: 13),
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        const Spacer(),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: _rs(13, min: 11.5, max: 13),
            fontWeight: FontWeight.w900,
            color: const Color(0xFF172033),
          ),
        ),
      ],
    );
  }

  Widget _signatureLine(String label) {
    return Column(
      children: [
        const Divider(color: Color(0xFFCBD5E1), thickness: 1),
        SizedBox(height: _rh(4, min: 3, max: 4)),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: _rs(8.5, min: 7.5, max: 9),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _emptyReport(bool isArabic) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: _rh(28, min: 20, max: 30)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(_rr(12, min: 10, max: 12)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        isArabic ? 'لا توجد تقارير لهذا النوع بعد' : 'No reports yet',
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: _rs(13, min: 11.5, max: 13),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildPdfButton(bool isArabic) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _rw(22, min: 16, max: 22),
        _rh(14, min: 10, max: 14),
        _rw(22, min: 16, max: 22),
        _rh(20, min: 12, max: 20),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
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
        child: SizedBox(
          width: double.infinity,
          height: _rh(58, min: 50, max: 58),
          child: ElevatedButton.icon(
            onPressed: _isSavingPdf ? null : _saveReportPdf,
            icon: _isSavingPdf
                ? SizedBox(
                    width: _rr(18, min: 16, max: 18),
                    height: _rr(18, min: 16, max: 18),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: _rr(22, min: 19, max: 22)),
            label: Text(
              isArabic ? 'تحميل التقرير كـ PDF' : 'Download report as PDF',
              style: GoogleFonts.cairo(
                fontSize: _rs(15, min: 13, max: 15),
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF152238),
              disabledBackgroundColor:
                  const Color(0xFF152238).withValues(alpha: 0.65),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_rr(14, min: 12, max: 14)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveReportPdf() async {
    if (_selectedPeriod == null) return;
    setState(() => _isSavingPdf = true);
    try {
      final boundary = _reportKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Report is not ready');
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception('Could not render report');
      final pdfBytes = _buildImagePdf(
        rgba: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'behavior_${_periodFileName(_selectedPeriod!)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ التقرير: ${file.path}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحميل التقرير كـ PDF'),
          backgroundColor: AppColors.rose,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingPdf = false);
    }
  }

  Uint8List _buildImagePdf({
    required Uint8List rgba,
    required int width,
    required int height,
  }) {
    final rgb = Uint8List(width * height * 3);
    var j = 0;
    for (var i = 0; i < rgba.length; i += 4) {
      rgb[j++] = rgba[i];
      rgb[j++] = rgba[i + 1];
      rgb[j++] = rgba[i + 2];
    }
    final compressed = zlib.encode(rgb);
    const pageWidth = 595.0;
    const pageHeight = 842.0;
    const margin = 24.0;
    final scale = math.min(
        (pageWidth - margin * 2) / width, (pageHeight - margin * 2) / height);
    final drawW = width * scale;
    final drawH = height * scale;
    final x = (pageWidth - drawW) / 2;
    final y = pageHeight - margin - drawH;

    final objects = <List<int>>[
      utf8.encode('<< /Type /Catalog /Pages 2 0 R >>'),
      utf8.encode('<< /Type /Pages /Kids [3 0 R] /Count 1 >>'),
      utf8.encode(
          '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageWidth $pageHeight] /Resources << /XObject << /Im0 5 0 R >> >> /Contents 4 0 R >>'),
      _streamObject(utf8.encode('q $drawW 0 0 $drawH $x $y cm /Im0 Do Q')),
      _streamObject(compressed,
          dict:
              '/Type /XObject /Subtype /Image /Width $width /Height $height /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode'),
    ];

    final out = BytesBuilder();
    out.add(utf8.encode('%PDF-1.4\n'));
    final offsets = <int>[0];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(out.length);
      out.add(utf8.encode('${i + 1} 0 obj\n'));
      out.add(objects[i]);
      out.add(utf8.encode('\nendobj\n'));
    }
    final xref = out.length;
    out.add(
        utf8.encode('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n'));
    for (var i = 1; i < offsets.length; i++) {
      out.add(
          utf8.encode('${offsets[i].toString().padLeft(10, '0')} 00000 n \n'));
    }
    out.add(utf8.encode(
        'trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF'));
    return out.toBytes();
  }

  List<int> _streamObject(List<int> data, {String dict = ''}) => [
        ...utf8.encode('<< $dict /Length ${data.length} >>\nstream\n'),
        ...data,
        ...utf8.encode('\nendstream'),
      ];

  List<_BehaviorReport> _filteredReports() {
    if (_selectedPeriod == null) return [];
    final byPeriod =
        _reports.where((report) => report.period == _selectedPeriod).toList();
    final child = _selectedChild;
    if (child == null) return byPeriod;
    final childReports =
        byPeriod.where((report) => report.studentId == child.id).toList();
    return childReports.isEmpty ? byPeriod : childReports;
  }

  _ChildInfo? _childFromReports(List<_BehaviorReport> reports) {
    if (reports.isEmpty) return null;
    final first = reports.first;
    return _ChildInfo(
      id: first.studentId,
      name: first.studentName,
      code: first.studentCode ?? first.studentIdShort,
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB));

  String _officialTitle(bool isArabic) {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return isArabic
            ? 'تقرير السلوك اليومي الرسمي'
            : 'Official Daily Behavior Report';
      case ReportPeriod.weekly:
        return isArabic
            ? 'تقرير السلوك الأسبوعي الرسمي'
            : 'Official Weekly Behavior Report';
      case ReportPeriod.monthly:
        return isArabic
            ? 'تقرير السلوك الشهري الرسمي'
            : 'Official Monthly Behavior Report';
      case null:
        return '';
    }
  }

  String _periodFileName(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return 'daily';
      case ReportPeriod.weekly:
        return 'weekly';
      case ReportPeriod.monthly:
        return 'monthly';
    }
  }

  String _formatFullDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

enum ReportPeriod { daily, weekly, monthly }

class _PeriodTab {
  final String label;
  final IconData icon;
  final ReportPeriod period;

  const _PeriodTab(this.label, this.icon, this.period);
}

class _ChildInfo {
  final String id;
  final String name;
  final String code;

  const _ChildInfo({
    required this.id,
    required this.name,
    required this.code,
  });

  factory _ChildInfo.fromJson(Map json) {
    final id = (json['id'] ?? '').toString();
    return _ChildInfo(
      id: id,
      name: (json['nameAr'] ?? json['nameEn'] ?? 'الطالب').toString(),
      code: (json['studentCode'] ??
              json['rollNumber'] ??
              (id.length >= 8 ? id.substring(0, 8) : id))
          .toString(),
    );
  }
}

class _BehaviorReport {
  final String type;
  final String title;
  final String description;
  final String teacherName;
  final String time;
  final String studentId;
  final String studentName;
  final String? studentCode;
  final ReportPeriod period;

  const _BehaviorReport({
    required this.type,
    required this.title,
    required this.description,
    required this.teacherName,
    required this.time,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.period,
  });

  factory _BehaviorReport.fromJson(Map json) {
    final traits = _parseTraits(json['traits']);
    final notes = (json['notes'] ?? '').toString();
    final period = _detectPeriod(traits, notes);
    final type = (json['type'] ?? 'FOLLOWUP').toString();
    final student = json['student'] as Map?;
    final teacher = json['teacher'] as Map?;
    final teacherUser = teacher?['user'] as Map?;
    final created = DateTime.tryParse((json['createdAt'] ?? '').toString());

    return _BehaviorReport(
      type: type,
      title: _titleFrom(type, traits, period),
      description: _descriptionFrom(notes, traits),
      teacherName: (teacherUser?['fullName'] ??
              teacher?['nameAr'] ??
              teacher?['nameEn'] ??
              'المعلم')
          .toString(),
      time: created == null
          ? '-'
          : '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}',
      studentId: (json['studentId'] ?? student?['id'] ?? '').toString(),
      studentName:
          (student?['nameAr'] ?? student?['nameEn'] ?? 'الطالب').toString(),
      studentCode:
          (student?['studentCode'] ?? student?['rollNumber'])?.toString(),
      period: period,
    );
  }

  String get studentIdShort =>
      studentId.length >= 8 ? studentId.substring(0, 8) : studentId;

  static List<String> _parseTraits(dynamic raw) {
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return raw
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static ReportPeriod _detectPeriod(List<String> traits, String notes) {
    final joined = '${traits.join(' ')} $notes';
    if (joined.contains('تقرير شهري')) return ReportPeriod.monthly;
    if (joined.contains('تقرير أسبوعي')) return ReportPeriod.weekly;
    return ReportPeriod.daily;
  }

  static String _titleFrom(
      String type, List<String> traits, ReportPeriod period) {
    if (period == ReportPeriod.weekly) return 'ملخص التقرير الأسبوعي';
    if (period == ReportPeriod.monthly) return 'ملخص التقرير الشهري';
    if (traits.isNotEmpty) return traits.first;
    if (type == 'POSITIVE') return 'سلوك إيجابي';
    if (type == 'NEGATIVE') return 'ملاحظة سلبية';
    return 'متابعة سلوكية';
  }

  static String _descriptionFrom(String notes, List<String> traits) {
    if (notes.trim().isNotEmpty) return notes.trim();
    if (traits.length > 1) return traits.skip(1).join('، ');
    return 'تم اعتماد هذه الملاحظة من المعلم.';
  }
}

class _ParentBgPainter extends CustomPainter {
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
        Offset(size.width * 0.15, size.height * 0.23),
        Size(size.width * 0.60, size.height * 0.23),
        const Color(0xFFC7E6F7).withValues(alpha: 0.40));
    _blob(
        canvas,
        Offset(size.width * 0.80, size.height * 0.08),
        Size(size.width * 0.42, size.height * 0.18),
        const Color(0xFFDCD4FF).withValues(alpha: 0.38));
    _blob(
        canvas,
        Offset(size.width * 0.77, size.height * 0.75),
        Size(size.width * 0.62, size.height * 0.24),
        const Color(0xFFDCEEFF).withValues(alpha: 0.44));

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.13);

    _drawCompass(
        canvas, Offset(size.width * 0.28, size.height * 0.10), 48, line);
    _drawLeaf(canvas, Offset(size.width * 0.52, size.height * 0.70), 72, line);
    _drawGear(canvas, Offset(size.width * 0.25, size.height * 0.73), 46, line);
    _drawBook(canvas, Offset(size.width * 0.03, size.height * 0.82), 64, line);
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

  void _drawBook(Canvas canvas, Offset offset, double size, Paint paint) {
    final rect = Rect.fromLTWH(offset.dx, offset.dy, size * 0.74, size * 0.86);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size * 0.08)), paint);
    canvas.drawLine(Offset(offset.dx + size * 0.18, offset.dy),
        Offset(offset.dx + size * 0.18, offset.dy + size * 0.86), paint);
    canvas.drawLine(Offset(offset.dx + size * 0.28, offset.dy + size * 0.22),
        Offset(offset.dx + size * 0.60, offset.dy + size * 0.22), paint);
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
