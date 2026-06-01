import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student_game_state.dart';

class Game1AngerTamer extends StatefulWidget {
  const Game1AngerTamer({super.key});

  @override
  State<Game1AngerTamer> createState() => _Game1AngerTamerState();
}

class _Game1AngerTamerState extends State<Game1AngerTamer> with TickerProviderStateMixin {
  // Game Levels and Scenarios progression
  int _currentLevel = 1; // 1 to 50
  int _currentScenarioInLevel = 0; // 0 to 9 (10 scenarios per level)

  // Game state variables
  int _score = 0; // Local temporary session score (only committed upon level completion!)
  double _angerLevel = 75.0; // Starts with high anger (75%)
  bool _isGameOver = false;
  bool _isWon = false;
  
  // Custom Success Dialogue Overlay State
  bool _showSuccessOverlay = false;
  String _successTitle = '';
  String _successDesc = '';
  int _earnedPoints = 0;

  // Restored Interactive Mini-game States
  String _activeInteraction = 'none'; // 'none', 'breathing', 'wudu', 'refuge', 'dialogue'
  double _breathingScale = 1.0;
  String _breathingText = 'اضغط واستمر في الضغط للشهيق 🌬️';
  Timer? _breathingTimer;
  int _breathingDuration = 0;

  double _wuduProgress = 0.0;
  final List<Offset> _wuduSwipePoints = [];

  String _dialogueQuestion = '';
  List<Map<String, dynamic>> _dialogueOptions = [];

  // Visual cues
  double _screenShake = 0.0;
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.white;
  final math.Random _random = math.Random();

