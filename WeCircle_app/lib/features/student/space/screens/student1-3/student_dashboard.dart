/*
🧠 اسم الملف: student_dashboard.dart (1-3)

📌 بيعمل إيه؟
دي الشاشة الرئيسية المبهجة اللي الطالب الصغير بيشوف فيها الكواكب والمهمات اللي المفروض يخلصها.

👤 موجه لمين؟
- طلاب (المرحلة من 1 لـ 3 ابتدائي)

💡 فكرته:
بيحول الدراسة لمغامرة في الفضاء عشان يحبب الطالب في المذاكرة والمهام اليومية.
*/

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state_manager.dart';
import '../../../student_game_state.dart';
import '../../../utils/student_rank_helper.dart';
import '../../../widgets/student_canteen_section.dart';
import '../../../screens/student_profile_screen.dart';
import '../../../screens/student_canteen_coupons_screen.dart';
import '../../../student_navigation.dart';
import '../../widgets/student1-3/animated_space_background.dart';
import '../../widgets/student1-3/galaxy_header.dart';
import '../../widgets/student1-3/hero_mission_card.dart';
import '../../widgets/student1-3/galaxy_sidebar.dart';

import '../../widgets/student1-3/floating_bottom_bar.dart';
import '../../models/student1-3/mission_model.dart';
import 'daily_missions_screen.dart';
import 'achievements_screen.dart';
import 'captain_calm_screen.dart';
import 'cosmic_memory_screen.dart';
import 'explorer_gear_up_screen.dart';
import 'kindness_journey_screen.dart';
import 'broken_galaxy_pulse_screen.dart';
import '../student_shared/student_chatbot_screen.dart';
import '../student_shared/game_intro_screen.dart';
import '../student_shared/game_data.dart';
import '../../../utils/student_responsive.dart';
import '../../../widgets/student_space_scaffold.dart';

