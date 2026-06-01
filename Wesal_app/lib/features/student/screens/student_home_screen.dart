import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../student_game_state.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _fullName = 'بطل WeCircle';

  @override
  void initState() {
    super.initState();
    _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('user_fullname') ?? 'بطل WeCircle';
    });
  }

  String _getRank(int points) {
    if (points >= 1500) return 'البطل الأسطوري الماسي 💎';
    if (points >= 1000) return 'حارس النوايا الذهبي 🥇';
    if (points >= 500) return 'ناشر السلام الفضي 🥈';
    return 'البطل الصغير الناشئ 🥉';
  }

  Color _getRankColor(int points) {
    if (points >= 1500) return const Color(0xFFF43F5E);
    if (points >= 1000) return const Color(0xFFF59E0B);
    if (points >= 500) return const Color(0xFF06B6D4);
    return const Color(0xFFB45309);
  }

  // ── Canteen Rewards Data ──
  List<_CanteenItem> get _canteenItems => [
    _CanteenItem(name: 'كوبون بـ 5 جنيه', pointsRequired: 600, code: 'W-CPN-05EGP'),
    _CanteenItem(name: 'كوبون بـ 10 جنيه', pointsRequired: 1200, code: 'W-CPN-10EGP'),
    _CanteenItem(name: 'كوبون بـ 15 جنيه', pointsRequired: 2400, code: 'W-CPN-15EGP'),
    _CanteenItem(name: 'كوبون بـ 20 جنيه', pointsRequired: 3600, code: 'W-CPN-20EGP'),
    _CanteenItem(name: 'كوبون بـ 30 جنيه', pointsRequired: 6000, code: 'W-CPN-30EGP'),
    _CanteenItem(name: 'كوبون بـ 50 جنيه', pointsRequired: 9600, code: 'W-CPN-50EGP'),
    _CanteenItem(name: 'كوبون بـ 75 جنيه', pointsRequired: 13200, code: 'W-CPN-75EGP'),
    _CanteenItem(name: 'كوبون بـ 100 جنيه', pointsRequired: 18000, code: 'W-CPN-100EGP'),
  ];

  void _showCouponDialog(BuildContext context, _CanteenItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مبروك يا بطل! 🎉',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              'لقد نجحت في فتح كوبون:',
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11.sp),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.cairo(color: const Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 14.sp),
                ),
                SizedBox(width: 4.w),
                Transform.rotate(
                  angle: -0.2,
                  child: const Text(
                    '💵',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            
            // ── Beautiful Mock QR Code / Barcode (High tech visual) ──
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  // Draw a mock QR code pattern using blocks
                  SizedBox(
                    width: 80.w,
                    height: 80.w,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: 25,
                      itemBuilder: (context, index) {
                        // Generate a structured mock QR pattern
                        final fill = (index % 2 == 0 && index % 3 != 0) || (index < 5) || (index % 5 == 0) || (index > 20);
                        return Container(
                          color: fill ? Colors.black : Colors.white,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    item.code,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 12.sp,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            
            Text(
              'اعرض هذا الرمز لمسؤول كنتين المدرسة للحصول على قيمة الكوبون واستخدامه في الشراء! 🎟️💵',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 10.sp, height: 1.4),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 38.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'حسناً',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<StudentGameState>();
    final firstName = _fullName.split(' ')[0];

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF06B6D4),
        backgroundColor: Colors.transparent,
        onRefresh: () async {
          await Provider.of<StudentGameState>(context, listen: false).refreshState();
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 100.h),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header: Large Profile Banner ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أهلاً بك في عالمك الخاص،',
                        style: GoogleFonts.cairo(
                          color: gameState.subtitleColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFFEC4899)],
                        ).createShader(bounds),
                        child: Text(
                          firstName,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Consumer<StudentGameState>(
                        builder: (context, state, child) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: _getRankColor(state.points).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: _getRankColor(state.points).withOpacity(0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              _getRank(state.points),
                              style: GoogleFonts.cairo(
                                color: _getRankColor(state.points),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Consumer<StudentGameState>(
                  builder: (context, state, child) {
                    final rankColor = _getRankColor(state.points);
                    return Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: rankColor.withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(color: rankColor, width: 2),
                        gradient: LinearGradient(
                          colors: [
                            rankColor.withOpacity(0.15),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          state.points >= 1500
                              ? '👑'
                              : state.points >= 1000
                                  ? '🏆'
                                  : state.points >= 500
                                      ? '⚡'
                                      : '⭐',
                          style: TextStyle(fontSize: 22.sp),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // ── Ultra Premium Interactive Progress Card ──
            Consumer<StudentGameState>(
              builder: (context, state, child) {
                final level = (state.points ~/ 500) + 1;
                final prevGoal = (level - 1) * 500;
                final currentProgressPoints = state.points - prevGoal;
                final progress = currentProgressPoints / 500;

                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: state.cardColor,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: state.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'رصيدك الحالي من نقاط الأبطال',
                                  style: GoogleFonts.cairo(
                                    color: state.subtitleColor,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${state.points}',
                                      style: GoogleFonts.outfit(
                                        color: state.textColor,
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'نقطة بطل',
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xFFF59E0B),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المستوى $level',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF06B6D4),
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '$currentProgressPoints / 500 لفتح المستوى التالي',
                                style: GoogleFonts.cairo(
                                  color: state.subtitleColor,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Stack(
                            children: [
                              Container(
                                height: 8.h,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOutCubic,
                                height: 8.h,
                                width: (1.sw - 72.w) * progress.clamp(0.0, 1.0),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF06B6D4), Color(0xFFEC4899)],
                                  ),
                                  borderRadius: BorderRadius.circular(6.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEC4899).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),

            // ── Canteen Rewards Grid (8 Custom Canteen Items) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 4.w, bottom: 10.h),
                  child: Row(
                    children: [
                      Transform.rotate(
                        angle: -0.2,
                        child: const Text('💵', style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'كوبونات كنتين المدرسة المالية 💵',
                        style: GoogleFonts.cairo(
                          color: gameState.textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Consumer<StudentGameState>(
                  builder: (context, state, child) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 items per row
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 1.3, // Sleek rectangular layout
                      ),
                      itemCount: _canteenItems.length,
                      itemBuilder: (context, index) {
                        final item = _canteenItems[index];
                        final isUnlocked = state.points >= item.pointsRequired;
                        
                        return GestureDetector(
                          onTap: () {
                            if (isUnlocked) {
                              _showCouponDialog(context, item);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'أنت بحاجة إلى ${item.pointsRequired} نقطة لفتح ${item.name}! 🔒',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: const Color(0xFFF43F5E),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isUnlocked 
                                  ? Colors.white
                                  : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isUnlocked 
                                    ? const Color(0xFF06B6D4).withOpacity(0.4) 
                                    : state.borderColor,
                                width: isUnlocked ? 1.2 : 0.8,
                              ),
                              boxShadow: isUnlocked
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF06B6D4).withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Lock icon and point indicator
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _AnimatedLockIcon(
                                            isUnlocked: isUnlocked,
                                            color: isUnlocked ? const Color(0xFF10B981) : Colors.white24,
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: isUnlocked 
                                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                                  : Colors.black.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              '${item.pointsRequired} نقطة',
                                              style: GoogleFonts.cairo(
                                                color: isUnlocked ? const Color(0xFF10B981) : state.mutedTextColor,
                                                fontSize: 9.sp,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      // Item Name
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 4.w,
                                        children: [
                                          Text(
                                            item.name,
                                            style: GoogleFonts.cairo(
                                              color: isUnlocked ? state.textColor : state.mutedTextColor,
                                              fontSize: 11.5.sp,
                                              fontWeight: isUnlocked ? FontWeight.w900 : FontWeight.w700,
                                              height: 1.3,
                                            ),
                                          ),
                                          Transform.rotate(
                                            angle: -0.2,
                                            child: Text(
                                              '💵',
                                              style: TextStyle(
                                                color: isUnlocked ? const Color(0xFF10B981) : state.mutedTextColor,
                                                fontSize: 13.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      // Status label
                                      Text(
                                        isUnlocked ? 'متاح للاستلام 🔓' : 'مغلق 🔒',
                                        style: GoogleFonts.cairo(
                                          color: isUnlocked ? const Color(0xFF06B6D4) : state.mutedTextColor,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isUnlocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16.r),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            
            SizedBox(height: 20.h),

            // ── Daily Quest Mission ──
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🌟', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 6.w),
                            Text(
                              'مهمة البطل اليومية!',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'تحدث مع أصدقائك بابتسامة لطيفة اليوم، وإذا شعرت بالغضب، خذ 5 أنفاس عميقة لتهدئة عقلك الجميل.',
                          style: GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Icon(
                    Icons.emoji_events_rounded,
                    color: const Color(0xFFFDE047),
                    size: 28.sp,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20.h),

            // ── Features Grid Banner ──
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
              decoration: BoxDecoration(
                color: gameState.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: gameState.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatIndicator('🎮 4 ألعاب', 'سلوكية فخمة', gameState),
                  Container(width: 1, height: 24.h, color: gameState.borderColor),
                  _buildStatIndicator('🏆 جوائز', 'ونقاط مستمرة', gameState),
                  Container(width: 1, height: 24.h, color: gameState.borderColor),
                  _buildStatIndicator('⚡ تحديث', 'سحابي فوري', gameState),
                ],
              ),
            ),
          ],
        ),
      ),
     ),
    );
  }

  Widget _buildStatIndicator(String title, String subtitle, StudentGameState gameState) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            color: gameState.textColor,
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.cairo(
            color: gameState.subtitleColor,
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CanteenItem {
  final String name;
  final int pointsRequired;
  final String code;
  
  _CanteenItem({
    required this.name,
    required this.pointsRequired,
    required this.code,
  });
}

class _AnimatedLockIcon extends StatefulWidget {
  final bool isUnlocked;
  final Color color;

  const _AnimatedLockIcon({required this.isUnlocked, required this.color});

  @override
  State<_AnimatedLockIcon> createState() => _AnimatedLockIconState();
}

class _AnimatedLockIconState extends State<_AnimatedLockIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    // Playful shaking back and forth (like a key turning)
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Bouncing pop scale
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.85), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 2),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isUnlocked) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedLockIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUnlocked && !oldWidget.isUnlocked) {
      _controller.forward(from: 0.0);
    } else if (!widget.isUnlocked && oldWidget.isUnlocked) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: Icon(
          widget.isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
          color: widget.color,
          size: 16.sp,
        ),
      ),
    );
  }
}
