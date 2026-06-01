import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../parent/parent_main.dart';
import '../teacher/teacher_main.dart';
import '../driver/driver_dashboard_screen.dart';
import '../supervisor/supervisor_dashboard_screen.dart';
import '../student/student_main.dart';
import 'forgot_password_screen.dart';
import 'auth_service.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _obscurePassword = true;
  bool _isPhoneInput = false;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  bool _rememberMe = false;
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  List<String> _emailSuggestions = [];
  final List<String> _domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com'];

  // Animation Controllers
  late AnimationController _entranceController;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_handleInputChange);

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null && session.user != null) {
        final email = session.user!.email;
        final provider = session.user!.appMetadata?['provider'] ?? 'google';
        final socialId = 'social_${provider}_${session.user!.id}';
        if (email != null) {
          _processSocialLoginApi(provider, email, socialId);
        }
      }
    });

    // 1. Screen entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();

  }

  void _handleInputChange() {
    String text = _identifierController.text;
    
    // Check if it's a phone number (only digits)
    bool isPhone = text.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(text);
    if (isPhone != _isPhoneInput) {
      setState(() {
        _isPhoneInput = isPhone;
      });
    }

    // Handle email suggestions
    if (text.contains('@')) {
      String parts = text.split('@').last;
      String prefix = text.split('@').first;
      setState(() {
        _emailSuggestions = _domains
            .where((d) => d.startsWith(parts) && d != parts)
            .map((d) => '$prefix@$d')
            .toList();
      });
    } else {
      if (_emailSuggestions.isNotEmpty) {
        setState(() {
          _emailSuggestions = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _handleAuth() async {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    setState(() {
      _isSubmitting = true;
    });

    final authService = AuthService();
    final result = await authService.login(
      _identifierController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
      }
      
      // Keep the stunning green checkmark visible for 1 second for premium UX satisfaction
      await Future.delayed(const Duration(milliseconds: 1000));

      final String role = result['role'];
      Widget targetMain;
      
      // Dynamic Navigation based on database credential role
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

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => targetMain,
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? (isArabic ? 'فشل تسجيل الدخول، يرجى المحاولة لاحقاً' : 'Login failed, please try again later'),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFEA4335),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _processSocialLoginApi(String provider, String email, String socialId) async {
    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    final authService = AuthService();
    final result = await authService.socialLogin(
      provider,
      email,
      socialId,
      rememberMe: _rememberMe,
    );

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 1000));

      final String role = result['role'];
      Widget targetMain;
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

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => targetMain,
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? (isArabic ? 'هذا الحساب غير مربوط بأي ولي أمر.' : 'Account not linked.'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.rose,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleSocialAuth(String provider) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider == 'google' ? OAuthProvider.google : OAuthProvider.apple,
        redirectTo: 'io.supabase.wesal://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: const {'prompt': 'select_account'},
      );
    } catch (e) {
      // Ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: AnimatedBuilder(
                      animation: _entranceAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _entranceAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 30.h * (1.0 - _entranceAnimation.value)),
                            child: child,
                          ),
                        );
                      },
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                      SizedBox(height: 24.h),

                      // A. Sleek modern Centered Logo & Text
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 90.w,
                              height: 90.w,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, -12.h),
                            child: Text(
                              'WeCircle',
                              style: GoogleFonts.outfit(
                                fontSize: 34.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 36.h),

                      // B. Welcome titles matching mockup
                      Center(
                        child: Text(
                          isArabic ? 'مرحباً بك!' : 'Welcome back!',
                          style: GoogleFonts.cairo(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Center(
                        child: Text(
                          isArabic ? 'يرجى إدخال البيانات المطلوبة للاستمرار' : 'Please enter requested credentials to continue',
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // F. Glassmorphic Pill Inputs
                      _CustomInputField(
                        hintText: isArabic ? 'id الدخول الخاص بك' : 'Your Login ID',
                        controller: _identifierController,
                        keyboardType: TextInputType.text,
                        prefixIcon: Icon(
                          Icons.vpn_key_outlined,
                          color: AppColors.textLight,
                          size: 18.r,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isArabic ? 'يرجى إدخال id الدخول' : 'Please enter your login ID';
                          }
                          return null;
                        },
                      ),

                      // Email Suggestion chips
                      if (_emailSuggestions.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        SizedBox(
                          height: 38.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _emailSuggestions.length,
                            itemBuilder: (context, index) {
                              final email = _emailSuggestions[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _identifierController.text = email;
                                    _identifierController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: email.length),
                                    );
                                    _emailSuggestions = [];
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(left: 8.w),
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.82),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      email,
                                      style: GoogleFonts.cairo(
                                        color: AppColors.textDark,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      SizedBox(height: 16.h),

                      _CustomInputField(
                        hintText: isArabic ? 'كلمة المرور' : 'Password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textLight,
                          size: 18.r,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textLight,
                            size: 18.r,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isArabic ? 'يرجى إدخال كلمة المرور' : 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return isArabic ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // G-1. Remember Me checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 22.r,
                            height: 22.r,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                              activeColor: const Color(0xFF1D4ED8),
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: AppColors.textLight,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Text(
                              isArabic ? 'تذكرني' : 'Remember me',
                              style: GoogleFonts.cairo(
                                color: AppColors.textDark,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // G-2. Forgot Password
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                              style: GoogleFonts.cairo(
                                color: AppColors.primary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // H. Premium Luminous Pill Button ("تسجيل الدخول")
                      _PrimaryButton(
                        label: isArabic ? 'تسجيل الدخول' : 'Login',
                        isLoading: _isSubmitting,
                        isSuccess: _isSuccess,
                        onPressed: () {
                          if (_formKey.currentState!.validate() && !_isSubmitting && !_isSuccess) {
                            _handleAuth();
                          }
                        },
                      ),

                      SizedBox(height: 48.h),

                      // I. Terms Footer at the very bottom
                      const _TermsFooter(),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          );
              },
            ),
          ),
    );
  }
}

// ---------------- Custom Helper Widgets ----------------

class _CustomInputField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _CustomInputField({
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(24.r), // Pill-shaped
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              prefixIcon!,
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                validator: validator,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.cairo(
                    color: AppColors.textLight,
                    fontSize: 13.sp,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (suffixIcon != null) suffixIcon!,
          ],
        ),
      ),
    );
  }
}



class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isSuccess;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    this.isLoading = false,
    this.isSuccess = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double targetWidth = (isLoading || isSuccess) ? 46.h : constraints.maxWidth;
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.fastOutSlowIn,
            width: targetWidth,
            height: 46.h,
            decoration: BoxDecoration(
              // Stunning royal-blue to deep-purple gradient matching the dashboard precisely, or success emerald green
              gradient: LinearGradient(
                colors: isSuccess
                    ? const [
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ]
                    : const [
                        Color(0xFF1D4ED8),
                        Color(0xFF7C3AED),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(23.r), // Pill or circle shape depending on width
              boxShadow: [
                BoxShadow(
                  color: isSuccess
                      ? const Color(0xFF10B981).withOpacity(0.6)
                      : const Color(0xFF1D4ED8).withOpacity(isLoading ? 0.6 : 0.4),
                  blurRadius: (isLoading || isSuccess) ? 25 : 20,
                  offset: Offset(0, (isLoading || isSuccess) ? 10 : 8),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSuccess
                  ? Center(
                      key: const ValueKey('success'),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 24.r,
                      ),
                    )
                  : isLoading
                      ? Center(
                          key: const ValueKey('loading'),
                          child: SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.0,
                            ),
                          ),
                        )
                      : SizedBox(
                          key: const ValueKey('button'),
                          width: double.infinity,
                          height: double.infinity,
                          child: ElevatedButton(
                            onPressed: onPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23.r)),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white, // Ultra-clean white text on gradient background
                              ),
                            ),
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isGoogle;
  final VoidCallback onTap;

  const _SocialButton({
    this.icon,
    required this.label,
    this.isGoogle = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(22.r), // Pill shape
          border: Border.all(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              const _GoogleIcon()
            else
              Icon(icon, color: AppColors.textDark, size: 18.r),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18.w,
      height: 18.w,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Top-right Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), -0.8 * 3.14, 0.4 * 3.14, true, paint);
    // Bottom Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 0, 0.5 * 3.14, true, paint);
    // Left Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 0.5 * 3.14, 0.3 * 3.14, true, paint);
    // Top-left Green
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), -1.2 * 3.14, 0.4 * 3.14, true, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _TermsFooter extends StatelessWidget {
  const _TermsFooter();

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => const TermsScreen(),
                  transitionsBuilder: (_, animation, __, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: Text(
              isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
              style: GoogleFonts.cairo(
                color: AppColors.textMedium,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textLight,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              '|',
              style: GoogleFonts.cairo(
                color: AppColors.textMuted,
                fontSize: 12.sp,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => const PrivacyScreen(),
                  transitionsBuilder: (_, animation, __, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: Text(
              isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
              style: GoogleFonts.cairo(
                color: AppColors.textMedium,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
