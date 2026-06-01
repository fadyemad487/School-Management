/*
🧠 اسم الملف: student_dashboard_group_b.dart

📌 بيعمل إيه؟
ده "مركز العمليات" أو اللوحة الرئيسية للطلاب الكبار، اللي منها بيقدروا يوصلوا لكل الألعاب والمهام بتاعتهم.

👤 موجه لمين؟
- طلاب (المرحلة من 4 لـ 6 ابتدائي)

💡 فكرته:
بيجمع كل نشاطات الطالب في مكان واحد بشكل احترافي بيحسسه إنه قائد حقيقي للمهمة.
*/

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../state_manager.dart';
import '../../widgets/student1-3/galaxy_sidebar.dart';
import 'hawk_eye_screen.dart';
import 'gravity_balance_screen.dart';
import 'critical_choice_screen.dart';
import 'social_os_screen.dart';
import 'mission_prep_screen.dart';
import '../student_shared/student_chatbot_screen.dart';
import '../student_shared/game_intro_screen.dart';
import '../student_shared/game_data.dart';
import '../../../student_navigation.dart';
import '../../../screens/student_profile_screen.dart';
import '../../../screens/student_canteen_coupons_screen.dart';
import '../../../widgets/student_bottom_nav_bar.dart';
import '../../../widgets/student_space_scaffold.dart';
import '../../../utils/student_responsive.dart';

class StudentDashboardGroupBScreen extends StatefulWidget {
  final int initialTab;
  const StudentDashboardGroupBScreen({super.key, this.initialTab = 0});

  @override
  State<StudentDashboardGroupBScreen> createState() =>
      _StudentDashboardGroupBScreenState();
}

