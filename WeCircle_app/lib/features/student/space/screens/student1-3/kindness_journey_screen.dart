import 'dart:ui';
/*
🧠 اسم الملف: kindness_journey_screen.dart

📌 بيعمل إيه؟
لعبة "رحلة اللطف" اللي بتشجع الطفل على عمل تصرفات إيجابية وطيبة مع اللي حواليه.

👤 موجه لمين؟
- طلاب (المرحلة من 1 لـ 3 ابتدائي)

💡 فكرته:
بناء شخصية سوية ومحبة للخير ونشر الإيجابية بين الأطفال.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/student1-3/animated_space_background.dart';

class ScenarioModel {
  final int level;
  final String description;
  final List<ChoiceModel> choices;
  final String successMessage;
  final String tryAgainMessage;

  ScenarioModel({
    required this.level,
    required this.description,
    required this.choices,
    required this.successMessage,
    required this.tryAgainMessage,
  });
}

class ChoiceModel {
  final String text;
  final IconData avatarIcon;
  final Color avatarColor;
  final bool isCorrect;

  ChoiceModel({
    required this.text,
    required this.avatarIcon,
    required this.avatarColor,
    required this.isCorrect,
  });
}

class KindnessJourneyScreen extends StatefulWidget {
  const KindnessJourneyScreen({super.key});

  @override
  State<KindnessJourneyScreen> createState() => _KindnessJourneyScreenState();
}

class _KindnessJourneyScreenState extends State<KindnessJourneyScreen> {
  int _currentScenarioIndex = 0;
  int _kindnessScore = 0;
  int _endlessLevel = 1; // Tracks endless progression

  bool _isAnimatingChoice = false;
  int? _selectedChoiceIndex;
  bool _showSuccessParticles = false;

  final List<ScenarioModel> _scenarios = [
    // Level 1: Easy - Obvious physical help
    ScenarioModel(
      level: 1,
      description: "زميلك سقط على الأرض ووقعت حقيبته، وبعض الأطفال يضحكون.",
      successMessage: "مساعدة الآخرين شجاعة حقيقية! لقد أسعدت زميلك ❤️",
      tryAgainMessage: "حاول اختيار تصرف أكثر لطفاً وإيجابية 💙",
      choices: [
        ChoiceModel(text: "أضحك بصوت عالٍ معهم", avatarIcon: Icons.emoji_emotions_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
        ChoiceModel(text: "أكمل طريقي وكأنني لم أرى شيئاً", avatarIcon: Icons.directions_walk_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
        ChoiceModel(text: "أساعده على النهوض وأسأله إن كان بخير", avatarIcon: Icons.front_hand_rounded, avatarColor: Colors.cyanAccent, isCorrect: true),
      ],
    ),
    // Level 2: Medium - Social inclusion
    ScenarioModel(
      level: 2,
      description: "طالب جديد يجلس بمفرده وقت الفسحة، وأصدقاؤك يلعبون بعيداً.",
      successMessage: "الكلمات الطيبة تصنع أصدقاء رائعين في المجرة! 🤝",
      tryAgainMessage: "تخيل لو كنت مكانه في مدرسة جديدة، ماذا ستحب؟ 💙",
      choices: [
        ChoiceModel(text: "أخبره أن يبتعد عن مكان لعبنا", avatarIcon: Icons.record_voice_over_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
        ChoiceModel(text: "أذهب إليه وأدعوه للعب معنا", avatarIcon: Icons.group_add_rounded, avatarColor: Colors.cyanAccent, isCorrect: true),
        ChoiceModel(text: "ألعب مع أصدقائي وأتجاهله تماماً", avatarIcon: Icons.groups_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
      ],
    ),
    // Level 3: Medium/Hard - Dealing with peer pressure
    ScenarioModel(
      level: 3,
      description: "صديقك المقرب يسخر من نظارة طالب آخر ويطلب منك أن تضحك.",
      successMessage: "قول الحق وعدم مسايرة التنمر هو تصرف الأبطال! 🌟",
      tryAgainMessage: "الصديق الحقيقي لا يشجع على التنمر، فكر مجدداً 💙",
      choices: [
        ChoiceModel(text: "أضحك مجاملةً لصديقي", avatarIcon: Icons.face_retouching_natural_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
        ChoiceModel(text: "أخبر صديقي سراً أن هذا التصرف خاطئ", avatarIcon: Icons.speaker_notes_rounded, avatarColor: Colors.cyanAccent, isCorrect: true),
        ChoiceModel(text: "أبتعد بهدوء لكي لا أتورط", avatarIcon: Icons.transfer_within_a_station_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
      ],
    ),
    // Level 4: Hard - Forgiveness and emotion control
    ScenarioModel(
      level: 4,
      description: "زميلك كسر قلمك المفضل عن طريق الخطأ واعتذر لك وهو خائف.",
      successMessage: "التسامح يجعلك أقوى! لقد سيطرت على غضبك بامتياز 🛡️",
      tryAgainMessage: "لقد حدث ذلك بالخطأ واعتذر، كيف يمكنك مسامحته؟ 💙",
      choices: [
        ChoiceModel(text: "أوبخه بشدة ليحذر في المرة القادمة", avatarIcon: Icons.campaign_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
        ChoiceModel(text: "أخبر المعلم ليعاقبه فوراً", avatarIcon: Icons.gavel_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
        ChoiceModel(text: "أتقبل اعتذاره وأقول: لا بأس، حصل خير", avatarIcon: Icons.handshake_rounded, avatarColor: Colors.cyanAccent, isCorrect: true),
      ],
    ),
    // Level 5: Very Hard - Bystander intervention / Safety
    ScenarioModel(
      level: 5,
      description: "رأيت أطفالاً أكبر سناً يتنمرون على طفل صغير وأنت تشعر بالخوف.",
      successMessage: "التصرف بحكمة وطلب مساعدة الكبار هو أذكى وأشجع قرار! 🏆",
      tryAgainMessage: "التدخل العنيف خطر، والتجاهل سيء. ابحث عن حل آمن وذكي 💙",
      choices: [
        ChoiceModel(text: "أهاجم المتنمرين بقوة لأدافع عنه", avatarIcon: Icons.sports_martial_arts_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
        ChoiceModel(text: "أذهب فوراً لإخبار أقرب معلم بصمت", avatarIcon: Icons.support_agent_rounded, avatarColor: Colors.cyanAccent, isCorrect: true),
        ChoiceModel(text: "أقف وأشاهد بصمت كي لا يؤذوني", avatarIcon: Icons.visibility_rounded, avatarColor: Colors.cyanAccent, isCorrect: false),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Optional: Shuffle choices for each scenario so the correct answer isn't always in the same spot
    for (var scenario in _scenarios) {
      scenario.choices.shuffle();
    }
  }

  void _onChoiceSelected(int index) async {
    if (_isAnimatingChoice) return;

    setState(() {
      _selectedChoiceIndex = index;
      _isAnimatingChoice = true;
    });

    final choice = _scenarios[_currentScenarioIndex].choices[index];

    if (choice.isCorrect) {
      HapticFeedback.heavyImpact();
      setState(() {
        _kindnessScore += 50 * _endlessLevel; // Higher levels give more points
        _showSuccessParticles = true;
      });

      _showFeedbackDialog(true, _scenarios[_currentScenarioIndex].successMessage);

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _showSuccessParticles = false;
        _selectedChoiceIndex = null;
        _isAnimatingChoice = false;
        
        // Endless progression
        _endlessLevel++;
        _currentScenarioIndex = (_currentScenarioIndex + 1) % _scenarios.length;
        _scenarios[_currentScenarioIndex].choices.shuffle();
      });
    } else {
      HapticFeedback.vibrate();

      _showFeedbackDialog(false, _scenarios[_currentScenarioIndex].tryAgainMessage);

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _selectedChoiceIndex = null;
        _isAnimatingChoice = false;
      });
    }
  }

  void _showFeedbackDialog(bool isCorrect, String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: EdgeInsets.only(top: 150.h, left: 20.w, right: 20.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.all(25.w),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.greenAccent.withValues(alpha: 0.1)
                        : Colors.orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.greenAccent.withValues(alpha: 0.5)
                          : Colors.orangeAccent.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCorrect
                            ? Colors.greenAccent.withValues(alpha: 0.2)
                            : Colors.orangeAccent.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCorrect ? "أحسنت! ❤️" : "حاول مرة أخرى",
                          style: TextStyle(
                            color: isCorrect ? Colors.greenAccent : Colors.orangeAccent,
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                  color: (isCorrect ? Colors.greenAccent : Colors.orangeAccent)
                                      .withValues(alpha: 0.8),
                                  blurRadius: 10)
                            ],
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ).animate().slideY(begin: -0.5, end: 0, curve: Curves.easeOutExpo).fadeIn(),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    final currentScenario = _scenarios[_currentScenarioIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF03001C),
      body: Stack(
        children: [
          const AnimatedSpaceBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 10.h),
                _buildHUD(_endlessLevel),
                SizedBox(height: 25.h),
                _buildScenarioCard(currentScenario),
                SizedBox(height: 20.h),
                // "ماذا ستفعل؟" Text
                Center(
                  child: Text(
                    "ماذا ستفعل؟",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.cyanAccent.withValues(alpha: 0.8), blurRadius: 10),
                      ],
                    ),
                  ),
                ).animate(key: ValueKey(currentScenario.level)).fadeIn(duration: 500.ms),
                SizedBox(height: 15.h),
                Expanded(child: _buildChoices(currentScenario)),
              ],
            ),
          ),
          if (_showSuccessParticles)
            Positioned.fill(
              child: Center(
                child: Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 150.sp)
                    .animate(onPlay: (c) => c.forward())
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 600.ms, curve: Curves.elasticOut)
                    .fadeOut(delay: 1.seconds, duration: 500.ms)
                    .moveY(begin: 0, end: -200, duration: 1.5.seconds),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'رحلة اللطف 🌟',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.pinkAccent.withValues(alpha: 0.8), blurRadius: 15),
              ],
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildHUD(int currentLevel) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(Icons.military_tech_rounded, color: Colors.cyanAccent, size: 28.sp),
                    SizedBox(width: 5.w),
                    Text(
                      "مستوى $currentLevel",
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                    ).animate(key: ValueKey(currentLevel)).scale(duration: 300.ms),
                  ],
                ),
                Container(width: 1, height: 30.h, color: Colors.white24),
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "$_kindnessScore",
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ).animate(key: ValueKey(_kindnessScore)).scale(duration: 200.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioCard(ScenarioModel scenario) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 35.h, horizontal: 25.w),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6A1B9A).withValues(alpha: 0.4),
                  const Color(0xFF1E88E5).withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Text(
              scenario.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.5,
              ),
            ).animate(key: ValueKey(scenario.description)).fadeIn(duration: 500.ms),
          ),
        ),
      ),
    );
  }

  Widget _buildChoices(ScenarioModel scenario) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      itemCount: scenario.choices.length,
      itemBuilder: (context, index) {
        final choice = scenario.choices[index];
        final isSelected = _selectedChoiceIndex == index;

        Color bgColor = Colors.white.withValues(alpha: 0.05);
        Color borderColor = Colors.white.withValues(alpha: 0.15);
        Color shadowColor = Colors.transparent;

        if (isSelected) {
          if (choice.isCorrect) {
            bgColor = Colors.greenAccent.withValues(alpha: 0.2);
            borderColor = Colors.greenAccent;
            shadowColor = Colors.greenAccent.withValues(alpha: 0.3);
          } else {
            bgColor = Colors.redAccent.withValues(alpha: 0.2);
            borderColor = Colors.redAccent;
            shadowColor = Colors.redAccent.withValues(alpha: 0.3);
          }
        }

        Widget button = GestureDetector(
          onTap: () => _onChoiceSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(bottom: 20.h),
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1.5),
              boxShadow: [
                if (isSelected)
                  BoxShadow(color: shadowColor, blurRadius: 15, spreadRadius: 2)
              ],
            ),
            child: Row(
              children: [
                // Professional Avatar Icon
                Container(
                  width: 55.r,
                  height: 55.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        choice.avatarColor.withValues(alpha: 0.8),
                        choice.avatarColor.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: choice.avatarColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: choice.avatarColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      choice.avatarIcon,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                // Choice Text
                Expanded(
                  child: Text(
                    choice.text,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Status Icon (if selected)
                if (isSelected)
                  Icon(
                    choice.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: choice.isCorrect ? Colors.greenAccent : Colors.redAccent,
                    size: 28.sp,
                  ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
              ],
            ),
          ),
        );

        if (isSelected && !choice.isCorrect) {
          button = button.animate().shakeX(duration: 400.ms, hz: 4);
        } else if (isSelected && choice.isCorrect) {
          button = button
              .animate()
              .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 200.ms)
              .then()
              .scale(begin: const Offset(1.05, 1.05), end: const Offset(1, 1));
        }

        // Add a slight fade-in delay for choices based on index to look dynamic
        return button.animate(key: ValueKey("${scenario.level}_$index")).fadeIn(delay: (100 * index).ms).slideX(begin: 0.2, end: 0, duration: 300.ms);
      },
    );
  }
}
