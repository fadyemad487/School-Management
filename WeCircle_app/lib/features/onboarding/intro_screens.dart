import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';

const List<Color> _weCircleIntroGradient = [
  Color(0xFF1D4ED8),
  Color(0xFF7C3AED),
];

class IntroPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? lottiePath;
  final double lottieScale;
  final Offset lottieOffset;
  final List<_FloatItem> floatItems;

  const IntroPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.lottiePath,
    this.lottieScale = 1.0,
    this.lottieOffset = Offset.zero,
    required this.floatItems,
  });
}

class _FloatItem {
  final IconData icon;
  final String label;
  final Alignment alignment;
  final double size;
  const _FloatItem(this.icon, this.label, this.alignment, this.size);
}

List<IntroPage> getIntroPages(bool isArabic) {
  return [
    IntroPage(
      title: isArabic ? 'مرحباً بك في WeCircle' : 'Welcome to WeCircle',
      subtitle: isArabic
          ? 'منصة تعليمية متكاملة تربط بين ولي الأمر والمعلم لمتابعة أفضل لأبنائكم'
          : 'An integrated educational platform connecting parents and teachers for better tracking of your children',
      icon: Icons.school_rounded,
      color: const Color(0xFF1D4ED8), // Royal Blue
      bgColor: const Color(0xFF1D4ED8).withOpacity(0.08),
      lottiePath: 'assets/animations/welcome_animation.json',
      floatItems: const [],
    ),
    IntroPage(
      title: isArabic ? 'الحضور والواجبات' : 'Attendance & Homework',
      subtitle: isArabic
          ? 'تابع حضور طفلك يومياً وتأكد من إنجاز الواجبات في الوقت المحدد مع تنبيهات فورية'
          : 'Track your child\'s daily attendance and ensure homework is completed on time with instant alerts',
      icon: Icons.fact_check_rounded,
      color: const Color(0xFF1D4ED8),
      bgColor: const Color(0xFF1D4ED8).withOpacity(0.08),
      lottiePath: 'assets/animations/attendance_animation.json',
      floatItems: const [],
    ),
    IntroPage(
      title: isArabic ? 'الدرجات والتقارير' : 'Grades & Reports',
      subtitle: isArabic
          ? 'اطّلع على درجات أبنائك في الامتحانات والواجبات وتحليل مستوى أدائهم الأكاديمي'
          : 'View your children\'s grades in exams and assignments and analyze their academic performance level',
      icon: Icons.bar_chart_rounded,
      color: const Color(0xFF7C3AED),
      bgColor: const Color(0xFF7C3AED).withOpacity(0.08),
      lottiePath: 'assets/animations/grades_animation.json',
      floatItems: const [],
    ),
    IntroPage(
      title: isArabic ? 'التواصل والإشعارات' : 'Communication & Notifications',
      subtitle: isArabic
          ? 'تعرف على سلوكيات ابنك وطورها خطوة بخطوة، مع إشعارات فورية من المدرسة'
          : 'Learn about your child\'s behaviors and develop them step by step, with instant notifications from the school',
      icon: Icons.chat_bubble_rounded,
      color: const Color(0xFF1D4ED8),
      bgColor: const Color(0xFF1D4ED8).withOpacity(0.08),
      lottiePath: 'assets/animations/communication_animation.json',
      floatItems: const [],
    ),
    IntroPage(
      title: isArabic ? 'المساعد الذكي' : 'Smart Assistant',
      subtitle: isArabic
          ? 'اسأل عن أي مشكلة تخص ابنك وخد نصائح تربوية فورية تساعدك تتعامل معاه بشكل أفضل'
          : 'Ask about any issue concerning your child and get instant educational tips to help you handle them better',
      icon: Icons.smart_toy_rounded,
      color: const Color(0xFF7C3AED),
      bgColor: const Color(0xFF7C3AED).withOpacity(0.08),
      lottiePath: 'assets/animations/chatbot_animation.json',
      floatItems: const [],
    ),
    IntroPage(
      title: isArabic ? 'الباص والنشاطات' : 'Bus & Activities',
      subtitle: isArabic
          ? 'تتبع موقع الباص المدرسي مباشرةً واطّلع على الرحلات والأنشطة والمناسبات المدرسية'
          : 'Track the school bus location live and view trips, activities, and school events',
      icon: Icons.directions_bus_rounded,
      color: const Color(0xFF1D4ED8),
      bgColor: const Color(0xFF1D4ED8).withOpacity(0.08),
      lottiePath: 'assets/animations/bus_animation.json',
      floatItems: const [],
    ),
  ];
}

