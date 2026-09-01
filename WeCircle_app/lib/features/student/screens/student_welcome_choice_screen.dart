import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student_game_state.dart';
import '../utils/student_responsive.dart';
import '../space/widgets/student1-3/animated_space_background.dart';

enum StudentEntryIntent { play, tasks, chatbot, profile }

class StudentWelcomeChoiceScreen extends StatefulWidget {
  final void Function(StudentEntryIntent intent) onChoice;

  const StudentWelcomeChoiceScreen({super.key, required this.onChoice});

  @override
  State<StudentWelcomeChoiceScreen> createState() => _StudentWelcomeChoiceScreenState();
}

class _StudentWelcomeChoiceScreenState extends State<StudentWelcomeChoiceScreen> {
  String _firstName = 'بطل';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final full = prefs.getString('user_fullname') ?? 'بطل WeCircle';
    if (mounted) {
      setState(() => _firstName = full.split(' ').first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = context.watch<StudentGameState>().points;
    final compact = StudentResponsive.isCompact(context);
    final padding = StudentResponsive.screenPadding(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF15264F),
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedSpaceBackground()),
            SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: padding.copyWith(top: 20.h, bottom: 24.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 32.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'أهلاً يا $_firstName!',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: StudentResponsive.adaptiveSp(context, compact ? 22 : 26),
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.38),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'عايز تدخل تعمل إيه النهاردة؟',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: StudentResponsive.adaptiveSp(context, compact ? 12 : 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'رصيدك: $points نقطة بطل',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFFFD166),
                            fontSize: StudentResponsive.adaptiveSp(context, 12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: compact ? 20.h : 32.h),
                        _ChoiceCard(
                          emoji: '🎮',
                          title: 'ألعب وأكمل تحديات',
                          subtitle: 'مغامرات السلوك والمهمات',
                          color: const Color(0xFF00D2FF),
                          compact: compact,
                          onTap: () => widget.onChoice(StudentEntryIntent.play),
                        ),
                        SizedBox(height: 12.h),
                        _ChoiceCard(
                          emoji: '📋',
                          title: 'أحل مهام اليوم',
                          subtitle: 'المهمات والتحديات اليومية',
                          color: const Color(0xFFBC00FF),
                          compact: compact,
                          onTap: () => widget.onChoice(StudentEntryIntent.tasks),
                        ),
                        SizedBox(height: 12.h),
                        _ChoiceCard(
                          emoji: '🤖',
                          title: 'أكلم المساعد الذكي',
                          subtitle: 'اسأل أي حاجة واسألني',
                          color: const Color(0xFF10B981),
                          compact: compact,
                          onTap: () => widget.onChoice(StudentEntryIntent.chatbot),
                        ),
                        SizedBox(height: compact ? 16.h : 24.h),
                        TextButton(
                          onPressed: () => widget.onChoice(StudentEntryIntent.profile),
                          child: Text(
                            'حسابي وإعداداتي',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Ink(
          padding: EdgeInsets.all(compact ? 14.w : 18.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            color: const Color(0xFF10284F).withValues(alpha: 0.70),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: compact ? 28.sp : 32.sp)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: StudentResponsive.adaptiveSp(context, compact ? 14 : 16),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: StudentResponsive.adaptiveSp(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded, color: color, size: 18.sp),
            ],
          ),
        ),
      ),
    );
  }
}
