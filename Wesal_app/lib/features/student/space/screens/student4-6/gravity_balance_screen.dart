/*
🧠 اسم الملف: gravity_balance_screen.dart

📌 بيعمل إيه؟
دي لعبة "موازنة نفاثة" اللي بتعتمد على رسم خط ثابت وتجنب العقبات عشان توصل لنقطة النهاية.

👤 موجه لمين؟
- طلاب (المرحلة من 4 لـ 6 ابتدائي)

💡 فكرته:
بتنمي عند الطالب مهارة الصبر، التركيز، والثبات الانفعالي تحت ضغط الوقت.
*/

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GravityBalanceScreen extends StatefulWidget {
  const GravityBalanceScreen({super.key});

  @override
  State<GravityBalanceScreen> createState() => _GravityBalanceScreenState();
}

class _GravityBalanceScreenState extends State<GravityBalanceScreen>
    with TickerProviderStateMixin {
  List<Offset> _linePoints = []; // The path being drawn
  double _stability = 1.0; // 0.0 to 1.0
  bool _isGameOver = false;
  bool _isSuccess = false;
  int _currentLevel = 1;
  int _score = 0;
  
  late AnimationController _pulseController;
  final math.Random _random = math.Random();
  
  Size _fieldSize = Size.zero;
  List<Rect> _obstacles = [];
  Timer? _gameTimer;
  DateTime? _lastMoveTime;
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _startGameLogic();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startGameLogic() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isGameOver || _isSuccess || _linePoints.isEmpty) return;
      
      setState(() {
        if (_lastMoveTime == null || DateTime.now().difference(_lastMoveTime!) > const Duration(milliseconds: 200)) {
          _stability = (_stability + 0.01).clamp(0.0, 1.0);
        }
        
        final lastPoint = _linePoints.last;
        for (var rect in _obstacles) {
          if (rect.contains(lastPoint)) {
            _handleCollision();
          }
        }

        if (lastPoint.dy < 60.h) {
          _handleWin();
        }
      });
    });
  }

  void _handleCollision() {
    HapticFeedback.heavyImpact();
    setState(() {
      _stability = 0; 
      _isGameOver = true;
    });
  }

  void _handleWin() {
    _isSuccess = true;
    _score += (_stability * 1000).toInt() + (_currentLevel * 500);
    HapticFeedback.mediumImpact();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isGameOver || _isSuccess) return;
    setState(() {
      _linePoints = [details.localPosition];
      _stability = 1.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isGameOver || _isSuccess) return;

    final newPoint = details.localPosition;
    
    setState(() {
      double speed = 0;
      if (_lastPosition != null) {
        speed = (newPoint - _lastPosition!).distance;
      }

      double speedThreshold = 15.0 - (_currentLevel * 0.5).clamp(0, 10);
      if (speed > speedThreshold) {
        double penalty = (speed / (400 - (_currentLevel * 15))).clamp(0.0, 0.2);
        _stability = (_stability - penalty).clamp(0.0, 1.0);
        if (speed > 30.0) HapticFeedback.lightImpact();
      }

      _linePoints.add(newPoint);
      _lastPosition = newPoint;
      _lastMoveTime = DateTime.now();

      if (_stability <= 0) {
        _isGameOver = true;
      }
    });
  }

  void _generateObstacles(Size size) {
    if (_obstacles.isNotEmpty && _fieldSize == size) return;
    _fieldSize = size;
    
    double width = size.width;
    double height = size.height;
    _obstacles = [];

    int obstacleCount = 2 + (_currentLevel ~/ 2);
    if (obstacleCount > 8) obstacleCount = 8;

    for (int i = 0; i < obstacleCount; i++) {
      double y = height * (0.2 + (i * (0.6 / obstacleCount)));
      double obstacleWidth = width * (0.5 + (_random.nextDouble() * 0.2));
      double x = _random.nextBool() ? 0 : width - obstacleWidth;
      
      _obstacles.add(Rect.fromLTWH(x, y, obstacleWidth, 30.h));
    }
  }

  void _goToNextLevel() {
    setState(() {
      _currentLevel++;
      _isSuccess = false;
      _stability = 1.0;
      _obstacles = []; 
      _linePoints = [];
      _lastMoveTime = null;
      _lastPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020412),
      body: Stack(
        children: [
          _buildSpaceCorridor(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStabilityHUD(),
                Expanded(
                  child: _buildNavigationField(),
                ),
                _buildFooter(),
              ],
            ),
          ),
          if (_isGameOver) _buildGameOverOverlay(),
          if (_isSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildSpaceCorridor() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E21), Color(0xFF020412)],
        ),
      ),
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: CorridorPainter(stability: _stability),
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
                'موازنة نفاثة',
                style: TextStyle(
                  color: const Color(0xFF00F2FF),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'GRAVITY BALANCE SYSTEM',
                style: TextStyle(color: Colors.white24, fontSize: 10.sp, letterSpacing: 2),
              ),
            ],
          ),
          const Icon(Icons.self_improvement_rounded, color: Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildStabilityHUD() {
    Color stabilityColor = Color.lerp(Colors.redAccent, Colors.greenAccent, _stability)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('مستوى الاستقرار', style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontFamily: 'Cairo')),
              Text('${(_stability * 100).toInt()}%', style: TextStyle(color: stabilityColor, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _stability,
              minHeight: 8.h,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(stabilityColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _generateObstacles(Size(constraints.maxWidth, constraints.maxHeight));
        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          child: Stack(
            children: [
              ..._obstacles.map((rect) => Positioned.fromRect(
                rect: rect,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent.withValues(alpha: 0.1), blurRadius: 10),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.bolt_rounded, color: Colors.redAccent.withValues(alpha: 0.5), size: 16.sp),
                  ),
                ),
              )),
              
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.greenAccent.withValues(alpha: 0.2), Colors.transparent],
                    ),
                  ),
                  child: Center(
                    child: Text('منطقة الوصول', style: TextStyle(color: Colors.greenAccent, fontSize: 12.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  ),
                ),
              ),

              CustomPaint(
                size: Size.infinite,
                painter: LinePainter(points: _linePoints, stability: _stability),
              ),

              if (_linePoints.isEmpty)
                Positioned(
                  bottom: 40.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Color(0xFF00F2FF), size: 30).animate(onPlay: (c) => c.repeat()).scale().fadeIn(),
                        SizedBox(height: 8.h),
                        Text('ابدأ الرسم من هنا للأعلى', style: TextStyle(color: Colors.white24, fontSize: 10.sp, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          Text(
            'ارسم خطاً مستقراً وتجنب ملامسة المناطق الحمراء',
            style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontFamily: 'Cairo'),
          ),
          SizedBox(height: 10.h),
          Text(
            'تحذير: الرسم السريع يفقدك التوازن',
            style: TextStyle(color: Colors.orangeAccent.withValues(alpha: 0.5), fontSize: 10.sp, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent, size: 80.r),
            SizedBox(height: 20.h),
            Text('انهيار الاستقرار!', style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            SizedBox(height: 40.h),
            ElevatedButton(
              onPressed: () => setState(() {
                _isGameOver = false;
                _stability = 1.0;
                _linePoints = [];
                _lastPosition = null;
              }),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 80.r),
            SizedBox(height: 20.h),
            Text('تمت المهمة بنجاح!', style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            SizedBox(height: 10.h),
            Text('المستوى $_currentLevel مكتمل', style: TextStyle(color: Colors.white70, fontSize: 16.sp, fontFamily: 'Cairo')),
            Text('النقاط: $_score', style: TextStyle(color: Colors.greenAccent, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 40.h),
            ElevatedButton(
              onPressed: _goToNextLevel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent, 
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
              ),
              child: const Text('المستوى التالي', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة للوحة التحكم', style: TextStyle(color: Colors.white38, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

class LinePainter extends CustomPainter {
  final List<Offset> points;
  final double stability;

  LinePainter({required this.points, required this.stability});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Color.lerp(Colors.redAccent, const Color(0xFF00F2FF), stability)!
      ..strokeWidth = 4.r
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.3)
      ..strokeWidth = 12.r
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
    
    final lastPoint = points.last;
    canvas.drawCircle(lastPoint, 6.r, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(LinePainter old) => true;
}

class CorridorPainter extends CustomPainter {
  final double stability;
  CorridorPainter({required this.stability});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.4, size.height * 0.4), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width * 0.6, size.height * 0.4), paint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width * 0.4, size.height * 0.6), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width * 0.6, size.height * 0.6), paint);
    
    double step = 50.r;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CorridorPainter old) => old.stability != stability;
}
