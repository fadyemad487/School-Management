import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../state_manager.dart';
import '../../../../auth/auth_service.dart';
import '../../../../auth/login_screen.dart';
import 'animated_space_background.dart';

class GalaxySidebar extends StatefulWidget {
  final String studentName;
  final String heroRank;
  final String avatarUrl;
  final VoidCallback? onAchievements;
  final VoidCallback? onCoupons;
  final VoidCallback? onProfile;

  const GalaxySidebar({
    super.key,
    required this.studentName,
    required this.heroRank,
    required this.avatarUrl,
    this.onAchievements,
    this.onCoupons,
    this.onProfile,
  });

  @override
  State<GalaxySidebar> createState() => _GalaxySidebarState();
}

class _GalaxySidebarState extends State<GalaxySidebar> with SingleTickerProviderStateMixin {
  late AnimationController _gridCtrl;

  @override
  void initState() {
    super.initState();
    _gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _gridCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isGroupB = AppStateManager().selectedGradeLevel.value == '4-6';

    return Drawer(
      backgroundColor: Colors.transparent,
      width: 300.w,
      child: Stack(
        children: [
          if (isGroupB)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF020108), Color(0xFF0A0E21), Color(0xFF020108)],
                ),
              ),
            )
          else
            const AnimatedSpaceBackground(),
          
          if (isGroupB) ...[
            Positioned(
              top: -100.r,
              right: -50.r,
              child: Container(
                width: 300.r,
                height: 300.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D2FF).withValues(alpha: 0.08),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 5.seconds),
            ),
            Positioned(
              bottom: 50.r,
              left: -50.r,
              child: Container(
                width: 250.r,
                height: 250.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFBC00FF).withValues(alpha: 0.05),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 7.seconds),
            ),
          ],

          if (isGroupB)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _gridCtrl,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _SidebarGridPainter(animationValue: _gridCtrl.value),
                    );
                  },
                ),
              ),
            ),

          Container(
            decoration: BoxDecoration(
              color: isGroupB
                  ? const Color(0xFF03001C).withValues(alpha: 0.6)
                  : const Color(0xFF10284F).withValues(alpha: 0.24),
              border: const Border(
                right: BorderSide(color: Colors.white12, width: 0.8),
              ),
            ),
          ),

          // 5. Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    isGroupB ? 'التحكم في المركبة' : 'قائمة البطل',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                _buildMenuItem(context, Icons.card_giftcard_rounded, 'كوبونات الكانتين', () {
                  Navigator.pop(context);
                  widget.onCoupons?.call();
                }),
                _buildMenuItem(context, Icons.auto_awesome_rounded, 'إنجازات البطل', () {
                  Navigator.pop(context);
                  widget.onAchievements?.call();
                }),
                _buildMenuItem(context, Icons.person_rounded, 'حسابي', () {
                  Navigator.pop(context);
                  widget.onProfile?.call();
                }),
                const Spacer(),
                
                // Logout with Navigation
                _buildMenuItem(
                  context, 
                  Icons.logout_rounded, 
                  'تسجيل الخروج', 
                  () async {
                    Navigator.pop(context);
                    await AuthService().logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }, 
                  isDestructive: true
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rotating glow behind avatar
              Container(
                width: 85.r,
                height: 85.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.2), width: 1),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
              
              Container(
                width: 75.r,
                height: 75.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00D2FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.avatarUrl.contains('assets')
                      ? Image.asset(
                          widget.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            Icon(Icons.person, color: Colors.white, size: 40.r),
                        )
                      : Center(
                          child: Text(widget.avatarUrl, style: TextStyle(fontSize: 40.sp)),
                        ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            widget.studentName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D2FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.3)),
                ),
                child: Text(
                  widget.heroRank,
                  style: TextStyle(
                    color: const Color(0xFF00D2FF),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    final glowColor = isDestructive ? Colors.redAccent : const Color(0xFFFFD166);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
          leading: Icon(
            icon, 
            color: color.withValues(alpha: 0.8), 
            size: 24.r,
            shadows: [
              Shadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 10),
            ],
          ),
          title: Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          hoverColor: Colors.white10,
          splashColor: glowColor.withValues(alpha: 0.2),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}


class _SidebarGridPainter extends CustomPainter {
  final double animationValue;
  _SidebarGridPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    final dotPaint = Paint()..style = PaintingStyle.fill;
    double spacing = 45.w;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Intersection dots with pulsing animation
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        double pulse = math.sin((animationValue * math.pi * 2) - (x + y) / 150);
        double normalizedPulse = (pulse + 1) / 2;
        
        if (normalizedPulse > 0.4) {
          double opacity = (normalizedPulse - 0.4) * 0.25;
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
  bool shouldRepaint(_SidebarGridPainter old) => old.animationValue != animationValue;
}
