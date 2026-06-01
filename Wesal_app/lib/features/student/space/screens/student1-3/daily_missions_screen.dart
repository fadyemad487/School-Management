import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import '../../widgets/student1-3/animated_space_background.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

enum MissionStatus { locked, active, completed, approved }

class _MissionTask {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  MissionStatus status;

  _MissionTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.status = MissionStatus.active,
  });

  bool get isCompleted => status == MissionStatus.completed || status == MissionStatus.approved;
  bool get isApproved  => status == MissionStatus.approved;
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _HexagonPainter extends CustomPainter {
  final Color color;
  _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawShadow(path, color, 8, true);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HexagonPainter old) => false;
}

class _ConnectorLinePainter extends CustomPainter {
  final Color color;
  _ConnectorLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final p1 = Offset(size.width / 2, 0);
    final p2 = Offset(size.width / 2, size.height);
    canvas.drawLine(p1, p2, glowPaint);
    canvas.drawLine(p1, p2, paint);

  }

  @override
  bool shouldRepaint(_ConnectorLinePainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class DailyMissionsScreen extends StatefulWidget {
  final int initialTab;
  final Function(int) onTabChanged;

  const DailyMissionsScreen({
    super.key,
    this.initialTab = 1,
    required this.onTabChanged,
  });

  @override
  State<DailyMissionsScreen> createState() => _DailyMissionsScreenState();
}

class _DailyMissionsScreenState extends State<DailyMissionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _lottieCtrl;
  bool _showCelebration = false;

  static const Color _cyan    = Color(0xFF00F2FF);
  static const Color _purple  = Color(0xFFBC00FF);
  static const Color _lime    = Color(0xFF39FF14);
  static const Color _gold    = Color(0xFFFFD700);

  final List<_MissionTask> _tasks = [
    _MissionTask(
      id: '1', icon: Icons.menu_book_rounded, color: const Color(0xFF00F2FF),
      title: 'نشاط القراءة',
      subtitle: 'اقرأ قصة كاملة ثم احكِ ما فهمته',
      status: MissionStatus.completed,
    ),
    _MissionTask(
      id: '2', icon: Icons.calculate_rounded, color: const Color(0xFFBC00FF),
      title: 'نشاط الرياضيات',
      subtitle: 'حل 10 مسائل جمع وطرح',
    ),
    _MissionTask(
      id: '3', icon: Icons.science_rounded, color: const Color(0xFF39FF14),
      title: 'نشاط العلوم',
      subtitle: 'استكشف أجزاء المجموعة الشمسية',
      status: MissionStatus.approved,
    ),
    _MissionTask(
      id: '4', icon: Icons.psychology_rounded, color: const Color(0xFFFFD700),
      title: 'نشاط الذاكرة',
      subtitle: 'احفظ 5 كلمات جديدة في دقيقتين',
    ),
    _MissionTask(
      id: '5', icon: Icons.self_improvement_rounded, color: const Color(0xFFFF00C8),
      title: 'نشاط التركيز',
      subtitle: 'تأمل وتنفس بعمق لمدة دقيقتين',
      status: MissionStatus.active,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _lottieCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _lottieCtrl.dispose();
    super.dispose();
  }

  int get _completedCount => _tasks.where((t) => t.isCompleted).length;
  double get _progress    => _tasks.isEmpty ? 0 : _completedCount / _tasks.length;
  bool get _allApproved => _tasks.every((t) => t.isApproved);

  void _triggerCelebration() async {
    if (_showCelebration) return;
    HapticFeedback.heavyImpact();
    _lottieCtrl.reset();
    setState(() => _showCelebration = true);
    await Future.delayed(const Duration(milliseconds: 3800));
    if (mounted) setState(() => _showCelebration = false);
  }

  void _toggleTask(_MissionTask task) {
    if (task.status == MissionStatus.locked || task.isApproved) return;
    HapticFeedback.lightImpact();

    setState(() {
      task.status = MissionStatus.completed;
    });
  }

  void _sendForReview(_MissionTask task) {
    if (!task.isCompleted || task.isApproved) return;
    HapticFeedback.mediumImpact();
    setState(() => task.status = MissionStatus.approved);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تم إرسال "${task.title}" للمراجعة 🛰️',
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
      backgroundColor: _cyan,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ));
    if (_allApproved) _triggerCelebration();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF15264F),
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedSpaceBackground()),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 120.h),
                      child: Column(
                        children: [
                          _buildTopRow(),
                          SizedBox(height: 20.h),
                          _buildMissionMap(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🏆 Celebration Overlay
            if (_showCelebration)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animations/celebration.json',
                        controller: _lottieCtrl,
                        width: 280.r,
                        repeat: false,
                        onLoaded: (comp) {
                          _lottieCtrl.duration = comp.duration;
                          _lottieCtrl.forward();
                        },
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '🎉 أنجزت كل المهام!',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          shadows: [Shadow(color: _gold.withValues(alpha: 0.7), blurRadius: 16)],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'أنت بطل المجرة هذا اليوم!',
                        style: TextStyle(color: Colors.white70, fontSize: 15.sp, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Row(
        children: [
          // Gem counter
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(colors: [_purple.withValues(alpha: 0.4), _cyan.withValues(alpha: 0.3)]),
              border: Border.all(color: _cyan.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.diamond_rounded, color: _cyan, size: 18.sp),
                SizedBox(width: 6.w),
                Text('250', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15.sp, fontFamily: 'Cairo')),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const Spacer(),
          Text(
            'المهام اليومية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              shadows: [Shadow(color: const Color(0xFF0F172A).withValues(alpha: 0.35), blurRadius: 12)],
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  // ── Top Row: progress circle only ───────────────────────────────────────────

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProgressCircle().animate().scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.elasticOut),
      ],
    );
  }

  Widget _buildProgressCircle() {
    return SizedBox(
      width: 95.r,
      height: 95.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => Container(
              width: 95.r,
              height: 95.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _cyan.withValues(alpha: 0.15 + 0.1 * _pulseCtrl.value), blurRadius: 20, spreadRadius: 2),
                ],
              ),
            ),
          ),
          CircularProgressIndicator(
            value: _progress,
            strokeWidth: 7,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(_cyan),
            strokeCap: StrokeCap.round,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_completedCount/${_tasks.length}',
                style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
              ),
              Text('مهام مكتملة', style: TextStyle(color: Colors.white54, fontSize: 9.sp, fontFamily: 'Cairo')),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mission Map ──────────────────────────────────────────────────────────────

  Widget _buildMissionMap() {
    // Layout: alternating left / right node positions, connected with lines and hex nodes
    // Index 0 (Reading)   → top-right  (card)
    // Index 1 (Math)      → left  (circle large)
    // Index 2 (Science)   → right (card)
    // Index 3 (Memory)    → left (circle)
    // Index 4 (Focus)     → right (card)

    final widgets = <Widget>[];

    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      final isRight = i % 2 != 0; // even = left, odd = right (alternating)
      final delay = Duration(milliseconds: 150 * i);

      widgets.add(
        _buildMissionNode(task, isRight: isRight, delay: delay),
      );

      // Connector between nodes (except after the last)
      if (i < _tasks.length - 1) {
        final nextTask = _tasks[i + 1];
        widgets.add(_buildConnector(_tasks[i].color, nextTask.color));
      }
    }

    return Column(children: widgets);
  }

  Widget _buildMissionNode(_MissionTask task, {required bool isRight, required Duration delay}) {
    final bool isCircleStyle = task.id == '2' || task.id == '4'; // math & memory = big circle

    Widget node = isCircleStyle
        ? _buildCircleNode(task)
        : _buildCardNode(task);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Align(
        alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
        child: node,
      ),
    ).animate().slideX(begin: isRight ? 0.3 : -0.3, duration: 450.ms, delay: delay, curve: Curves.easeOutQuart)
     .fadeIn(duration: 350.ms, delay: delay);
  }

  // Card-style node (for Reading, Science, Focus)
  Widget _buildCardNode(_MissionTask task) {
    return GestureDetector(
      onTap: () => _toggleTask(task),
      child: Container(
        width: 210.w,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: const Color(0xFF10284F).withValues(alpha: 0.76),
          border: Border.all(color: task.color.withValues(alpha: task.isCompleted ? 0.9 : 0.4), width: 2),
          boxShadow: [
            BoxShadow(color: task.color.withValues(alpha: task.isCompleted ? 0.35 : 0.1), blurRadius: 18, spreadRadius: 1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                // Title + subtitle (takes remaining space, right-aligned)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        task.title,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white, fontSize: 15.sp,
                          fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                          shadows: [Shadow(color: task.color.withValues(alpha: 0.5), blurRadius: 8)],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        task.subtitle,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: task.color.withValues(alpha: 0.75),
                          fontSize: 10.sp, fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                // Big icon box
                Container(
                  width: 50.r,
                  height: 50.r,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: LinearGradient(
                      colors: [task.color.withValues(alpha: 0.25), task.color.withValues(alpha: 0.1)],
                    ),
                    border: Border.all(color: task.color.withValues(alpha: 0.5)),
                    boxShadow: [BoxShadow(color: task.color.withValues(alpha: 0.3), blurRadius: 10)],
                  ),
                  child: Icon(task.icon, color: task.color, size: 26.sp),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _buildStatusChips(task),
          ],
        ),
      ),
    );
  }

  // Circle-style node (for Math, Memory)
  Widget _buildCircleNode(_MissionTask task) {
    return GestureDetector(
      onTap: () => _toggleTask(task),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, child) => Container(
          width: 148.r,
          height: 148.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [task.color.withValues(alpha: 0.3), task.color.withValues(alpha: 0.05)],
            ),
            border: Border.all(color: task.color.withValues(alpha: task.isCompleted ? 0.9 : 0.5), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: task.color.withValues(alpha: task.isCompleted ? (0.3 + 0.15 * _pulseCtrl.value) : 0.1),
                blurRadius: 20, spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(child: child),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(task.icon, color: task.color, size: 30.sp),
              SizedBox(height: 3.h),
              Text(
                task.title,
                style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                task.subtitle,
                style: TextStyle(color: task.color.withValues(alpha: 0.7), fontSize: 8.sp, fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              _buildCompactStatus(task),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChips(_MissionTask task) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 4.h,
      alignment: WrapAlignment.end,
      children: [
        if (task.status == MissionStatus.approved)
          _StatusChip(label: 'معتمد ✓', color: _lime)
        else if (task.status == MissionStatus.completed) ...[
          _StatusChip(label: 'قيد المراجعة', color: _gold),
          GestureDetector(
            onTap: () => _sendForReview(task),
            child: _StatusChip(label: 'إرسال للمراجعة', color: task.color, isButton: true),
          ),
        ] else if (task.status == MissionStatus.locked)
          _StatusChip(label: 'مقفلة 🔒', color: Colors.white38)
        else
          _StatusChip(label: 'لم يبدأ بعد', color: Colors.white38),
      ],
    );
  }

  Widget _buildCompactStatus(_MissionTask task) {
    if (task.isApproved)    return _StatusChip(label: 'معتمد ✓', color: _lime);
    if (task.isCompleted)   return GestureDetector(onTap: () => _sendForReview(task), child: _StatusChip(label: 'إرسال', color: task.color, isButton: true));
    if (task.status == MissionStatus.locked) return _StatusChip(label: 'مقفلة', color: Colors.white38);
    return _StatusChip(label: 'لم يبدأ', color: Colors.white38);
  }

  // Connector: vertical line + hexagon
  Widget _buildConnector(Color colorA, Color colorB) {
    return SizedBox(
      height: 70.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Expanded(
                child: SizedBox(
                  width: 4.w,
                  child: CustomPaint(
                    painter: _ConnectorLinePainter(color: colorA),
                  ),
                ),
              ),
              SizedBox(
                width: 30.r,
                height: 30.r,
                child: CustomPaint(
                  painter: _HexagonPainter(color: colorB),
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: 4.w,
                  child: CustomPaint(
                    painter: _ConnectorLinePainter(color: colorB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────


}

// ─────────────────────────────────────────────────────────────────────────────
// Status Chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isButton;

  const _StatusChip({required this.label, required this.color, this.isButton = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: color.withValues(alpha: isButton ? 0.15 : 0.08),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: isButton ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6)] : null,
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
      ),
    );
  }
}
