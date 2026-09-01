/*
🧠 اسم الملف: captain_calm_screen.dart

📌 بيعمل إيه؟
دي لعبة "القائد الهادئ" اللي بتعلم الطفل إزاي يتحكم في مشاعره وقت الغضب أو التوتر عن طريق تمارين تنفس بسيطة.

👤 موجه لمين؟
- طلاب (المرحلة من 1 لـ 3 ابتدائي)

💡 فكرته:
تحسين الذكاء العاطفي عند الطفل وتعليمه الهدوء والسكينة بشكل تفاعلي.
*/

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/student1-3/animated_space_background.dart';

class CaptainCalmScreen extends StatefulWidget {
  const CaptainCalmScreen({super.key});

  @override
  State<CaptainCalmScreen> createState() => _CaptainCalmScreenState();
}

class _CaptainCalmScreenState extends State<CaptainCalmScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _shakeController;

  bool _isPressed = false;
  bool _isSuccess = false;
  bool _isFailed = false;

  final double _movementThreshold = 3.5; // Sensitivity to movement
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
    // 20 Seconds challenge
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..addListener(() {
        if (_progressController.isCompleted && !_isSuccess) {
          _onSuccess();
        }
        setState(() {});
      });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onSuccess() {
    setState(() {
      _isSuccess = true;
      _isPressed = false;
    });
    HapticFeedback.heavyImpact();
    // In a real app, play success sound and show particles here
  }

  void _onPanStart(DragDownDetails details) {
    if (_isSuccess) return;
    setState(() {
      _isPressed = true;
      _isFailed = false;
      _lastPosition = details.globalPosition;
    });
    HapticFeedback.lightImpact();
    _progressController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isPressed || _isSuccess) return;

    final currentPosition = details.globalPosition;
    if (_lastPosition != null) {
      final distance = (currentPosition - _lastPosition!).distance;
      if (distance > _movementThreshold) {
        // Failed - moved too much
        _triggerFail();
      }
    }
    _lastPosition = currentPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSuccess || !_isPressed) return;
    _triggerFail();
  }

  void _triggerFail() {
    setState(() {
      _isPressed = false;
      _isFailed = true;
    });
    HapticFeedback.vibrate();
    _progressController.reverse();
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Current state color
    Color glowColor = const Color(0xFF00E676); // Green by default
    if (_isFailed) glowColor = const Color(0xFFFF1744); // Red on fail
    if (_isSuccess) glowColor = const Color(0xFF00D2FF); // Cyan on success

    return Scaffold(
      backgroundColor: const Color(0xFF03001C),
      body: Stack(
        children: [
          // 1. Futuristic Space Background
          const AnimatedSpaceBackground(),

          // 2. Cosmic Dust Particles (simulated using Animate)
          if (_isSuccess)
            Positioned.fill(
              child: Center(
                child: const Icon(Icons.star, color: Colors.white, size: 100)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                        begin: const Offset(1, 1), end: const Offset(1.5, 1.5))
                    .fadeOut(duration: 1.seconds),
              ),
            ),

          // 3. UI Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) {
                        final dx = math.sin(_shakeController.value * math.pi * 4) * 10;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onPanDown: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onPanCancel: () {
                          if (_isPressed) _triggerFail();
                        },
                        child: _buildEnergyBubble(glowColor),
                      ),
                    ),
                  ),
                ),
                _buildInstructions(),
                SizedBox(height: 50.h),
              ],
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'تحدي القبطان الهادئ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.cyan.withValues(alpha: 0.8), blurRadius: 10),
              ],
            ),
          ),
          SizedBox(width: 48.w), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildEnergyBubble(Color glowColor) {
    final double size = 250.r;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing background glow
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isPressed ? size * 1.1 : size,
          height: _isPressed ? size * 1.1 : size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.4),
                blurRadius: _isPressed ? 50 : 20,
                spreadRadius: _isPressed ? 10 : 5,
              ),
            ],
          ),
        ),

        // Progress Ring
        SizedBox(
          width: size + 20,
          height: size + 20,
          child: CircularProgressIndicator(
            value: _progressController.value,
            strokeWidth: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(glowColor),
          ),
        ),

        // Inner Bubble
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glowColor.withValues(alpha: 0.1),
                glowColor.withValues(alpha: 0.3),
              ],
            ),
            border: Border.all(
              color: glowColor.withValues(alpha: 0.8),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Alien Image
                Image.asset(
                  'assets/images/memory_portal.png',
                  width: size * 0.7,
                  fit: BoxFit.contain,
                )
                    .animate(target: _isPressed ? 1 : 0)
                    .scale(end: const Offset(1.05, 1.05), duration: 200.ms),

                // Success Overlay Overlay
                if (_isSuccess)
                  Container(
                    color: Colors.white.withValues(alpha: 0.2),
                  ).animate().fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    String text = "ضع إصبعك على الفضائي وابقَ هادئاً";
    Color textColor = Colors.white70;

    if (_isSuccess) {
      text = "عمل رائع! أنت قبطان هادئ بامتياز 🌟";
      textColor = const Color(0xFF00D2FF);
    } else if (_isFailed) {
      text = "لقد تحركت بسرعة! حاول أن تكون أهدأ ⚠️";
      textColor = const Color(0xFFFF1744);
    } else if (_isPressed) {
      final secondsLeft = 20 - (_progressController.value * 20).floor();
      text = "حافظ على هدوئك... $secondsLeft ثانية";
      textColor = const Color(0xFF00E676);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        text,
        key: ValueKey<String>(text),
        style: TextStyle(
          color: textColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
