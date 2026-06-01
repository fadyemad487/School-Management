import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum RadarGameState { idle, missionBrief, active, success, failure }

class RadarTarget {
  final int id;
  final String type;
  final Color color;
  final IconData icon;
  Offset position;
  Offset direction;
  final double speed;

  RadarTarget({
    required this.id,
    required this.type,
    required this.color,
    required this.icon,
    required this.position,
    required this.direction,
    required this.speed,
  });
}

class CaptainRadarScreen extends StatefulWidget {
  const CaptainRadarScreen({super.key});

  @override
  State<CaptainRadarScreen> createState() => _CaptainRadarScreenState();
}

class _CaptainRadarScreenState extends State<CaptainRadarScreen>
    with TickerProviderStateMixin {
  RadarGameState _gameState = RadarGameState.idle;
  int _currentLevel = 1;
  int _score = 0;
  int _streak = 0;
  double _timerProgress = 1.0;
  Timer? _gameTimer;
  Timer? _movementTimer;

  late RadarTarget _correctTarget;
  List<RadarTarget> _allTargets = [];
  String _missionCommand = "";

  late AnimationController _sweepController;
  late AnimationController _glitchController;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _glitchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    
    Future.delayed(const Duration(milliseconds: 500), () => _startNewRound());
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _movementTimer?.cancel();
    _sweepController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  void _startNewRound() {
    _gameTimer?.cancel();
    _movementTimer?.cancel();

    setState(() {
      _gameState = RadarGameState.missionBrief;
      _timerProgress = 1.0;
      _generateTargets();
      _generateMission();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _gameState = RadarGameState.active);
      _startTimers();
    });
  }

  void _generateTargets() {
    _allTargets = [];
    int targetCount = 4 + (_currentLevel ~/ 2);
    if (targetCount > 12) targetCount = 12;

    List<Map<String, dynamic>> types = [
      {'type': 'rocket', 'icon': Icons.rocket_launch_rounded, 'color': Colors.redAccent, 'label': 'الصاروخ الأحمر'},
      {'type': 'core', 'icon': Icons.settings_input_component_rounded, 'color': const Color(0xFF00F2FF), 'label': 'نواة الطاقة الزرقاء'},
      {'type': 'asteroid', 'icon': Icons.landscape_rounded, 'color': Colors.orangeAccent, 'label': 'النيزك المتوهج'},
      {'type': 'ufo', 'icon': Icons.vaping_rooms_rounded, 'color': const Color(0xFFBC00FF), 'label': 'الطبق الطائر البنفسجي'},
    ];

    // Pick correct target type
    var targetType = types[_random.nextInt(types.length)];
    _missionCommand = "حدد موقع: ${targetType['label']}";

    // Create correct target
    _correctTarget = _createTarget(0, targetType, isCorrect: true);
    _allTargets.add(_correctTarget);

    // Create decoys
    for (int i = 1; i < targetCount; i++) {
      var decoyType = types[_random.nextInt(types.length)];
      _allTargets.add(_createTarget(i, decoyType, isCorrect: false));
    }
  }

  RadarTarget _createTarget(int id, Map<String, dynamic> data, {required bool isCorrect}) {
    return RadarTarget(
      id: id,
      type: data['type'],
      color: data['color'],
      icon: data['icon'],
      position: Offset(_random.nextDouble() * 260.r, _random.nextDouble() * 260.r),
      direction: Offset(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1),
      speed: 1.0 + (_currentLevel * 0.2),
    );
  }

  void _generateMission() {
    // Mission command already set in _generateTargets
  }

  void _startTimers() {
    // Movement Timer
    _movementTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (!mounted) return;
      setState(() {
        for (var target in _allTargets) {
          target.position += target.direction * target.speed;
          
          // Bounce off walls
          if (target.position.dx < 0 || target.position.dx > 260.r) target.direction = Offset(-target.direction.dx, target.direction.dy);
          if (target.position.dy < 0 || target.position.dy > 260.r) target.direction = Offset(target.direction.dx, -target.direction.dy);
        }
      });
    });

    // Game Timer (Countdown)
    const duration = Duration(milliseconds: 50);
    double totalTime = 6.0 - (_currentLevel * 0.2); 
    if (totalTime < 2.5) totalTime = 2.5;
    double decrement = duration.inMilliseconds / (totalTime * 1000);

    _gameTimer = Timer.periodic(duration, (timer) {
      if (!mounted) return;
      setState(() {
        _timerProgress -= decrement;
        if (_timerProgress <= 0) {
          _timerProgress = 0;
          _handleFailure();
        }
      });
    });
  }

  void _handleTargetTap(RadarTarget target) {
    if (_gameState != RadarGameState.active) return;

    if (target.id == _correctTarget.id) {
      _handleSuccess();
    } else {
      _handleFailure();
    }
  }

  void _handleSuccess() {
    _gameTimer?.cancel();
    _movementTimer?.cancel();
    setState(() {
      _gameState = RadarGameState.success;
      _score += 150 + (_streak * 30);
      _streak++;
    });

    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _currentLevel++;
      _startNewRound();
    });
  }

  void _handleFailure() {
    _gameTimer?.cancel();
    _movementTimer?.cancel();
    _glitchController.forward(from: 0);
    setState(() {
      _gameState = RadarGameState.failure;
      _streak = 0;
    });

    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _startNewRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020412),
      body: Stack(
        children: [
          _buildSpaceBackground(),
          _buildGlitchOverlay(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildMissionPanel(),
                const Spacer(),
                _buildRadarSystem(),
                const Spacer(),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF020412), Color(0xFF0A0E21), Color(0xFF020412)],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(40, (i) {
            return Positioned(
              left: math.Random().nextDouble() * 1.sw,
              top: math.Random().nextDouble() * 1.sh,
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: math.Random().nextDouble() * 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGlitchOverlay() {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        if (_glitchController.value == 0) return const SizedBox.shrink();
        return Container(
          color: Colors.red.withValues(alpha: 0.15 * (1 - _glitchController.value)),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'رادار القائد',
                style: TextStyle(
                  color: const Color(0xFF00F2FF),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'CAPTAIN RADAR v2.1',
                style: TextStyle(color: Colors.white38, fontSize: 10.sp, letterSpacing: 1),
              ),
            ],
          ),
          _buildStreakBadge(),
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFF00F2FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF00F2FF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 16),
          SizedBox(width: 4.w),
          Text(
            '$_streak',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionPanel() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المهمة الحالية:', style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontFamily: 'Cairo')),
                Text(
                  _missionCommand,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildMiniStat('النتيجة', '$_score'),
          ],
        ),
      ),
    ).animate(target: _gameState == RadarGameState.missionBrief ? 1 : 0)
     .slideY(begin: -0.2, duration: 500.ms)
     .fadeIn();
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontFamily: 'Cairo')),
        Text(value, style: TextStyle(color: const Color(0xFFBC00FF), fontSize: 14.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRadarSystem() {
    return Container(
      width: 300.r,
      height: 300.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0A0E21).withValues(alpha: 0.6),
        border: Border.all(color: const Color(0xFF00F2FF).withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00F2FF).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: ClipOval(
        child: Stack(
          children: [
            // Radar Grids
            CustomPaint(
              size: Size(300.r, 300.r),
              painter: RadarGridPainter(),
            ),
            
            // Sweep Animation
            AnimatedBuilder(
              animation: _sweepController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(300.r, 300.r),
                  painter: RadarSweepPainter(angle: _sweepController.value * 2 * math.pi),
                );
              },
            ),

            // Targets
            ..._allTargets.map((target) => _buildTargetWidget(target)),

            // UI Feedback (Success/Failure)
            if (_gameState == RadarGameState.success)
              Center(child: Icon(Icons.check_circle_rounded, color: const Color(0xFF00FF95), size: 80.r).animate().scale().fadeOut()),
            if (_gameState == RadarGameState.failure)
              Center(child: Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 80.r).animate().shake()),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetWidget(RadarTarget target) {
    bool isVisible = _gameState != RadarGameState.missionBrief;
    return Positioned(
      left: target.position.dx,
      top: target.position.dy,
      child: GestureDetector(
        onTap: () => _handleTargetTap(target),
        child: Opacity(
          opacity: isVisible ? 1.0 : 0.0,
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: target.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: target.color.withValues(alpha: 0.5)),
            ),
            child: Icon(target.icon, color: target.color, size: 24.sp),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .shimmer(duration: 2.seconds, color: Colors.white24)
           .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    String status = "";
    Color color = Colors.white;

    if (_gameState == RadarGameState.missionBrief) {
      status = "جاري مسح القطاع...";
      color = const Color(0xFF00F2FF);
    } else if (_gameState == RadarGameState.active) {
      status = "الهدف مكتشف! أسرع!";
      color = Colors.amber;
    }

    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          Text(
            status,
            style: TextStyle(color: color, fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ).animate(onPlay: (c) => c.repeat()).shimmer(),
          SizedBox(height: 20.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _timerProgress,
              minHeight: 8.h,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                _timerProgress > 0.3 ? const Color(0xFF00F2FF) : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F2FF).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Circles
    canvas.drawCircle(center, size.width * 0.2, paint);
    canvas.drawCircle(center, size.width * 0.4, paint);
    
    // Cross lines
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class RadarSweepPainter extends CustomPainter {
  final double angle;

  RadarSweepPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: angle - 0.5,
        endAngle: angle,
        colors: [Colors.transparent, const Color(0xFF00F2FF).withValues(alpha: 0.3)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
    
    // Leading line
    final linePaint = Paint()
      ..color = const Color(0xFF00F2FF).withValues(alpha: 0.5)
      ..strokeWidth = 2;
    
    canvas.drawLine(
      center,
      Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(RadarSweepPainter old) => old.angle != angle;
}
