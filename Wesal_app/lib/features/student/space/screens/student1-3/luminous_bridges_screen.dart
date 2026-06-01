import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TargetStar {
  Offset position;
  bool isConnected;
  TargetStar(this.position, {this.isConnected = false});
}

class JealousyCloud {
  Offset position;
  double radius;
  JealousyCloud(this.position, this.radius);
}

class LuminousBridgesScreen extends StatefulWidget {
  const LuminousBridgesScreen({super.key});

  @override
  State<LuminousBridgesScreen> createState() => _LuminousBridgesScreenState();
}

class _LuminousBridgesScreenState extends State<LuminousBridgesScreen> with TickerProviderStateMixin {
  int _currentLevel = 1;
  int _score = 0;
  
  Offset _mainStarPos = Offset.zero;
  final List<TargetStar> _targets = [];
  final List<JealousyCloud> _clouds = [];
  
  final List<List<Offset>> _completedPaths = [];
  List<Offset> _currentPath = [];

  bool _isLevelComplete = false;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLevel();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initLevel() {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    _mainStarPos = Offset(w / 2, h * 0.85);
    _completedPaths.clear();
    _currentPath.clear();
    _isLevelComplete = false;

    _targets.clear();
    _clouds.clear();

    final rng = math.Random();

    int targetCount = math.min(_currentLevel + 1, 7);
    int cloudCount = _currentLevel > 2 ? math.min(_currentLevel - 2, 4) : 0;

    // Generate Targets
    for (int i = 0; i < targetCount; i++) {
      double tx = 40.w + rng.nextDouble() * (w - 80.w);
      double ty = 150.h + rng.nextDouble() * (h * 0.5);
      _targets.add(TargetStar(Offset(tx, ty)));
    }

    // Generate Clouds avoiding targets and main star
    for (int i = 0; i < cloudCount; i++) {
      double cx = 50.w + rng.nextDouble() * (w - 100.w);
      double cy = 250.h + rng.nextDouble() * (h * 0.3);
      _clouds.add(JealousyCloud(Offset(cx, cy), 40.w + rng.nextDouble() * 30.w));
    }

    setState(() {});
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isLevelComplete) return;
    final pos = details.localPosition;
    // Check if starting near main star
    if ((pos - _mainStarPos).distance < 60.w) {
      setState(() {
        _currentPath = [pos];
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_currentPath.isEmpty || _isLevelComplete) return;

    final pos = details.localPosition;
    
    // Check cloud collision
    for (var cloud in _clouds) {
      if ((pos - cloud.position).distance < cloud.radius) {
        // Hit a cloud! Break connection
        HapticFeedback.vibrate();
        setState(() {
          _currentPath.clear();
        });
        return;
      }
    }

    setState(() {
      _currentPath.add(pos);
    });

    // Check star collision
    for (var target in _targets) {
      if (!target.isConnected && (pos - target.position).distance < 40.w) {
        // Connected!
        HapticFeedback.heavyImpact();
        target.isConnected = true;
        _completedPaths.add(List.from(_currentPath));
        _currentPath.clear();
        _score += 100 * _currentLevel;
        
        _checkLevelCompletion();
        break;
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _currentPath.clear();
    });
  }

  void _checkLevelCompletion() async {
    if (_targets.every((t) => t.isConnected)) {
      setState(() {
        _isLevelComplete = true;
      });
      HapticFeedback.heavyImpact();
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _currentLevel++;
        });
        _initLevel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03001C), // Deep dark space
      body: Stack(
        children: [
          // Background fade-in based on completion
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: _isLevelComplete ? 2.0 : 0.8,
                colors: [
                  const Color(0xFF2A0845).withValues(alpha: _isLevelComplete ? 0.8 : 0.3),
                  const Color(0xFF03001C),
                ],
              ),
            ),
          ),
          
          // Game Layer (Placed behind UI so it doesn't block touches)
          // Game Layer (Isolated for performance)
          GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: LuminousBridgesPainter(
                      mainStar: _mainStarPos,
                      targets: _targets,
                      clouds: _clouds,
                      completedPaths: _completedPaths,
                      currentPath: _currentPath,
                      pulseValue: _pulseController.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),

          // UI Layer (Header, HUD) placed ON TOP
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 10.h),
                _buildHUD(),
              ],
            ),
          ),

          if (_isLevelComplete)
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent, size: 120)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 800.ms),
                    SizedBox(height: 20.h),
                    Text(
                      "المجرة تشرق بنورك! ✨",
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.amberAccent, blurRadius: 20)],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.5, end: 0),
                  ],
                ),
              ),
            ),
            
          // Helper text
          if (_currentLevel == 1)
            Positioned(
              bottom: 120.h,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "اسحب النور من النجمة الكبيرة للنجوم المطفية",
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'جسور النور ✨',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.amberAccent.withValues(alpha: 0.8), blurRadius: 15),
              ],
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              "مستوى $_currentLevel",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
            ),
            Container(width: 1, height: 20.h, color: Colors.white24),
            Text(
              "نور: $_score",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class LuminousBridgesPainter extends CustomPainter {
  final Offset mainStar;
  final List<TargetStar> targets;
  final List<JealousyCloud> clouds;
  final List<List<Offset>> completedPaths;
  final List<Offset> currentPath;
  final double pulseValue;

  LuminousBridgesPainter({
    required this.mainStar,
    required this.targets,
    required this.clouds,
    required this.completedPaths,
    required this.currentPath,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mainStar == Offset.zero) return;

    // Draw completed paths (glowing lines)
    final pathPaint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.6)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5);

    for (var path in completedPaths) {
      if (path.length > 1) {
        final Path p = Path();
        p.moveTo(path.first.dx, path.first.dy);
        for (int i = 1; i < path.length; i++) {
          p.lineTo(path[i].dx, path[i].dy);
        }
        canvas.drawPath(p, pathPaint);
      }
    }

    // Draw current path
    if (currentPath.length > 1) {
      final currentPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.8)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final Path p = Path();
      p.moveTo(currentPath.first.dx, currentPath.first.dy);
      for (int i = 1; i < currentPath.length; i++) {
        p.lineTo(currentPath[i].dx, currentPath[i].dy);
      }
      canvas.drawPath(p, currentPaint);
    }

    // Draw Clouds (Gray obstacles)
    final cloudPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (var cloud in clouds) {
      canvas.drawCircle(cloud.position, cloud.radius, cloudPaint);
      // Inner dense cloud
      canvas.drawCircle(cloud.position, cloud.radius * 0.6, Paint()..color = Colors.grey.withValues(alpha: 0.6));
    }

    // Draw Target Stars
    for (var target in targets) {
      if (target.isConnected) {
        // Glowing connected star
        final connectedPaint = Paint()
          ..color = Colors.amberAccent
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
        canvas.drawCircle(target.position, 15 + (pulseValue * 5), connectedPaint);
        canvas.drawCircle(target.position, 8, Paint()..color = Colors.white);
      } else {
        // Faded unconnected star
        final fadedPaint = Paint()
          ..color = Colors.white24
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(target.position, 10, fadedPaint);
      }
    }

    // Draw Main Star
    final mainGlow = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    
    canvas.drawCircle(mainStar, 40 + (pulseValue * 15), mainGlow);
    canvas.drawCircle(mainStar, 20, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant LuminousBridgesPainter oldDelegate) {
    return true; // Always repaint for animations
  }
}
