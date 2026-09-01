import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum HawkGameState { idle, observation, memory, selection, success, failure }

class HawkObject {
  final int id;
  final IconData icon;
  final Color color;
  final double size;
  final double rotation;
  bool isTarget;
  Offset position;

  HawkObject({
    required this.id,
    required this.icon,
    required this.color,
    this.size = 30.0,
    this.rotation = 0.0,
    this.isTarget = false,
    this.position = Offset.zero,
  });

  HawkObject copyWith({Offset? position}) {
    return HawkObject(
      id: id,
      icon: icon,
      color: color,
      size: size,
      rotation: rotation,
      isTarget: isTarget,
      position: position ?? this.position,
    );
  }
}

class HawkEyeScreen extends StatefulWidget {
  const HawkEyeScreen({super.key});

  @override
  State<HawkEyeScreen> createState() => _HawkEyeScreenState();
}

class _HawkEyeScreenState extends State<HawkEyeScreen>
    with TickerProviderStateMixin {
  HawkGameState _gameState = HawkGameState.idle;
  int _currentLevel = 1;
  int _score = 0;
  int _streak = 0;
  double _timerProgress = 1.0;
  Timer? _gameTimer;

  List<HawkObject> _objects = [];
  
  late AnimationController _pulseController;
  final math.Random _random = math.Random();
  Size _fieldSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startNewRound() {
    _gameTimer?.cancel();
    setState(() {
      _gameState = HawkGameState.observation;
      _timerProgress = 1.0;
      _generateObjects();
    });

    double observationTime = 3.5 - (_currentLevel * 0.3);
    if (observationTime < 1.2) observationTime = 1.2;

    Future.delayed(Duration(milliseconds: (observationTime * 1000).toInt()), () {
      if (!mounted) return;
      _transitionToMemory();
    });
  }

  void _transitionToMemory() {
    setState(() => _gameState = HawkGameState.memory);
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _gameState = HawkGameState.selection);
      _startCountdown();
    });
  }

  void _generateObjects() {
    _objects = [];
    int count = 4 + (_currentLevel ~/ 2);
    if (count > 12) count = 12;

    // Base attributes for similarity
    IconData baseIcon = Icons.star_rounded;
    Color baseColor = const Color(0xFF00F2FF);
    double baseSize = 35.r;
    double baseRotation = 0.0;

    int targetIndex = _random.nextInt(count);

    for (int i = 0; i < count; i++) {
      bool isTarget = i == targetIndex;
      
      IconData icon = baseIcon;
      Color color = baseColor;
      double size = baseSize;
      double rotation = baseRotation;

      if (isTarget) {
        // Make difference more pronounced
        int diffType = _random.nextInt(4);
        if (_currentLevel < 3) {
           color = Colors.amberAccent; // Very clear difference for beginners
           size = baseSize * 1.2;
        } else {
          switch (diffType) {
            case 0: color = Colors.purpleAccent; break; // Distinct color
            case 1: size = baseSize * 0.7; break; // Significantly smaller
            case 2: rotation = 0.8; break; // Clear rotation
            case 3: icon = Icons.star_outline_rounded; break; // Bordered vs Filled
          }
        }
      }

      _objects.add(HawkObject(
        id: i,
        icon: icon,
        color: color,
        size: size,
        rotation: rotation,
        isTarget: isTarget,
        position: Offset.zero, // Positioned later by LayoutBuilder
      ));
    }
  }

  void _startCountdown() {
    const duration = Duration(milliseconds: 50);
    double totalTime = 6.0 - (_currentLevel * 0.3);
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

  void _onObjectTap(HawkObject obj) {
    if (_gameState != HawkGameState.selection) return;

    if (obj.isTarget) {
      _handleSuccess();
    } else {
      _handleFailure();
    }
  }

  void _handleSuccess() {
    _gameTimer?.cancel();
    setState(() {
      _gameState = HawkGameState.success;
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
    setState(() {
      _gameState = HawkGameState.failure;
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
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildMissionHUD(),
                Expanded(
                  child: _buildGameField(),
                ),
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
          colors: [Color(0xFF020412), Color(0xFF080D20)],
        ),
      ),
      child: Stack(
        children: List.generate(30, (i) {
          return Positioned(
            left: _random.nextDouble() * 1.sw,
            top: _random.nextDouble() * 1.sh,
            child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _random.nextDouble() * 0.3),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
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
                'مهمة عين الصقر',
                style: TextStyle(
                  color: const Color(0xFF00F2FF),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'HAWK EYE MISSION v3.0',
                style: TextStyle(color: Colors.white24, fontSize: 10.sp, letterSpacing: 2),
              ),
            ],
          ),
          _buildStatBox('$_streak', Icons.local_fire_department_rounded, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4.w),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildMissionHUD() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMiniStat('المستوى', '$_currentLevel'),
          _buildMiniStat('النقاط', '$_score'),
          _buildMiniStat('الدقة', '${(_timerProgress * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white24, fontSize: 10.sp, fontFamily: 'Cairo')),
        Text(value, style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGameField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_objects.isNotEmpty && _objects[0].position == Offset.zero) {
          _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
          _positionObjects();
        }
        return Stack(
          children: _objects.map((obj) => _buildObjectWidget(obj)).toList(),
        );
      },
    );
  }

  void _positionObjects() {
    double padding = 50.r;
    for (var i = 0; i < _objects.length; i++) {
      _objects[i] = _objects[i].copyWith(
        position: Offset(
          padding + _random.nextDouble() * (_fieldSize.width - padding * 2),
          padding + _random.nextDouble() * (_fieldSize.height - padding * 2),
        ),
      );
    }
  }

  Widget _buildObjectWidget(HawkObject obj) {
    bool showReal = _gameState == HawkGameState.observation || 
                    _gameState == HawkGameState.success || 
                    _gameState == HawkGameState.failure;
    
    // In selection/memory phase, all objects look identical to force memory usage
    Color displayColor = showReal ? obj.color : const Color(0xFF00F2FF);
    IconData displayIcon = showReal ? obj.icon : Icons.star_rounded;
    double displayRotation = showReal ? obj.rotation : 0.0;
    double displaySize = showReal ? obj.size : 35.r;

    bool isHidden = _gameState == HawkGameState.memory;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      left: obj.position.dx,
      top: obj.position.dy,
      child: GestureDetector(
        onTap: () => _onObjectTap(obj),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isHidden ? 0.0 : 1.0,
          child: Transform.rotate(
            angle: displayRotation,
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
                boxShadow: [
                  if (obj.isTarget && _gameState == HawkGameState.success)
                    BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 20),
                ],
              ),
              child: Icon(
                displayIcon,
                color: displayColor,
                size: displaySize,
              ).animate(onPlay: (c) => obj.isTarget && _gameState == HawkGameState.observation ? c.repeat(reverse: true) : null)
               .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    String message = "";
    Color color = Colors.white;

    switch (_gameState) {
      case HawkGameState.observation:
        message = "ابحث عن العنصر المختلف...";
        color = const Color(0xFF00F2FF);
        break;
      case HawkGameState.memory:
        message = "تذكر موقعه جيداً!";
        color = const Color(0xFFBC00FF);
        break;
      case HawkGameState.selection:
        message = "أين كان العنصر المختلف؟";
        color = Colors.amberAccent;
        break;
      case HawkGameState.success:
        message = "رائع! رصد دقيق";
        color = const Color(0xFF00FF95);
        break;
      case HawkGameState.failure:
        message = "حاول التركيز أكثر";
        color = Colors.redAccent;
        break;
      default:
        message = "";
    }

    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(color: color, fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ).animate(onPlay: (c) => c.repeat()).shimmer(),
          SizedBox(height: 20.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _timerProgress,
              minHeight: 6.h,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                _timerProgress > 0.3 ? const Color(0xFF00F2FF) : Colors.redAccent,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          if (_gameState == HawkGameState.idle)
            ElevatedButton(
              onPressed: () => _startNewRound(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F2FF),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              ),
              child: const Text('ابدأ المهمة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ),
        ],
      ),
    );
  }
}
