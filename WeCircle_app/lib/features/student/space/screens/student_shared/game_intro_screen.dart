import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../student_game_state.dart';

class GameIntroStep {
  final String description;
  final Widget illustration;

  const GameIntroStep({
    required this.description,
    required this.illustration,
  });
}

class GameIntroScreen extends StatefulWidget {
  final String title;
  final List<GameIntroStep> steps;
  final Color color;
  final Widget gameScreen;

  const GameIntroScreen({
    super.key,
    required this.title,
    required this.steps,
    required this.color,
    required this.gameScreen,
  });

  @override
  State<GameIntroScreen> createState() => _GameIntroScreenState();
}

class _GameIntroScreenState extends State<GameIntroScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1528), // Dark purple/navy background
      body: Stack(
        children: [
          // Deep Space Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  const Color(0xFF1E1B33),
                  const Color(0xFF0F0C1D),
                  const Color(0xFF020108),
                ],
              ),
            ),
          ),

          // Animated Stars Overlay
          ...List.generate(15, (index) {
            final random = (index * 137) % 1000;
            return Positioned(
              left: (random % 100).w * 4,
              top: ((random ~/ 10) % 100).h * 8,
              child: Icon(
                Icons.star_rounded,
                color: Colors.white.withValues(alpha: 0.1),
                size: (random % 4 + 2).r,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .fadeIn(duration: (1000 + random % 2000).ms)
             .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2));
          }),
          
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 40.h),
                
                // Header Title
                Text(
                  'كيفية اللعب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),
                
                SizedBox(height: 10.h),
                
                // Game Title
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.color.withValues(alpha: 0.8),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ).animate().fadeIn(delay: 200.ms),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.steps.length,
                    itemBuilder: (context, index) {
                      final step = widget.steps[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Premium Illustration Card (Glassmorphism)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30.r),
                              child: Container(
                                height: 320.h,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Subtle glow in the background of the icon
                                    Center(
                                      child: Container(
                                        width: 150.r,
                                        height: 150.r,
                                        decoration: BoxDecoration(
                                          color: widget.color.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: widget.color.withValues(alpha: 0.2),
                                              blurRadius: 40,
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(child: step.illustration),
                                  ],
                                ),
                              ),
                            ).animate(key: ValueKey(index)).scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
                            
                            SizedBox(height: 30.h),
                            
                            // Step indicator badge
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: widget.color.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'الخطوة ${index + 1}',
                                style: TextStyle(color: widget.color, fontSize: 12.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
                            
                            SizedBox(height: 15.h),
                            
                            // Description text container
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Text(
                                step.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                  fontFamily: 'Cairo',
                                  shadows: [
                                    Shadow(color: Colors.black45, offset: const Offset(0, 2), blurRadius: 4),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Indicators
                SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.steps.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: widget.color,
                    dotColor: Colors.white24,
                    dotHeight: 8.h,
                    dotWidth: 8.h,
                    expansionFactor: 3,
                    spacing: 8.w,
                  ),
                ),
                
                SizedBox(height: 40.h),
                
                // Start Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
                  child: GestureDetector(
                    onTap: () async {
                      final gameState = context.read<StudentGameState>();
                      await gameState.addPoints(10);
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider<StudentGameState>.value(
                            value: gameState,
                            child: widget.gameScreen,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 65.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6EDD00),
                            const Color(0xFF4A9800),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5AB900).withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'بدء التحدي الآن',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28.sp),
                        ],
                      ),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .shimmer(duration: 2.seconds, color: Colors.white24)
                 .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 1.seconds),
                
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