class StudentDashboardScreen extends StatefulWidget {
  final int initialTab;
  const StudentDashboardScreen({super.key, this.initialTab = 0});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late int _currentTab;
  String _studentName = 'بطل';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final full = prefs.getString('user_fullname') ?? 'بطل WeCircle';
    if (mounted) setState(() => _studentName = full.split(' ').first);
  }


  final List<MissionModel> _missions = [
    MissionModel(
      id: '1',
      title: 'جسر النور',
      type: 'Memory',
      imagePath: 'assets/images/reading_planet.png',
      color: const Color(0xFF00D2FF), // Blue/Cyan
      isActive: true,
    ),
    MissionModel(
      id: '2',
      title: 'تجهيز المستكشف',
      type: 'Reading',
      imagePath: 'assets/images/math_asteroid.png',
      color: const Color(0xFFFFB300), // Yellow/Orange
      isActive: true,
    ),
    MissionModel(
      id: '3',
      title: 'تحدي الذاكرة',
      type: 'Science',
      imagePath: 'assets/images/science_rocket.png',
      color: const Color(0xFF9C27B0), // Purple
      isActive: true,
    ),
    MissionModel(
      id: '4',
      title: 'تحدي القبطان الهادئ',
      type: 'Focus',
      imagePath: 'assets/images/memory_portal.png',
      color: const Color(0xFF4CAF50), // Green
      isActive: true,
    ),
    MissionModel(
      id: '5',
      title: 'رحلة اللطف',
      type: 'Math',
      imagePath: 'assets/images/focus_galaxy.png',
      color: const Color(0xFFE91E63), // Pink/Red
      isActive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return StudentSpaceScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: ValueListenableBuilder<String>(
        valueListenable: AppStateManager().selectedStudentAvatar,
        builder: (context, avatar, child) {
          return Consumer<StudentGameState>(
            builder: (context, gs, _) => GalaxySidebar(
              studentName: _studentName,
              heroRank: StudentRankHelper.shortRankForPoints(gs.points),
              avatarUrl: avatar.isEmpty ? '🚀' : avatar,
              onAchievements: () => setState(() => _currentTab = 2),
              onCoupons: () {
                pushWithStudentGameState(context, const StudentCanteenCouponsScreen(), wrapSafeRoute: true);
              },
              onProfile: () {
                pushWithStudentGameState(context, const StudentProfileScreen());
              },
            ),
          );
        },
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildMainDashboardBody(),
          DailyMissionsScreen(
            initialTab: 1,
            onTabChanged: (i) {
              if (i == 3) {
                pushWithStudentGameState(context, const StudentChatbotScreen(isGroupB: false));
              } else {
                setState(() => _currentTab = i);
              }
            },
          ),
          const AchievementsScreen(),
        ],
      ),
      bottomNavigationBar: FloatingBottomBar(
        currentIndex: _currentTab,
        onTap: (index) {
          if (index == 3) {
            pushWithStudentGameState(context, const StudentChatbotScreen(isGroupB: false));
          } else {
            setState(() => _currentTab = index);
          }
        },
      ),
    );
  }

  Widget _buildMainDashboardBody() {
    return Stack(
      children: [
        // 1. Background
        const AnimatedSpaceBackground(),

        // 2. Main Content
        CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: ValueListenableBuilder<String>(
                  valueListenable: AppStateManager().selectedStudentAvatar,
                  builder: (context, avatar, child) {
                    return Consumer<StudentGameState>(
                      builder: (context, gs, _) => GalaxyHeader(
                        studentName: _studentName,
                        heroRank: StudentRankHelper.shortRankForPoints(gs.points),
                        crystalBalance: gs.points,
                        avatarUrl: avatar.isEmpty ? '🚀' : avatar,
                      ),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 30.h)),

              // Hero Missions Section
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25.w),
                      child: Row(
                        children: [
                          Text(
                          'تحديات البطل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 10),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.bolt_rounded, color: Colors.yellowAccent)
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: Duration(seconds: 1)),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),
                    _buildMissionPath(),
                  ],
                ),
              ),



              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              const SliverToBoxAdapter(child: StudentCanteenSection()),
              studentScrollBottomSpacer(context),
            ],
          ),
      ],
    );
  }

  Widget _buildMissionPath() {
    // Pixel-accurate fractions measured from galaxy_path.png (350 × 713 px)
    // via dark-circle detection — each Offset is the circle centre (x/w, y/h):
    const List<Offset> positions = [
      Offset(0.79, 0.325), // Reading Planet   – top-right (Start RTL)
      Offset(0.24, 0.33),  // Math Asteroid    – top-left
      Offset(0.50, 0.50),  // Science Rocket   – centre
      Offset(0.79, 0.65),  // Memory Portal    – bottom-right
      Offset(0.24, 0.65),  // Focus Galaxy     – bottom-left
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double imgW = constraints.maxWidth - 40.w; // same as previous horizontal padding
        // galaxy_path.png is 350 × 713 px  →  ratio = 350/713 = 0.491
        const double imageAspectRatio = 0.491;
        final double imgH = imgW / imageAspectRatio;

        final double iconSize = StudentResponsive.missionPlanetIconSize(context);
        final double half    = iconSize / 2;

        return SizedBox(
          width: constraints.maxWidth,
          height: imgH,
          child: Stack(
            children: [
              // ── Background galaxy path ──────────────────────────────────
              Positioned(
                left: 20.w,
                top: 0,
                width: imgW,
                height: imgH,
                child: Image.asset(
                  'assets/images/galaxy_path.png',
                  fit: BoxFit.fill, // fill the box we sized ourselves → no distortion
                ),
              ),

              // ── Mission buttons ─────────────────────────────────────────
              for (int i = 0; i < _missions.length; i++)
                Positioned(
                  left: 20.w + imgW * positions[i].dx - half,
                  top:         imgH * positions[i].dy - half,
                  width:  iconSize,
                  height: iconSize,
                  child: _buildMissionIcon(i),
                ),
            ],
          ),
        );
      },
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

  Widget _buildMissionIcon(int index) {
    final mission = _missions[index];
    return HeroMissionCard(
      title: mission.title,
      icon: mission.icon,
      imagePath: mission.imagePath,
      color: mission.color,
      isActive: mission.isActive,
      onTap: () {
        if (mission.type == 'Reading') {
          // math_asteroid.png (Bag)
          _launchGameWithIntro(
            title: 'تجهيز المستكشف (الشنطة)',
            color: mission.color,
            game: const ExplorerGearUpScreen(),
            gameKey: 'organization',
          );
        } else if (mission.type == 'Math') {
          // focus_galaxy.png (Heart)
          _launchGameWithIntro(
            title: 'رحلة اللطف (القلب الأحمر)',
            color: mission.color,
            game: const KindnessJourneyScreen(),
            gameKey: 'kindness_journey',
          );
        } else if (mission.type == 'Science') {
          // science_rocket.png (Rocket and Clock)
          _launchGameWithIntro(
            title: 'تحدي الذاكرة (الصاروخ والساعة)',
            color: mission.color,
            game: const CosmicMemoryScreen(),
            gameKey: 'cosmic_memory',
          );
        } else if (mission.type == 'Memory') {
          // reading_planet.png (Star/Hands)
          _launchGameWithIntro(
            title: 'جسر النور (نبض المجرة)',
            color: mission.color,
            game: const BrokenGalaxyPulseScreen(),
            gameKey: 'sharing',
          );
        } else if (mission.type == 'Focus') {
          // memory_portal.png (Alien)
          _launchGameWithIntro(
            title: 'تحدي القبطان الهادئ (الفضائي)',
            color: mission.color,
            game: const CaptainCalmScreen(),
            gameKey: 'captain_calm_v1',
          );
        }
      },
    );
  }
}