  // Procedural dynamic scenario generator with 10 school stories
  // Every story has 4 customized choices that are 100% SPECIFIC to that story!
  Map<String, dynamic> _getScenario(int level, int scenarioIndex) {
    final int seed = level * 13 + scenarioIndex * 7;
    
    final List<String> environments = [
      "في الفصل الدراسي أثناء الحصة",
      "في ساحة المدرسة الكبيرة أثناء الفسحة",
      "في مكتبة المدرسة الهادئة",
      "في صالة الألعاب الرياضية (الجمنازيوم)",
      "في حافلة المدرسة (الأوتوبيس) أثناء العودة",
      "في طابور الصباح المدرسي أمام الجميع",
      "في معمل العلوم أثناء إجراء التجارب",
      "في غرفة الحاسب الآلي بالمدرسة",
      "في مقصف المدرسة (الكانتين) لشراء الطعام",
      "في معمل الرسم والأشغال اليدوية"
    ];
    
    final List<Map<String, dynamic>> triggers = [
      {
        'name': 'تلف الأدوات واللوحة',
        'correct': 'wudu',
        'situation': 'قام زميلك {name} بالخطأ بسكب الطلاء على لوحتك وتخريب عملك الخاص الذي بذلت فيه جهداً كبيراً طوال الأسبوع 🎨... فشعرت بغليان وحرارة الغضب الشديد في رأسك ووجهك وتريد ضربه!',
        'choices': [
          {
            'emoji': '💦',
            'title': 'الوضوء بالماء البارد',
            'desc': 'أذهب للميضأة فوراً لأتوضأ بالماء وأغسل وجهي لأهدأ 💦',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'wudu',
            'explanation': 'الوضوء يطفئ نار الغضب الجسدي فوراً ويعيد إليك هدوءك النفسي والبدني السليم! 💧',
          },
          {
            'emoji': '🕊️',
            'title': 'الاستعاذة ومسامحة {name}',
            'desc': 'أستعيذ بالله وأقول لـ {name} بهدوء: لا بأس سأصلح اللوحة 🕊️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'refuge',
            'explanation': 'الاستعاذة تطرد وساوس الانتقام، ومسامحة {name} تعكس نبل وأخلاق الأبطال! 🌸',
          },
          {
            'emoji': '🌋',
            'title': 'سكب الطلاء على {name}',
            'desc': 'أقوم بسكب علبة الطلاء على لوحة {name} فوراً لكي يشعر بقهرتي!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'الانتقام وتخريب ممتلكات الآخرين بالمثل يزيد المشكلة اشتعالاً ويحرمك من حلم البطولة! 🌋',
          },
          {
            'emoji': '👊',
            'title': 'الضرب والاشتباك مع {name}',
            'desc': 'أصرخ في وجه {name} وأشتبك معه باليد ليعرف عاقبة إهماله!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'العنف الجسدي وتدمير الممتلكات سلوك خاطئ تماماً ويعرضك لعقوبة إدارة المدرسة القاسية! ❌',
          },
        ],
        'dialoguePrompt': 'كيف تعبر عن مشاعرك لـ {name} بأدب ولطف؟ 🗣️',
        'dialogueOptions': [
          {'text': 'يا {name}، أنا حزين لأن تعب أسبوعي ضاع، لكنني أعلم أنه خطأ غير مقصود، هل يمكنك مساعدتي في تنظيفها؟ 💖', 'isCorrect': true},
          {'text': 'أنت مهمل وأحمق، سأقوم بتمزيق كتبك لكي تبكي كما أبكيتني! 🤬', 'isCorrect': false},
          {'text': 'سأعاقبك وأخبر المعلم ليحرمك من الحصص، وأتمنى ألا أراك مجدداً! 🌋', 'isCorrect': false},
        ],
      },
      {
        'name': 'صعوبة ورقة الاختبار المفاجئ',
        'correct': 'breathing',
        'situation': 'وزع المعلم أوراق اختبار الرياضيات الفجائي، وعندما نظرت إلى الأسئلة شعرت بصعوبة بالغة وانسداد في تفكيرك ورغبة في البكاء وتكسير قلمك! 📝',
        'choices': [
          {
            'emoji': '🧘‍♂️',
            'title': 'التنفس بعمق وهدوء',
            'desc': 'آخذ 3 أنفاس عميقة وأغمض عيني لتهدئة ضربات قلبي واستعادة تركيزي 🧘‍♂️',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'breathing',
            'explanation': 'التنفس بعمق يهدئ ضربات القلب المتسارعة ويعيد الأكسجين لعقلك لتفكر بذكاء! 🌬️',
          },
          {
            'emoji': '🗣️',
            'title': 'طلب المساعدة بأدب',
            'desc': 'أرفع يدي وأطلب من معلمي بلطف شرح السؤال الصعب الذي لم أفهمه 🗣️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'dialogue',
            'explanation': 'طلب المساعدة بلطف من معلمك يفتح لك باب الفهم والحل، وهو سلوك رائع يعكس ذكائك! 👨‍🏫',
          },
          {
            'emoji': '🌋',
            'title': 'تمزيق ورقة الاختبار',
            'desc': 'أمزق ورقة الاختبار وأرميها تحت الطاولة غاضباً وأرفض الحل!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'تمزيق الورقة يضيع جهدك بالكامل ويحرمك من فرصة المحاولة والتعلم! ❌',
          },
          {
            'emoji': '🤬',
            'title': 'الصراخ والبكاء والانسحاب',
            'desc': 'أصرخ في الفصل وأبكي بصوت مرتفع وأغادر القاعة غاضباً!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'الصراخ والبكاء يشتت انتباه زملائك في القاعة ويعرضك للمساءلة السلوكية! 🌋',
          },
        ],
        'dialoguePrompt': 'كيف تطلب مساعدة المعلم في شرح السؤال بأدب؟ 👨‍🏫',
        'dialogueOptions': [
          {'text': 'يا معلمي الفاضل، أجد صعوبة في استيعاب فكرة هذا السؤال، هل تتكرم بشرحه لي برفق؟ 📝', 'isCorrect': true},
          {'text': 'أنت لم تشرح هذا الدرس جيداً والاختبار صعب جداً وظالم! 🤬', 'isCorrect': false},
          {'text': 'سأترك الورقة فارغة لأن أسئلتك مستحيلة ولا أحد يستطيع حلها! 🌋', 'isCorrect': false},
        ],
      },
      {
        'name': 'استفزاز وتنمر في الساحة',
        'correct': 'refuge',
        'situation': 'بدأ طالب من الصف الأكبر وهو {name} باستفزازك ودفعك ومحاولة إثارتك للمشاجرة أمام زملائك، وشعرت برغبة عارمة في ضربه بشدة والاشتباك معه! 👊',
        'choices': [
          {
            'emoji': '🕊️',
            'title': 'الاستعاذة والانسحاب',
            'desc': 'أقول بقلب حاضر: أعوذ بالله من الشيطان الرجيم، وأنسحب فوراً دون رد 🕊️',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'refuge',
            'explanation': 'الاستعاذة تحميك إيمانياً، والانسحاب الذكي يفشل خطة المستفز ويجعلك البطل الحقيقي! 🛡️',
          },
          {
            'emoji': '🧘‍♂️',
            'title': 'التنفس والهدوء الحازم',
            'desc': 'آخذ نفساً عميقاً وأذهب فوراً لإبلاغ المعلم المشرف في ساحة الفسحة بالتصرف 🧘‍♂️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'breathing',
            'explanation': 'الهدوء يزيل الشد العصبي الناتج عن الاستفزاز ويساعدك على التصرف بوعي تام! 👍',
          },
          {
            'emoji': '👊',
            'title': 'اللكم والضرب الفوري',
            'desc': 'أقوم بلكمه بقوة في وجهه أمام الجميع وأبدأ العراك معه لأثبت شجاعتي!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'الضرب يعرضك للأذى الجسدي ولعقوبة المدرسة الشديدة بالفصل والإنذار! ❌',
          },
          {
            'emoji': '🤬',
            'title': 'الشتم ورمي الحجارة',
            'desc': 'أشتمه بأقسى الكلمات البذيئة وأرميه بالحصى والعلب الفارغة لأهينه!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'الشتم ورمي الحصى يعكسان سلوكاً غير لائق بالبطل ويشوه مظهرك الجميل أمام الجميع! 🌋',
          },
        ],
        'dialoguePrompt': 'كيف تبلغ المعلم المشرف عن استفزاز {name} بهدوء؟ 🛡️',
        'dialogueOptions': [
          {'text': 'يا معلمي، الطالب {name} يضايقني ويدفعني في الساحة، وجئت إليك لكي تحل الموقف بحكمتك 🕊️', 'isCorrect': true},
          {'text': 'تعال بسرعة لتضرب الطالب {name} وإلا سأقوم بتكسير رأسه بالخارج! 🤬', 'isCorrect': false},
          {'text': 'المشرفون نائمون والطلاب يضربوننا، سأذهب وأحضر أخي الأكبر ليضربه! 🌋', 'isCorrect': false},
        ],
      },
      {
        'name': 'تجاهل الرأي في المشروع الجماعي',
        'correct': 'dialogue',
        'situation': 'تجاهل زملؤك بقيادة {name} رأيك تماماً وقرروا العمل بدون مشاركتك في المشروع، فشعرت بالغضب الشديد ورغبة في تمزيق لوحتهم أو الصراخ عليهم! 👥',
        'choices': [
          {
            'emoji': '🗣️',
            'title': 'التعبير الهادئ والمشاركة',
            'desc': 'أحدثهم بصوت هادئ قائلاً: يا أصدقائي، حزين لتجاهل رأي، ودعونا نتناقش 🗣️',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'dialogue',
            'explanation': 'التعبير الهادئ عن المشاعر يحل سوء التفاهم، ويقوي روابط الصداقة وروح الفريق! 👥💖',
          },
          {
            'emoji': '🧘‍♂️',
            'title': 'التنظيم والهدوء',
            'desc': 'آخذ نفساً عميقاً وأقترح كتابة كل أفكارنا على ورقة ومقارنتها بشكل عادل 🧘‍♂️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'breathing',
            'explanation': 'التنظيم والتفكير العملي يقدمان حلولاً مريحة للمجموعة ويبهج المعلم بذكائكم! 📝',
          },
          {
            'emoji': '🌋',
            'title': 'تخريب لوحة الفريق',
            'desc': 'أقوم بخطف لوحة المشروع وتمزيقها بالمقص لكي أحرمهم جميعاً من الدرجات!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'تخريب مجهود الآخرين يدمر الصداقة تماماً ويظهرك بمظهر الطفل المخرب الأناني! ❌',
          },
          {
            'emoji': '🤬',
            'title': 'الصراخ والانسحاب بغضب',
            'desc': 'أصرخ عليهم قائلاً أنهم أنانيون وسيئون، وأنسحب من المجموعة بغضب شديد!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'الصراخ والانسحاب يضيعان فرصة إثبات وجودك الإيجابي ويعمقان المشاكل! 🌋',
          },
        ],
        'dialoguePrompt': 'كيف تتكلم مع {name} وباقي زملائك بأدب لإشراكك؟ 🗣️',
        'dialogueOptions': [
          {'text': 'يا {name}، أنا عضو في الفريق وأريد مشاركتكم بأفكاري ليكون مشروعنا هو الأفضل في الصف 👥💖', 'isCorrect': true},
          {'text': 'أنتم فاشلون ومشروعكم سخيف ولن أشارك معكم في أي عمل تافه! 🤬', 'isCorrect': false},
          {'text': 'سأخرب عملكم وأخبر المعلم ليعطيكم درجة صفر لأنكم تجاهلتموني! 🌋', 'isCorrect': false},
        ],
      },
      {
        'name': 'خسارة مباراة كرة القدم',
        'correct': 'breathing',
        'situation': 'خسرت مباراتك المفضلة اليوم وبدأ زميلك {name} بالضحك عليك ونسب الفوز لنفسه وسخريته منك ⚽... وتشعر بضيق شديد وحسرة بقلبك ورغبة بالصراخ!',
        'choices': [
          {
            'emoji': '🧘‍♂️',
            'title': 'التنفس والروح الرياضية',
            'desc': 'آخذ 3 أنفاس عميقة وأهدأ، ثم أذهب لمصافحة {name} بروح رياضية عالية 🧘‍♂️',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'breathing',
            'explanation': 'التنفس بعمق يهدئ ضربات قلبك، ومصافحة منافسك تدل على نضجك الرياضي الكبير! 🤝🏆',
          },
          {
            'emoji': '🕊️',
            'title': 'الاستعاذة وتهدئة النفس',
            'desc': 'أستعيذ بالله من الشيطان الرجيم وأقول لنفسي: هذه مجرد مباراة وسأتدرب لأفوز القادم 🕊️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'refuge',
            'explanation': 'الاستعاذة تطرد الغل والضيق، وتجعلك تركز على تطوير مهارتك بدلاً من الغضب! 👍⚽',
          },
          {
            'emoji': '🌋',
            'title': 'ركل الكرة وتوجيه الشتائم',
            'desc': 'أقوم بركل الكرة بقوة وتوجيه الشتائم لـ {name} وأتهم الحكم بالغش والانحياز!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'الغضب على الحكم وسب الزملاء يشوه أخلاقك الرياضية ويحرمك من احترام فريقك! ❌',
          },
          {
            'emoji': '🤬',
            'title': 'الصراخ والبكاء العنيف',
            'desc': 'أبكي بغضب وأصرخ في وجه {name} قائلاً أنه فاز بالحظ وأرفض مصافحته!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'البكاء والصراخ لعدم تقبل الخسارة يظهرك ضعيفاً؛ البطل الحقيقي يتقبل الخسارة ويتعلم! 🌋',
          },
        ],
        'dialoguePrompt': 'كيف تهنئ {name} وتتحدث معه بروح رياضية؟ ⚽',
        'dialogueOptions': [
          {'text': 'مبارك الفوز يا {name}، لقد لعبتم مباراة رائعة، وسنتدرب بقوة لمواجهتكم القادمة بروح طيبة! 🤝', 'isCorrect': true},
          {'text': 'لقد فزتم بالحظ والتحكيم الفاشل، وأنت لاعب سيء لا تجيد ركل الكرة! 🤬', 'isCorrect': false},
          {'text': 'لن ألعب معكم مجدداً وسأمزق كرة اللعب لكي لا تفرحوا بها! 🌋', 'isCorrect': false},
        ],
      },
      {
        'name': 'أخذ الأدوات دون إذن',
        'correct': 'refuge',
        'situation': 'أخذ زميلك {name} قلمك المفضل أو كشكولك دون استئذانك ورفض إعادته فوراً وشعرت برغبة في ضربه واسترجاعه بالقوة وتوجيه الشتائم له! ✏️',
        'choices': [
          {
            'emoji': '🕊️',
            'title': 'الاستعاذة والطلب بهدوء',
            'desc': 'أستعيذ بالله لأطرد فكرة العنف، ثم أطلب من {name} القلم بهدوء وثقة دون مشاجرة 🕊️',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'refuge',
            'explanation': 'الاستعاذة تحميك من الشيطان، والطلب الواثق الهادئ يجبر {name} على خجل من تصرفه وإعادته! 🛡️✏️',
          },
          {
            'emoji': '🗣',
            'title': 'التعبير المؤدب الحازم',
            'desc': 'أعبر له عن ضيقي قائلاً: يا {name}، أرجو استئذاني أولاً قبل استخدام أشيائي الخاصة 🗣️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'dialogue',
            'explanation': 'وضع حدود واضحة بأدب واحترام يحفظ ممتلكاتك ويعلم زملائك آداب الاستئذان السليمة! 👍',
          },
          {
            'emoji': '👊',
            'title': 'الضرب والانتزاع بالقوة',
            'desc': 'أضربه بيدي وأنتزع القلم من مقلمته بالقوة وأخرب دفاتر {name} انتقاماً!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'أخذ الحق بالعنف والضرب يحولك إلى معتدٍ في نظر المعلم ويضيع حقك تماماً! ❌',
          },
          {
            'emoji': '🤬',
            'title': 'الصراخ والشتم في القاعة',
            'desc': 'أصرخ في وجه {name} وأشتمه أمام بقية زملائه في الغرفة لكي أحرجه!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'الصراخ والشتم ينفيان عنك صفات البطل المؤدب ويشوهان سمعتك المدرسية الجميلة! 🌋',
          },
        ],
        'dialoguePrompt': 'كيف تطلب من {name} إعادة قلمك بأدب وحزم؟ ✏️',
        'dialogueOptions': [
          {'text': 'يا {name}، هذا القلم يخصني وأحتاجه لحل الواجب الآن، الرجاء إعادته وتفضل استأذن المرة القادمة 💖', 'isCorrect': true},
          {'text': 'أنت سارق وبليد، أرجع قلمي فوراً وإلا سأقوم بضربك ضرباً مبرحاً! 🤬', 'isCorrect': false},
          {'text': 'سأخطف كل أقلامك وأرميها في سلة المهملات انتقاماً منك يا غشاش! 🌋', 'isCorrect': false},
        ],
      },
      {
        'name': 'التعثر والإحراج بالطابور',
        'correct': 'wudu',
        'situation': 'بينما كنت واقفاً في طابور الصباح، تعثرت وسقطت على الأرض فضحك زميلك {name} وبعض الطلاب عليك، وشعرت بوجهك يشتعل خجلاً وحرارة وغضباً! 😳',
        'choices': [
          {
            'emoji': '💦',
            'title': 'الوضوء لغسل الوجه',
            'desc': 'أستأذن للذهاب لدورة المياه لأغسل وجهي بالماء البارد لأهدأ وأزيل حرارة الخجل 💦',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'wudu',
            'explanation': 'غسل الوجه بالماء البارد والوضوء يعيد دورتك الدموية للهدوء ويزيل حرارة الغضب والخجل تماماً! 💧😳',
          },
          {
            'emoji': '🧘‍♂️',
            'title': 'التنفس والنهوض بابتسامة',
            'desc': 'آخذ 3 أنفاس عميقة لتنظيم نبضات قلبي وأنهض مبتسماً وأنفض الغبار عن ملابسي 🧘‍♂️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'breathing',
            'explanation': 'النهوض بابتسامة وثقة ينهي الموقف المحرج فوراً ويجعل الضحك بلا قيمة! 👍🌸',
          },
          {
            'emoji': '👊',
            'title': 'النهوض والضرب والتوعد',
            'desc': 'أنهض غاضباً وأدفع {name} الذي ضحك علي وأتوعده بالضرب المبرح بعد المدرسة!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'الانتقام بالضرب لشخص ضحك على سقوطك يحول موقفاً بسيطاً غير مقصود إلى معركة وجناية سلوكية! ❌',
          },
          {
            'emoji': '🤬',
            'title': 'الصراخ والسب والاعتراض',
            'desc': 'أصرخ في الطابور وأسب {name} وأبكي بصوت عالٍ أمام المعلمين والمدير!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'البكاء والصراخ في الطابور يفقدك وقارك المدرسي ويعزز الموقف المحرج بدلاً من إنهائه! 🌋',
          },
        ],
        'dialoguePrompt': 'كيف تتصرف وتتحدث مع {name} الذي ضحك عليك بثقة وأدب؟ 🗣️',
        'dialogueOptions': [
          {'text': 'لا بأس يا {name}، كلنا معرضون للتعثر والسقوط، الحمد لله أنني بخير بفضل الله 💖', 'isCorrect': true},
          {'text': 'لماذا تضحك يا غبي؟ أتمنى أن تسقط وتكسر ساقك لكي أضحك عليك بالمثل! 🤬', 'isCorrect': false},
          {'text': 'سأجعلك تندم وأشكو للمدير ليفصلك من المدرسة لأنك ضحكت علي! 🌋', 'isCorrect': false},
        ],
      },
      {
        'name': 'الانتظار الطويل في الكانتين',
        'correct': 'dialogue',
        'situation': 'وقفت في طابور طويل جداً لشراء الطعام في الفسحة، وجاء زميلك {name} وتخطاك بالدور بغش وشعرت برغبة في دفعه وشتمه بعنف! ⏳',
        'choices': [
          {
            'emoji': '🗣️',
            'title': 'التحدث بأدب وحزم',
            'desc': 'أربت على كتفه بلطف وأقول له: يا {name}، الرجاء الالتزام بدورك والعودة للخلف 🗣️',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'dialogue',
            'explanation': 'التحدث الهادئ الحازم يظهر رقي أخلاقك ويجعل {name} يخجل من تصرفه الأناني ويعود للخلف! 👥🌸',
          },
          {
            'emoji': '🧘‍♂️',
            'title': 'التنفس والاستعانة بالمشرف',
            'desc': 'آخذ نفساً عميقاً وأشير للمعلم المشرف المسؤول ليوجه {name} لمكانه الصحيح 🧘‍♂️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'breathing',
            'explanation': 'الاستعانة بالنظام والمعلمين يحفظ لك حقك بذكاء وبدون إثارة شغب أو مشكلات! 👍',
          },
          {
            'emoji': '🌋',
            'title': 'الدفع العنيف وإسقاط طعامه',
            'desc': 'أقوم بدفع {name} بقوة وإسقاط محفظته وطعامه على الأرض لكي أمنعه من التخطي!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'استخدام العنف الجسدي والدفع يعرضك لعقوبة إدارة المدرسة ويجعلك مخطئاً بنظرهم! ❌',
          },
          {
            'emoji': '🤬',
            'title': 'الشتم بصوت عالٍ والإهانة',
            'desc': 'أشتم {name} بصوت عالٍ لكي يسمعه الجميع في الساحة وأنعته بالغشاش والأنانية!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'السب والشتم والفضائح لا تبني حقاً بل تنزع عنك وقار البطل الحكيم الهادئ! 🌋',
          },
        ],
        'dialoguePrompt': 'كيف تطلب من {name} التزام النظام والعودة لمكانه بأدب؟ 🗣️',
        'dialogueOptions': [
          {'text': 'يا {name}، لقد وقفنا جميعاً بالدور ونشعر بالجوع أيضاً، أرجو أن تلتزم بالنظام وتعود للخلف 👥🌸', 'isCorrect': true},
          {'text': 'عد للخلف يا سارق الأدوار وإلا سأبرحك ضرباً أمام بائع الكانتين! 🤬', 'isCorrect': false},
          {'text': 'يا معلمي، الطالب {name} لص وغشاش وقام بسرقة شطيرتي ووجبتي بالقوة! 🌋', 'isCorrect': false},
        ],
      },
      {
        'name': 'لوم المعلم أمام الصف',
        'correct': 'breathing',
        'situation': 'وجه المعلم لومًا وعتابًا شديدًا لك بخصوص واجب نسيته أمام زملائك وبحضور {name}، وشعرت بضيق شديد وإحراج وحرارة الغضب ورغبة في الصراخ! 👨‍🏫',
        'choices': [
          {
            'emoji': '🧘‍♂️',
            'title': 'التنفس والاعتذار المؤدب',
            'desc': 'آخذ 3 أنفاس عميقة لأهدأ وأتحكم بأعصابي، ثم أعتذر للمعلم بأدب وأعده بحله 🧘‍♂️',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'breathing',
            'explanation': 'التنفس يهدئ الشحن العصبي، والاعتذار للمعلم بأدب يكبرك في عيون المعلم وزملائك! 👨‍🏫💖',
          },
          {
            'emoji': '🗣️',
            'title': 'التحدث الهادئ بعد الحصة',
            'desc': 'أنتظر حتى نهاية الحصة وأذهب للمعلم منفرداً لأشرح له ظروفي الخاصة بأدب ولطف 🗣️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'dialogue',
            'explanation': 'التحدث الفردي مع المعلم بأدب يعكس نضجك وتقديرك له، ويجعله يعتذر لك ويقدر ظروفك! 👍',
          },
          {
            'emoji': '🌋',
            'title': 'تخريب أدوات المعمل والتجارب',
            'desc': 'أقوم بإلقاء دفاتر معمل العلوم والتجارب على الطاولة بغضب معلناً اعتراضي!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'تكسير وتخريب أدوات المعمل والاعتراض بغضب يجعلك طالباً مشاكباً مهدداً بالفصل! ❌',
          },
          {
            'emoji': '🤬',
            'title': 'مقاطعة المعلم بالصراخ',
            'desc': 'أقاطع كلام المعلم بصراخ قائلاً له: لست المذنب الوحيد وهناك {name} لم يحل أيضاً!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'مقاطعة المعلم بالصراخ وذكر عيوب زملائك مثل {name} يعتبر سوء سلوك وفتنة مذمومة! 🌋',
          },
        ],
        'dialoguePrompt': 'كيف تشرح ظروفك الخاصة لمعلمك بأدب ولطف بعد الحصة؟ 👨‍🏫',
        'dialogueOptions': [
          {'text': 'معلمي الفاضل، أعتذر بشدة عن نسيان الواجب بالمنزل، ولقد كتبته كاملاً وسأحضره غداً صباحاً بالتأكيد 💖', 'isCorrect': true},
          {'text': 'أنت معلم قاسٍ وتتعمد إحراجي أمام {name} وزملائي، وأنا أكره مادتك! 🤬', 'isCorrect': false},
          {'text': 'لقد نسيت الواجب لأن درسي صعب وسخيف، ولن أكتبه أبداً بعد اليوم! 🌋', 'isCorrect': false},
        ],
      },
      {
        'name': 'الحرمان من اللعب الجماعي',
        'correct': 'dialogue',
        'situation': 'رفض زميلك {name} مشاركتك في اللعبة الجماعية المفضلة بالفسحة وأبعدك عنهم وشعرت بالقهر والضيق الشديد ورغبة في دفعه وشتمه! 👥',
        'choices': [
          {
            'emoji': '🗣️',
            'title': 'التحدث وطلب المشاركة بأدب',
            'desc': 'أقترب من {name} بهدوء وأقول: يا صديقي، أحب اللعب معكم فهل يمكنني الانضمام؟ 🗣️',
            'isPerfect': true,
            'isGood': false,
            'interaction': 'dialogue',
            'explanation': 'الطلب المؤدب الهادئ يرقق قلوب زملائك ويجعل {name} يرحب بك للعب معهم بسعادة! 👥💖',
          },
          {
            'emoji': '🧘‍♂️',
            'title': 'التنفس واقتراح حل عادل',
            'desc': 'آخذ نفساً عميقاً وأقترح عليهم أن نكون فريقين متساويين لكي يلعب الجميع بعدالة 🧘‍♂️',
            'isPerfect': false,
            'isGood': true,
            'interaction': 'breathing',
            'explanation': 'اقتراح تقسيم الفرق بعدالة يظهر مهاراتك القيادية وحب الخير للجميع! 👍⚽',
          },
          {
            'emoji': '🌋',
            'title': 'خطف الكرة وتخريب اللعب',
            'desc': 'أخطف الكرة من {name} وأجري بها بعيداً لكي أخرب عليهم متعة اللعب والفسحة!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'تخريب ألعاب الآخرين وانسحاب بالكرة يزيد المشاحنات ويجعل الطلاب يكرهون اللعب معك! ❌',
          },
          {
            'emoji': '🤬',
            'title': 'الصراخ والشتم والتهديد',
            'desc': 'أصرخ في وجوههم قائلاً أنهم أشرار وأنانيون، وأهدد {name} بالضرب بعد المدرسة!',
            'isPerfect': false,
            'isGood': false,
            'interaction': 'none',
            'explanation': 'الغضب والصراخ والتهديد بالضرب يعرضك للمساءلة القانونية ويمنعك من الصداقة! 🌋',
          },
        ],
        'dialoguePrompt': 'كيف تطلب من {name} الانضمام للعب الجماعي بلطف؟ ⚽',
        'dialogueOptions': [
          {'text': 'يا {name}، أود أن أشارككم اللعب كحارس مرمى أو مهاجم، لنستمتع جميعاً بالفسحة معاً 👥💖', 'isCorrect': true},
          {'text': 'أنت شخص أناني وسخيف وهذه الكرة ليست ملكك، سآخذها رغماً عن أنفك! 🤬', 'isCorrect': false},
          {'text': 'سأذهب للمعلم وأكذب عليه وأقول أن {name} قام بضربي لكي يعاقبكم ويمنعكم من اللعب! 🌋', 'isCorrect': false},
        ],
      },
    ];
    
    final List<String> names = ['أحمد', 'عمر', 'يوسف', 'خالد', 'علي', 'عادل', 'مازن', 'زياد', 'إبراهيم', 'مصطفى', 'كريم', 'حمزة', 'سليم', 'هاني'];
    
    final String env = environments[seed % environments.length];
    // Map scenario index directly to one of the 10 triggers to avoid repetition within a level
    final int triggerIndex = scenarioIndex % triggers.length;
    final Map<String, dynamic> trig = triggers[triggerIndex];
    final String classmateName = names[(seed + 7) % names.length];
    
    // Build custom situation text with environment and classmate name
    String situationText = trig['situation']!.replaceAll('{name}', classmateName);
    situationText = "بينما كنت $env، $situationText";
    
    final String correctAction = trig['correct']!;
    
    // Parse customized choices and replace {name} dynamically
    final List<Map<String, dynamic>> choices = [];
    final List rawChoices = trig['choices'] as List;
    for (var c in rawChoices) {
      final map = Map<String, dynamic>.from(c as Map);
      choices.add({
        'emoji': map['emoji'],
        'title': map['title'].toString().replaceAll('{name}', classmateName),
        'desc': map['desc'].toString().replaceAll('{name}', classmateName),
        'isPerfect': map['isPerfect'],
        'isGood': map['isGood'],
        'interaction': map['interaction'],
        'explanation': map['explanation'].toString().replaceAll('{name}', classmateName),
      });
    }
    
    // Shuffle choices dynamically using random seed to prevent static layouts
    choices.shuffle(math.Random(seed));
    
    // Build customized dialogue options and replace {name} dynamically
    final List<Map<String, dynamic>> dialogueOptions = [];
    final List rawDialogueOptions = trig['dialogueOptions'] as List;
    for (var opt in rawDialogueOptions) {
      final map = Map<String, dynamic>.from(opt as Map);
      dialogueOptions.add({
        'text': map['text'].toString().replaceAll('{name}', classmateName),
        'isCorrect': map['isCorrect'],
      });
    }
    
    return {
      'situation': situationText,
      'trigger': trig['name']!,
      'correctInteraction': correctAction,
      'choices': choices,
      'dialoguePrompt': trig['dialoguePrompt']!.replaceAll('{name}', classmateName),
      'dialogueOptions': dialogueOptions,
    };
  }

