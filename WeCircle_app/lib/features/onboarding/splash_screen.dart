import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import 'intro_screens.dart';
import '../auth/auth_service.dart';
import '../parent/parent_main.dart';
import '../teacher/teacher_main.dart';
import '../driver/driver_dashboard_screen.dart';
import '../supervisor/supervisor_dashboard_screen.dart';
import '../student/student_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/biometrics_unlock_screen.dart';
import '../../core/network/socket_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _dotsController;
  late Animation<double> _textFade;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    _textController.forward();

    // Loading rotation/pulse animation controller
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.2).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.8).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_dotsController);

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 4000), () async {
      if (!mounted) return;

      // Check if user has a remembered session
      final isRemembered = await AuthService.isRemembered();
      if (isRemembered) {
        final role = await AuthService.getRememberedRole();
        final prefs = await SharedPreferences.getInstance();
        final useBiometrics = prefs.getBool('use_biometrics') ?? false;

        Widget targetMain;
        if (useBiometrics) {
          targetMain = BiometricsUnlockScreen(role: role ?? 'PARENT');
        } else {
          if (role == 'TEACHER') {
            targetMain = const TeacherMain();
          } else if (role == 'DRIVER') {
            targetMain = const DriverDashboardScreen();
          } else if (role == 'BUS_SUPERVISOR') {
            targetMain = const SupervisorDashboardScreen();
          } else if (role == 'STUDENT') {
            targetMain = const StudentMain();
          } else {
            targetMain = const ParentMain();
          }
        }
        // Connect to global Real-time service on startup
        SocketService().connect();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => targetMain,
              transitionsBuilder: (_, animation, __, child) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      } else {
        // Clear session fields if not remembered to ensure clean state on next login
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('school_id');
        await prefs.remove('school_name');
        await prefs.remove('school_code');
        await prefs.remove('user_role');
        await prefs.remove('user_fullname');
        await prefs.remove('remember_me');
        await prefs.remove('use_biometrics');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const IntroScreens(),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie Animation
                  SizedBox(
                    width: 220.w,
                    height: 220.h,
                    child: Lottie.asset(
                      'assets/animations/splash_animation.json',
                      fit: BoxFit.contain,
                      frameRate: FrameRate.max,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.school_rounded, size: 70.r, color: AppColors.primary);
                      },
                    ),
                  ),
                  
                  SizedBox(height: 10.h),
                  
                  // Animated Text & Branding
                  FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          isArabic ? 'WeCircle' : 'WeCircle',
                          style: GoogleFonts.cairo(
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            isArabic ? 'مستقبل التعليم بين يديك' : 'The future of education in your hands',
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMedium,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Sleek High-Tech Glowing Linear Loader
            Positioned(
              bottom: 95.h,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFade,
                child: Center(
                  child: Column(
                    children: [
                      // Progress Bar Container
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Ambient Glow behind the bar (moves with the loader)
                          AnimatedBuilder(
                            animation: _dotsController,
                            builder: (context, child) {
                              return FractionalTranslation(
                                translation: Offset(-1.5 + (_dotsController.value * 3.0), 0.0),
                                child: Container(
                                  width: 60.w,
                                  height: 6.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.r),
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF06B6D4).withOpacity(0.4),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // 2. The Main Track and Sweeping Laser Beam
                          Container(
                            width: 180.w,
                            height: 3.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              color: AppColors.border.withOpacity(0.5),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AnimatedBuilder(
                              animation: _dotsController,
                              builder: (context, child) {
                                return FractionalTranslation(
                                  translation: Offset(-1.5 + (_dotsController.value * 3.0), 0.0),
                                  child: Container(
                                    width: 70.w,
                                    height: 3.h,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.r),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Color(0xFF06B6D4), // Cyan
                                          Color(0xFF7C3AED), // Purple
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