class _StudentDashboardGroupBScreenState extends State<StudentDashboardGroupBScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _lottieMCtrl;
  bool _showMCelebration = false;
  late int _currentTab;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Mock Data
  final List<Map<String, dynamic>> _skillsChallenges = [
    {
      'title': 'بطل التركيز (Hyper-Focus)',
      'original': 'تحدي التركيز',
      'progress': 0.85,
      'icon': Icons.track_changes_rounded,
      'color': const Color(0xFF00F2FF),
      'tip': 'ركز على هدف واحد لمدة 10 دقائق لرفع مستوى الطاقة.'
    },
    {
      'title': 'ملك الاختيار (Flex Logic)',
      'original': 'اتخاذ القرار',
      'progress': 0.65,
      'icon': Icons.alt_route_rounded,
      'color': const Color(0xFFBC00FF),
      'tip': 'المرونة في التفكير هي مفتاح القوة الحقيقية.'
    },
    {
      'title': 'كابتن الهدوء (Zen Control)',
      'original': 'التحكم في الغضب',
      'progress': 0.45,
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFF00FF95),
      'tip': 'التنفس العميق يعيد تشغيل نظام الهدوء لديك.'
    },
    {
      'title': 'درع اللطف (Shield Mode)',
      'original': 'التعامل مع التنمر',
      'progress': 0.90,
      'icon': Icons.security_rounded,
      'color': const Color(0xFFFFD700),
      'tip': 'القوي هو من يحمي الآخرين ويحترم الجميع.'
    },
    {
      'title': 'رائد مستقل (Self-Reliance)',
      'original': 'الاعتماد على النفس',
      'progress': 0.30,
      'icon': Icons.rocket_launch_rounded,
      'color': const Color(0xFFFF006B),
      'tip': 'كل مهمة تنجزها بنفسك تزيد من رتبتك كقائد.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lottieMCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lottieMCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StudentSpaceScaffold(
      scaffoldKey: _scaffoldKey,
      backgroundColor: const Color(0xFF020108),
      drawer: ValueListenableBuilder<String>(
        valueListenable: AppStateManager().selectedStudentAvatar,
        builder: (context, avatar, child) {
          return GalaxySidebar(
            studentName: 'أدهم',
            heroRank: 'رائد فضاء متقدم',
            avatarUrl: avatar,
            onAchievements: () => setState(() => _currentTab = 2),
            onCoupons: () {
              pushWithStudentGameState(context, const StudentCanteenCouponsScreen(), wrapSafeRoute: true);
            },
            onProfile: () => pushWithStudentGameState(context, const StudentProfileScreen()),
          );
        },
      ),
      body: Stack(
        children: [
          // Base Dark Background
          Container(color: const Color(0xFF020108)),
          
          // NEW: Cyber Grid Background for 4-6
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CyberGridPainter(
                    animationValue: _pulseController.value,
                  ),
                );
              }
            ),
          ),

          // 1. Background Grid (Optimized with RepaintBoundary)
          const Positioned.fill(
            child: RepaintBoundary(
              child: _GeometricGridPainterWidget(),
            ),
          ),

          // 2. Main Content
          _buildMainContent(),

          // 3. Mission Completion Celebration (Lazy Loaded)
          if (_showMCelebration)
            _buildCelebrationOverlay(),
        ],
      ),
      bottomNavigationBar: StudentBottomNavBar(
        currentIndex: _currentTab,
        onTap: (index) {
          if (index == 3) {
            pushWithStudentGameState(context, const StudentChatbotScreen(isGroupB: true));
          } else {
            setState(() => _currentTab = index);
          }
        },
        items: const [
          StudentNavItem(icon: Icons.dashboard_rounded, label: 'الرئيسية'),
          StudentNavItem(icon: Icons.rocket_launch_rounded, label: 'المهام'),
          StudentNavItem(icon: Icons.emoji_events_rounded, label: 'الشهادات'),
          StudentNavItem(icon: Icons.smart_toy_rounded, label: 'المساعد'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return IndexedStack(
      index: _currentTab,
      children: [
        _buildHomeTab(),
        _buildMissionsTab(),
        const _CertificatesTab(),
      ],
    );
  }

  Widget _buildCelebrationOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/celebration.json',
              controller: _lottieMCtrl,
              width: 320.r,
              repeat: false,
              onLoaded: (comp) {
                _lottieMCtrl.duration = comp.duration;
                _lottieMCtrl.forward().then((_) {
                   Future.delayed(const Duration(seconds: 1), () {
                     if (mounted) setState(() => _showMCelebration = false);
                   });
                });
              },
            ),
            SizedBox(height: 16.h),
            Text(
              '🎖️ قائد العمليات المتميز!',
              style: TextStyle(
                color: const Color(0xFFFFD700),
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                shadows: [Shadow(color: const Color(0xFFFFD700).withValues(alpha: 0.6), blurRadius: 15)],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _OpsAppBarWidget(title: 'مركز العمليات v2.0'),
        SliverPadding(
          padding: StudentResponsive.screenPadding(context),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              SizedBox(height: 12.h),
              const RepaintBoundary(child: _RankingProfileWidget()),
              SizedBox(height: 16.h),
              const _TopControlBar(),
              SizedBox(height: 32.h),
              _buildSkillsChallengesSection(),
              SizedBox(height: StudentResponsive.scrollBottomPadding(context)),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Daily Missions (Group B – Grade 4-6) ───────────────────────────────────

  static const Color _mCyan    = Color(0xFF00F2FF);
  static const Color _mLime    = Color(0xFF39FF14);

  final List<Map<String, dynamic>> _dailyTasks = [
    {
      'id': '1', 'title': 'نشاط القراءة: اقرأ قصة كاملة',
      'subtitle': 'كابتن المكتبة - القطاع أ',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF00F2FF), 'status': 'completed',
      'badge': 'assets/images/badges/star_badge.png', // Placeholder or use icon
    },
    {
      'id': '2', 'title': 'نشاط الرياضيات: ألعاب الأرقام',
      'subtitle': 'كابتن الحساب - مختبر دلتا',
      'icon': Icons.calculate_rounded,
      'color': const Color(0xFFFFD700), 'status': 'active',
      'badge': 'assets/images/badges/math_badge.png',
    },
    {
      'id': '3', 'title': 'نشاط العلوم: استكشف المجموعة...',
      'subtitle': 'كابتن العلوم - مركز الأبحاث',
      'icon': Icons.science_rounded,
      'color': const Color(0xFF00F2FF), 'status': 'approved',
      'badge': 'assets/images/badges/science_badge.png',
    },
    {
      'id': '4', 'title': 'نشاط الذاكرة: تحدي الحفظ الـ...',
      'subtitle': 'كابتن الذاكرة - أرشيف المجرة',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFFFFD700), 'status': 'active',
      'badge': 'assets/images/badges/memory_badge.png',
    },
    {
      'id': '5', 'title': 'نشاط التركيز: تأمل دقيقتين',
      'subtitle': 'كابتن التركيز - غرفة الزين',
      'icon': Icons.self_improvement_rounded,
      'color': const Color(0xFF00F2FF), 'status': 'active',
      'badge': 'assets/images/badges/focus_badge.png',
    },
  ];

  int get _mCompletedCount => _dailyTasks.where((t) => t['status'] == 'completed' || t['status'] == 'approved').length;
  double get _mProgress => _dailyTasks.isEmpty ? 0 : _mCompletedCount / _dailyTasks.length;
  bool get _mAllApproved => _dailyTasks.every((t) => t['status'] == 'approved');

  void _triggerMCelebration() async {
    if (_showMCelebration) return;
    HapticFeedback.heavyImpact();
    _lottieMCtrl.reset();
    setState(() => _showMCelebration = true);
    await Future.delayed(const Duration(milliseconds: 3800));
    if (mounted) setState(() => _showMCelebration = false);
  }

  Widget _buildMissionsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: StudentResponsive.screenPadding(context).copyWith(
        bottom: StudentResponsive.scrollBottomPadding(context),
      ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // ── Header (Glowing Box) ─────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  children: [
                    // Angular Header Frame
                    CustomPaint(
                      painter: _AngularFramePainter(color: _mCyan),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
                        child: Text(
                          'سجل المهمات اليومية',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                            letterSpacing: 1.5,
                            shadows: [Shadow(color: _mCyan, blurRadius: 10)],
                          ),
                        ),
                      ),
                    ).animate().slideY(begin: -0.3).fadeIn(),
                    SizedBox(height: 10.h),
                    Text(
                      'COMMAND CENTER v2.0',
                      style: TextStyle(
                        color: _mCyan,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Sector Progress Section ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF070B1A).withValues(alpha: 0.8),
                  border: Border.all(color: _mCyan.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اكتمال القطاع',
                              style: TextStyle(
                                color: _mCyan.withValues(alpha: 0.7),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              'SECTOR CLEARANCE',
                              style: TextStyle(color: Colors.white24, fontSize: 8.sp, letterSpacing: 1),
                            ),
                          ],
                        ),
                        Text(
                          '${(_mProgress * 100).toInt()}%',
                          style: TextStyle(
                            color: _mCyan,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    // Geometric Segmented Progress Bar
                    Row(
                      children: List.generate(20, (idx) {
                        bool isActive = idx / 20.0 < _mProgress;
                        return Expanded(
                          child: Container(
                            height: 8.h,
                            margin: EdgeInsets.symmetric(horizontal: 1.w),
                            decoration: BoxDecoration(
                              color: isActive ? _mCyan : Colors.white.withValues(alpha: 0.05),
                              boxShadow: isActive ? [BoxShadow(color: _mCyan.withValues(alpha: 0.5), blurRadius: 5)] : null,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('STATUS: OPERATIONAL', style: TextStyle(color: _mLime.withValues(alpha: 0.6), fontSize: 9.sp, fontWeight: FontWeight.bold)),
                        Text(
                          '$_mCompletedCount / ${_dailyTasks.length} MISSIONS ARCHIVED',
                          style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // ── Mission List ──────────────────────────────────────────────
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dailyTasks.length,
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  final task = _dailyTasks[index];
                  return _buildGroupBMissionCard(task);
                },
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildGroupBMissionCard(Map<String, dynamic> task) {
    final Color color = task['color'] as Color;
    final String status = task['status'] as String;
    final bool isApproved = status == 'approved';
    final bool isCompleted = status == 'completed' || isApproved;

    return GestureDetector(
      onTap: () {
        if (status == 'active') {
          setState(() {
            final idx = _dailyTasks.indexOf(task);
            _dailyTasks[idx]['status'] = 'completed';
          });
          HapticFeedback.mediumImpact();
        }
      },
      child: SizedBox(
        height: 140.h,
        child: Stack(
          children: [
            // Octagonal Card Body
            ClipPath(
              clipper: _MissionCardClipper(),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1124).withValues(alpha: 0.95),
                  border: Border.all(color: color.withValues(alpha: isCompleted ? 1.0 : 0.3), width: 1.5),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 80.w, top: 16.h, bottom: 16.h),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Left: Sharp Checkbox
                          Container(
                            width: 38.r,
                            height: 38.r,
                            decoration: BoxDecoration(
                              border: Border.all(color: color.withValues(alpha: isCompleted ? 1.0 : 0.4), width: 2),
                              color: color.withValues(alpha: isCompleted ? 0.2 : 0.02),
                            ),
                            child: isCompleted 
                              ? Icon(Icons.check_rounded, color: color, size: 24.sp)
                              : null,
                          ),
                          SizedBox(width: 16.w),
                          // Center: Texts
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  task['title'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Cairo',
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  task['subtitle'],
                                  style: TextStyle(
                                    color: color.withValues(alpha: 0.7),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Bottom Button (Flat Geometric)
                      Row(
                        children: [
                          SizedBox(width: 54.w), // Offset for checkbox
                          if (isApproved)
                            _mGamingStatusChip('معتمد', _mLime, icon: Icons.verified_user_rounded)
                          else if (status == 'completed')
                            GestureDetector(
                              onTap: () => setState(() {
                                final idx = _dailyTasks.indexOf(task);
                                _dailyTasks[idx]['status'] = 'approved';
                                if (_mAllApproved) _triggerMCelebration();
                              }),
                              child: _mGamingStatusChip('إرسال للقيادة', color, isButton: true),
                            )
                          else
                            _mGamingStatusChip('تفعيل المهمة', color, isButton: true, opacity: 0.5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // LARGE TRIANGULAR BADGE CONTAINER (Right Side)
            Positioned(
              right: -2,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 100.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sharp triangular frame
                    CustomPaint(
                      size: Size(100.w, 140.h),
                      painter: _SharpTriangularContainerPainter(color: color),
                    ),
                    // The Badge Content
                    Padding(
                      padding: EdgeInsets.only(left: 15.w),
                      child: Container(
                        width: 60.r,
                        height: 60.r,
                        decoration: BoxDecoration(
                          border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 1),
                          ],
                        ),
                        child: Icon(task['icon'], color: color, size: 28.sp),
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

  Widget _mGamingStatusChip(String label, Color color, {bool isButton = false, double opacity = 1.0, IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isButton ? color.withValues(alpha: 0.15 * opacity) : Colors.transparent,
        border: Border.all(color: color.withValues(alpha: 0.8 * opacity), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14.sp),
            SizedBox(width: 8.w),
          ],
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: opacity),
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildSkillsChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'تحديات المهارات المتقدمة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontFamily: 'Cairo',
              ),
            ),
            const Spacer(),
            const Icon(Icons.bolt_rounded, color: Color(0xFFFFD700))
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 180.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _skillsChallenges.length,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final challenge = _skillsChallenges[index];
              return _buildChallengeCard(challenge);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    Color color = challenge['color'];
    return GestureDetector(
      onTap: () => _showChallengeDetails(challenge),
      child: Container(
        width: 160.w,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(challenge['icon'], color: color, size: 24.sp),
            ),
            const Spacer(),
            Text(
              challenge['title'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                height: 1.2,
              ),
            ),
            SizedBox(height: 12.h),
            _buildSmallProgress(challenge['progress'], color),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallProgress(double progress, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(progress * 100).toInt()}%',
                style: TextStyle(color: color, fontSize: 9.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(3.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4.h,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }









  void _launchGameWithIntro({
    required String title,
    required Color color,
    required Widget game,
    required String gameKey,
  }) {
    pushWithStudentGameState(
      context,
      GameIntroScreen(
        title: title,
        steps: GameData.getSteps(gameKey, color),
        color: color,
        gameScreen: game,
      ),
    );
  }

  void _showChallengeDetails(Map<String, dynamic> challenge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(32.r),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E21),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(challenge['icon'], color: challenge['color'], size: 32.sp),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    challenge['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'نصيحة تعزيز القوة:',
              style: TextStyle(
                color: challenge['color'],
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              challenge['tip'],
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
                height: 1.5,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (challenge['title'].contains('التركيز')) {
                    _launchGameWithIntro(
                      title: 'عين الصقر (Hawk Eye)',
                      color: challenge['color'],
                      game: const HawkEyeScreen(),
                      gameKey: 'hawk_eye',
                    );
                  } else if (challenge['title'].contains('الاختيار')) {
                    _launchGameWithIntro(
                      title: 'قرار المصير (Critical Choice)',
                      color: challenge['color'],
                      game: const CriticalChoiceScreen(),
                      gameKey: 'critical_choice',
                    );
                  } else if (challenge['title'].contains('اللطف')) {
                    _launchGameWithIntro(
                      title: 'نظام التواصل (Social OS)',
                      color: challenge['color'],
                      game: const SocialOSScreen(),
                      gameKey: 'social_os',
                    );
                  } else if (challenge['title'].contains('الهدوء')) {
                    _launchGameWithIntro(
                      title: 'توازن الجاذبية (Gravity Balance)',
                      color: challenge['color'],
                      game: const GravityBalanceScreen(),
                      gameKey: 'gravity_balance',
                    );
                  } else if (challenge['title'].contains('رائد')) {
                    _launchGameWithIntro(
                      title: 'الرائد المستقل (Mission Prep)',
                      color: challenge['color'],
                      game: const MissionPrepScreen(),
                      gameKey: 'mission_prep',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: challenge['color'],
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: const Text('بدء المهمة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double b = 24.0; // Sharp 45-degree bevel size
    path.moveTo(b, 0);
    path.lineTo(size.width - b, 0);
    path.lineTo(size.width, b);
    path.lineTo(size.width, size.height - b);
    path.lineTo(size.width - b, size.height);
    path.lineTo(b, size.height);
    path.lineTo(0, size.height - b);
    path.lineTo(0, b);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _SharpTriangularContainerPainter extends CustomPainter {
  final Color color;
  _SharpTriangularContainerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(20.w, size.height / 2); // The sharp "cut" point
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
    
    // Add a glowing line on the sharp edge
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(20.w, size.height / 2),
      Paint()..color = color..strokeWidth = 3..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
    );
  }

  @override
  bool shouldRepaint(_SharpTriangularContainerPainter old) => false;
}

class _AngularFramePainter extends CustomPainter {
  final Color color;
  _AngularFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    double b = 15.0; // bevel
    path.moveTo(b, 0);
    path.lineTo(size.width - b, 0);
    path.lineTo(size.width, b);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - b, size.height);
    path.lineTo(b, size.height);
    path.lineTo(0, size.height - b);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_AngularFramePainter old) => false;
}

class _GeometricGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40.w) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40.h) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(_GeometricGridPainter old) => false;
}


// ── Optimized High-Performance Sub-Widgets ─────────────────────────────────────

class _GeometricGridPainterWidget extends StatelessWidget {
  const _GeometricGridPainterWidget();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GeometricGridPainter(),
      willChange: false,
    );
  }
}

class _RankingProfileWidget extends StatelessWidget {
  const _RankingProfileWidget();
  @override
  Widget build(BuildContext context) {
    final cyan = const Color(0xFF00F2FF);
    return ValueListenableBuilder<String>(
      valueListenable: AppStateManager().selectedStudentAvatar,
      builder: (context, avatar, child) {
        return Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1124).withValues(alpha: 0.8),
            border: Border.all(color: cyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              _buildAvatarWithGlow(cyan, avatar),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'القائد أدهم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'رتبة: رائد فضاء متقدم',
                      style: TextStyle(
                        color: cyan,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              _buildRankBadge(cyan),
            ],
          ),
        );
      }
    );
  }

  Widget _buildAvatarWithGlow(Color color, String avatarPath) {
    return Container(
      width: 65.r,
      height: 65.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Image.asset(avatarPath, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildRankBadge(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
      ),
      child: Text(
        'XP 2450',
        style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TopControlBar extends StatelessWidget {
  const _TopControlBar();
  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFFFD700);
    final cyan = const Color(0xFF00F2FF);
    return Row(
      children: [
        Expanded(child: _buildInfoBox('الطاقة الحيوية', '98%', gold, Icons.bolt_rounded)),
        SizedBox(width: 12.w),
        Expanded(child: _buildInfoBox('الاعتمادات', '450', cyan, Icons.toll_rounded)),
      ],
    );
  }

  Widget _buildInfoBox(String label, String val, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1124),
        border: Border(right: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white54, fontSize: 10.sp, fontFamily: 'Cairo')),
              Text(val, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpsBottomBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTap;

  const _OpsBottomBar({
    required this.currentTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(35.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 75.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(35.r),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.dashboard_rounded, 'الرئيسية', 0),
                    _buildNavItem(Icons.rocket_launch_rounded, 'المهام', 1),
                    _buildNavItem(Icons.emoji_events_rounded, 'الشهادات', 2),
                    _buildNavItem(Icons.smart_toy_rounded, 'المساعد', 3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool active = currentTab == index;
    final color = active ? const Color(0xFF00F2FF) : Colors.white38;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26.sp).animate(target: active ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 200.ms),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(color: color, fontSize: 10.sp, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}

class _CertificatesTab extends StatelessWidget {
  const _CertificatesTab();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> certificates = [
      {
        'title': 'خبير المنطق وفك التشفير',
        'subtitle': 'إتمام تحديات التفكير المنطقي والرياضيات بدقة عالية',
        'progress': 1.0,
        'points': 500,
        'total': 500,
        'color': const Color(0xFF00F2FF),
        'icon': Icons.psychology_rounded,
        'isLocked': false,
      },
      {
        'title': 'وسام نبض المشاركة الإيجابية',
        'subtitle': 'نشر الروح الطيبة والتعاون مع الزملاء في المجرة',
        'progress': 0.85,
        'points': 425,
        'total': 500,
        'color': const Color(0xFFFFD700),
        'icon': Icons.share_location_rounded,
        'isLocked': false,
      },
      {
        'title': 'درع الهدوء والسيطرة (Zen)',
        'subtitle': 'التحكم الكامل في المشاعر والهدوء تحت الضغط',
        'progress': 0.6,
        'points': 300,
        'total': 500,
        'color': const Color(0xFF00FF95),
        'icon': Icons.self_improvement_rounded,
        'isLocked': false,
      },
      {
        'title': 'قائد العمليات الميدانية',
        'subtitle': 'إتمام 100 مهمة يومية بنجاح واعتماد القيادة',
        'progress': 0.45,
        'points': 225,
        'total': 500,
        'color': const Color(0xFFBC00FF),
        'icon': Icons.military_tech_rounded,
        'isLocked': false,
      },
      {
        'title': 'خبير رادار الحقيقة والتركيز',
        'subtitle': 'الانتباه للتفاصيل الدقيقة واكتشاف الثغرات بذكاء',
        'progress': 0.2,
        'points': 100,
        'total': 500,
        'color': const Color(0xFFFF006B),
        'icon': Icons.track_changes_rounded,
        'isLocked': false,
      },
      {
        'title': 'رائد فضاء مستقل (بطل التجهيز)',
        'subtitle': 'الاعتماد الكامل على النفس في تجهيز كافة المهمات',
        'progress': 0.0,
        'points': 0,
        'total': 500,
        'color': const Color(0xFF00D2FF),
        'icon': Icons.rocket_launch_rounded,
        'isLocked': true,
      },
    ];

    return Padding(
        padding: StudentResponsive.screenPadding(context),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              SizedBox(height: 24.h),
              Text(
                'سجل الشهادات والأوسمة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                  shadows: [Shadow(color: const Color(0xFF00F2FF), blurRadius: 10)],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),
              SizedBox(height: 10.h),
              Text(
                'CERTIFICATE MANAGEMENT SYSTEM v2.0',
                style: TextStyle(
                  color: const Color(0xFF00F2FF).withValues(alpha: 0.7),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(height: 32.h),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: certificates.length,
                  separatorBuilder: (context, index) => SizedBox(height: 20.h),
                  itemBuilder: (context, index) {
                    final cert = certificates[index];
                    return _buildCertificateCard(cert, index);
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> cert, int index) {
    final Color color = cert['color'];
    final bool isLocked = cert['isLocked'];

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1124).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isLocked ? Colors.white10 : color.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          if (!isLocked)
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 25,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Row(
        children: [
          // Cyber Icon Container
          Container(
            width: 75.r,
            height: 75.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isLocked ? Colors.white24 : color, width: 2),
              boxShadow: [
                if (!isLocked)
                  BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  cert['icon'],
                  color: isLocked ? Colors.white24 : color,
                  size: 36.sp,
                ),
                if (isLocked)
                  Icon(Icons.lock_rounded, color: Colors.white, size: 20.sp),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cert['title'],
                      style: TextStyle(
                        color: isLocked ? Colors.white38 : Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if (!isLocked && cert['progress'] == 1.0)
                      Icon(Icons.verified_rounded, color: color, size: 18.sp),
                  ],
                ),
                Text(
                  cert['subtitle'],
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10.sp,
                    fontFamily: 'Cairo',
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 14.h),
                // Segmented Tech Progress Bar
                Row(
                  children: List.generate(10, (idx) {
                    bool active = (idx + 1) / 10.0 <= cert['progress'];
                    return Expanded(
                      child: Container(
                        height: 5.h,
                        margin: EdgeInsets.symmetric(horizontal: 1.w),
                        decoration: BoxDecoration(
                          color: active ? color : Colors.white.withValues(alpha: 0.05),
                          boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)] : null,
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isLocked ? 'المهمة مقفلة 🔐' : 'تحت المعالجة ⚙️',
                      style: TextStyle(
                        color: isLocked ? Colors.white24 : color.withValues(alpha: 0.7),
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      '${cert['points']} / ${cert['total']} XP',
                      style: TextStyle(color: Colors.white54, fontSize: 10.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.2);
  }
}

class _CyberGridPainter extends CustomPainter {
  final double animationValue;
  _CyberGridPainter({required this.animationValue});

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
  bool shouldRepaint(_CyberGridPainter old) => old.animationValue != animationValue;
}
class _OpsAppBarWidget extends StatelessWidget {
  final String title;
  const _OpsAppBarWidget({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontFamily: 'Cairo',
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: EdgeInsets.only(left: 20.w),
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Color(0xFF00F2FF), size: 20),
          ),
        ),
      ],
    );
  }
}