  @override
  void initState() {
    super.initState();
    
    // Load local game progress from SharedPreferences!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGameProgress();
    });

    // Start ambient updates for volcano shake
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _isGameOver || _isWon) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_screenShake > 0.1) {
          _screenShake *= 0.85;
        } else {
          _screenShake = 0.0;
        }
      });
    });
  }

  // Persistent Game Load Progress
  Future<void> _loadGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final gameState = Provider.of<StudentGameState>(context, listen: false);
    
    setState(() {
      _currentLevel = prefs.getInt('g1_current_level') ?? gameState.getUnlockedLevel('game1');
      _currentScenarioInLevel = prefs.getInt('g1_current_scenario') ?? 0;
      _score = prefs.getInt('g1_session_score') ?? 0;
    });
  }

  // Persistent Game Save Progress (Session stats remain separate from account balance!)
  Future<void> _saveGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('g1_current_level', _currentLevel);
    await prefs.setInt('g1_current_scenario', _currentScenarioInLevel);
    await prefs.setInt('g1_session_score', _score);
  }

  void _handleActionSelected(Map<String, dynamic> card) {
    if (_showSuccessOverlay || _activeInteraction != 'none') return; 

    final scenario = _getScenario(_currentLevel, _currentScenarioInLevel);

    if (card['isPerfect'] == true || card['isGood'] == true) {
      // Tapping a positive card launches its corresponding interactive mini-game!
      setState(() {
        _activeInteraction = card['interaction'] ?? 'none';
        
        if (_activeInteraction == 'breathing') {
          _breathingScale = 1.0;
          _breathingDuration = 0;
          _breathingText = 'اضغط واستمر في الضغط للشهيق 🌬️';
        } else if (_activeInteraction == 'wudu') {
          _wuduProgress = 0.0;
          _wuduSwipePoints.clear();
        } else if (_activeInteraction == 'refuge') {
          // Tapping Refuge Shield
        } else if (_activeInteraction == 'dialogue') {
          _dialogueQuestion = scenario['dialoguePrompt'] ?? 'كيف تعبر عن مشاعرك بأدب ولطف؟ 🗣️';
          final rawOptions = scenario['dialogueOptions'] as List? ?? [];
          _dialogueOptions = rawOptions.map((o) => Map<String, dynamic>.from(o as Map)).toList();
        }
      });
    } else {
      // DESTRUCTIVE ACTION CHOSEN! (Negative feedback)
      HapticFeedback.vibrate();
      setState(() {
        _screenShake = 22.0; // Violent volcano shake!
        _score = math.max(0, _score - 2); // Penalty to temporary score
        
        // Volcano heats up when making a negative choice! (+25%)
        _angerLevel = math.min(100.0, _angerLevel + 25.0); 
        
        _feedbackMessage = card['explanation'] ?? 'أوه لا! هذا التصرف زاد من اشتعال البركان! 🌋';
        _feedbackColor = const Color(0xFFEF4444);
      });
      
      _saveGameProgress();

      // Check failure condition
      if (_angerLevel >= 100.0) {
        _isGameOver = true;
        _showFinishDialog(false);
      }
    }
  }

  // Once the restored interactive overlay is completed, reward and proceed!
  void _applyPositiveCompletion(String completedInteraction, bool isPerfect) {
    HapticFeedback.mediumImpact();
    final scenario = _getScenario(_currentLevel, _currentScenarioInLevel);
    
    // Determine the selected card's details to show in success overlay
    final List rawChoices = scenario['choices'] as List? ?? [];
    final List<Map<String, dynamic>> choices = rawChoices.map((c) => Map<String, dynamic>.from(c as Map)).toList();
    final selectedCard = choices.firstWhere(
      (c) => c['interaction'] == completedInteraction && (isPerfect ? c['isPerfect'] == true : c['isGood'] == true),
      orElse: () => choices.firstWhere((c) => c['interaction'] == completedInteraction),
    );

    final int points = isPerfect ? 5 : 2;
    // Positive action decreases volcano incrementally! Perfect cools -40%, Good cools -20%
    final double coolingAmount = isPerfect ? 40.0 : 20.0;

    setState(() {
      _activeInteraction = 'none';
      _score += points; // Add points to temporary session score
      
      // Volcano level cools down when making a positive choice!
      _angerLevel = math.max(0.0, _angerLevel - coolingAmount);
      
      _earnedPoints = points;
      
      if (_angerLevel <= 0.0) {
        // Round Won! Volcano is fully cooled to 0%
        _successTitle = isPerfect ? 'تصرف مثالي ورائع! 🏆🌟' : 'تصرف جيد ومفيد! 👍🌸';
        _successDesc = '${selectedCard['explanation']}\n\nلقد نجحت في إخماد بركان الغضب بالكامل وتبريده! 🎉❄️';
        _showSuccessOverlay = true;
      } else {
        // Decreased but still hot
        _feedbackMessage = '${selectedCard['explanation']}\n\nلقد نجحت في تبريد البركان بمقدار ${coolingAmount.toInt()}%، ولكنه لا يزال مشتعلاً! اختر تصرفاً إيجابياً آخر لتبريده بالكامل! ❄️🌬️';
        _feedbackColor = const Color(0xFF22D3EE);
        _saveGameProgress();
      }
    });
  }

  // Immersive Breathing Coach logic
  void _startBreathing() {
    _breathingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _breathingDuration += 100;
        if (_breathingDuration < 3000) {
          // Inhale phase: scale up
          _breathingScale = 1.0 + (_breathingDuration / 3000.0) * 0.8;
          _breathingText = 'شهيق عميق... املأ صدرك بالسلام 🌬️';
        } else if (_breathingDuration >= 3000 && _breathingDuration < 6000) {
          // Exhale phase: scale down
          _breathingScale = 1.8 - ((_breathingDuration - 3000) / 3000.0) * 0.8;
          _breathingText = 'زفير هادئ... أخرج كل حرارة الغضب 💨';
        } else {
          // Finished breath cycle!
          _finishBreathingSuccess();
        }
      });
    });
  }

  void _stopBreathingPrematurely() {
    _breathingTimer?.cancel();
    if (_activeInteraction == 'breathing') {
      setState(() {
        _activeInteraction = 'none';
        _feedbackMessage = 'لقد توقفت عن التنفس مبكراً! حاول إكمال دورة الشهيق والزفير بالكامل 🌸';
        _feedbackColor = const Color(0xFFF59E0B);
      });
    }
  }

  void _finishBreathingSuccess() {
    _breathingTimer?.cancel();
    final scenario = _getScenario(_currentLevel, _currentScenarioInLevel);
    final List rawChoices = scenario['choices'] as List? ?? [];
    final List<Map<String, dynamic>> choices = rawChoices.map((c) => Map<String, dynamic>.from(c as Map)).toList();
    final breathingCard = choices.firstWhere((c) => c['interaction'] == 'breathing');
    final bool isPerfect = breathingCard['isPerfect'] == true;

    _applyPositiveCompletion('breathing', isPerfect);
  }

  // Wudu Swiping logic
  void _handleWuduSwipe(DragUpdateDetails details) {
    if (_activeInteraction != 'wudu') return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPos = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _wuduSwipePoints.add(localPos);
      if (_wuduSwipePoints.length > 30) {
        _wuduSwipePoints.removeAt(0);
      }
      
      _wuduProgress += 0.008; // progressive wash
      if (_wuduProgress >= 1.0) {
        _finishWuduSuccess();
      }
    });
  }

  void _finishWuduSuccess() {
    final scenario = _getScenario(_currentLevel, _currentScenarioInLevel);
    final List rawChoices = scenario['choices'] as List? ?? [];
    final List<Map<String, dynamic>> choices = rawChoices.map((c) => Map<String, dynamic>.from(c as Map)).toList();
    final wuduCard = choices.firstWhere((c) => c['interaction'] == 'wudu');
    final bool isPerfect = wuduCard['isPerfect'] == true;

    _applyPositiveCompletion('wudu', isPerfect);
  }

  // Refuge/Seek Shield Logic
  void _triggerRefugeShield() {
    final scenario = _getScenario(_currentLevel, _currentScenarioInLevel);
    final List rawChoices = scenario['choices'] as List? ?? [];
    final List<Map<String, dynamic>> choices = rawChoices.map((c) => Map<String, dynamic>.from(c as Map)).toList();
    final refugeCard = choices.firstWhere((c) => c['interaction'] == 'refuge');
    final bool isPerfect = refugeCard['isPerfect'] == true;

    _applyPositiveCompletion('refuge', isPerfect);
  }

  // Dialogue option selection logic
  void _handleDialogueOptionSelected(Map<String, dynamic> option) {
    if (option['isCorrect'] == true) {
      final scenario = _getScenario(_currentLevel, _currentScenarioInLevel);
      final List rawChoices = scenario['choices'] as List? ?? [];
      final List<Map<String, dynamic>> choices = rawChoices.map((c) => Map<String, dynamic>.from(c as Map)).toList();
      final dialogueCard = choices.firstWhere((c) => c['interaction'] == 'dialogue');
      final bool isPerfect = dialogueCard['isPerfect'] == true;

      _applyPositiveCompletion('dialogue', isPerfect);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _activeInteraction = 'none';
        _screenShake = 22.0; // Volcano shakes
        _score = math.max(0, _score - 2); // Penalty
        
        // Volcano heats up (+25%) when choosing wrong dialogue option!
        _angerLevel = math.min(100.0, _angerLevel + 25.0); 
        
        _feedbackMessage = 'أوه! التعبير بهذه الطريقة زاد من غضب الطرف الآخر وأشعل البركان! 🤬';
        _feedbackColor = const Color(0xFFEF4444);
      });
      
      _saveGameProgress();
      
      if (_angerLevel >= 100.0) {
        _isGameOver = true;
        _showFinishDialog(false);
      }
    }
  }

  void _goToNextScenario() {
    final gameState = Provider.of<StudentGameState>(context, listen: false);

    setState(() {
      _showSuccessOverlay = false;
      if (_currentScenarioInLevel < 9) {
        // Move to next scenario inside current level
        _currentScenarioInLevel++;
        _angerLevel = 75.0; // Reset anger
        _feedbackMessage = '';
        _feedbackColor = Colors.white;
        _saveGameProgress(); // Save mid-level progress
      } else {
        // Finished all 10 scenarios of the current level!
        
        // ── REGISTER/SAVE ACCUMULATED LEVEL POINTS PERMANENTLY! ──
        gameState.addPoints(10);
        
        // Unlock next level in the main state if currently on highest unlocked level
        if (_currentLevel == gameState.getUnlockedLevel('game1')) {
          gameState.unlockNextLevel('game1');
        }

        if (_currentLevel < 50) {
          _currentLevel++;
          _currentScenarioInLevel = 0;
          _score = 0; // Reset session score for the new level
          _angerLevel = 75.0;
          _feedbackMessage = 'رائع جداً! لقد نجحت بتخطي كافة عقبات المستوى السابق! وتم تسجيل نقاطك في رصيدك 🏆';
          _feedbackColor = const Color(0xFFEAB308);
          _saveGameProgress(); // Save level start progress
        } else {
          // Finished all 50 levels! Victory!
          _isWon = true;
          _showFinishDialog(true);
        }
      }
    });
  }

  void _showFinishDialog(bool won) {
    if (won) {
      context.read<StudentGameState>().addPoints(10);
      context.read<StudentGameState>().unlockNextLevel('game1');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
          side: BorderSide(
            color: won ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            width: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: won ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                won ? '👑' : '🌋',
                style: TextStyle(fontSize: 48.sp),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              won ? 'قاهر بركان الغضب الأسطوري! 🏆' : 'انفجر البركان! 🌋',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              won
                  ? 'مذهل يا بطل الأبطال! لقد روضت نيران الغضب والبركان عبر 50 مستوى كاملاً من المواقف المدرسية الواقعية، وأصبحت حكيماً وقدوة لكافة الطلاب! +15 نقطة 👑🌟'
                  : 'لقد تسببت الخيارات العنيفة والغاضبة في ثوران البركان بالكامل.. تذكر دائماً ألا تقابل الغضب بالضرب أو الصراخ. حاول مجدداً لتتعلم التصرف السليم!',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13.sp, height: 1.5),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? const Color(0xFF10B981) : const Color(0xFF475569),
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: () {
                Navigator.pop(context); // pop dialog
                Navigator.pop(context); // pop screen
              },
              child: Text(
                'العودة للرئيسية',
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<StudentGameState>(context);
    final scenario = _getScenario(_currentLevel, _currentScenarioInLevel);
    final List rawChoices = scenario['choices'] as List? ?? [];
    final List<Map<String, dynamic>> choices = rawChoices.map((c) => Map<String, dynamic>.from(c as Map)).toList();

    // Compute shake effect
    final double shakeOffset = (_random.nextDouble() - 0.5) * _screenShake;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Transform.translate(
        offset: Offset(shakeOffset, 0),
        child: Stack(
          children: [
            // Ambient glowing background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF030712), Color(0xFF0D0E25), Color(0xFF1E1B4B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Floor elements or smoke particles
            ...List.generate(8, (index) {
              final double bottom = (index * 80) % MediaQuery.of(context).size.height;
              final double left = (index * 110) % MediaQuery.of(context).size.width;
              return Positioned(
                bottom: bottom,
                left: left,
                child: Icon(
                  Icons.lens_blur_rounded,
                  color: const Color(0xFFEF4444).withOpacity(0.015 + (_angerLevel / 4000)),
                  size: 80.w,
                ),
              );
            }),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Appbar Panel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Column(
                          children: [
                            Text(
                              'بركان الغضب: المستوى $_currentLevel 🌋',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'الموقف ${_currentScenarioInLevel + 1} من 10',
                              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 11.sp, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 16),
                              SizedBox(width: 4.w),
                              Text(
                                '$_score',
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // ── Active Scenario Card (Beautiful Glassmorphism) ──
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'الموقف: ${scenario['trigger']}',
                              style: GoogleFonts.cairo(color: const Color(0xFFA78BFA), fontSize: 11.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            scenario['situation']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // ── Visual Interactive Volcano / Thermometer Arena ──
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Heat Glow Aura behind Volcano
                            Positioned(
                              top: 20.h,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 120.w + (_angerLevel * 0.7).w,
                                height: 120.w + (_angerLevel * 0.7).w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _angerLevel >= 60.0
                                          ? const Color(0xFFEF4444).withOpacity(0.08 + (_angerLevel / 400.0))
                                          : const Color(0xFF06B6D4).withOpacity(0.05 + ((100 - _angerLevel) / 400.0)),
                                      blurRadius: 30,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Dynamic Central Volcano/Heart Visual Representation
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // The Volcano Emoji / Thermometer
                                AnimatedScale(
                                  scale: 1.0 + (_angerLevel / 350.0),
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    _angerLevel >= 60.0 ? '🌋' : '🏝️',
                                    style: TextStyle(fontSize: 64.sp),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  _angerLevel >= 60.0 ? 'بركان الغضب مشتعل وساخن!' : 'قلب البطل هادئ وبارد كالمصيف!',
                                  style: GoogleFonts.cairo(
                                    color: _angerLevel >= 60.0 ? const Color(0xFFF43F5E) : const Color(0xFF22D3EE),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 8.h),

                                // Thermometer Bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.thermostat_rounded, color: Colors.white60, size: 18),
                                    SizedBox(width: 6.w),
                                    Container(
                                      width: 150.w,
                                      height: 10.h,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10.r),
                                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                                      ),
                                      child: Stack(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 400),
                                            width: 150.w * (_angerLevel / 100.0),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: _angerLevel >= 60.0
                                                    ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                                                    : [const Color(0xFF06B6D4), const Color(0xFF10B981)],
                                              ),
                                              borderRadius: BorderRadius.circular(10.r),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '${_angerLevel.toInt()}%',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white70,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Active Live Feedback Banner
                    if (_feedbackMessage.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: _feedbackColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: _feedbackColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          _feedbackMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: _feedbackColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(height: 10.h),

                    // ── Dynamic Actions Choice Panel (Learn by Choosing) ──
                    Text(
                      'اختر التصرف المناسب للسيطرة على غضبك يا بطل: 👇',
                      style: GoogleFonts.cairo(
                        color: Colors.white60,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    
                    // Action Grid (4 customized school scenario choices)
                    Expanded(
                      flex: 3,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 8.h,
                          childAspectRatio: 1.8,
                        ),
                        itemCount: choices.length,
                        itemBuilder: (context, index) {
                          final card = choices[index];
                          
                          return GestureDetector(
                            onTap: () => _handleActionSelected(card),
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: (card['isPerfect'] == true || card['isGood'] == true)
                                      ? const Color(0xFF10B981).withOpacity(0.2) 
                                      : const Color(0xFFEF4444).withOpacity(0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 4.w,
                                    runSpacing: 2.h,
                                    children: [
                                      Text(card['emoji'] ?? '🎮', style: TextStyle(fontSize: 13.sp)),
                                      Text(
                                        card['title'] ?? '',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    card['desc'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white38,
                                      fontSize: 8.sp,
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
            ),

            // restored Interactive overlays
            if (_activeInteraction == 'breathing')
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (_) => _startBreathing(),
                  onTapUp: (_) => _stopBreathingPrematurely(),
                  onTapCancel: () => _stopBreathingPrematurely(),
                  child: Container(
                    color: Colors.black.withOpacity(0.85),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: _breathingScale,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              width: 130.w,
                              height: 130.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF06B6D4).withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.spa_rounded,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          ),
                          SizedBox(height: 30.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              _breathingText,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'أبقِ إصبعك ضاغطاً لتكمل التهدئة 🧘‍♂️',
                            style: GoogleFonts.cairo(color: Colors.white38, fontSize: 10.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (_activeInteraction == 'wudu')
              Positioned.fill(
                child: GestureDetector(
                  onPanUpdate: _handleWuduSwipe,
                  child: Container(
                    color: Colors.black.withOpacity(0.88),
                    child: Stack(
                      children: [
                        // Water trail custom painter
                        CustomPaint(
                          size: Size.infinite,
                          painter: WaterSwipePainter(_wuduSwipePoints),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '🚿 امسح ونظف وجهك ويديك بالماء!',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'مرر إصبعك بسرعة في كل الاتجاهات لإطفاء الحرارة بالماء البارد 💦',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11.sp),
                              ),
                              SizedBox(height: 24.h),
                              // Progress circle indicator
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 100.w,
                                    height: 100.w,
                                    child: CircularProgressIndicator(
                                      value: _wuduProgress,
                                      color: const Color(0xFF22D3EE),
                                      backgroundColor: Colors.white.withOpacity(0.05),
                                      strokeWidth: 8.w,
                                    ),
                                  ),
                                  Text(
                                    '${(_wuduProgress * 100).toInt()}%',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
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
                ),
              ),

            if (_activeInteraction == 'refuge')
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '🕊️ قل بلسانك وقلبك وبصوت مسموع:',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '"أعوذ بالله من الشيطان الرجيم"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 28.h),
                        GestureDetector(
                          onTap: _triggerRefugeShield,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_rounded, color: Colors.white),
                                SizedBox(width: 8.w),
                                Text(
                                  'تفعيل درع الحماية الإيماني 🛡️',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_activeInteraction == 'dialogue')
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.92),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1B4B),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFA78BFA), width: 2),
                            ),
                            child: const Icon(
                              Icons.forum_rounded,
                              color: Color(0xFFA78BFA),
                              size: 48,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            _dialogueQuestion,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ..._dialogueOptions.map((opt) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: GestureDetector(
                                onTap: () => _handleDialogueOptionSelected(opt),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Text(
                                    opt['text'] ?? '',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          SizedBox(height: 20.h),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _activeInteraction = 'none';
                              });
                            },
                            child: Text(
                              'إلغاء وتغيير التصرف 🔙',
                              style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Intermediate success popup panel
            if (_showSuccessOverlay)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.92),
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(28.r),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 52,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _successTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              'كسبت +$_earnedPoints نقطة 🌟',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFFF59E0B),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _successDesc,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 12.sp,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              minimumSize: Size(double.infinity, 50.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            onPressed: _goToNextScenario,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  (_currentScenarioInLevel < 9 || _currentLevel < 50)
                                      ? 'الموقف التالي ➡️'
                                      : 'عرض النتيجة النهائية 👑',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

// Custom Painter to render fluid water cleaning swiping waves
class WaterSwipePainter extends CustomPainter {
  final List<Offset> points;
  WaterSwipePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final double progress = i / points.length;
      final paint = Paint()
        ..color = const Color(0xFF06B6D4).withOpacity(progress * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 10.w + progress * 20.w
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
