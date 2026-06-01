import 'dart:math' as math;
/*
🧠 اسم الملف: broken_galaxy_pulse_screen.dart

📌 بيعمل إيه؟
لعبة "نبض المجرة" اللي بتعتمد على التوقيت والسرعة في إنقاذ أجزاء من المجرة عن طريق الضغط في الوقت المناسب.

👤 موجه لمين؟
- طلاب (المرحلة من 1 لـ 3 ابتدائي)

💡 فكرته:
تنمية مهارات التنسيق بين اليد والعين وسرعة الاستجابة عند الطفل.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FadedPlanet {
  Offset position;
  bool isAwake;
  FadedPlanet(this.position, {this.isAwake = false});
}

class BrokenGalaxyPulseScreen extends StatefulWidget {
  const BrokenGalaxyPulseScreen({super.key});

  @override
  State<BrokenGalaxyPulseScreen> createState() => _BrokenGalaxyPulseScreenState();
}

class _BrokenGalaxyPulseScreenState extends State<BrokenGalaxyPulseScreen> with TickerProviderStateMixin {
  int _currentLevel = 1;
  double _galaxyHealth = 0.5; // 0.0 (Dead/Selfish) to 1.0 (Alive/Shared)

  Offset _coreStarPos = Offset.zero;
  final List<FadedPlanet> _planets = [];
  
  final List<List<Offset>> _sharedBeams = [];
  List<Offset> _currentBeam = [];

  bool _isLevelComplete = false;
  bool _showEndRecap = false;
  
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

    _coreStarPos = Offset(w / 2, h * 0.8);
    _sharedBeams.clear();
    _currentBeam.clear();
    _isLevelComplete = false;
    _showEndRecap = false;
    _galaxyHealth = 0.5;

    _planets.clear();
    final rng = math.Random();

    int planetCount = math.min(_currentLevel, 6);

    for (int i = 0; i < planetCount; i++) {
      double tx = 40.w + rng.nextDouble() * (w - 80.w);
      double ty = 150.h + rng.nextDouble() * (h * 0.4);
      _planets.add(FadedPlanet(Offset(tx, ty)));
    }

    setState(() {});
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isLevelComplete || _showEndRecap) return;
    final pos = details.localPosition;
    
    // Check if starting from core star
    if ((pos - _coreStarPos).distance < 60.w) {
      setState(() {
        _currentBeam = [pos];
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_currentBeam.isEmpty || _isLevelComplete) return;

    final pos = details.localPosition;
    
    setState(() {
      _currentBeam.add(pos);
    });

    // Check collision with faded planets
    for (var planet in _planets) {
      if (!planet.isAwake && (pos - planet.position).distance < 45.w) {
        // Shared Energy!
        HapticFeedback.heavyImpact();
        planet.isAwake = true;
        
        // Optimize beam to just a straight line for the final completed path
        _sharedBeams.add([_currentBeam.first, planet.position]);
        _currentBeam.clear();
        
        // Increase galaxy health
        _galaxyHealth = math.min(1.0, _galaxyHealth + (0.5 / _planets.length));
        
        _checkLevelCompletion();
        break;
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _currentBeam.clear();
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isLevelComplete || _showEndRecap) return;
    final pos = details.localPosition;
    
    // Check if tapping core star
    if ((pos - _coreStarPos).distance < 60.w) {
      _onCoreStarTapped();
    }
  }

  void _onCoreStarTapped() {
    if (_isLevelComplete || _showEndRecap) return;
    
    // Selfish behavior -> Decrease health
    HapticFeedback.vibrate();
    setState(() {
      _galaxyHealth = math.max(0.0, _galaxyHealth - 0.2);
    });
  }

  void _checkLevelCompletion() async {
    if (_planets.every((p) => p.isAwake)) {
      setState(() {
        _isLevelComplete = true;
        _galaxyHealth = 1.0;
      });
      HapticFeedback.heavyImpact();
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _showEndRecap = true;
        });
      }
    }
  }

  void _nextLevel() {
    setState(() {
      _currentLevel++;
    });
    _initLevel();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = Color.lerp(const Color(0xFF010005), const Color(0xFF1A0B2E), _galaxyHealth)!;
    Color glowColor = Color.lerp(Colors.redAccent.withValues(alpha: 0.2), Colors.cyanAccent.withValues(alpha: 0.8), _galaxyHealth)!;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.5 + (_galaxyHealth * 1.5),
                colors: [glowColor, bgColor],
              ),
            ),
          ),
          
          GestureDetector(
            onTapUp: _handleTapUp,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GalaxyPulsePainter(
                      coreStar: _coreStarPos,
                      sharedBeams: _sharedBeams,
                      currentBeam: _currentBeam,
                      pulseValue: _pulseController.value,
                      galaxyHealth: _galaxyHealth,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          
          for (var planet in _planets)
            Positioned(
              left: planet.position.dx - 35.w,
              top: planet.position.dy - 35.w,
              width: 70.w,
              height: 70.w,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Image.asset(
                  planet.isAwake 
                      ? 'assets/images/planet_awake.png' 
                      : 'assets/images/planet_faded.png',
                  key: ValueKey(planet.isAwake),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 10.h),
                _buildHUD(),
              ],
            ),
          ),

          if (_currentLevel == 1 && !_isLevelComplete && !_showEndRecap)
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Text(
                      "اسحب النور من قلبك لتنير الكواكب",
                      style: TextStyle(color: Colors.white70, fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
                    SizedBox(height: 5.h),
                    Text(
                      "أو اضغط على قلبك لتحتفظ بالنور لنفسك!",
                      style: TextStyle(color: Colors.white38, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            ),

          if (_showEndRecap) _buildEndRecap(),
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
            'نبض المجرة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.cyanAccent.withValues(alpha: 0.8), blurRadius: 15),
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
            Row(
              children: [
                Icon(Icons.favorite_rounded, color: Color.lerp(Colors.grey, Colors.pinkAccent, _galaxyHealth), size: 20.sp),
                SizedBox(width: 5.w),
                Text(
                  "نبض المجرة: ${(_galaxyHealth * 100).toInt()}%",
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndRecap() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "ماذا تعلمنا؟",
                style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.amberAccent),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.5, end: 0),
              
              SizedBox(height: 40.h),
              
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off_rounded, color: Colors.redAccent, size: 40.sp),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Text(
                        "عندما احتفظت بالنور لنفسك: أصبحت المجرة مظلمة وضعيفة.",
                        style: TextStyle(color: Colors.white, fontSize: 16.sp, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideX(),

              SizedBox(height: 20.h),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent, size: 40.sp),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "عندما شاركت النور مع الآخرين:",
                            style: TextStyle(color: Colors.greenAccent, fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            "كلما ساعدت أصدقاءك وشاركتهم، أصبحت أنت أقوى والمجرة أجمل بكثير! ✨",
                            style: TextStyle(color: Colors.white, fontSize: 18.sp, height: 1.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1500.ms).slideX(),

              SizedBox(height: 50.h),

              GestureDetector(
                onTap: _nextLevel,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A1B9A), Color(0xFF1E88E5), Color(0xFF00E5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Text(
                    "المستوى التالي 🚀",
                    style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ).animate().fadeIn(delay: 3000.ms).scale(curve: Curves.elasticOut, duration: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class GalaxyPulsePainter extends CustomPainter {
  final Offset coreStar;
  final List<List<Offset>> sharedBeams;
  final List<Offset> currentBeam;
  final double pulseValue;
  final double galaxyHealth;

  GalaxyPulsePainter({
    required this.coreStar,
    required this.sharedBeams,
    required this.currentBeam,
    required this.pulseValue,
    required this.galaxyHealth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (coreStar == Offset.zero) return;
    final double beamAlpha = math.max(0.2, galaxyHealth);
    final pathPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: beamAlpha)
      ..strokeWidth = 4.0 + (galaxyHealth * 4)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8);

    for (var path in sharedBeams) {
      if (path.length > 1) {
        final Path p = Path();
        p.moveTo(path.first.dx, path.first.dy);
        for (int i = 1; i < path.length; i++) {
          p.lineTo(path[i].dx, path[i].dy);
        }
        canvas.drawPath(p, pathPaint);
      }
    }

    if (currentBeam.length > 1) {
      final currentPaint = Paint()
        ..color = Colors.pinkAccent.withValues(alpha: 0.8)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      final Path p = Path();
      p.moveTo(currentBeam.first.dx, currentBeam.first.dy);
      for (int i = 1; i < currentBeam.length; i++) {
        p.lineTo(currentBeam[i].dx, currentBeam[i].dy);
      }
      canvas.drawPath(p, currentPaint);
    }

    double coreRadius = 30 + (pulseValue * 10 * galaxyHealth);
    if (galaxyHealth < 0.2) coreRadius = 25;
    final coreGlow = Paint()
      ..color = Color.lerp(Colors.redAccent, Colors.pinkAccent, galaxyHealth)!
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 + (galaxyHealth * 20));
    canvas.drawCircle(coreStar, coreRadius, coreGlow);
    canvas.drawCircle(coreStar, 15, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(GalaxyPulsePainter oldDelegate) => true;
}
