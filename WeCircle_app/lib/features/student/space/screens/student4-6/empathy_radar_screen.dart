import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum EmpathyAction { transform, accept, block }
enum WaveType { anger, confusion, request, positive }

class EmotionalWave {
  final int id;
  final String message;
  final WaveType type;
  final EmpathyAction requiredAction;
  double position; // 0.0 to 1.0 (reaches shield)
  bool isProcessed = false;

  EmotionalWave({
    required this.id,
    required this.message,
    required this.type,
    required this.requiredAction,
    this.position = 0.0,
  });
}

class EmpathyRadarScreen extends StatefulWidget {
  const EmpathyRadarScreen({super.key});

  @override
  State<EmpathyRadarScreen> createState() => _EmpathyRadarScreenState();
}

class _EmpathyRadarScreenState extends State<EmpathyRadarScreen>
    with TickerProviderStateMixin {
  int _score = 0;
  int _streak = 0;
  double _stability = 0.8; // 0.0 to 1.0
  
  final List<EmotionalWave> _activeWaves = [];
  Timer? _gameTimer;
  int _waveCounter = 0;
  
  late AnimationController _shieldController;
  late AnimationController _pulseController;
  
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _shieldController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _shieldController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateWaves();
      if (_random.nextDouble() < 0.008) { // Adjusted spawn rate for 60fps
        _spawnWave();
      }
    });
  }

  void _spawnWave() {
    if (_activeWaves.length > 3) return;

    List<Map<String, dynamic>> scenarios = [
      {'msg': 'أنت دائماً تفسد كل شيء!', 'type': WaveType.anger, 'action': EmpathyAction.transform},
      {'msg': 'لا أفهم هذا، هل تساعدني؟', 'type': WaveType.request, 'action': EmpathyAction.accept},
      {'msg': 'أنا حزين جداً اليوم...', 'type': WaveType.confusion, 'action': EmpathyAction.accept},
      {'msg': 'كلامك غبي ولا يهم أحداً', 'type': WaveType.anger, 'action': EmpathyAction.block},
      {'msg': 'أنا فخور بك جداً!', 'type': WaveType.positive, 'action': EmpathyAction.accept},
    ];

    var scenario = scenarios[_random.nextInt(scenarios.length)];
    
    setState(() {
      _activeWaves.add(EmotionalWave(
        id: _waveCounter++,
        message: scenario['msg'],
        type: scenario['type'],
        requiredAction: scenario['action'],
      ));
    });
  }

  void _updateWaves() {
    setState(() {
      for (var wave in _activeWaves) {
        if (!wave.isProcessed) {
          wave.position += 0.004; // Slower increment for 16ms loop
          if (wave.position >= 0.85) { // Hit shield
            _handleMiss(wave);
          }
        }
      }
      _activeWaves.removeWhere((w) => w.position >= 1.0 || w.isProcessed);
    });
  }

  void _handleMiss(EmotionalWave wave) {
    if (wave.isProcessed) return;
    wave.isProcessed = true;
    if (wave.type == WaveType.anger || wave.type == WaveType.confusion) {
      _stability = (_stability - 0.1).clamp(0.0, 1.0);
      HapticFeedback.vibrate();
    }
  }

  void _processAction(EmpathyAction action) {
    if (_activeWaves.isEmpty) return;
    
    // Find closest wave to shield
    EmotionalWave? target;
    double maxPos = -1.0;
    for (var w in _activeWaves) {
      if (!w.isProcessed && w.position > maxPos) {
        maxPos = w.position;
        target = w;
      }
    }

    if (target != null && target.position > 0.3) {
      if (target.requiredAction == action) {
        _handleSuccess(target);
      } else {
        _handleFailure();
      }
    }
  }

  void _handleSuccess(EmotionalWave wave) {
    setState(() {
      wave.isProcessed = true;
      _score += 100 + (_streak * 20);
      _streak++;
      _stability = (_stability + 0.05).clamp(0.0, 1.0);
    });
    _shieldController.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _handleFailure() {
    setState(() {
      _streak = 0;
      _stability = (_stability - 0.1).clamp(0.0, 1.0);
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020412),
      body: Stack(
        children: [
          _buildRadarBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStabilityMeter(),
                Expanded(
                  child: _buildPlayArea(),
                ),
                _buildActionControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0xFF0A1433), Color(0xFF020412)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: CustomPaint(
              size: Size(350.r, 350.r),
              painter: RadarCirclesPainter(pulse: _pulseController.value),
            ),
          ),
        ],
      ),
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
                'رادار المشاعر',
                style: TextStyle(
                  color: const Color(0xFF00F2FF),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'EMPATHY RADAR v1.5',
                style: TextStyle(color: Colors.white24, fontSize: 10.sp, letterSpacing: 1.5),
              ),
            ],
          ),
          _buildScoreBox(),
        ],
      ),
    );
  }

  Widget _buildScoreBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 16),
          SizedBox(width: 4.w),
          Text('$_score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildStabilityMeter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الاستقرار العاطفي', style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontFamily: 'Cairo')),
              Text('${(_stability * 100).toInt()}%', style: TextStyle(color: Colors.greenAccent, fontSize: 10.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 4.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _stability,
              minHeight: 6.h,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                _stability > 0.3 ? const Color(0xFF00FF95) : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Incoming Waves
        ..._activeWaves.map((wave) => _buildWaveWidget(wave)),
        
        // Central Shield
        _buildCentralShield(),
      ],
    );
  }

  Widget _buildWaveWidget(EmotionalWave wave) {
    Color color;
    IconData icon;
    switch (wave.type) {
      case WaveType.anger: color = Colors.redAccent; icon = Icons.warning_rounded; break;
      case WaveType.confusion: color = Colors.amberAccent; icon = Icons.help_outline_rounded; break;
      case WaveType.request: color = Colors.blueAccent; icon = Icons.chat_bubble_outline_rounded; break;
      case WaveType.positive: color = Colors.greenAccent; icon = Icons.auto_awesome_rounded; break;
    }

    return Positioned(
      top: 50.h + (wave.position * 350.h),
      child: Opacity(
        opacity: (1.0 - wave.position).clamp(0, 1),
        child: Container(
          width: 320.w,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  wave.message,
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 15.sp, 
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
      ),
    );
  }

  Widget _buildCentralShield() {
    return AnimatedBuilder(
      animation: _shieldController,
      builder: (context, child) {
        return Container(
          width: 130.r,
          height: 130.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00F2FF).withValues(alpha: 0.05 + (0.1 * _shieldController.value)),
            border: Border.all(
              color: const Color(0xFF00F2FF).withValues(alpha: 0.3 + (0.7 * _shieldController.value)),
              width: 2 + (5 * _shieldController.value),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F2FF).withValues(alpha: 0.3 * _shieldController.value),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.shield_rounded,
              color: const Color(0xFF00F2FF),
              size: 50.r,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionControls() {
    return Padding(
      padding: EdgeInsets.fromLTRB(32.r, 0, 32.r, 40.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.swap_horiz_rounded, 'تحويل', Colors.amberAccent, () => _processAction(EmpathyAction.transform)),
          _buildActionButton(Icons.favorite_rounded, 'قبول', Colors.blueAccent, () => _processAction(EmpathyAction.accept)),
          _buildActionButton(Icons.block_rounded, 'صد', Colors.redAccent, () => _processAction(EmpathyAction.block)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 75.r,
            height: 75.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Icon(icon, color: color, size: 35.sp),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .shimmer(duration: 3.seconds, color: Colors.white10),
          SizedBox(height: 10.h),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ],
      ),
    ).animate().scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOut);
  }
}

class RadarCirclesPainter extends CustomPainter {
  final double pulse;
  RadarCirclesPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F2FF).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, (size.width / 2) * (i / 3) * (0.9 + 0.1 * pulse), paint);
    }
    
    // Draw cross lines
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paint);
  }

  @override
  bool shouldRepaint(RadarCirclesPainter old) => old.pulse != pulse;
}
