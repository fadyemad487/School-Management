import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../student_game_state.dart';
import '../games/game1_anger_tamer.dart';
import '../games/game2_kindness_hero.dart';
import '../games/game3_honesty_guardian.dart';
import '../games/game4_contentment_garden.dart';
import '../games/game5_memory_challenge.dart';

class StudentGamesScreen extends StatelessWidget {
  const StudentGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<StudentGameState>(context, listen: false);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Beautiful Compact Neon Title Header ──
          Padding(
            padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                  ).createShader(bounds),
                  child: Text(
                    'تحديات الأبطال 🎮',
                    style: GoogleFonts.cairo(
                      color: Color(0xFF0F172A),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'اختر التحدي الذي تريده لمباركة سلوكك وكسب الجوائز!',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF64748B),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // ── Compact Games List ──
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 8.h, bottom: 100.h),
              children: [
                _GameCard(
                  gameId: 'game1',
                  title: 'صرف الغضب 🌬️',
                  subtitle: 'تغلب على الغضب، استنشق الهدوء، وافرز المشاعر الصالحة.',
                  icon: Icons.wind_power_rounded,
                  colors: const [Color(0xFFEF4444), Color(0xFFF97316)],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: gameState,
                          child: Game1AngerTamer(),
                        ),
                      )
                    );
                  },
                ),
                SizedBox(height: 10.h),
                _GameCard(
                  gameId: 'game2',
                  title: 'بطل اللطف 🤝',
                  subtitle: 'اهزم قوى التنمر وساعد زملاءك بالأفعال الطيبة المحبوبة.',
                  icon: Icons.favorite_rounded,
                  colors: const [Color(0xFF10B981), Color(0xFF059669)],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: gameState,
                          child: Game2KindnessHero(),
                        ),
                      )
                    );
                  },
                ),
                SizedBox(height: 10.h),
                _GameCard(
                  gameId: 'game3',
                  title: 'حارس الأمانة 💰',
                  subtitle: 'حافظ على ممتلكات الآخرين وحقق أعلى مراتب النزاهة والصدق.',
                  icon: Icons.shield_rounded,
                  colors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: gameState,
                          child: Game3HonestyGuardian(),
                        ),
                      )
                    );
                  },
                ),
                SizedBox(height: 10.h),
                _GameCard(
                  gameId: 'game4',
                  title: 'حديقة الرضا 🌸',
                  subtitle: 'تمنّى الخير للآخرين واشعر بالقناعة لتزهر حديقتك الجميلة.',
                  icon: Icons.local_florist_rounded,
                  colors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: gameState,
                          child: Game4ContentmentGarden(),
                        ),
                      )
                    );
                  },
                ),
                SizedBox(height: 10.h),
                _GameCard(
                  gameId: 'game5',
                  title: 'تحدي الذاكرة 🧠🚀',
                  subtitle: 'اختبر قوة تركيزك وحافظ على ترتيب الأنماط والأشكال بدقة.',
                  icon: Icons.psychology_rounded,
                  colors: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: gameState,
                          child: Game5MemoryChallenge(),
                        ),
                      )
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String gameId;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _GameCard({
    required this.gameId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentGameState>(
      builder: (context, state, child) {
        final currentLevel = state.getUnlockedLevel(gameId);
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 92.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Glowing background icon
                Positioned(
                  left: -10.w,
                  bottom: -15.h,
                  child: Icon(
                    icon,
                    size: 80.sp,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Level Tag
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎮 ', style: TextStyle(fontSize: 9)),
                                Text(
                                  'المستوى $currentLevel',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Circular glowing Play Button
                          Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: colors.first,
                                size: 18.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Title & Subtitle description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
