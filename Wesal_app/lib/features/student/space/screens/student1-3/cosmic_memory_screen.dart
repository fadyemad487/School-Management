import 'dart:math' as math;
import 'dart:ui';
/*
🧠 اسم الملف: cosmic_memory_screen.dart

📌 بيعمل إيه؟
لعبة "الذاكرة الكونية" اللي بتختبر قوة ملاحظة الطفل وذاكرته عن طريق ترتيب الأشكال والألوان.

👤 موجه لمين؟
- طلاب (المرحلة من 1 لـ 3 ابتدائي)

💡 فكرته:
تنشيط الذاكرة قصيرة المدى وزيادة حدة الانتباه عند الأطفال.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/student1-3/animated_space_background.dart';

class CosmicMemoryScreen extends StatefulWidget {
  const CosmicMemoryScreen({super.key});

  @override
  State<CosmicMemoryScreen> createState() => _CosmicMemoryScreenState();
}

enum GameState { idle, showingSequence, waitingInput, success, failed }

class _CosmicMemoryScreenState extends State<CosmicMemoryScreen> {
  final math.Random _rng = math.Random();
  final int _gridSize = 9; // 3x3 memory pads

  final List<int> _sequence = [];
  int _playerIndex = 0;
  int _level = 1;
  int _score = 0;
  int _combo = 0;

  GameState _gameState = GameState.idle;
  int? _activePad;
  bool _isSuccessAnim = false;
  bool _isFailAnim = false;

  final List<Color> _padColors = [
    const Color(0xFF00D2FF), // Cyan
    const Color(0xFFFF1744), // Red
    const Color(0xFF00E676), // Green
    const Color(0xFFFFB300), // Amber
    const Color(0xFFE040FB), // Purple
    const Color(0xFF2979FF), // Blue
    const Color(0xFFFF4081), // Pink
    const Color(0xFF76FF03), // Light Green
    const Color(0xFFFF9100), // Orange
  ];

  final List<IconData> _padIcons = [
    Icons.star_rounded,
    Icons.bolt_rounded,
    Icons.local_fire_department_rounded,
    Icons.shield_rounded,
    Icons.diamond_rounded,
    Icons.eco_rounded,
    Icons.favorite_rounded,
    Icons.sports_esports_rounded,
    Icons.explore_rounded,
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), _startNewLevel);
  }

  void _startNewLevel() async {
    setState(() {
      _gameState = GameState.idle;
      _playerIndex = 0;
      _isSuccessAnim = false;
      _isFailAnim = false;
      _sequence.add(_rng.nextInt(_gridSize));
    });

    await Future.delayed(const Duration(milliseconds: 500));
    _playSequence();
  }

  void _playSequence() async {
    setState(() {
      _gameState = GameState.showingSequence;
    });

    int speedMs = math.max(250, 800 - (_level * 60));

    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      setState(() {
        _activePad = _sequence[i];
      });
      HapticFeedback.selectionClick();
      await Future.delayed(Duration(milliseconds: speedMs));

      if (!mounted) return;
      setState(() {
        _activePad = null;
      });
      await Future.delayed(Duration(milliseconds: speedMs ~/ 2));
    }

    if (!mounted) return;
    setState(() {
      _gameState = GameState.waitingInput;
    });
  }

  void _onPadTapped(int index) async {
    if (_gameState != GameState.waitingInput) return;

    setState(() {
      _activePad = index;
    });
    HapticFeedback.lightImpact();

    if (index == _sequence[_playerIndex]) {
      // Correct
      _playerIndex++;
      _score += 10 + (_combo * 5);
      _combo++;

      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _activePad = null;
      });

      if (_playerIndex == _sequence.length) {
        _handleLevelSuccess();
      }
    } else {
      // Wrong
      _handleFailure();
    }
  }

  void _handleLevelSuccess() async {
    setState(() {
      _gameState = GameState.success;
      _isSuccessAnim = true;
      _activePad = null;
      _level++;
    });
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _startNewLevel();
    }
  }

  void _handleFailure() async {
    setState(() {
      _gameState = GameState.failed;
      _isFailAnim = true;
      _combo = 0;
    });
    HapticFeedback.vibrate();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isFailAnim = false;
        _playerIndex = 0;
      });
      _playSequence();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03001C),
      body: Stack(
        children: [
          const AnimatedSpaceBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 10.h),
                _buildScoreBoard(),
                SizedBox(height: 20.h),
                _buildStatusMessage(),
                Expanded(child: Center(child: _buildGameGrid())),
                SizedBox(height: 20.h),
              ],
            ),
          ),

          // Success Particles Overlay
          if (_isSuccessAnim)
            Positioned.fill(
              child: Center(
                child:
                    const Icon(
                          Icons.verified_rounded,
                          color: Colors.greenAccent,
                          size: 180,
                        )
                        .animate(onPlay: (c) => c.forward())
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.2, 1.2),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeOut(delay: 1200.ms, duration: 400.ms),
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'تحدي الذاكرة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: Colors.purpleAccent.withValues(alpha: 0.8),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'المستوى',
                  '$_level',
                  Icons.military_tech,
                  Colors.cyan,
                ),
                Container(width: 1, height: 40.h, color: Colors.white24),
                _buildStatItem(
                  'النقاط',
                  '$_score',
                  Icons.stars_rounded,
                  Colors.amber,
                ),
                Container(width: 1, height: 40.h, color: Colors.white24),
                _buildStatItem(
                  'كومبو',
                  'x$_combo',
                  Icons.local_fire_department,
                  Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16.sp),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
              ),
            )
            .animate(key: ValueKey(value))
            .scale(duration: 200.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildGameGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.w),
      child: AspectRatio(
        aspectRatio: 1, // Make it a perfect square grid
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 15.w,
            crossAxisSpacing: 15.w,
          ),
          itemCount: _gridSize,
          itemBuilder: (context, index) {
            final isActive = _activePad == index;
            final color = _padColors[index];
            final icon = _padIcons[index];

            Widget pad = GestureDetector(
              onTapDown: (_) {
                if (_gameState == GameState.waitingInput) {
                  setState(() => _activePad = index);
                }
              },
              onTapCancel: () {
                if (_gameState == GameState.waitingInput) {
                  setState(() => _activePad = null);
                }
              },
              onTap: () => _onPadTapped(index),
              child: AnimatedScale(
                scale: isActive ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive
                          ? [color.withValues(alpha: 0.8), color]
                          : [
                              color.withValues(alpha: 0.15),
                              color.withValues(alpha: 0.05),
                            ],
                    ),
                    border: Border.all(
                      color: isActive
                          ? Colors.white
                          : color.withValues(alpha: 0.3),
                      width: isActive ? 3 : 1.5,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: isActive ? 45.sp : 35.sp,
                      color: isActive
                          ? Colors.white
                          : color.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            );

            if (_isFailAnim && isActive) {
              pad = pad.animate().shake(duration: 400.ms, hz: 6);
            }

            return pad;
          },
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    String text = "";
    Color color = Colors.white;
    IconData statusIcon = Icons.info_outline;

    switch (_gameState) {
      case GameState.idle:
        text = "استعد للمستوى القادم...";
        statusIcon = Icons.hourglass_empty;
        break;
      case GameState.showingSequence:
        text = "ركز واحفظ الترتيب!";
        color = Colors.cyanAccent;
        statusIcon = Icons.visibility;
        break;
      case GameState.waitingInput:
        text = "دورك! كرر النمط";
        color = Colors.greenAccent;
        statusIcon = Icons.touch_app;
        break;
      case GameState.success:
        text = "أداء رائع ومبهر 🌟";
        color = Colors.amberAccent;
        statusIcon = Icons.star;
        break;
      case GameState.failed:
        text = "خطأ! حاول مرة أخرى";
        color = Colors.redAccent;
        statusIcon = Icons.warning_amber_rounded;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<String>(text),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: color, size: 20.sp),
            SizedBox(width: 10.w),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