class IntroScreens extends StatefulWidget {
  const IntroScreens({super.key});

  @override
  State<IntroScreens> createState() => _IntroScreensState();
}

class _IntroScreensState extends State<IntroScreens>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconAnimations;
  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      6,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );
    _iconAnimations = _iconControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.elasticOut))
        .toList();
    _iconControllers[0].forward();

  }

  @override
  void dispose() {
    for (var c in _iconControllers) c.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final pages = getIntroPages(isArabic);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Skip button row
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
                        TextButton(
                          onPressed: _navigateToLogin,
                          child: Text(
                            isArabic ? 'تخطى' : 'Skip',
                            style: GoogleFonts.cairo(
                              color: AppColors.textMedium,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _iconControllers[index].forward(from: 0);
                      },
                      itemBuilder: (_, index) => _IntroPageWidget(
                          page: pages[index], animation: _iconAnimations[index]),
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                    child: Column(
                      children: [
                        // Indicator
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: pages.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: _weCircleIntroGradient.first,
                            dotColor: AppColors.textMuted,
                            dotHeight: 8.h,
                            dotWidth: 8.w,
                            expansionFactor: 3,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Next button
                        SizedBox(
                          width: double.infinity,
                          height: 46.h,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _weCircleIntroGradient,
                              ),
                              borderRadius: BorderRadius.circular(23.r), // Pill shape matching login
                              boxShadow: [
                                BoxShadow(
                                  color: pages[_currentPage].color.withOpacity(0.35),
                                  blurRadius: 16.r,
                                  offset: Offset(0, 6.h),
                                )
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _goToNext,
                                borderRadius: BorderRadius.circular(23.r),
                                child: Center(
                                  child: Text(
                                    _currentPage == pages.length - 1
                                        ? (isArabic ? 'ابدأ الآن 🚀' : 'Start Now 🚀')
                                        : (isArabic ? 'التالي' : 'Next'),
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPageWidget extends StatelessWidget {
  final IntroPage page;
  final Animation<double> animation;

  const _IntroPageWidget({required this.page, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 8.h),
          // Illustration area
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [

                // Floating mini icons
                ..._buildFloatItems(page.floatItems, animation),
                // Main icon or Lottie
                AnimatedBuilder(
                  animation: animation,
                  builder: (_, __) => Transform.scale(
                    scale: animation.value * page.lottieScale,
                    child: Transform.translate(
                      offset: page.lottieOffset,
                      child: page.lottiePath != null
                          ? Lottie.asset(
                              page.lottiePath!,
                              width: 220.w,
                              height: 220.h,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80.r,
                                  height: 80.r,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _weCircleIntroGradient,
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Icon(page.icon,
                                      color: Colors.white, size: 42.r),
                                );
                              },
                            )
                          : Container(
                              width: 80.r,
                              height: 80.r,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _weCircleIntroGradient,
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: page.color.withOpacity(0.4),
                                    blurRadius: 20.r,
                                    offset: Offset(0, 8.h),
                                  ),
                                ],
                              ),
                              child: Icon(page.icon,
                                  color: Colors.white, size: 42.r),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Text area
          Expanded(
            flex: 3,
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: AppColors.textMedium,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatItems(
      List<_FloatItem> items, Animation<double> animation) {
    return items.map((item) {
      final offset = _alignToOffset(item.alignment);
      return AnimatedBuilder(
        animation: animation,
        builder: (_, __) => Transform.translate(
          offset:
              Offset(offset.dx * animation.value, offset.dy * animation.value),
          child: Transform.scale(
            scale: animation.value,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 24.r, color: Colors.white),
                  SizedBox(height: 2.h),
                  Text(
                    item.label,
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Offset _alignToOffset(Alignment alignment) {
    return Offset(alignment.x * 100.w, alignment.y * 100.h);
  }
}
