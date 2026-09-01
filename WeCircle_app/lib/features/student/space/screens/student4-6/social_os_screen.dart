import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum SocialOSState { receiving, analyzing, deciding, evaluating }

class SocialResponse {
  final String text;
  final String type; // Defensive, Analytical, Strategic, Delayed
  final double relationshipImpact; // -1.0 to 1.0
  final double reputationImpact; // -1.0 to 1.0
  final String analysis;

  SocialResponse({
    required this.text,
    required this.type,
    required this.relationshipImpact,
    required this.reputationImpact,
    required this.analysis,
  });
}

class SocialScenario {
  final String sender;
  final String message;
  final String emotionalTone; // Anger, Frustration, Neutral, Friendly
  final String intentType; // Criticism, Sarcasm, Request, Misunderstanding
  final int riskLevel; // 1-3
  final List<SocialResponse> options;

  SocialScenario({
    required this.sender,
    required this.message,
    required this.emotionalTone,
    required this.intentType,
    required this.riskLevel,
    required this.options,
  });
}

class SocialOSScreen extends StatefulWidget {
  const SocialOSScreen({super.key});

  @override
  State<SocialOSScreen> createState() => _SocialOSScreenState();
}

class _SocialOSScreenState extends State<SocialOSScreen>
    with TickerProviderStateMixin {
  SocialOSState _state = SocialOSState.receiving;
  int _currentLevel = 1;
  double _socialScore = 750;
  double _relationshipStatus = 0.8;
  
  late SocialScenario _currentScenario;
  SocialResponse? _selectedResponse;

  final List<SocialScenario> _scenarios = [
    // 1. Academic & School
    SocialScenario(
      sender: 'زميل الدراسة',
      message: 'يا لك من "ذكي"، دائماً ما تسلم مشاريعك في آخر لحظة وتحصل على الدرجة الكاملة!',
      emotionalTone: 'سخرية / غيرة',
      intentType: 'سخرية (Sarcasm)',
      riskLevel: 2,
      options: [
        SocialResponse(text: 'شكراً، الذكاء موهبة لا يملكها الجميع.', type: 'هجومي', relationshipImpact: -0.3, reputationImpact: -0.1, analysis: 'هذا الرد يزيد من حدة التوتر ويجعلك تبدو مغروراً.'),
        SocialResponse(text: 'فعلاً، لقد كان وقتاً ضيقاً جداً، المرة القادمة سأبدأ مبكراً.', type: 'تحليلي', relationshipImpact: 0.2, reputationImpact: 0.1, analysis: 'رد هادئ يمتص الغضب ويركز على تحسين الذات.'),
        SocialResponse(text: 'أحياناً يكون الضغط محفزاً، هل تحتاج مساعدة في مشروعك؟', type: 'استراتيجي', relationshipImpact: 0.5, reputationImpact: 0.3, analysis: 'رد ذكي يحول السخرية إلى فرصة لبناء علاقة ودعم الزميل.'),
      ],
    ),
    SocialScenario(
      sender: 'صديق مقرب',
      message: 'لماذا لم ترد على رسائلي بالأمس؟ لقد كنت أحتاج للتحدث معك في أمر هام.',
      emotionalTone: 'إحباط',
      intentType: 'عتاب',
      riskLevel: 1,
      options: [
        SocialResponse(text: 'كنت مشغولاً جداً، لا يمكنني الرد دائماً.', type: 'هجومي', relationshipImpact: -0.4, reputationImpact: 0.0, analysis: 'رد قاسي يتجاهل مشاعر الصديق وحاجته للدعم.'),
        SocialResponse(text: 'أعتذر بشدة، لقد كان هاتفي صامتاً. أنا هنا الآن، ماذا حدث؟', type: 'تحليلي', relationshipImpact: 0.4, reputationImpact: 0.1, analysis: 'توضيح هادئ واعتذار يرمم العلاقة فوراً.'),
        SocialResponse(text: 'حقك عليّ، سأخصص وقتاً للحديث معك الليلة لنعوض ذلك.', type: 'استراتيجي', relationshipImpact: 0.6, reputationImpact: 0.2, analysis: 'تحمل المسؤولية وتقديم حل عملي لتعميق الصداقة.'),
      ],
    ),
    // 2. Family
    SocialScenario(
      sender: 'الأخ الأكبر',
      message: 'لقد استعرت سماعاتي دون استئذان مرة أخرى! لا تلمس أشيائي أبداً.',
      emotionalTone: 'غضب',
      intentType: 'تحذير / صراع',
      riskLevel: 2,
      options: [
        SocialResponse(text: 'أنت أيضاً تأخذ أشيائي دائماً، توقف عن الصراخ.', type: 'هجومي', relationshipImpact: -0.5, reputationImpact: -0.2, analysis: 'الرد بالمثل يزيد من الصراع العائلي.'),
        SocialResponse(text: 'آسف، كنت أحتاجها لدرس سريع. سأعيدها الآن ولن يتكرر ذلك.', type: 'تحليلي', relationshipImpact: 0.3, reputationImpact: 0.1, analysis: 'الاعتراف بالخطأ ينهي التوتر بسرعة.'),
        SocialResponse(text: 'اعتذاري، سأشتري لنفسي واحدة قريباً. هل يمكنني استخدامها لـ10 دقائق أخرى؟', type: 'استراتيجي', relationshipImpact: 0.2, reputationImpact: 0.1, analysis: 'اعتذار مع محاولة تفاوض هادئة.'),
      ],
    ),
    // 3. Social Media / Digital
    SocialScenario(
      sender: 'شخص مجهول',
      message: 'صورتك التي نشرتها تبدو مضحكة جداً، أنت لا تعرف كيف تختار ملابسك!',
      emotionalTone: 'سخرية',
      intentType: 'تنمر إلكتروني',
      riskLevel: 3,
      options: [
        SocialResponse(text: 'انظر إلى نفسك أولاً قبل أن تتحدث عن الآخرين.', type: 'هجومي', relationshipImpact: -0.1, reputationImpact: -0.3, analysis: 'الرد على المتنمرين بنفس أسلوبهم يعطيهم ما يريدون.'),
        SocialResponse(text: 'الأذواق تختلف، وأنا معجب بها. شكراً لرأيك.', type: 'تحليلي', relationshipImpact: 0.1, reputationImpact: 0.4, analysis: 'رد واثق وغير منفعل ينهي المحادثة بذكاء.'),
        SocialResponse(text: '(تجاهل الرسالة وحظر المستخدم)', type: 'استراتيجي', relationshipImpact: 0.0, reputationImpact: 0.5, analysis: 'أفضل رد على التنمر المجهول هو عدم إعطائهم أي اهتمام.'),
      ],
    ),
    // 4. Group Projects
    SocialScenario(
      sender: 'قائد الفريق',
      message: 'الجزء الذي كتبته في البحث ضعيف جداً، سأضطر لإعادته بنفسي.',
      emotionalTone: 'استعلاء',
      intentType: 'نقد قاسي',
      riskLevel: 2,
      options: [
        SocialResponse(text: 'افعل ما تريد، أنا بذلت جهدي وهذا يكفي.', type: 'دفاعي', relationshipImpact: -0.4, reputationImpact: -0.2, analysis: 'الانسحاب السلبي يضعف موقفك في الفريق.'),
        SocialResponse(text: 'ما هي النقاط الضعيفة بالضبط؟ أريد أن أتعلم كيف أحسنه.', type: 'تحليلي', relationshipImpact: 0.4, reputationImpact: 0.5, analysis: 'تحويل النقد إلى فرصة للتعلم يظهر نضجك.'),
        SocialResponse(text: 'أقدر حرصك، دعنا نجلس معاً لـ10 دقائق لنعدله سوياً.', type: 'استراتيجي', relationshipImpact: 0.6, reputationImpact: 0.4, analysis: 'حل تعاوني يحافظ على روح الفريق ويحسن جودة العمل.'),
      ],
    ),
    // 5. Ethical Dilemma
    SocialScenario(
      sender: 'زميل',
      message: 'لقد وجدت محفظة في الساحة، دعنا نأخذ المال ونقسمه بيننا، لن يعرف أحد.',
      emotionalTone: 'إغراء',
      intentType: 'عرض غير أخلاقي',
      riskLevel: 3,
      options: [
        SocialResponse(text: 'فكرة رائعة، أنا أحتاج لبعض المال فعلاً.', type: 'مندفع', relationshipImpact: 0.2, reputationImpact: -0.8, analysis: 'قرار غير أخلاقي يدمر سمعتك تماماً إذا اكتُشف.'),
        SocialResponse(text: 'هذا خطأ، يجب أن نسلمها للمدير فوراً.', type: 'تحليلي', relationshipImpact: -0.1, reputationImpact: 0.7, analysis: 'موقف أخلاقي حازم يحمي نزاهتك.'),
        SocialResponse(text: 'تخيل لو كانت محفظتك؟ دعنا نبحث عن صاحبها، سيكون ممتناً جداً.', type: 'استراتيجي', relationshipImpact: 0.3, reputationImpact: 0.8, analysis: 'استخدام التعاطف لإقناع الطرف الآخر بفعل الصواب.'),
      ],
    ),
    // 6. Time Management
    SocialScenario(
      sender: 'صديق',
      message: 'هيا نخرج الآن لنتمشى، يمكنك إكمال واجبك في الصباح الباكر.',
      emotionalTone: 'حماس',
      intentType: 'تشتيت',
      riskLevel: 1,
      options: [
        SocialResponse(text: 'حسناً، الدراسة مملة على أي حال.', type: 'مندفع', relationshipImpact: 0.3, reputationImpact: -0.3, analysis: 'تفضيل المتعة اللحظية على المسؤولية يضرك مستقبلاً.'),
        SocialResponse(text: 'لا أستطيع، يجب أن أنهي واجبي الآن لأنام مبكراً.', type: 'تحليلي', relationshipImpact: 0.1, reputationImpact: 0.4, analysis: 'وضع حدود واضحة لمهامك يظهر انضباطك.'),
        SocialResponse(text: 'سأنهي عملي في ساعة، ثم نخرج لنحتفل بالإنجاز معاً.', type: 'استراتيجي', relationshipImpact: 0.5, reputationImpact: 0.5, analysis: 'توازن ذكي بين العمل والترويح عن النفس.'),
      ],
    ),
    // 7. Sibling Support
    SocialScenario(
      sender: 'الأخت الصغيرة',
      message: 'لقد كسرت كوب أمي المفضل بالخطأ، أنا خائفة جداً، ماذا أفعل؟',
      emotionalTone: 'خوف / قلق',
      intentType: 'طلب مساعدة',
      riskLevel: 1,
      options: [
        SocialResponse(text: 'أنت دائماً مهملة، ستوبخك أمي كثيراً.', type: 'هجومي', relationshipImpact: -0.6, reputationImpact: -0.1, analysis: 'زيادة خوف الطرف الضعيف يقلل الثقة بينكما.'),
        SocialResponse(text: 'لا تخافي، سأذهب معك لنخبر أمي بالحقيقة ونعتذر.', type: 'تحليلي', relationshipImpact: 0.7, reputationImpact: 0.4, analysis: 'دعم عاطفي وعملي يعزز الروابط الأخوية.'),
        SocialResponse(text: 'دعينا ننظف المكان أولاً، ثم نشتري واحداً جديداً قبل عودتها.', type: 'استراتيجي', relationshipImpact: 0.5, reputationImpact: 0.2, analysis: 'محاولة حل المشكلة بسرعة، لكن الصدق دائماً أفضل.'),
      ],
    ),
    // 8. Public Criticism
    SocialScenario(
      sender: 'زميل في الفصل',
      message: 'إجابتك اليوم كانت خاطئة تماماً ومحرجة أمام الجميع!',
      emotionalTone: 'استفزاز',
      intentType: 'إحراج علني',
      riskLevel: 2,
      options: [
        SocialResponse(text: 'على الأقل أنا أشارك، أنت تجلس صامتاً دائماً.', type: 'هجومي', relationshipImpact: -0.4, reputationImpact: -0.3, analysis: 'الرد بالهجوم الشخصي يجعلك تبدو ضعيفاً.'),
        SocialResponse(text: 'الخطأ جزء من التعلم، المهم أنني عرفت الإجابة الصحيحة الآن.', type: 'تحليلي', relationshipImpact: 0.2, reputationImpact: 0.6, analysis: 'رد ناضج يظهر ثقتك بنفسك ويحرج المستفز.'),
        SocialResponse(text: 'شكراً لملاحظتك، هل يمكنك شرح النقطة التي أخطأت فيها؟', type: 'استراتيجي', relationshipImpact: 0.3, reputationImpact: 0.7, analysis: 'رد ذكي جداً يحول الموقف لصالحك ويظهر رغبتك في التطور.'),
      ],
    ),
    // 9. Borrowing Items
    SocialScenario(
      sender: 'ابن عمك',
      message: 'هل يمكنني استعارة دراجتك لأسبوع؟ أريد الذهاب بها للنادي.',
      emotionalTone: 'رجاء',
      intentType: 'طلب استعارة',
      riskLevel: 1,
      options: [
        SocialResponse(text: 'لا، أنت دائماً تكسر الأشياء.', type: 'هجومي', relationshipImpact: -0.5, reputationImpact: -0.1, analysis: 'رفض قاسي يسيء للعلاقة العائلية.'),
        SocialResponse(text: 'أحتاجها للذهاب للمدرسة، لكن يمكنني إعطاؤها لك في عطلة نهاية الأسبوع.', type: 'تحليلي', relationshipImpact: 0.4, reputationImpact: 0.3, analysis: 'توضيح السبب مع تقديم حل بديل يحافظ على الود.'),
        SocialResponse(text: 'بالطبع، بشرط أن تعتني بها جيداً وتعيدها في الموعد.', type: 'استراتيجي', relationshipImpact: 0.6, reputationImpact: 0.4, analysis: 'كرم مع وضع شروط واضحة للمحافظة على ممتلكاتك.'),
      ],
    ),
    // 10. Group Inclusion
    SocialScenario(
      sender: 'زميل جديد',
      message: 'هل يمكنني الجلوس معكم في وقت الغداء؟ لا أعرف أحداً هنا.',
      emotionalTone: 'تردد / خجل',
      intentType: 'محاولة اندماج',
      riskLevel: 1,
      options: [
        SocialResponse(text: 'طاولتنا ممتلئة، ابحث عن مكان آخر.', type: 'هجومي', relationshipImpact: -0.7, reputationImpact: -0.5, analysis: 'القسوة مع الغرباء تظهر شخصية غير مرحبة.'),
        SocialResponse(text: 'أهلاً بك، نحن نتحدث عن كرة القدم، هل تحبها؟', type: 'تحليلي', relationshipImpact: 0.8, reputationImpact: 0.6, analysis: 'ترحيب حار يساعد الشخص الجديد على الاندماج فوراً.'),
        SocialResponse(text: 'تفضل، سأعرفك على بقية الأصدقاء.', type: 'استراتيجي', relationshipImpact: 0.9, reputationImpact: 0.7, analysis: 'دور قيادي في الترحيب وبناء علاقات جديدة.'),
      ],
    ),
    // 11. Teacher Interaction
    SocialScenario(
      sender: 'المعلم',
      message: 'لقد لاحظت تراجع مستواك في الاختبار الأخير، هل هناك مشكلة؟',
      emotionalTone: 'قلق',
      intentType: 'استفسار تربوي',
      riskLevel: 1,
      options: [
        SocialResponse(text: 'الاختبار كان صعباً جداً وغير عادل.', type: 'دفاعي', relationshipImpact: -0.2, reputationImpact: -0.4, analysis: 'إلقاء اللوم على الظروف يظهر عدم تحمل المسؤولية.'),
        SocialResponse(text: 'لم أذاكر جيداً هذه المرة، سأجتهد أكثر في الاختبار القادم.', type: 'تحليلي', relationshipImpact: 0.4, reputationImpact: 0.6, analysis: 'صدق وتحمل مسؤولية يبني ثقة المعلم بك.'),
        SocialResponse(text: 'شكراً لاهتمامك، هل يمكنك إرشادي لمصادر إضافية للمذاكرة؟', type: 'استراتيجي', relationshipImpact: 0.6, reputationImpact: 0.8, analysis: 'استغلال الموقف لإظهار الرغبة الجادة في التحسن.'),
      ],
    ),
    // 12. Secret Keeping
    SocialScenario(
      sender: 'صديق',
      message: 'سأخبرك بسراً كبيراً، لكن عدني ألا تخبر أحداً أبداً، حتى أهلك.',
      emotionalTone: 'سرية / ضغط',
      intentType: 'مشاركة سر',
      riskLevel: 2,
      options: [
        SocialResponse(text: 'أعدك، سري في بئر عميق.', type: 'مندفع', relationshipImpact: 0.5, reputationImpact: 0.0, analysis: 'الوعود المطلقة قد تضعك في ورطة إذا كان السر خطيراً.'),
        SocialResponse(text: 'إذا كان السر سيضرك أو يضر غيرك، سأضطر لإخبار شخص كبير.', type: 'تحليلي', relationshipImpact: -0.2, reputationImpact: 0.5, analysis: 'أمانة ومسؤولية تجاه سلامة الصديق.'),
        SocialResponse(text: 'أنا أسمعك، لكن دعنا نتفق أن الصدق دائماً أفضل من الأسرار.', type: 'استراتيجي', relationshipImpact: 0.3, reputationImpact: 0.4, analysis: 'تقديم النصح مع الحفاظ على دور الصديق المستمع.'),
      ],
    ),
    // 13. Peer Pressure (Health)
    SocialScenario(
      sender: 'زميل في النادي',
      message: 'جرب هذا المشروب السكري الجديد، سيعطيك طاقة خرافية للتمرين!',
      emotionalTone: 'إغراء',
      intentType: 'تأثير الأقران',
      riskLevel: 2,
      options: [
        SocialResponse(text: 'هاتِ واحداً، أريد أن أصبح أقوى بسرعة.', type: 'مندفع', relationshipImpact: 0.3, reputationImpact: -0.2, analysis: 'اتباع الآخرين دون تفكير في العواقب الصحية.'),
        SocialResponse(text: 'أفضل الماء، السكريات تسبب الخمول لاحقاً.', type: 'تحليلي', relationshipImpact: 0.1, reputationImpact: 0.5, analysis: 'تمسك بالعادات الصحية بوعي.'),
        SocialResponse(text: 'شكراً، لكني أتبع نظاماً غذائياً محدداً من مدربي.', type: 'استراتيجي', relationshipImpact: 0.2, reputationImpact: 0.6, analysis: 'رفض لبق ومقنع يحافظ على شخصيتك.'),
      ],
    ),
    // 14. Online Privacy
    SocialScenario(
      sender: 'صديق إلكتروني',
      message: 'أرسل لي رقم هاتفك وعنوانك لأرسل لك هدية فزت بها في اللعبة!',
      emotionalTone: 'ود مصطنع',
      intentType: 'تصيد بيانات',
      riskLevel: 3,
      options: [
        SocialResponse(text: 'حسناً، ها هو عنواني، أنا متحمس للهدية!', type: 'مندفع', relationshipImpact: 0.1, reputationImpact: -0.9, analysis: 'خطر شديد جداً على أمنك الشخصي وعائلتك.'),
        SocialResponse(text: 'والداي يمنعانني من إعطاء معلوماتي الغرباء. شكراً.', type: 'تحليلي', relationshipImpact: 0.0, reputationImpact: 0.8, analysis: 'التزام بقواعد الأمان الرقمي يحميك.'),
        SocialResponse(text: '(تجاهل الرسالة وإبلاغ الوالدين فوراً)', type: 'استراتيجي', relationshipImpact: 0.0, reputationImpact: 1.0, analysis: 'التصرف الأمثل والآمن عند التعامل مع الغرباء عبر الإنترنت.'),
      ],
    ),
    // 15. Financial Responsibility
    SocialScenario(
      sender: 'والدك',
      message: 'هذا مصروفك للشهر كاملاً، حاول أن تدخره وتصرفه بحكمة.',
      emotionalTone: 'توجيه',
      intentType: 'درس مالي',
      riskLevel: 1,
      options: [
        SocialResponse(text: 'سأشتري كل الألعاب التي أريدها اليوم!', type: 'مندفع', relationshipImpact: -0.2, reputationImpact: -0.5, analysis: 'سوء إدارة مالية سيجعلك تندم في نهاية الشهر.'),
        SocialResponse(text: 'سأضع نصفه في حصالتي وأصرف الباقي عند الحاجة.', type: 'تحليلي', relationshipImpact: 0.4, reputationImpact: 0.7, analysis: 'بداية رائعة لتعلم الادخار والمسؤولية.'),
        SocialResponse(text: 'شكراً، هل يمكننا وضع خطة معاً لأتعلم كيف أستثمره؟', type: 'استراتيجي', relationshipImpact: 0.8, reputationImpact: 0.9, analysis: 'رغبة في التعلم تثير إعجاب الوالدين وتنمي مهاراتك.'),
      ],
    ),
    // 16. Bullying Support
    SocialScenario(
      sender: 'زميل خائف',
      message: 'هناك طلاب في الخلف يهددونني بأخذ طعامي كل يوم، ماذا أفعل؟',
      emotionalTone: 'رعب',
      intentType: 'طلب استغاثة',
      riskLevel: 2,
      options: [
        SocialResponse(text: 'لا علاقة لي بالأمر، لا أريد أن يهاجموني أنا أيضاً.', type: 'دفاعي', relationshipImpact: -0.8, reputationImpact: -0.6, analysis: 'السلبية أمام الظلم تضعف شخصيتك وتدمر ثقة الآخرين بك.'),
        SocialResponse(text: 'يجب أن تخبر المشرف فوراً، وأنا سأشهد معك إذا لزم الأمر.', type: 'تحليلي', relationshipImpact: 0.7, reputationImpact: 0.8, analysis: 'شجاعة ومساندة حقيقية للمظلوم.'),
        SocialResponse(text: 'تعال لنجلس بجانب المعلمين اليوم، وسنفكر في خطة لمنعهم.', type: 'استراتيجي', relationshipImpact: 0.8, reputationImpact: 0.7, analysis: 'توفير حماية فورية وتفكير هادئ لحل المشكلة.'),
      ],
    ),
    // 17. Sarcastic Praise
    SocialScenario(
      sender: 'منافس في النادي',
      message: 'أوه، لقد فزت أخيراً! يبدو أن الحظ كان معك اليوم بشكل غريب.',
      emotionalTone: 'تقليل من الشأن',
      intentType: 'سخرية مغلفة بالمدح',
      riskLevel: 2,
      options: [
        SocialResponse(text: 'لقد فزت لأنني أفضل منك، اعترف بذلك.', type: 'هجومي', relationshipImpact: -0.5, reputationImpact: -0.2, analysis: 'الغرور يفسد فرحة الفوز ويصنع أعداء.'),
        SocialResponse(text: 'الحظ يأتي مع التدريب المستمر. شكراً على الروح الرياضية.', type: 'تحليلي', relationshipImpact: 0.2, reputationImpact: 0.8, analysis: 'رد دبلوماسي يحافظ على كبريائك ويحترم المنافسة.'),
        SocialResponse(text: 'لقد كانت مباراة صعبة، وأنت لعبت بشكل رائع أيضاً.', type: 'استراتيجي', relationshipImpact: 0.6, reputationImpact: 0.9, analysis: 'تجاهل السخرية والرد بروح رياضية عالية يظهر أنك بطل حقيقي.'),
      ],
    ),
    // 18. Misunderstanding
    SocialScenario(
      sender: 'والدتك',
      message: 'لماذا تركت غرفتك فوضوية؟ لقد طلبت منك ترتيبها قبل الخروج!',
      emotionalTone: 'انزعاج',
      intentType: 'سوء فهم / عتاب',
      riskLevel: 1,
      options: [
        SocialResponse(text: 'لقد رتبتها! أنتِ دائماً تتهمينني بالخطأ.', type: 'دفاعي', relationshipImpact: -0.4, reputationImpact: -0.2, analysis: 'الرد بانفعال يغلق أبواب التفاهم مع الوالدين.'),
        SocialResponse(text: 'عذراً يا أمي، ربما نسيت جزءاً منها. سأقوم بترتيبها الآن.', type: 'تحليلي', relationshipImpact: 0.5, reputationImpact: 0.3, analysis: 'طاعة واعتراف بالتقصير يمتص غضب الوالدين.'),
        SocialResponse(text: 'لقد حاولت ترتيبها بسرعة، هل يمكنك مساعدتي لنرى كيف يمكن تنظيمها بشكل أفضل؟', type: 'استراتيجي', relationshipImpact: 0.7, reputationImpact: 0.4, analysis: 'تحويل العتاب إلى وقت مشترك للتعلم والتعاون.'),
      ],
    ),
    // 19. Cheating Opportunity
    SocialScenario(
      sender: 'صديق في الامتحان',
      message: '(يهمس): أرني إجابة السؤال الثالث، سأفشل إذا لم أكتب شيئاً!',
      emotionalTone: 'يأس',
      intentType: 'طلب غش',
      riskLevel: 3,
      options: [
        SocialResponse(text: 'حسناً، خذ الورقة بسرعة قبل أن يراك المعلم.', type: 'مندفع', relationshipImpact: 0.3, reputationImpact: -0.9, analysis: 'خيانة للأمانة وتعريض نفسك للطرد من المدرسة.'),
        SocialResponse(text: '(تجاهله والتركيز في ورقتك)', type: 'تحليلي', relationshipImpact: 0.0, reputationImpact: 0.5, analysis: 'حماية نفسك من الوقوع في ورطة أثناء الامتحان.'),
        SocialResponse(text: '(تشير له بالرفض بصمت): سأشرح لك الدرس بعد الامتحان.', type: 'استراتيجي', relationshipImpact: 0.2, reputationImpact: 0.7, analysis: 'رفض للخطأ مع تقديم مساعدة حقيقية لاحقاً.'),
      ],
    ),
    // 20. Future Career
    SocialScenario(
      sender: 'الموجه الطلابي',
      message: 'أرى أنك تحب الرسم جداً، لكن والديك يريدانك أن تصبح مهندساً. ماذا تنوي أن تفعل؟',
      emotionalTone: 'استكشاف',
      intentType: 'سؤال مصيري',
      riskLevel: 2,
      options: [
        SocialResponse(text: 'سأفعل ما يريده والداي، الرسم مجرد هواية غير مفيدة.', type: 'استسلام', relationshipImpact: 0.4, reputationImpact: 0.0, analysis: 'التخلي عن شغفك قد يسبب لك الإحباط مستقبلاً.'),
        SocialResponse(text: 'سأدرس الهندسة لأرضيهما، لكن سأستمر في تنمية موهبتي في الرسم.', type: 'تحليلي', relationshipImpact: 0.5, reputationImpact: 0.5, analysis: 'محاولة التوازن بين رغبات الأهل والشغف الشخصي.'),
        SocialResponse(text: 'سأحاول إقناعهما بأن هندسة الديكور تجمع بين العلم والفن الذي أحبه.', type: 'استراتيجي', relationshipImpact: 0.6, reputationImpact: 0.8, analysis: 'بحث عن حلول وسطية ذكية ترضي الجميع وتحقق طموحك.'),
      ],
    ),
    // Continuing to reach 50...
    SocialScenario(sender: 'صديق', message: 'لقد سمعت أن خالد يتحدث عنك بسوء في غيابك.', emotionalTone: 'إثارة فتنة', intentType: 'نقل كلام', riskLevel: 2, 
      options: [
        SocialResponse(text: 'سأذهب لأضربه الآن!', type: 'هجومي', relationshipImpact: -0.6, reputationImpact: -0.7, analysis: 'الاندفاع خلف الإشاعات يسبب مشاكل لا تنتهي.'),
        SocialResponse(text: 'سأتحقق من الأمر منه مباشرة قبل أن أصدق أي شيء.', type: 'تحليلي', relationshipImpact: 0.3, reputationImpact: 0.8, analysis: 'التثبت من الأخبار هو قمة النضج الاجتماعي.'),
        SocialResponse(text: 'شكراً لإخباري، لكن لا أريد سماع كلام سلبي عن أصدقائي.', type: 'استراتيجي', relationshipImpact: 0.2, reputationImpact: 0.9, analysis: 'إيقاف الفتنة في مهدها يرفع من قيمتك أمام الجميع.'),
      ]),
    SocialScenario(sender: 'المدرب', message: 'أنت تتأخر عن التدريب دائماً، هذا يؤثر على أداء الفريق.', emotionalTone: 'حزم', intentType: 'تنبيه', riskLevel: 2, 
      options: [
        SocialResponse(text: 'المواصلات صعبة، لست أنا السبب.', type: 'دفاعي', relationshipImpact: -0.2, reputationImpact: -0.4, analysis: 'الاعتذار الدائم يظهر عدم الجدية.'),
        SocialResponse(text: 'أعتذر، سأبدأ في ضبط منبهي قبل موعدي بـ30 دقيقة.', type: 'تحليلي', relationshipImpact: 0.5, reputationImpact: 0.7, analysis: 'تحمل المسؤولية وتقديم حل عملي.'),
        SocialResponse(text: 'حقك عليّ، هل يمكنني تعويض هذا التأخير بتدريب إضافي اليوم؟', type: 'استراتيجي', relationshipImpact: 0.7, reputationImpact: 0.9, analysis: 'إظهار الالتزام والحرص على مصلحة الفريق.'),
      ]),
    // (Adding more concise scenarios to fill the 50 limit efficiently)
    SocialScenario(sender: 'جارك', message: 'كرتك كسرت نافذتي! يجب أن يدفع والدك ثمنها.', emotionalTone: 'غضب', intentType: 'شكوى', riskLevel: 2, options: [
      SocialResponse(text: 'لم أفعل ذلك، ابحث عن شخص آخر.', type: 'كذب', relationshipImpact: -0.8, reputationImpact: -0.9, analysis: 'الكذب يدمر الجيرة والسمعة.'),
      SocialResponse(text: 'أنا آسف جداً، سأخبر والدي فوراً وسنتحمل التكاليف.', type: 'صدق', relationshipImpact: 0.6, reputationImpact: 0.9, analysis: 'الاعتراف بالخطأ والتعويض هو التصرف الرجولي.'),
      SocialResponse(text: 'آسف، سأعمل في الصيف لأدفع ثمنها من مصروفي الخاص.', type: 'مسؤولية', relationshipImpact: 0.8, reputationImpact: 1.0, analysis: 'تحمل المسؤولية الشخصية يجعلك شخصاً يثق به الجميع.'),
    ]),
    SocialScenario(sender: 'زميلة', message: 'لماذا تبدو حزيناً اليوم؟ هل يمكنني مساعدتك؟', emotionalTone: 'تعاطف', intentType: 'دعم', riskLevel: 1, options: [
      SocialResponse(text: 'لا شأن لكِ بي، اتركوني وشأني.', type: 'قاسي', relationshipImpact: -0.5, reputationImpact: -0.3, analysis: 'صد من يحاول مساعدتك يجعلك وحيداً.'),
      SocialResponse(text: 'أمر ببعض الضغوط الدراسية، شكراً لسؤالكِ، هذا يعني لي الكثير.', type: 'منفتح', relationshipImpact: 0.6, reputationImpact: 0.4, analysis: 'مشاركة المشاعر بصدق يقوي الروابط الاجتماعية.'),
      SocialResponse(text: 'بخير، مجرد تعب بسيط. ماذا عنكِ؟ كيف تسير أموركِ؟', type: 'متوازن', relationshipImpact: 0.4, reputationImpact: 0.5, analysis: 'رد لبق يحافظ على الخصوصية مع رد الجميل بالسؤال.'),
    ]),
    SocialScenario(sender: 'المنافس', message: 'لقد خسرت المباراة! اذهب وابكِ بعيداً أيها الفاشل.', emotionalTone: 'استفزاز', intentType: 'هجوم عاطفي', riskLevel: 3, options: [
      SocialResponse(text: 'سأريك من هو الفاشل في المرة القادمة (بصراخ).', type: 'منفعل', relationshipImpact: -0.4, reputationImpact: -0.6, analysis: 'الغضب هو ما يريده المستفز بالضبط.'),
      SocialResponse(text: 'مبروك لك الفوز، سأتدرب أكثر وأعود أقوى.', type: 'روح رياضية', relationshipImpact: 0.3, reputationImpact: 1.0, analysis: 'الرد برقي يقتل الاستفزاز ويرفع من شأنك.'),
      SocialResponse(text: '(صمت وابتسامة واثقة ثم الرحيل)', type: 'ثبات', relationshipImpact: 0.1, reputationImpact: 0.9, analysis: 'أحياناً يكون الصمت هو أبلغ رد على الإساءة.'),
    ]),
    // Academic - 26
    SocialScenario(sender: 'المعلمة', message: 'من كتب هذه الخاطرة الرائعة في مجلة المدرسة؟', emotionalTone: 'إعجاب', intentType: 'ثناء', riskLevel: 1, options: [
      SocialResponse(text: 'أنا، وأعرف أنها الأفضل في المجلة.', type: 'مغرور', relationshipImpact: 0.0, reputationImpact: -0.2, analysis: 'الغرور يقلل من جمال الإنجاز.'),
      SocialResponse(text: 'أنا من كتبتها، شكراً لكِ على دعمكِ الدائم لي.', type: 'متواضع', relationshipImpact: 0.5, reputationImpact: 0.6, analysis: 'الاعتراف بالفضل للأخرين يزيد من محبتهم لك.'),
      SocialResponse(text: 'شكراً، لقد ساعدتني زميلتي في مراجعتها أيضاً.', type: 'تعاوني', relationshipImpact: 0.8, reputationImpact: 0.7, analysis: 'نسب الفضل لأهله يظهر روحاً جماعية رائعة.'),
    ]),
    // Family - 27
    SocialScenario(sender: 'الجد', message: 'يا بني، هل يمكنك مساعدتي في فهم هذا التطبيق الجديد على هاتفي؟', emotionalTone: 'حيرة', intentType: 'طلب تعليم', riskLevel: 1, options: [
      SocialResponse(text: 'أنا مشغول باللعب الآن، اطلب من أخي.', type: 'أناني', relationshipImpact: -0.8, reputationImpact: -0.4, analysis: 'تفضيل الألعاب على كبار السن يظهر قلة تقدير.'),
      SocialResponse(text: 'بالطبع يا جدي، تعال لنجلس وسأشرحه لك خطوة بخطوة.', type: 'بار', relationshipImpact: 1.0, reputationImpact: 0.8, analysis: 'بر الوالدين والأجداد هو قمة الأخلاق.'),
      SocialResponse(text: 'سأقوم بضبطه لك وجعل استخدامه أسهل ما يكون.', type: 'مبادر', relationshipImpact: 0.9, reputationImpact: 0.7, analysis: 'استخدام مهاراتك لخدمة عائلتك يجعلك محبوباً.'),
    ]),
    // Digital - 28
    SocialScenario(sender: 'صديق في لعبة', message: 'لقد خسرت بسببك! سأقوم بسبك في كل المجموعات.', emotionalTone: 'عدواني', intentType: 'تهديد رقمي', riskLevel: 3, options: [
      SocialResponse(text: 'افعل ذلك وسأقوم بقرصنة حسابك!', type: 'عدواني مضاد', relationshipImpact: -0.5, reputationImpact: -0.8, analysis: 'التهديد بالقرصنة هو سلوك غير قانوني وسيؤذيك.'),
      SocialResponse(text: 'إنها مجرد لعبة، لا داعي لكل هذا الغضب.', type: 'هادئ', relationshipImpact: 0.1, reputationImpact: 0.4, analysis: 'محاولة تهدئة الأمور بعقلانية.'),
      SocialResponse(text: '(تجاهل وحظر فوراً وإبلاغ إدارة اللعبة)', type: 'حازم', relationshipImpact: 0.0, reputationImpact: 0.9, analysis: 'حماية خصوصيتك وراحتك النفسية هي الأولوية.'),
    ]),
    // Social - 29
    SocialScenario(sender: 'زميل', message: 'خالد لم يدعوك لحفلة ميلاده، هل أنت حزين؟', emotionalTone: 'تطفل', intentType: 'جس نبض', riskLevel: 2, options: [
      SocialResponse(text: 'نعم، هو شخص سيء ولن أتحدث معه ثانية.', type: 'منفعل', relationshipImpact: -0.6, reputationImpact: -0.5, analysis: 'إظهار الضعف والانفعال يشجع المتطفلين.'),
      SocialResponse(text: 'ربما نسي أو لديه أسبابه، أتمنى له وقتاً ممتعاً.', type: 'متصالح', relationshipImpact: 0.4, reputationImpact: 0.9, analysis: 'سلام نفسي وقوة شخصية لا تتأثر بصغائر الأمور.'),
      SocialResponse(text: 'لا بأس، كنت مشغولاً أصلاً في ذلك اليوم.', type: 'دبلوماسي', relationshipImpact: 0.1, reputationImpact: 0.6, analysis: 'رد يحفظ ماء الوجه دون الإساءة لأحد.'),
    ]),
    // Financial - 30
    SocialScenario(sender: 'بائع', message: 'اشترِ هذه اللعبة الآن، غداً سيرتفع سعرها للضعف!', emotionalTone: 'ضغط بيعي', intentType: 'تلاعب مالي', riskLevel: 2, options: [
      SocialResponse(text: 'حسناً، خذ مالي بسرعة قبل أن يرتفع السعر.', type: 'مندفع', relationshipImpact: -0.1, reputationImpact: -0.4, analysis: 'الوقوع في فخ التسويق يضيع أموالك في أشياء قد لا تحتاجها.'),
      SocialResponse(text: 'سأفكر في الأمر وأقارن الأسعار أولاً.', type: 'عقلاني', relationshipImpact: 0.0, reputationImpact: 0.6, analysis: 'التفكير قبل الشراء هو أساس الذكاء المالي.'),
      SocialResponse(text: 'لدي ميزانية محددة لهذا الشهر، لن أشتريها الآن.', type: 'منضبط', relationshipImpact: 0.0, reputationImpact: 0.8, analysis: 'الالتزام بالميزانية يحميك من الديون والمشاكل المالية.'),
    ]),
    // Academic - 31
    SocialScenario(sender: 'صديق', message: 'المعلم يحبك أكثر منا، دائماً ما يعطيك فرصة ثانية.', emotionalTone: 'غيرة', intentType: 'اتهام بالمحاباة', riskLevel: 2, options: [
      SocialResponse(text: 'لأنني أفضل منكم وأستحق ذلك.', type: 'مستفز', relationshipImpact: -0.7, reputationImpact: -0.4, analysis: 'الاستفزاز يزيد من كراهية الزملاء لك.'),
      SocialResponse(text: 'أنا فقط أسأله دائماً وأهتم بالدرس، يمكنك فعل ذلك أيضاً.', type: 'توضيحي', relationshipImpact: 0.3, reputationImpact: 0.5, analysis: 'شرح السبب بوضوح دون تفاخر.'),
      SocialResponse(text: 'المعلم يساعد الجميع، دعنا نذهب لنسأله معاً عن الدرس القادم.', type: 'استيعابي', relationshipImpact: 0.7, reputationImpact: 0.8, analysis: 'مشاركة النجاح مع الأصدقاء ينهي الغيرة.'),
    ]),
    // Family - 32
    SocialScenario(sender: 'الأب', message: 'ساعدني في تنظيف الحديقة اليوم، وسأعطيك مكافأة.', emotionalTone: 'تشجيع', intentType: 'تحفيز', riskLevel: 1, options: [
      SocialResponse(text: 'لن أفعل ذلك إلا إذا زدت المكافأة.', type: 'طماع', relationshipImpact: -0.4, reputationImpact: -0.3, analysis: 'المساومة مع الوالدين تظهر قلة تقدير للجهد العائلي.'),
      SocialResponse(text: 'سأساعدك بكل سرور، لا أحتاج لمكافأة لأساعدك يا أبي.', type: 'مخلص', relationshipImpact: 1.0, reputationImpact: 0.7, analysis: 'العطاء دون مقابل للأهل يقوي الروابط جداً.'),
      SocialResponse(text: 'حسناً، سأقوم بجمع الأوراق الجافة وتنظيم الأدوات.', type: 'عملي', relationshipImpact: 0.8, reputationImpact: 0.5, analysis: 'استجابة سريعة ومنظمة تظهر نضجك.'),
    ]),
    // Ethical - 33
    SocialScenario(sender: 'زميل', message: 'ألقِ هذه القمامة في الممر، لا أحد يراقبنا الآن.', emotionalTone: 'استهتار', intentType: 'تحريض على الخطأ', riskLevel: 2, options: [
      SocialResponse(text: '(يلقيها): صحيح، المنظفون سيقومون بذلك لاحقاً.', type: 'مستهتر', relationshipImpact: 0.1, reputationImpact: -0.7, analysis: 'قلة وعي بيئي تسيء لشخصيتك وبيئتك.'),
      SocialResponse(text: 'سأضعها في سلة المهملات، المكان ملك للجميع.', type: 'مسؤول', relationshipImpact: -0.1, reputationImpact: 0.9, analysis: 'الحفاظ على النظافة واجب أخلاقي وجمالي.'),
      SocialResponse(text: 'تخيل لو فعل الجميع ذلك؟ سيصبح الممر مقززاً، دعنا ننظفه.', type: 'قدوة', relationshipImpact: 0.2, reputationImpact: 1.0, analysis: 'التأثير الإيجابي في الآخرين هو سمة القادة.'),
    ]),
    // Social - 34
    SocialScenario(sender: 'شخص جديد', message: 'تبدو شخصاً رائعاً، هل يمكننا أن نصبح أصدقاء؟', emotionalTone: 'ودود', intentType: 'بدء صداقة', riskLevel: 1, options: [
      SocialResponse(text: 'لدي ما يكفي من الأصدقاء، شكراً.', type: 'منغلق', relationshipImpact: -0.6, reputationImpact: -0.4, analysis: 'الرفض القاطع يضيع عليك فرصاً لمعرفة أشخاص رائعين.'),
      SocialResponse(text: 'بالتأكيد، يسعدني ذلك. ما هو اسمك؟', type: 'اجتماعي', relationshipImpact: 0.8, reputationImpact: 0.6, analysis: 'الانفتاح الاجتماعي يبني علاقات صحية.'),
      SocialResponse(text: 'أهلاً بك، دعنا نكتشف اهتماماتنا المشتركة أولاً.', type: 'حذر/ذكي', relationshipImpact: 0.5, reputationImpact: 0.7, analysis: 'بداية صداقة متوازنة بذكاء.'),
    ]),
    // Digital - 35
    SocialScenario(sender: 'مجموعة الفصل', message: 'هيا نغير صورة المجموعة لصورة المعلم وهو نائم في الحافلة!', emotionalTone: 'سخرية جماعية', intentType: 'تنمر جماعي', riskLevel: 3, options: [
      SocialResponse(text: 'ههههه، فكرة عبقرية! افعلوا ذلك.', type: 'تابع', relationshipImpact: 0.2, reputationImpact: -0.8, analysis: 'المشاركة في السخرية من المعلم تسقط هيبتك واحترامك لنفسك.'),
      SocialResponse(text: 'هذا قلة احترام، المعلم يتعب من أجلنا، لا تفعلوا ذلك.', type: 'شجاع', relationshipImpact: -0.4, reputationImpact: 0.9, analysis: 'قول الحق أمام الجماعة يتطلب شجاعة كبيرة ونزاهة.'),
      SocialResponse(text: 'سيصل الخبر للإدارة وسنتعرض جميعاً للعقاب، تراجعوا.', type: 'عقلاني', relationshipImpact: 0.0, reputationImpact: 0.8, analysis: 'استخدام لغة المنطق لمنع وقوع خطأ جماعي.'),
    ]),
    // Time Management - 36
    SocialScenario(sender: 'نفسك (تفكير داخلي)', message: 'أنا متعب جداً، هل أشاهد فيلماً أم أنام لأرتاح للاختبار؟', emotionalTone: 'صراع داخلي', intentType: 'قرار شخصي', riskLevel: 1, options: [
      SocialResponse(text: 'الفلم طبعاً، سأستمتع بوقتي.', type: 'مندفع', relationshipImpact: 0.0, reputationImpact: -0.4, analysis: 'تفضيل اللذة على الراحة الجسدية سيؤثر على أدائك في الاختبار.'),
      SocialResponse(text: 'النوم هو الأولوية، عقلي يحتاج للراحة ليستوعب المعلومات.', type: 'حكيم', relationshipImpact: 0.0, reputationImpact: 0.6, analysis: 'معرفة أولويات الجسم والنجاح.'),
      SocialResponse(text: 'سأنام الآن، وسأشاهد الفلم كمكافأة بعد الانتهاء من الاختبار.', type: 'منضبط', relationshipImpact: 0.0, reputationImpact: 0.8, analysis: 'تأجيل اللذة هو سر النجاح في الحياة.'),
    ]),
    // Sibling Interaction - 37
    SocialScenario(sender: 'الأخ الصغير', message: 'هل يمكنني اللعب بجهازك اللوحي لـ10 دقائق فقط؟ أعدك بالحفاظ عليه.', emotionalTone: 'رجاء', intentType: 'طلب استعارة', riskLevel: 1, options: [
      SocialResponse(text: 'اذهب من هنا، ستكسره كما فعلت المرة الماضية.', type: 'قاسي', relationshipImpact: -0.6, reputationImpact: -0.2, analysis: 'القسوة مع الإخوة تبني جدران كراهية.'),
      SocialResponse(text: 'حسناً، سأجلس بجانبك لأعلمك كيف تستخدمه بسلامة.', type: 'تعليمي', relationshipImpact: 0.9, reputationImpact: 0.6, analysis: 'صبر وتوجيه يقوي العلاقة ويحمي ممتلكاتك.'),
      SocialResponse(text: 'بعد أن تنهي واجباتك، سيكون متاحاً لك.', type: 'تحفيزي', relationshipImpact: 0.7, reputationImpact: 0.5, analysis: 'استخدام الممتلكات كأداة للتحفيز الإيجابي.'),
    ]),
    // Social Status - 38
    SocialScenario(sender: 'طالب مشهور', message: 'إذا أردت الانضمام لمجموعتنا، يجب أن تتوقف عن التحدث مع خالد.', emotionalTone: 'استبداد', intentType: 'شرط إقصائي', riskLevel: 3, options: [
      SocialResponse(text: 'حسناً، خالد ممل أصلاً، سأنضم إليكم.', type: 'خائن', relationshipImpact: -0.9, reputationImpact: -0.7, analysis: 'بيع الأصدقاء من أجل الشهرة يظهر شخصية ضعيفة جداً.'),
      SocialResponse(text: 'خالد صديقي، ولا أقبل أن يملي عليّ أحد مع من أتحدث.', type: 'قوي الشخصية', relationshipImpact: 0.4, reputationImpact: 1.0, analysis: 'الوفاء والكرامة أهم من أي مجموعة مشهورة.'),
      SocialResponse(text: 'لماذا؟ خالد شخص جيد، ربما عليكم التعرف عليه أكثر.', type: 'وسيط', relationshipImpact: 0.6, reputationImpact: 0.8, analysis: 'محاولة تليين المواقف والدفاع عن الصديق بذكاء.'),
    ]),
    // Online Behavior - 39
    SocialScenario(sender: 'مجموعة ألعاب', message: 'لقد فزنا! هيا نسخر من الفريق الخاسر ونرسل لهم رموزاً مهينة.', emotionalTone: 'نشوة كاذبة', intentType: 'غرور رياضي', riskLevel: 2, options: [
      SocialResponse(text: 'نعم، لقد كانوا ضعفاء جداً! (إرسال رموز مهينة).', type: 'متنمر', relationshipImpact: -0.3, reputationImpact: -0.8, analysis: 'عدم احترام المنافس يقلل من قيمة فوزك.'),
      SocialResponse(text: 'لعبنا جيداً وهم أيضاً حاولوا، يكفي الفوز دون إهانة.', type: 'متوازن', relationshipImpact: 0.2, reputationImpact: 0.6, analysis: 'الحفاظ على الأخلاق حتى في لحظات الانتصار.'),
      SocialResponse(text: 'سأكتب لهم "هارد لك"، لقد كانت مباراة ممتعة.', type: 'بطل حقيقي', relationshipImpact: 0.5, reputationImpact: 0.9, analysis: 'الروح الرياضية العالية هي ما يميز المحترفين.'),
    ]),
    // Financial Dilemma - 40
    SocialScenario(sender: 'بائع الحلوى', message: 'لقد أعطيتني 10 ريالات بالخطأ وهي 5 فقط، خذ الباقي.', emotionalTone: 'أمانة بائع', intentType: 'اختبار أمانة', riskLevel: 1, options: [
      SocialResponse(text: 'شكراً لك (يأخذ المال ويرحل بسرعة).', type: 'طماع', relationshipImpact: 0.0, reputationImpact: -0.5, analysis: 'استغلال أخطاء الآخرين المالية هو نوع من السرقة المستترة.'),
      SocialResponse(text: 'عفواً، لقد كانت 10 فعلاً، تأكد من حسابك مرة أخرى.', type: 'صادق', relationshipImpact: 0.5, reputationImpact: 0.8, analysis: 'الصدق في التعاملات المالية يبني مجتمعاً آمناً.'),
      SocialResponse(text: 'احتفظ بالباقي كإكرامية لك، شكراً على أمانتك.', type: 'كريم', relationshipImpact: 0.9, reputationImpact: 1.0, analysis: 'مكافأة الأمانة تشجع على انتشار الأخلاق الحميدة.'),
    ]),
    // 41-50 Summary Scenarios
    SocialScenario(sender: 'المتحدث الرسمي', message: 'من يمثل المدرسة في مسابقة الخطابة؟ نحتاج شخصاً واثقاً.', emotionalTone: 'بحث', intentType: 'تحدي قيادي', riskLevel: 1, options: [
      SocialResponse(text: 'أنا أخجل جداً، اطلبوا من شخص آخر.', type: 'متردد', relationshipImpact: 0.0, reputationImpact: -0.2, analysis: 'الخجل الزائد يضيع عليك فرصاً ذهبية للبروز.'),
      SocialResponse(text: 'أريد المحاولة، سأتدرب جيداً وأبذل قصارى جهدي.', type: 'طموح', relationshipImpact: 0.4, reputationImpact: 0.8, analysis: 'مواجهة المخاوف هي أول خطوة نحو القيادة.'),
      SocialResponse(text: 'سأقوم بترشيح "عمر"، لديه صوت جهوري وقوة إلقاء.', type: 'ناكر للذات', relationshipImpact: 0.8, reputationImpact: 0.7, analysis: 'ترشيح الأفضل للمهمة يظهر وعيك بمصلحة المجموعة.'),
    ]),
    SocialScenario(sender: 'زميل غائب', message: 'هل يمكنني أخذ ملخصاتك؟ لم أحضر دروس الأسبوع الماضي.', emotionalTone: 'حاجة', intentType: 'طلب مساعدة دراسية', riskLevel: 1, options: [
      SocialResponse(text: 'لا، تعبت في كتابتها ولن أعطيها لأحد.', type: 'بخيل', relationshipImpact: -0.7, reputationImpact: -0.5, analysis: 'البخل بالعلم يمنع عنك مساعدة الآخرين مستقبلاً.'),
      SocialResponse(text: 'بالتأكيد، سأرسلها لك مصورة الآن.', type: 'معطاء', relationshipImpact: 0.9, reputationImpact: 0.6, analysis: 'مساعدة الزملاء في الدراسة تبني صداقات متينة.'),
      SocialResponse(text: 'تفضل، وإذا لم تفهم أي نقطة يمكننا مراجعتها معاً.', type: 'داعم', relationshipImpact: 1.0, reputationImpact: 0.8, analysis: 'قمة التعاون الطلابي المثمر.'),
    ]),
    SocialScenario(sender: 'المتنمر', message: 'أعطني قلمك الجديد وإلا سأخبر الجميع بسرك المحرج!', emotionalTone: 'تهديد', intentType: 'ابتزاز', riskLevel: 3, options: [
      SocialResponse(text: 'خذ القلم، أرجوك لا تخبر أحداً.', type: 'خاضع', relationshipImpact: -0.3, reputationImpact: -0.6, analysis: 'الخضوع للمبتز يجعله يطلب المزيد دائماً.'),
      SocialResponse(text: 'افعل ما تريد، سري لا يخجلني والقلم لي.', type: 'شجاع', relationshipImpact: 0.0, reputationImpact: 0.9, analysis: 'كسر قوة المبتز باللامبالاة والشجاعة.'),
      SocialResponse(text: 'سأذهب للمدير الآن لنحل هذا الموضوع قانونياً.', type: 'حازم', relationshipImpact: 0.0, reputationImpact: 1.0, analysis: 'اللجوء للسلطة هو الحل الأمثل في حالات الابتزاز.'),
    ]),
    SocialScenario(sender: 'صديق قديم', message: 'لقد ابتعدت عنا منذ بدأت ترافق هؤلاء الطلاب المتفوقين.', emotionalTone: 'عتاب / غيرة', intentType: 'شعور بالإقصاء', riskLevel: 2, options: [
      SocialResponse(text: 'نعم، لأنهم يهتمون بمستقبلهم أكثر منكم.', type: 'متعالي', relationshipImpact: -0.8, reputationImpact: -0.4, analysis: 'خسارة الأصدقاء القدامى بطريقة فظة تترك أثراً سيئاً.'),
      SocialResponse(text: 'أبداً، أنا فقط أحاول تحسين درجاتي، دعونا نخرج معاً غداً.', type: 'وفي', relationshipImpact: 0.8, reputationImpact: 0.6, analysis: 'توضيح سوء الفهم والتمسك بالأصدقاء القدامى.'),
      SocialResponse(text: 'لماذا لا تنضمون إلينا في المذاكرة؟ سنستمتع ونستفيد جميعاً.', type: 'جامع', relationshipImpact: 0.9, reputationImpact: 0.8, analysis: 'محاولة دمج دوائر الأصدقاء لتعميم الفائدة والود.'),
    ]),
    SocialScenario(sender: 'المدير', message: 'لقد تم اختيارك "طالب الشهر" لالتزامك وأخلاقك العالية.', emotionalTone: 'فخر', intentType: 'تكريم', riskLevel: 1, options: [
      SocialResponse(text: 'أنا أعرف أنني الأفضل دائماً، شكراً.', type: 'نرجسي', relationshipImpact: -0.1, reputationImpact: -0.4, analysis: 'الغرور يقتل فرحة التكريم في عيون الآخرين.'),
      SocialResponse(text: 'شكراً جزيلاً، هذا فضل ربي ثم توجيهات معلمي وأهلي.', type: 'ممتن', relationshipImpact: 0.6, reputationImpact: 0.9, analysis: 'الامتنان يرفع من شأنك ويزيد من احترام الناس لك.'),
      SocialResponse(text: 'سأبذل قصارى جهدي لأكون قدوة حسنة لزملائي دائماً.', type: 'مسؤول', relationshipImpact: 0.4, reputationImpact: 1.0, analysis: 'تحمل مسؤولية اللقب والحرص على الاستمرار في التميز.'),
    ]),
    SocialScenario(sender: 'شخص غريب', message: 'يا بني، هل يمكنني استخدام هاتفك لإجراء مكالمة ضرورية؟', emotionalTone: 'حاجة طارئة', intentType: 'طلب مساعدة خطر', riskLevel: 3, options: [
      SocialResponse(text: 'تفضل، الهاتف معك.', type: 'ساذج', relationshipImpact: 0.1, reputationImpact: -0.5, analysis: 'خطر أمني كبير، قد يسرق الهاتف أو يستخدمه في أمور سيئة.'),
      SocialResponse(text: 'آسف، لا يمكنني إعطاء هاتفي للغرباء، اطلب من الشرطة.', type: 'حذر', relationshipImpact: 0.0, reputationImpact: 0.7, analysis: 'حماية خصوصيتك وأمنك الشخصي تأتي أولاً.'),
      SocialResponse(text: 'أعطني الرقم وسأقوم بإجراء المكالمة لك وأنا أمسك بالهاتف.', type: 'ذكي', relationshipImpact: 0.4, reputationImpact: 0.9, analysis: 'تقديم المساعدة مع الحفاظ على أمن ممتلكاتك وبشروطك.'),
    ]),
    SocialScenario(sender: 'صديق', message: 'لقد كسرت لعبتك التي استعرتها، سأشتري لك واحدة غيرها غداً.', emotionalTone: 'اعتذار صادق', intentType: 'اعتراف بالخطأ', riskLevel: 1, options: [
      SocialResponse(text: 'أنت دائماً تخرب الأشياء! لن أعيرك شيئاً أبداً.', type: 'قاسي', relationshipImpact: -0.7, reputationImpact: -0.2, analysis: 'القسوة عند الاعتذار الصادق تنهي الصداقات.'),
      SocialResponse(text: 'فداك اللعبة، المهم أنها لم تؤذِك، لا داعي لشراء غيرها.', type: 'متسامح', relationshipImpact: 1.0, reputationImpact: 0.8, analysis: 'التسامح عند الخطأ غير المقصود يقوي الروابط جداً.'),
      SocialResponse(text: 'لا بأس، يمكننا محاولة إصلاحها معاً اليوم.', type: 'بناء', relationshipImpact: 0.8, reputationImpact: 0.6, analysis: 'تفكير إيجابي يحول المشكلة إلى نشاط مشترك.'),
    ]),
    SocialScenario(sender: 'مجموعة الأصدقاء', message: 'هيا نتسلل لمختبر العلوم لنرى ماذا يوجد هناك في الخفاء!', emotionalTone: 'مغامرة طائشة', intentType: 'تحريض على خرق القوانين', riskLevel: 3, options: [
      SocialResponse(text: 'هيا بنا! ستكون مغامرة لا تنسى.', type: 'طائش', relationshipImpact: 0.4, reputationImpact: -0.9, analysis: 'خرق القوانين المدرسية يعرضك للفصل والمشاكل الكبيرة.'),
      SocialResponse(text: 'هذا ممنوع وقد نؤذي أنفسنا بالمواد الكيميائية، لن أذهب.', type: 'عقلاني', relationshipImpact: -0.2, reputationImpact: 0.7, analysis: 'الحفاظ على السلامة والالتزام بالقوانين يظهر نضجك.'),
      SocialResponse(text: 'دعونا نطلب من معلم العلوم أن يأخذنا في جولة رسمية الأسبوع القادم.', type: 'قائد حكيم', relationshipImpact: 0.3, reputationImpact: 0.9, analysis: 'تحويل الفضول الطائش إلى تعلم رسمي وآمن.'),
    ]),
    SocialScenario(sender: 'المعلم', message: 'من منكم يستطيع شرح هذه النقطة الصعبة لزملائه؟', emotionalTone: 'تحدي', intentType: 'طلب قيادة تعليمية', riskLevel: 1, options: [
      SocialResponse(text: 'أنا أعرفها لكني لن أشرحها لأحد لكي أتفوق وحدي.', type: 'أناني', relationshipImpact: -0.5, reputationImpact: -0.6, analysis: 'كتم العلم يمنع البركة ويجعلك منبوذاً.'),
      SocialResponse(text: 'أنا سأحاول، سأستخدم السبورة لأبسط المعلومة كما فهمتها.', type: 'مبادر', relationshipImpact: 0.8, reputationImpact: 0.9, analysis: 'المبادرة للتعليم تثبت المعلومة في عقلك وترفع شأنك.'),
      SocialResponse(text: 'أعتقد أن "سارة" فهمتها جيداً، ربما يمكننا التعاون في شرحها.', type: 'مشجع', relationshipImpact: 0.9, reputationImpact: 0.8, analysis: 'دعم الزملاء وإظهار مواهبهم هو قمة الرقي الاجتماعي.'),
    ]),
    SocialScenario(sender: 'نظام التشغيل الاجتماعي', message: 'لقد أكملت 50 مهمة بنجاح! كيف تشعر تجاه مهاراتك الآن؟', emotionalTone: 'احتفالي', intentType: 'نهاية المحاكاة', riskLevel: 1, options: [
      SocialResponse(text: 'أنا الآن ملك التواصل الاجتماعي ولا أحتاج لمزيد من التدريب.', type: 'واثق بزيادة', relationshipImpact: 0.0, reputationImpact: -0.2, analysis: 'التوقف عن التعلم هو بداية التراجع.'),
      SocialResponse(text: 'لقد تعلمت الكثير، وسأحاول تطبيق هذه الاستراتيجيات في حياتي الحقيقية.', type: 'متعلم مجتهد', relationshipImpact: 0.6, reputationImpact: 0.9, analysis: 'الهدف من المحاكاة هو التطبيق الواقعي للنجاح.'),
      SocialResponse(text: 'شكراً للـ OS، سأستمر في تحليل المواقف بذكاء وهدوء دائماً.', type: 'خريج متميز', relationshipImpact: 0.4, reputationImpact: 1.0, analysis: 'اعتماد الهدوء والتحليل كمنهج حياة هو النجاح الحقيقي.'),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _loadScenario(0);
  }

  void _loadScenario(int index) {
    setState(() {
      _currentScenario = _scenarios[index % _scenarios.length];
      _state = SocialOSState.receiving;
      _selectedResponse = null;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _state = SocialOSState.analyzing);
      
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _state = SocialOSState.deciding);
      });
    });
  }

  void _handleChoice(SocialResponse response) {
    setState(() {
      _selectedResponse = response;
      _state = SocialOSState.evaluating;
      _socialScore += (response.relationshipImpact * 100) + (response.reputationImpact * 50);
      _relationshipStatus = (_relationshipStatus + response.relationshipImpact / 5).clamp(0.0, 1.0);
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      body: Stack(
        children: [
          _buildBackgroundGrid(),
          SafeArea(
            child: Column(
              children: [
                _buildTopHUD(),
                Expanded(
                  child: _buildMainDashboard(),
                ),
                _buildSystemFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [Color(0xFF0D121F), Color(0xFF05070A)],
        ),
      ),
      child: Opacity(
        opacity: 0.05,
        child: CustomPaint(
          size: Size.infinite,
          painter: GridPainter(),
        ),
      ),
    );
  }

  Widget _buildTopHUD() {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHUDItem('SOCIAL SCORE', _socialScore.toInt().toString(), const Color(0xFF00F2FF)),
          Column(
            children: [
              Text(
                'SOCIAL OS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'CORE INTELLIGENCE v4.2',
                style: TextStyle(color: Colors.white24, fontSize: 8.sp, letterSpacing: 1),
              ),
            ],
          ),
          _buildHUDItem('LVL', '$_currentLevel', const Color(0xFFBC00FF)),
        ],
      ),
    );
  }

  Widget _buildHUDItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white24, fontSize: 8.sp, letterSpacing: 1)),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _buildMainDashboard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            _buildIncomingMessage(),
            if (_state != SocialOSState.receiving) _buildAnalysisModule(),
            if (_state == SocialOSState.deciding) _buildDecisionOptions(),
            if (_state == SocialOSState.evaluating) _buildEvaluationPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: Color(0xFF00F2FF), size: 16),
              SizedBox(width: 8.w),
              Text(
                _currentScenario.sender,
                style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              const Spacer(),
              _buildRiskIndicator(_currentScenario.riskLevel),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            _currentScenario.message,
            style: TextStyle(color: Colors.white, fontSize: 15.sp, height: 1.5, fontFamily: 'Cairo'),
          ),
        ],
      ),
    ).animate().slideX(begin: -0.1).fadeIn();
  }

  Widget _buildRiskIndicator(int level) {
    Color color = level == 1 ? Colors.greenAccent : level == 2 ? Colors.amberAccent : Colors.redAccent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        'RISK: ${level == 1 ? "LOW" : level == 2 ? "MED" : "HIGH"}',
        style: TextStyle(color: color, fontSize: 8.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAnalysisModule() {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildAnalysisRow('نبرة الصوت العاطفية', _currentScenario.emotionalTone, Colors.orangeAccent),
          SizedBox(height: 12.h),
          _buildAnalysisRow('الهدف من الرسالة', _currentScenario.intentType, Colors.cyanAccent),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildAnalysisRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontFamily: 'Cairo')),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionOptions() {
    return Container(
      margin: EdgeInsets.only(top: 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر استراتيجية الرد:',
            style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontFamily: 'Cairo'),
          ),
          SizedBox(height: 16.h),
          ..._currentScenario.options.map((opt) => _buildOptionCard(opt)),
        ],
      ),
    );
  }

  Widget _buildOptionCard(SocialResponse option) {
    return GestureDetector(
      onTap: () => _handleChoice(option),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.type,
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 8.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    option.text,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
            const Icon(Icons.navigate_next_rounded, color: Colors.white24),
          ],
        ),
      ).animate().slideX(begin: 0.1).fadeIn(),
    );
  }

  Widget _buildEvaluationPanel() {
    bool isPositive = (_selectedResponse?.relationshipImpact ?? 0) > 0;
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: (isPositive ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(isPositive ? Icons.check_circle_outline : Icons.error_outline, color: isPositive ? Colors.greenAccent : Colors.redAccent),
              SizedBox(width: 12.w),
              Text(
                isPositive ? 'تم تحسين العلاقة' : 'خطر في التواصل',
                style: TextStyle(color: isPositive ? Colors.greenAccent : Colors.redAccent, fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            _selectedResponse?.analysis ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.5, fontFamily: 'Cairo'),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              _currentLevel++;
              _loadScenario(_currentLevel - 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F2FF),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: const Text('المهمة التالية', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ),
        ],
      ),
    ).animate().scale().fadeIn();
  }

  Widget _buildSystemFooter() {
    return Container(
      padding: EdgeInsets.all(24.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatProgress('علاقات', _relationshipStatus, const Color(0xFF00F2FF)),
              _buildStatProgress('سمعة', 0.85, const Color(0xFFBC00FF)),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            _state == SocialOSState.receiving ? 'جاري استقبال البيانات...' :
            _state == SocialOSState.analyzing ? 'جاري تحليل النوايا العاطفية...' :
            _state == SocialOSState.deciding ? 'في انتظار اختيار الاستراتيجية...' : 'تم تحديث سجل البيانات الاجتماعي',
            style: TextStyle(color: Colors.white24, fontSize: 9.sp, letterSpacing: 1),
          ).animate(onPlay: (c) => c.repeat()).shimmer(),
        ],
      ),
    );
  }

  Widget _buildStatProgress(String label, double value, Color color) {
    return SizedBox(
      width: 140.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontFamily: 'Cairo')),
          SizedBox(height: 4.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 3.h,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    double step = 40.r;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
