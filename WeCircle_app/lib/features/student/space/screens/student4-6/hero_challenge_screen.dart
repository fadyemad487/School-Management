import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app_theme.dart';

class HeroChallengeScreen extends StatefulWidget {
  const HeroChallengeScreen({super.key});

  @override
  State<HeroChallengeScreen> createState() => _HeroChallengeScreenState();
}

class _HeroChallengeScreenState extends State<HeroChallengeScreen> {
  int _currentMissionIdx = 0;

  final List<Map<String, dynamic>> _missions = [
    {
      'id': 'focus',
      'title': 'بطل التركيز الفائق 🎯',
      'topic': 'عدم التركيز',
      'story':
          'أنت الآن في منطقة النيازك المشتتة! المدرس بيشرح وأصحابك بيتكلموا جنبك. هتعمل إيه عشان تحمي "وقود المعلومات"؟',
      'icon': '🎯',
      'options': [
        {'text': 'أركز مع المدرس وأتجاهل النيازك (المشتتات)', 'correct': true},
        {'text': 'أشوف أصحابي بيقولوا إيه (ضياع الوقود)', 'correct': false},
      ],
      'feedbackCorrect': 'رائع! حافظت على شحنة التركيز كاملة. 🔋',
      'feedbackWrong': 'أوه! النيازك سحبت انتباهك وضاع جزء من الوقود. ⚠️',
    },
    {
      'id': 'stubborn',
      'title': 'ملك الاختيار الذكي 👑',
      'topic': 'العناد',
      'story':
          'القائد خيرك: "تحب ترتب الكبسولة دلوقتي ولا بعد 5 دقائق؟" بس أنت مش عاوز ترتب خالص. بطل WeCircle بيعمل إيه؟',
      'icon': '👑',
      'options': [
        {'text': 'أختار واحد من الحلين وأنفذه بذكاء', 'correct': true},
        {'text': 'أقول "لأ" ومش هعمل حاجة', 'correct': false},
      ],
      'feedbackCorrect': 'ممتاز! التحكم في النفس هو سر القوة الحقيقة. ⭐',
      'feedbackWrong': 'العناد بيخلي السفينة تقف مكانها ومبتوصلش. 🚫',
    },
    {
      'id': 'hyper',
      'title': 'كابتن الهدوء والمهمات 🧘‍♂️',
      'topic': 'المشاغبة',
      'story':
          'عندك طاقة كبيرة وعاوز تتحرك في السفينة وقت الشرح. هتعمل إيه عشان متخبطش في الأجهزة الحساسة؟',
      'icon': '🧘‍♂️',
      'options': [
        {'text': 'أسمع التعليمات وبعد المهمة أتحرك براحتي', 'correct': true},
        {'text': 'أتحرك وأجري وأنا مش مركز مع القائد', 'correct': false},
      ],
      'feedbackCorrect': 'أنت قائد حقيقي! عرفت تتحكم في طاقتك في الوقت الصح. ✨',
      'feedbackWrong': 'الحركة العشوائية عطلت أجهزة السفينة وحصلت فوضى. ⚠️',
    },
    {
      'id': 'bullying',
      'title': 'درع الصداقة واللطف 🛡️',
      'topic': 'التنمر',
      'story':
          'شوفت رائد فضاء جديد زعلان لوحده. هل تساعده وتكون صديقه ولا تضحك عليه مع الباقيين؟',
      'icon': '🛡️',
      'options': [
        {'text': 'أروح أساعده وأقوله كلمة تشجعه', 'correct': true},
        {'text': 'أهزر عليه وأخليه يزعل أكتر', 'correct': false},
      ],
      'feedbackCorrect': 'قلب البطل هو أكبر قوة في الكون! أحسنت. ❤️',
      'feedbackWrong': 'الأبطال مبيأذوش حد، التصرف ده بيطفي نور السفينة. 🌑',
    },
    {
      'id': 'dependency',
      'title': 'رائد الفضاء المستقل 🚀',
      'topic': 'الاعتمادية',
      'story':
          'واجهت مشكلة في حل لغز كوني. هل تحاول تفكر فيه لوحدك الأول ولا تنادي المساعدة فوراً؟',
      'icon': '🚀',
      'options': [
        {'text': 'أحاول وأفكر 3 مرات قبل ما أطلب المساعدة', 'correct': true},
        {'text': 'أنادي حد يحلهولي وأنا قاعد أتفرج', 'correct': false},
      ],
      'feedbackCorrect': 'برافو! عقلك كبر وبقيت رائد فضاء يعتمد عليه. 🧠',
      'feedbackWrong': 'الاعتماد على الغير بيخلي عضلات التفكير تضعف. 💪',
    },
  ];

  void _handleChoice(bool isCorrect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B0044),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text(
          isCorrect ? 'نجاح المهمة 🚀' : 'تنبيه من القاعدة ☄️',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isCorrect
              ? _missions[_currentMissionIdx]['feedbackCorrect']
              : _missions[_currentMissionIdx]['feedbackWrong'],
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isCorrect && _currentMissionIdx < _missions.length - 1) {
                setState(() => _currentMissionIdx++);
              } else if (isCorrect &&
                  _currentMissionIdx == _missions.length - 1) {
                Navigator.pop(context);
              }
            },
            child: Text(
              isCorrect ? 'المهمة التالية' : 'حاول مرة أخرى',
              style: const TextStyle(
                color: AppTheme.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mission = _missions[_currentMissionIdx];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF03001C),
        body: Stack(
          children: [
            // Background cosmic elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300.r,
                height: 300.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.skyBlue.withValues(alpha: 0.1),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 60.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          const Text(
                            'تحديات الأبطال',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'مهمة ${_currentMissionIdx + 1} من ${_missions.length}',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  SizedBox(height: 40.h),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: LinearProgressIndicator(
                      value: (_currentMissionIdx + 1) / _missions.length,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.emeraldGreen,
                      ),
                      minHeight: 8.h,
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Mission Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(32.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(35.r),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          mission['icon'],
                          style: const TextStyle(fontSize: 60),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(height: 20.h),
                        Text(
                          mission['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          mission['story'],
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16.sp,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Options
                  ...List.generate(mission['options'].length, (idx) {
                    final opt = mission['options'][idx];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: GestureDetector(
                        onTap: () => _handleChoice(opt['correct']),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: 20.h,
                            horizontal: 24.w,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20.w,
                                height: 20.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 2,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Text(
                                  opt['text'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
