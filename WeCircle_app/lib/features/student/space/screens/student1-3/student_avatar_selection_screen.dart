import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../app_theme.dart';
import '../../state_manager.dart';
import '../../widgets/student1-3/animated_space_background.dart';

class StudentAvatarSelectionScreen extends StatefulWidget {
  const StudentAvatarSelectionScreen({super.key});

  @override
  State<StudentAvatarSelectionScreen> createState() =>
      _StudentAvatarSelectionScreenState();
}

class _StudentAvatarSelectionScreenState
    extends State<StudentAvatarSelectionScreen>
    with TickerProviderStateMixin {
  int _step = 0; // 0: Gender, 1: Avatar
  String? _selectedGender;
  String? _selectedAvatar;

  final List<Map<String, String>> _boyAvatars = [
    {'emoji': '👨‍🚀', 'name': 'رائد'},
    {'emoji': '🦸‍♂️', 'name': 'بطل'},
    {'emoji': '🤖', 'name': 'آلي'},
    {'emoji': '🥷', 'name': 'شجاع'},
    {'emoji': '🤴', 'name': 'فارس'},
    {'emoji': '🧑‍💻', 'name': 'عبقري'},
  ];

  final List<Map<String, String>> _girlAvatars = [
    {'emoji': '👩‍🚀', 'name': 'رائدة'},
    {'emoji': '🦸‍♀️', 'name': 'بطلة'},
    {'emoji': '👩‍🎨', 'name': 'مبدعة'},
    {'emoji': '👸', 'name': 'أميرة'},
    {'emoji': '🧚‍♀️', 'name': 'ساحرة'},
    {'emoji': '👩‍🔬', 'name': 'ذكية'},
  ];

  final List<Map<String, String>> _boyAvatarsGroupB = [
    {'image': 'assets/images/avatars/boy_hacker.jpg', 'name': 'المبرمج'},
    {'image': 'assets/images/avatars/boy_warrior.jpg', 'name': 'المقاتل'},
    {'image': 'assets/images/avatars/boy_gamer.jpg', 'name': 'الجيمر'},
  ];

  final List<Map<String, String>> _girlAvatarsGroupB = [
    {'image': 'assets/images/avatars/girl_gamer.jpg', 'name': 'الجيمر'},
    {'image': 'assets/images/avatars/girl_warrior.jpg', 'name': 'المقاتلة'},
    {'image': 'assets/images/avatars/girl_hacker.jpg', 'name': 'المبرمجة'},
  ];

  late AnimationController _fadeController;
  late AnimationController _gridController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  void _nextStep(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    _fadeController.reverse().then((_) {
      setState(() => _step = 1);
      _fadeController.forward();
    });
  }

  void _finish() {
    AppStateManager().selectedStudentAvatar.value = _selectedAvatar ?? '👨‍🚀';
    if (AppStateManager().selectedGradeLevel.value == '1-3') {
      Navigator.pushReplacementNamed(context, '/student_dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/student_dashboard_group_b');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGroupB = AppStateManager().selectedGradeLevel.value == '4-6';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF03001C),
        body: Stack(
          children: [
            const AnimatedSpaceBackground(),
            if (isGroupB)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _gridController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _GeometricGridPainter(animationValue: _gridController.value),
                    );
                  }
                ),
              ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _step == 0
                    ? _buildGenderSelection()
                    : _buildAvatarSelection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    final bool isGroupB = AppStateManager().selectedGradeLevel.value == '4-6';
    final Color primaryColor = isGroupB ? const Color(0xFF00F2FF) : const Color(0xFF00D2FF);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'أهلاً بك يا بطل! ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.sp,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                shadows: [
                  Shadow(color: primaryColor.withValues(alpha: 0.5), blurRadius: 15),
                ],
              ),
            ),
            if (!isGroupB)
              const Text('🌟', style: TextStyle(fontSize: 32))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.2, duration: 800.ms),
          ],
        ).animate().fade(duration: 500.ms).slideY(begin: -0.2),
        SizedBox(height: 12.h),
        Text(
          'أنت ولد ولا بنت؟',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ).animate().fade(delay: 300.ms).slideY(begin: -0.2),
        SizedBox(height: 60.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGenderCard('ولد', '👦', isGroupB ? const Color(0xFF00F2FF) : const Color(0xFF00D2FF), isGroupB)
                .animate()
                .fade(delay: 500.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            SizedBox(width: 24.w),
            _buildGenderCard('بنت', '👧', isGroupB ? const Color(0xFFFFD700) : const Color(0xFFE91E63), isGroupB)
                .animate()
                .fade(delay: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(String label, String emoji, Color color, bool isGroupB) {
    return GestureDetector(
      onTap: () => _nextStep(label),
      child: isGroupB 
      ? CustomPaint(
          painter: _SharpPolygonPainter(color: color),
          child: Container(
            width: 150.w,
            height: 180.h,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: 65.sp))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -5, end: 5, duration: 1500.ms),
                SizedBox(height: 16.h),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    shadows: [Shadow(color: color, blurRadius: 10)],
                  ),
                ),
              ],
            ),
          ),
        )
      : Container(
        width: 150.w,
        height: 180.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: 65.sp))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -5, end: 5, duration: 1500.ms),
            SizedBox(height: 16.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                shadows: [
                  Shadow(color: color, blurRadius: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSelection() {
    final grade = AppStateManager().selectedGradeLevel.value;
    final List<Map<String, String>> avatars;
    
    if (_selectedGender == 'ولد') {
      avatars = (grade == '4-6') ? _boyAvatarsGroupB : _boyAvatars;
    } else {
      avatars = (grade == '4-6') ? _girlAvatarsGroupB : _girlAvatars;
    }

    return Column(
      children: [
        SizedBox(height: 40.h),
        Text(
          grade == '4-6' ? 'اختر شخصيتك القتالية' : 'اختر شخصيتك الفضائية',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            shadows: [
              Shadow(color: const Color(0xFF00D2FF).withValues(alpha: 0.5), blurRadius: 15),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: -0.2),
        SizedBox(height: 8.h),
        Text(
          grade == '4-6' ? 'استعد للعمليات الخاصة' : 'هتكون مين في رحلة WeCircle؟',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ).animate().fade(delay: 200.ms).slideY(begin: -0.2),
        SizedBox(height: 30.h),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20.w,
              mainAxisSpacing: 20.h,
              mainAxisExtent: 160.h,
            ),
            itemCount: avatars.length,
            itemBuilder: (context, i) {
              final av = avatars[i];
              final String val = av['image'] ?? av['emoji']!;
              bool isSelected = _selectedAvatar == val;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  transform: Matrix4.diagonal3Values(isSelected ? 1.05 : 1.0, isSelected ? 1.05 : 1.0, 1.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isSelected ? const Color(0xFF00D2FF).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                        isSelected ? const Color(0xFF00D2FF).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00D2FF) : Colors.white12,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (av.containsKey('image'))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Image.asset(
                            av['image']!,
                            width: 80.r,
                            height: 80.r,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.grid_view_rounded, size: 60.r, color: const Color(0xFF00F2FF).withValues(alpha: 0.3)),
                          ),
                        )
                      else
                        Text(av['emoji']!, style: TextStyle(fontSize: 55.sp))
                            .animate(target: isSelected ? 1 : 0)
                            .scaleXY(end: 1.1, duration: 200.ms),
                      SizedBox(height: 12.h),
                      Text(
                        av['name']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 18.sp,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                          fontFamily: 'Cairo',
                          shadows: isSelected
                              ? [Shadow(color: const Color(0xFF00D2FF), blurRadius: 10)]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: (300 + (i * 100)).ms).scale(begin: const Offset(0.8, 0.8));
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(24.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(grade == '4-6' ? 2.r : 24.r),
              boxShadow: _selectedAvatar != null
                  ? [
                      BoxShadow(
                        color: (grade == '4-6' ? const Color(0xFF00F2FF) : AppTheme.emeraldGreen).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: _selectedAvatar != null ? _finish : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: grade == '4-6' ? const Color(0xFF00F2FF).withValues(alpha: 0.8) : AppTheme.emeraldGreen,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                minimumSize: Size(double.infinity, 64.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(grade == '4-6' ? 2.r : 24.r),
                  side: BorderSide(
                    color: _selectedAvatar != null 
                      ? (grade == '4-6' ? const Color(0xFF00F2FF) : AppTheme.emeraldGreen) 
                      : Colors.white12,
                    width: 2,
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                grade == '4-6' ? 'انطلاق' : 'انطلاق 🚀',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                  color: _selectedAvatar != null ? Colors.white : Colors.white38,
                ),
              ),
            ),
          ).animate(target: _selectedAvatar != null ? 1 : 0).shimmer(duration: 1.seconds, color: Colors.white54),
        ),
      ],
    );
  }
}
class _SharpPolygonPainter extends CustomPainter {
  final Color color;
  _SharpPolygonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    double b = 25.0; // Sharp bevel size
    path.moveTo(b, 0);
    path.lineTo(size.width - b, 0);
    path.lineTo(size.width, b);
    path.lineTo(size.width, size.height - b);
    path.lineTo(size.width - b, size.height);
    path.lineTo(b, size.height);
    path.lineTo(0, size.height - b);
    path.lineTo(0, b);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
    
    // Glowing edge
    canvas.drawLine(
      Offset(b, 0),
      Offset(size.width - b, 0),
      Paint()..color = color..strokeWidth = 2.5..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
    );
  }

  @override
  bool shouldRepaint(_SharpPolygonPainter old) => false;
}

class _GeometricGridPainter extends CustomPainter {
  final double animationValue;
  _GeometricGridPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    final dotPaint = Paint()..style = PaintingStyle.fill;
    double spacing = 50.w;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Intersections dots with wave pulse
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        double pulse = math.sin((animationValue * math.pi * 2) - (x + y) / 200);
        double normalizedPulse = (pulse + 1) / 2;
        
        if (normalizedPulse > 0.4) {
          double opacity = (normalizedPulse - 0.4) * 0.3;
          canvas.drawCircle(
            Offset(x, y), 
            1.2.r + (normalizedPulse * 0.8.r), 
            dotPaint..color = const Color(0xFF00F2FF).withValues(alpha: opacity)
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GeometricGridPainter old) => old.animationValue != animationValue;
}
