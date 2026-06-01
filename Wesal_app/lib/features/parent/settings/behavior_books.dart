import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

class BehaviorBooks extends StatelessWidget {
  const BehaviorBooks({super.key});

  static final List<BehaviorArticle> _articles = [
    BehaviorArticle(
      titleAr: 'التعامل مع نوبات الغضب',
      titleEn: 'Handling Tantrums',
      categoryAr: 'تعديل سلوك',
      categoryEn: 'Behavior',
      summaryAr: 'كيف تتعامل مع صراخ الطفل وغضبه المفاجئ بطريقة تربوية هادئة.',
      summaryEn: 'How to respond calmly and constructively to sudden anger.',
      bodyAr: [
        'نوبات الغضب غالبا تكون رسالة من الطفل أنه لا يعرف كيف يعبّر عن احتياجه أو إحباطه. ابدأ بالهدوء وخفّض نبرة صوتك حتى لا يتحول الموقف إلى صراع.',
        'سمّ الشعور أمامه بجملة قصيرة مثل: "أنت غاضب لأن اللعبة توقفت". هذا يساعده على فهم ما يحدث داخله بدلا من الاكتفاء بالصراخ.',
        'بعد أن يهدأ، اتفق معه على بديل واضح: يطلب المساعدة، يأخذ دقيقة تنفس، أو يستخدم كلمات محددة بدل الضرب أو الصراخ.',
      ],
    ),
    BehaviorArticle(
      titleAr: 'قوة التشجيع الإيجابي',
      titleEn: 'Positive Encouragement',
      categoryAr: 'تحفيز',
      categoryEn: 'Motivation',
      summaryAr:
          'لماذا ينجح المديح في تغيير السلوك أكثر من العقاب؟ وكيف تطبقه؟',
      summaryEn:
          'Why praise changes behavior better than punishment and how to use it.',
      bodyAr: [
        'التشجيع الإيجابي يلفت انتباه الطفل للسلوك الذي نريد تكراره. امدح السلوك نفسه لا شخصية الطفل: "رتبت أدواتك بسرعة" أفضل من "أنت ممتاز" فقط.',
        'اجعل التشجيع فوريا وقصيرا. الطفل يربط المكافأة أو الكلمة الطيبة بالسلوك عندما تأتي بعده مباشرة.',
        'استخدم جدول نجوم بسيط للسلوكيات اليومية، لكن لا تجعل كل تصرف مرتبطا بجائزة مادية. الكلمة الدافئة والاهتمام غالبا أقوى.',
      ],
    ),
    BehaviorArticle(
      titleAr: 'وضع الحدود الذكية',
      titleEn: 'Smart Boundaries',
      categoryAr: 'انضباط',
      categoryEn: 'Discipline',
      summaryAr: 'كيف تضع قوانين منزلية يحترمها الطفل بدون صراخ أو تهديد.',
      summaryEn: 'How to create calm household rules children can follow.',
      bodyAr: [
        'الحدود الذكية قليلة وواضحة. اختر ثلاث قواعد أساسية فقط في البداية، واكتبها بلغة بسيطة يفهمها الطفل.',
        'اربط كل قاعدة بنتيجة طبيعية ومنطقية. إذا لم تُجمع الألعاب، تتوقف لعبة معينة حتى يتم ترتيب المكان.',
        'الثبات أهم من الشدة. تطبيق هادئ ومتكرر لنفس القاعدة يعطي الطفل إحساسا بالأمان ويقلل اختبار الحدود.',
      ],
    ),
    BehaviorArticle(
      titleAr: 'تنمية الذكاء العاطفي',
      titleEn: 'Emotional Intelligence',
      categoryAr: 'ذكاء عاطفي',
      categoryEn: 'Emotions',
      summaryAr: 'ساعد طفلك على فهم مشاعره والتعامل معها بذكاء.',
      summaryEn:
          'Help your child understand and manage feelings intelligently.',
      bodyAr: [
        'ابدأ بتسمية المشاعر في الحياة اليومية: فرح، خوف، غيرة، إحباط. الطفل الذي يعرف اسم شعوره يستطيع التعامل معه بشكل أفضل.',
        'اسأله: "أين تشعر بهذا في جسمك؟" هذا السؤال ينقل الطفل من الانفعال إلى الملاحظة والوعي.',
        'درّبه على بدائل عملية مثل التنفس البطيء، الرسم، طلب حضن، أو التحدث مع شخص آمن عندما تضغط عليه المشاعر.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final pageWidth = MediaQuery.sizeOf(context).width.clamp(0, 390).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF5FF),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BooksBgPainter())),
          SafeArea(
            bottom: false,
            child: Center(
              child: SizedBox(
                width: pageWidth,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 28.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _BackCircle(onTap: () => Navigator.pop(context)),
                          Expanded(
                            child: Text(
                              isArabic ? 'مقالات سلوكية' : 'Behavior Articles',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF9B2FE3),
                                fontSize: 23.sp.clamp(20, 24),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(width: 44.r),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      ..._articles
                          .map((article) => _ArticleCard(article: article)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BehaviorArticleDetails extends StatelessWidget {
  final BehaviorArticle article;
  const BehaviorArticleDetails({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final title = isArabic ? article.titleAr : article.titleEn;
    final category = isArabic ? article.categoryAr : article.categoryEn;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF5FF),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BooksBgPainter())),
          SafeArea(
            child: Center(
              child: SizedBox(
                width:
                    MediaQuery.sizeOf(context).width.clamp(0, 390).toDouble(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(18.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _BackCircle(onTap: () => Navigator.pop(context)),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                fontSize: 19.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF172033),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(26.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5147E8)
                                  .withValues(alpha: 0.08),
                              blurRadius: 24.r,
                              offset: Offset(0, 12.h),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: _Tag(text: category),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              isArabic ? article.summaryAr : article.summaryEn,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                fontSize: 12.5.sp,
                                height: 1.8,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMedium,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            ...article.bodyAr.map(
                              (paragraph) => Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: Text(
                                  paragraph,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.5.sp,
                                    height: 1.9,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF20283A),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final BehaviorArticle article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BehaviorArticleDetails(article: article)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 18.w, 16.h),
        constraints: BoxConstraints(minHeight: 112.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5147E8).withValues(alpha: 0.07),
              blurRadius: 20.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.chevron_left_rounded,
                color: const Color(0xFFC89BEA), size: 30.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Tag(
                      text: isArabic ? article.categoryAr : article.categoryEn),
                  SizedBox(height: 12.h),
                  Text(
                    isArabic ? article.titleAr : article.titleEn,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 17.5.sp.clamp(16, 19),
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF172033),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isArabic ? article.summaryAr : article.summaryEn,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E6FF),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF9B2FE3),
        ),
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _BackCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44.r,
        height: 44.r,
        child: Icon(Icons.chevron_right_rounded,
            color: const Color(0xFF9B2FE3), size: 34.r),
      ),
    );
  }
}

class _BooksBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final softBlue = Paint()
      ..color = const Color(0xFFBDE4FF).withValues(alpha: 0.33);
    final softPurple = Paint()
      ..color = const Color(0xFFE3D5FF).withValues(alpha: 0.42);
    final linePaint = Paint()
      ..color = const Color(0xFF8795AD).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(
        Offset(size.width * .78, size.height * .06), 82.r, softPurple);
    canvas.drawCircle(
        Offset(size.width * .18, size.height * .39), 96.r, softBlue);
    canvas.drawCircle(
        Offset(size.width * .82, size.height * .82), 118.r, softPurple);

    for (var i = 0; i < 5; i++) {
      final x = size.width * (.12 + i * .18);
      canvas.drawLine(Offset(x, size.height * .16),
          Offset(x + 46, size.height * .06), linePaint);
      canvas.drawCircle(
          Offset(x + 22, size.height * (.22 + i * .12)), 22.r, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BehaviorArticle {
  final String titleAr;
  final String titleEn;
  final String categoryAr;
  final String categoryEn;
  final String summaryAr;
  final String summaryEn;
  final List<String> bodyAr;

  const BehaviorArticle({
    required this.titleAr,
    required this.titleEn,
    required this.categoryAr,
    required this.categoryEn,
    required this.summaryAr,
    required this.summaryEn,
    required this.bodyAr,
  });
}
