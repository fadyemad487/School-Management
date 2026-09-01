import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../parent/parent_main.dart';
import '../teacher/teacher_main.dart';
import 'auth_service.dart';

class BiometricsUnlockScreen extends StatefulWidget {
  final String role;
  const BiometricsUnlockScreen({super.key, required this.role});

  @override
  State<BiometricsUnlockScreen> createState() => _BiometricsUnlockScreenState();
}

class _BiometricsUnlockScreenState extends State<BiometricsUnlockScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  bool _isScanning = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Auto trigger scan on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVerification();
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _hasFailed = false;
    });

    // Simulate scanning for a premium feel
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    // Simulate successful biometrics verification
    setState(() {
      _isScanning = false;
    });

    _proceedToMain();
  }

  void _proceedToMain() {
    Widget target;
    if (widget.role == 'TEACHER') {
      target = const TeacherMain();
    } else {
      target = const ParentMain();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => target,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B12), // Deep premium dark background
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Stack(
          children: [
            // Top Glow
            Positioned(
              top: -50.h,
              right: -50.w,
              width: 300.w,
              height: 300.w,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Glow
            Positioned(
              bottom: -50.h,
              left: -50.w,
              width: 300.w,
              height: 300.w,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C3AED).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // Brand Name
                    Text(
                      'WeCircle',
                      style: GoogleFonts.cairo(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'مؤمّن بواسطة WeCircle Shield',
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),

                    const Spacer(),

                    // Scanner Area
                    GestureDetector(
                      onTap: _startVerification,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple animation
                          AnimatedBuilder(
                            animation: _scanController,
                            builder: (context, child) {
                              return Container(
                                width: 140.r * _pulseAnimation.value,
                                height: 140.r * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (_isScanning
                                      ? AppColors.primary
                                      : (_hasFailed ? AppColors.rose : AppColors.emerald))
                                      .withOpacity(0.08),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _scanController,
                            builder: (context, child) {
                              return Container(
                                width: 110.r * (1.0 + (_pulseAnimation.value - 1.0) * 0.5),
                                height: 110.r * (1.0 + (_pulseAnimation.value - 1.0) * 0.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (_isScanning
                                      ? AppColors.primary
                                      : (_hasFailed ? AppColors.rose : AppColors.emerald))
                                      .withOpacity(0.12),
                                ),
                              );
                            },
                          ),
                          // Core Scanner Button
                          Container(
                            width: 86.r,
                            height: 86.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isScanning
                                    ? [AppColors.primary, const Color(0xFF3B82F6)]
                                    : (_hasFailed
                                        ? [AppColors.rose, const Color(0xFFEF4444)]
                                        : [AppColors.emerald, const Color(0xFF10B981)]),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isScanning
                                      ? AppColors.primary
                                      : (_hasFailed ? AppColors.rose : AppColors.emerald))
                                      .withOpacity(0.4),
                                  blurRadius: 20.r,
                                  offset: Offset(0, 8.h),
                                )
                              ],
                            ),
                            child: Icon(
                              _isScanning
                                  ? Icons.face_retouching_natural_rounded
                                  : Icons.fingerprint_rounded,
                              color: Colors.white,
                              size: 40.r,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Help Text
                    Text(
                      _isScanning
                          ? 'جاري التحقق من الهوية الحيوية...'
                          : (_hasFailed
                              ? 'فشل التحقق، اضغط لإعادة المحاولة'
                              : 'يرجى تأكيد البصمة أو Face ID للدخول'),
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'ضع إصبعك على المستشعر أو دع الكاميرا تتعرف على وجهك',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.5),
                        height: 1.5,
                      ),
                    ),

                    const Spacer(),

                    // Enter Password fallback
                    TextButton(
                      onPressed: () async {
                        // Clear session and go to intro/login to re-authenticate manually
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.6),
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      ),
                      child: Text(
                        'تسجيل الدخول بكلمة المرور',
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
