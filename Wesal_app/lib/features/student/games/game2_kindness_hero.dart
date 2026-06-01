import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student_game_state.dart';

class Game2KindnessHero extends StatefulWidget {
  const Game2KindnessHero({super.key});

  @override
  State<Game2KindnessHero> createState() => _Game2KindnessHeroState();
}

class _Game2KindnessHeroState extends State<Game2KindnessHero> with TickerProviderStateMixin {
  int _score = 0; // Local session score (committed on level completion)
  int _currentLevel = 1; // 1 to 80 levels
  int _lives = 4; // 4 hearts total
  bool _isGameOver = false;
  bool _isWon = false;
  
  // Sorting stats
  int _sortedCount = 0;
  final int _targetSorts = 50; // 50 dynamic situations to solve per level as requested!
  
  // Active Situation Text
  String _activeSituationText = '';
  
  // Physics/animation state for floating capsules
  late AnimationController _floatController;
  final List<BehaviorCapsule> _capsules = [];
  final List<BasketEffect> _effects = [];
  final math.Random _random = math.Random();

  // Screen shake animation on error
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Active behavior transformation dialog overlay state
  bool _showTransformationEffect = false;
  String _transformedFrom = '';
  String _transformedTo = '';

  // Custom Success Dialogue Overlay State
  bool _showSuccessOverlay = false;
  String _successTitle = '';
  String _successDesc = '';
  int _earnedPoints = 0;
  double _arenaWidth = 0.0;
  double _arenaHeight = 0.0;

  // Mapping negative/bullying behaviors to their beautiful transformed positive equivalents!
  final Map<String, String> _transformationMap = {
    'أضحك مع الطلاب المستهزئين': 'أدافع عن المظلوم بلطف 🤝',
    'أناديه بلقب غريب سخيف': 'أناديه بأحب أسمائه إليه 😊',
    'أقوم بإخفاء نظارته سخرية': 'أحافظ على أدوات زملائي 🌸',
    'أسخر من طريقة سقوطه': 'أساعده على النهوض بابتسامة 😊',
    'أقول له أنه مهمل وبليد': 'أشجعه بكلمات طيبة وداعمة 🌟',
    'آخذ طعامه السليم المتبقي': 'أشاركه طعامي اللذيذ 🍱',
    'أشير إليه وأقول وحيداً': 'أذهب للجلوس والحديث معه 🤝',
    'أتجاهله وأمشي بعيداً عنه': 'أدعوه للعب معنا بالكرة ⚽',
    'أرمي الكرة باتجاهه غاضباً': 'أمرر له الكرة بكل لطف ⚽',
    'أقوم بدفعه من الخلف ليسقط': 'أفتح له باب الصف بهدوء 🕊️',
    'أسخر من ضعف عضلاته': 'أشجعه وأدعو له بالصحة 💪',
    'أخطف الحقيبة وألقيها بعيداً': 'أحمل الحقيبة معه بلطف 🎒',
    'أشتمه لأنه كثير النسيان': 'أعيره قلماً دفتراً إضافياً ✏️',
    'أرفض إعارته وأخبئ أقلامي': 'أشاركه أدواتي بكل سرور 🤝',
    'أخبر المعلم بغرض إحراجه': 'أستره وأساعده بهدوء 🤫',
    'أدوس على دفاتره بالخطأ متعمداً': 'أساعده في جمعها وترتيبها 📚',
    'أقف وأضحك عليه مع الطلاب': 'أواسيه وأمد يدي لمساعدته 🤝',
    'أتخطاه متجاهلاً تعثره تماماً': 'أقف لأحميه من الزحام 🛡️',
    'أصرخ في وجهه لكي يبتعد': 'أسقيه ماء بارداً منعشاً 💧',
    'أقول له أنه يمثل المرض': 'أخبر المعلم فوراً بحالته 🏥',
    'أتركه يتألم دون إبداء مساعدة': 'أقوم بتهويته بكتيب صغير 🌬️',
    'أنشر ورقته وأسخر من درجته': 'أعرض عليه المذاكرة معاً 🧠',
    'أنعته بالبليد وغير الذكي': 'أواسيه وأقول له سيعوضها 😊',
    'أتباهى بدرجتي العالية أمامه': 'أشجعه وأذكره بمواهبه الأخرى 🌟',
    'أنظر إليه بتعالي وسخرية': 'أرحب به بابتسامة كبيرة 👋',
    'أرفض إجلاسه بجانبي تماماً': 'أدعوه للجلوس والتعرف عليه 🤝',
    'أهمس مع زملائي عنه بسوء': 'أدافع عنه في غيابه 🌸',
    'أشمت بكسر مشروعه الجميل': 'أساعده في إعادة بنائه مجدداً 🛠️',
    'أقول له أن مشروعه كان سيئاً': 'أثني على مجهوده الرائع 🌟',
    'أرمي الأجزاء المكسورة بالقمامة': 'أجمع معه الأجزاء لنصلحها 🛠️',
    'أضحك عليه وأقلد صوته': 'أشجعه بالتصفيق والابتسام 👏',
    'أقول له أنه طفل مهمل': 'أشتري له وجبة شهية طيبة 🍱',
    'أشير إلى ملابسه ضاحكاً': 'أعطيه معطفي الدافئ الإضافي 🌸',
    'أدفعه معهم لكي لا يركب': 'أفسح له مكاناً طيباً بجانبي 🚌',
    'أسخر منه وأنعته بالطفل الباكي': 'أجلس بجانبه وأمسح دموعه 😊'
  };

  // Procedural dynamic school bullying/conflict generator for 80 levels!
  Map<String, dynamic> _generateDynamicSituation(int level, int index) {
    final int seed = level * 130 + index * 17 + 5;
    
    final List<String> names = ['أحمد', 'سارة', 'علي', 'يوسف', 'فاطمة', 'عمر', 'مريم', 'خالد', 'منى', 'نور', 'ليلى', 'زياد', 'طارق', 'حمزة', 'روان', 'هناء'];
    final List<String> locations = ['في الفسحة', 'في الفصل', 'في ممر المدرسة', 'في طابور الصباح', 'في المكتبة', 'في حافلة المدرسة', 'في ساحة الألعاب'];
    
    final String name = names[seed % names.length];
    final String location = locations[(seed ~/ 3) % locations.length];

    final List<Map<String, dynamic>> templates = [
      {
        'situation': 'يتعرض {name} للسخرية {location} بسبب نظارته الجديدة 👓 ويبكي حزيناً.',
        'pos': {'emoji': '🤝', 'text': 'أدافع عنه وأهدئه بلطف'},
        'neg': {'emoji': '👊', 'text': 'أضحك مع الطلاب المستهزئين'}
      },
      {
        'situation': 'سقطت علبة طعام {name} بالكامل على الأرض {location} 🍱 ولا يملك طعاماً بدلاً منها.',
        'pos': {'emoji': '🍱', 'text': 'أشاركه شطيرتي اللذيذة'},
        'neg': {'emoji': '👊', 'text': 'أسخر من طريقة سقوطه'}
      },
      {
        'situation': 'يجلس {name} وحيداً {location} 👥 ولا يجد أحداً يشاركه اللعب أو الحديث.',
        'pos': {'emoji': '⚽', 'text': 'أدعوه للعب معنا بالكرة'},
        'neg': {'emoji': '🚶‍♂️', 'text': 'أتجاهله وأمشي بعيداً عنه'}
      },
      {
        'situation': 'يجد {name} صعوبة بالغة في حمل حقيبته المدرسية الثقيلة 🎒 {location}.',
        'pos': {'emoji': '🤝', 'text': 'أحمل الحقيبة معه بلطف'},
        'neg': {'emoji': '⚡', 'text': 'أسخر من ضعف عضلاته'}
      },
      {
        'situation': 'نسي {name} أدواته المدرسية ومقلمته اليوم ✏️ ويشعر بالقلق {location}.',
        'pos': {'emoji': '✏️', 'text': 'أعيره قلماً دفتراً إضافياً'},
        'neg': {'emoji': '🤬', 'text': 'أشتمه لأنه كثير النسيان'}
      },
      {
        'situation': 'تعثر {name} بالطابور وسقطت دفاتره بالكامل {location} 📚.',
        'pos': {'emoji': '📚', 'text': 'أساعده في جمع الدفاتر فوراً'},
        'neg': {'emoji': '👊', 'text': 'أدوس على دفاتره متعمداً'}
      },
      {
        'situation': 'يشعر {name} بتعب ودوخة شديدة {location} 🤒 ويكاد يسقط.',
        'pos': {'emoji': '💧', 'text': 'أسقيه ماء بارداً منعشاً'},
        'neg': {'emoji': '🤬', 'text': 'أصرخ في وجهه لكي يبتعد'}
      },
      {
        'situation': 'حصل {name} على درجة ضعيفة في الاختبار 📝 ويشعر بالخجل الشديد {location}.',
        'pos': {'emoji': '🧠', 'text': 'أعرض عليه المذاكرة معاً'},
        'neg': {'emoji': '⚡', 'text': 'أنشر ورقته وأسخر من درجته'}
      },
      {
        'situation': 'يدخل {name} طالباً جديداً للصف 👥 ويقف خائفاً ومحرجاً {location}.',
        'pos': {'emoji': '👋', 'text': 'أرحب به بابتسامة كبيرة'},
        'neg': {'emoji': '⚡', 'text': 'أنظر إليه بتعالي وسخرية'}
      },
      {
        'situation': 'كسر زملاؤك مشروع العلوم الذي تعب {name} في بنائه 🏗️ عن طريق الخطأ.',
        'pos': {'emoji': '🛠️', 'text': 'أساعده في إعادة بنائه مجدداً'},
        'neg': {'emoji': '👊', 'text': 'أشمت بكسر مشروعه الجميل'}
      },
      {
        'situation': 'يتلعثم {name} أثناء قراءته بالإذاعة المدرسية 🎤 ويشعر بالخجل الشديد.',
        'pos': {'emoji': '👏', 'text': 'أشجعه بالتصفيق والابتسام'},
        'neg': {'emoji': '⚡', 'text': 'أضحك عليه وأقلد صوته'}
      },
      {
        'situation': 'ضاع مصروف الفسحة الخاص بـ {name} 💸 ويقف حزيناً أمام المقصف.',
        'pos': {'emoji': '🍱', 'text': 'أشتري له وجبة شهية طيبة'},
        'neg': {'emoji': '🤬', 'text': 'أقول له أنه طفل مهمل'}
      },
      {
        'situation': 'يرتدي {name} ملابس المدرسة مبللة بالماء بسبب المطر 🌧️ ويسخر منه البعض.',
        'pos': {'emoji': '🌸', 'text': 'أعطيه معطفي الدافئ الإضافي'},
        'neg': {'emoji': '⚡', 'text': 'أشير إلى ملابسه ضاحكاً'}
      },
      {
        'situation': 'يريد {name} الصعود للحافلة المدرسية 🚌 ولكن يدفعه الطلاب بقوة للخلف.',
        'pos': {'emoji': '🤝', 'text': 'أفسح له مكاناً طيباً بجانبي'},
        'neg': {'emoji': '👊', 'text': 'أدفعه معهم لكي لا يركب'}
      },
      {
        'situation': 'يبكي {name} في ركن الصف 😢 لأنه يشتاق لأمه ويشعر بالخوف.',
        'pos': {'emoji': '😊', 'text': 'أجلس بجانبه وأمسح دموعه'},
        'neg': {'emoji': '⚡', 'text': 'أسخر منه وأنعته بالطفل الباكي'}
      }
    ];

    final int templateIndex = seed % templates.length;
    final Map<String, dynamic> rawTemp = templates[templateIndex];
    
    // Replace placeholders
    final String situation = rawTemp['situation']!
        .replaceAll('{name}', name)
        .replaceAll('{location}', location);
    
    return {
      'situation': situation,
      'pos': rawTemp['pos'],
      'neg': rawTemp['neg'],
    };
  }

  @override
  void initState() {
    super.initState();

    // Load progress from SharedPreferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGameProgress();
    });

    // 1. Floating physics loop for behavior capsules
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_onFloatPhysicsTick);
    _floatController.repeat();

    // 2. Shake animation controller for errors
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // Persistent Game Load Progress
  Future<void> _loadGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final gameState = Provider.of<StudentGameState>(context, listen: false);
    
    setState(() {
      _currentLevel = prefs.getInt('g2_current_level') ?? gameState.getUnlockedLevel('game2');
      _score = prefs.getInt('g2_session_score') ?? 0;
      _sortedCount = prefs.getInt('g2_sorted_count') ?? 0;
      _lives = prefs.getInt('g2_lives') ?? 4; 
      _isGameOver = false;
      _isWon = false;
      _showSuccessOverlay = false;
      _loadActiveSituation();
    });
  }

  // Persistent Game Save Progress
  Future<void> _saveGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('g2_current_level', _currentLevel);
    await prefs.setInt('g2_session_score', _score);
    await prefs.setInt('g2_sorted_count', _sortedCount);
    await prefs.setInt('g2_lives', _lives);
  }

  // Dynamically load the single active situation and spawn its matching 2 capsules (1 positive, 1 negative)
  void _loadActiveSituation() {
    _capsules.clear();
    
    final sitData = _generateDynamicSituation(_currentLevel, _sortedCount);
    _activeSituationText = sitData['situation'];

    // Spawn Positive behavior capsule
    _capsules.add(BehaviorCapsule(
      id: 'pos_${_sortedCount}',
      emoji: sitData['pos']['emoji'],
      text: sitData['pos']['text'],
      isPositive: true,
      x: 50.0 + _random.nextDouble() * 100.0,
      y: 60.0 + _random.nextDouble() * 120.0,
      vx: (_random.nextDouble() * 1.5) - 0.75,
      vy: (_random.nextDouble() * 1.5) - 0.75,
    ));

    // Spawn Negative behavior capsule
    _capsules.add(BehaviorCapsule(
      id: 'neg_${_sortedCount}',
      emoji: sitData['neg']['emoji'],
      text: sitData['neg']['text'],
      isPositive: false,
      x: 170.0 + _random.nextDouble() * 100.0,
      y: 60.0 + _random.nextDouble() * 120.0,
      vx: (_random.nextDouble() * 1.5) - 0.75,
      vy: (_random.nextDouble() * 1.5) - 0.75,
    ));
  }

  // Bounding physics float loop
  void _onFloatPhysicsTick() {
    if (_isGameOver || _isWon || _showSuccessOverlay || _showTransformationEffect) return;

    setState(() {
      final double wBound = _arenaWidth > 0 ? _arenaWidth : 320.w;
      final double hBound = _arenaHeight > 0 ? _arenaHeight : 260.h;

      for (var capsule in _capsules) {
        capsule.x += capsule.vx;
        capsule.y += capsule.vy;

        // Bounce horizontally
        if (capsule.x <= 5.w || capsule.x >= wBound - 96.w) {
          capsule.vx = -capsule.vx;
          capsule.x = capsule.x.clamp(5.w, wBound - 96.w);
        }

        // Bounce vertically
        if (capsule.y <= 5.h || capsule.y >= hBound - 56.h) {
          capsule.vy = -capsule.vy;
          capsule.y = capsule.y.clamp(5.h, hBound - 56.h);
        }
      }
    });
  }

  // Handles drag dropping to 'مصفاة اللطف' (Kindness Refiner) or 'مصنع التقويم' (Correction Factory)
  void _handleBehaviorSort(BehaviorCapsule capsule, String targetJar) {
    if (_isGameOver || _isWon) return;

    if (capsule.isPositive) {
      if (targetJar == 'refiner') {
        // CORRECT: Dragged positive behavior to Kindness Refiner!
        HapticFeedback.lightImpact();
        setState(() {
          _score += 1;
          _sortedCount++;
          _capsules.removeWhere((c) => c.id == capsule.id);

          _effects.add(BasketEffect(
            position: const Offset(100, 500),
            color: const Color(0xFF10B981),
            emoji: '✨',
          ));

          _saveGameProgress(); // Save situation progress immediately!

          if (_sortedCount >= _targetSorts) {
            _triggerLevelCompleted();
          } else {
            // Load the next dynamic school situation immediately!
            _loadActiveSituation();
          }
        });
      } else {
        // WRONG: Positive behavior in Correction Factory!
        _triggerSortError();
      }
    } else {
      if (targetJar == 'factory') {
        // CORRECT: Dragged negative behavior to Correction Factory! (Transforms & shows correction dialog)
        HapticFeedback.mediumImpact();
        
        final String correctedBehavior = _transformationMap[capsule.text] ?? 'أتعامل بلطف وأساند زميلي 🤝';
        
        setState(() {
          _score += 1;
          _sortedCount++;
          _capsules.removeWhere((c) => c.id == capsule.id);

          _transformedFrom = capsule.text;
          _transformedTo = correctedBehavior;
          _showTransformationEffect = true;
        });

        _saveGameProgress(); // Save situation progress immediately!

        // Delay to read behavior transformation, then load next dynamic situation
        Future.delayed(const Duration(milliseconds: 3200), () {
          if (mounted) {
            setState(() {
              _showTransformationEffect = false;
              if (_sortedCount >= _targetSorts) {
                _triggerLevelCompleted();
              } else {
                // Load the next dynamic school situation!
                _loadActiveSituation();
              }
            });
          }
        });
      } else {
        // WRONG: Negative behavior in Kindness Refiner!
        _triggerSortError();
      }
    }
  }

  void _triggerSortError() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0.0);

    setState(() {
      _score = math.max(0, _score - 2);
      _lives--;

      if (_lives <= 0) {
        _isGameOver = true;
        _showFinishDialog(false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ! لقد قمت بفرز التصرف بشكل غير لائق ❌! القلوب المتبقية: $_lives',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFEF4444).withOpacity(0.95),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    });
    _saveGameProgress();
  }

  void _triggerLevelCompleted() {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _earnedPoints = _score;
      _successTitle = 'خبير تعديل السلوكيات! 🧪💚';
      _successDesc = 'لقد قمت بفرز السلوكيات وتقويم وتصحيح العادات السيئة بنجاح مبهر عبر 50 موقفاً متغيراً! تم حفظ تقدمك.';
      _showSuccessOverlay = true;
    });
  }

  void _goToNextLevel() {
    final gameState = Provider.of<StudentGameState>(context, listen: false);

    setState(() {
      _showSuccessOverlay = false;
      
      // ── REGISTER/COMMIT ACCUMULATED LEVEL POINTS PERMANENTLY! ──
      gameState.addPoints(10);

      // Unlock next level in the main state if currently on highest unlocked level
      if (_currentLevel == gameState.getUnlockedLevel('game2')) {
        gameState.unlockNextLevel('game2');
      }

      if (_currentLevel < 80) {
        _currentLevel++;
        _score = 0; // Reset session score for the new level
        _sortedCount = 0;
        _lives = 4; // Reset to 4 hearts
        _effects.clear();
        _loadActiveSituation();
        _saveGameProgress(); // Save level start progress
      } else {
        // Finished all 80 levels! Complete Victory!
        _isWon = true;
        _showFinishDialog(true);
      }
    });
  }

  void _showFinishDialog(bool won) {
    _floatController.stop();

    if (won) {
      context.read<StudentGameState>().addPoints(10);
      context.read<StudentGameState>().unlockNextLevel('game2');
    } else {
      // Reset level session values on game over so next entry is fresh!
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('g2_session_score', 0);
        prefs.setInt('g2_sorted_count', 0);
        prefs.setInt('g2_lives', 4);
      });
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
                won ? '👑' : '🧪',
                style: TextStyle(fontSize: 48.sp),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              won ? 'البروفيسور بطل اللطف الحقيقي! 🏆' : 'خسرت في المستوى $_currentLevel 💔',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              won
                  ? 'مذهل يا بطل الأبطال! لقد روضت وقوّمت قوى السلوك عبر 80 مستوى كاملاً من فرز الأفعال، وأصبحت حارساً للسلام المدرسي ونبراساً يقتدي به الجميع! +25 نقطة 👑🌟'
                  : 'لقد خسرت في المستوى $_currentLevel لأنك قمت بفرز سلوكيات سيئة بداخل مصفاة اللطف أو العكس.. تذكر دائماً أن السلوكيات الطيبة تعزز فوراً والسيئة نرسلها لمصنع التقويم لنصححها! حاول مجدداً لتتعلم السلوك القويم.',
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
    final Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _saveGameProgress(); // Guarantees saving current level progress on exit
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF030712),
        body: Stack(
          children: [
            // Gorgeous Cyberpunk Sky Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF030712), Color(0xFF06091B), Color(0xFF0E1325)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Top AppBar Status Bar
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                          onPressed: () {
                            _saveGameProgress();
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'تقويم السلوكيات: مستوى $_currentLevel 🧪🛡️',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'فرز السلوكيات لتقويم بيئة المدرسة',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(color: Colors.white60, fontSize: 9.sp, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // 4 Hearts Counter
                        Row(
                          children: List.generate(4, (index) {
                            return Padding(
                              padding: EdgeInsets.only(left: 3.w),
                              child: Icon(
                                index < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: const Color(0xFFF43F5E),
                                size: 18.w,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // ── Bullying/Conflict Scenario top panel ──
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  'حالة الموقف الميدانية 🚨',
                                  style: GoogleFonts.cairo(color: const Color(0xFF34D399), fontSize: 9.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded, color: Colors.white, size: 12.sp),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'نقاطي: $_score ⭐',
                                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            _activeSituationText.isNotEmpty ? _activeSituationText : 'جاري تحميل الموقف المعين...',
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
                    SizedBox(height: 8.h),

                    // ── Sorting Target progress bar ──
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 10.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: (size.width - 90.w) * (_sortedCount / _targetSorts),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                    ),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '$_sortedCount / $_targetSorts',
                            style: GoogleFonts.cairo(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // ── Physics floating behavior capsules arena ──
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value * math.sin(math.pi * _shakeController.value * 10), 0),
                            child: child,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(32.r),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              _arenaWidth = constraints.maxWidth;
                              _arenaHeight = constraints.maxHeight;
                              return Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  // Floating physics behavior capsules (Draggable!)
                                  ..._capsules.map((capsule) {
                                    return Positioned(
                                      left: capsule.x,
                                      top: capsule.y,
                                      child: Draggable<BehaviorCapsule>(
                                        data: capsule,
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child: Container(
                                            width: 110.w,
                                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                                            decoration: BoxDecoration(
                                              color: capsule.isPositive 
                                                  ? const Color(0xFF10B981).withOpacity(0.9)
                                                  : const Color(0xFFEF4444).withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(20.r),
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (capsule.isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.4),
                                                  blurRadius: 20,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(capsule.emoji, style: TextStyle(fontSize: 24.sp)),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  capsule.text,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.cairo(
                                                    color: Colors.white,
                                                    fontSize: 9.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        childWhenDragging: Opacity(
                                          opacity: 0.15,
                                          child: Container(
                                            width: 96.w,
                                            height: 52.h,
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius: BorderRadius.circular(16.r),
                                            ),
                                          ),
                                        ),
                                        child: Container(
                                          width: 96.w,
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                          decoration: BoxDecoration(
                                            color: capsule.isPositive 
                                                ? const Color(0xFF10B981).withOpacity(0.08)
                                                : const Color(0xFFEF4444).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(18.r),
                                            border: Border.all(
                                              color: capsule.isPositive 
                                                  ? const Color(0xFF10B981).withOpacity(0.4)
                                                  : const Color(0xFFEF4444).withOpacity(0.4),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(capsule.emoji, style: TextStyle(fontSize: 20.sp)),
                                              SizedBox(height: 3.h),
                                              Text(
                                                capsule.text,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontSize: 8.sp,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),

                                  // Loader if container is empty
                                  if (_capsules.isEmpty && !_showSuccessOverlay)
                                    Center(
                                      child: CircularProgressIndicator(
                                        color: const Color(0xFF10B981),
                                        strokeWidth: 2.w,
                                      ),
                                    ),
                                ],
                              );
                            }
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // ── Dynamic Glowing Drop Zones/Jars at the bottom! ──
                    Row(
                      children: [
                        // Left Jar: Kindness Refiner (مصفاة اللطف)
                        Expanded(
                          child: DragTarget<BehaviorCapsule>(
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              _handleBehaviorSort(details.data, 'refiner');
                            },
                            builder: (context, candidateData, rejectedData) {
                              final bool isHovered = candidateData.isNotEmpty;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 80.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isHovered
                                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                        : [const Color(0xFF10B981).withOpacity(0.08), const Color(0xFF059669).withOpacity(0.04)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: isHovered ? Colors.white : const Color(0xFF10B981).withOpacity(0.3),
                                    width: isHovered ? 2.0 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(isHovered ? 0.3 : 0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      color: isHovered ? Colors.white : const Color(0xFF10B981),
                                      size: 24.sp,
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      'مصفاة اللطف 🟢',
                                      style: GoogleFonts.cairo(
                                        color: isHovered ? Colors.white : Colors.white70,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'السلوكيات الطيبة والجميلة',
                                      style: GoogleFonts.cairo(
                                        color: isHovered ? Colors.white70 : Colors.white38,
                                        fontSize: 7.5.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 14.w),

                        // Right Jar: Correction Factory (مصنع التقويم)
                        Expanded(
                          child: DragTarget<BehaviorCapsule>(
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              _handleBehaviorSort(details.data, 'factory');
                            },
                            builder: (context, candidateData, rejectedData) {
                              final bool isHovered = candidateData.isNotEmpty;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 80.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isHovered
                                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                        : [const Color(0xFFF59E0B).withOpacity(0.08), const Color(0xFFD97706).withOpacity(0.04)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: isHovered ? Colors.white : const Color(0xFFF59E0B).withOpacity(0.3),
                                    width: isHovered ? 2.0 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withOpacity(isHovered ? 0.3 : 0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.published_with_changes_rounded,
                                      color: isHovered ? Colors.white : const Color(0xFFF59E0B),
                                      size: 24.sp,
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      'مصنع التقويم 🔴',
                                      style: GoogleFonts.cairo(
                                        color: isHovered ? Colors.white : Colors.white70,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'السلوكيات الخاطئة لتقويمها',
                                      style: GoogleFonts.cairo(
                                        color: isHovered ? Colors.white70 : Colors.white38,
                                        fontSize: 7.5.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Live Behavior Transformation Effect Dialogue Overlay
            if (_showTransformationEffect)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.94),
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(32.r),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.12),
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
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.science_rounded,
                              color: Color(0xFFF59E0B),
                              size: 48,
                            ),
                          ),
                          SizedBox(height: 18.h),
                          Text(
                            'تم تقويم السلوك الخاطئ بنجاح! ⚡🧪',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15.sp),
                          ),
                          SizedBox(height: 18.h),
                          // Transformation card
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'السلوك السيء:',
                                  style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _transformedFrom,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF34D399), size: 24),
                                ),
                                Text(
                                  'السلوك السليم المقوم:',
                                  style: GoogleFonts.cairo(color: const Color(0xFF34D399), fontSize: 10.sp, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _transformedTo,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900),
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

            // Success Level Completed Overlay
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
                              Icons.verified_user_rounded,
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
                              'رصيد النقاط المحرز: +$_earnedPoints نقطة 🌟',
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
                            onPressed: _goToNextLevel,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentLevel < 80
                                      ? 'المستوى التالي ➡️'
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

            // Start Directions Overlay on level 1 startup or when starting a fresh session
            if (_score == 0 && _capsules.isEmpty && !_showSuccessOverlay)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  margin: EdgeInsets.symmetric(horizontal: 32.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🛡️ مختبر تقويم السلوكيات',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'مرحباً بك يا بطل السلوك السليم! 🧪\n\nأمامك كبسولات سلوكية تطفو بداخل المختبر لمواجهة حالة الموقف المدرسي المعروض في الأعلى.\n\nطريقة اللعب الاحترافية:\n1. اسحب الكبسولات الخضراء (سلوك طيب) وضعها داخل "مصفاة اللطف 🟢".\n2. اسحب الكبسولات الحمراء (سلوك سيء) وضعها داخل "مصنع التقويم 🔴" لتشاهد كيف يحولها المختبر فوراً إلى سلوكيات طيبة رائعة! (+3 نقاط لكل فرز صحيح).\n\nسيتغير الموقف في الأعلى تلقائياً مع كل فرز صحيح! قم بحل 50 موقفاً متتالياً لتجاوز المستوى!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12.sp, height: 1.5),
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        ),
                        onPressed: () {
                          _loadActiveSituation();
                        },
                        child: Text(
                          'ابدأ التجربة والفرز! 🚀',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
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
}

class BehaviorCapsule {
  final String id;
  final String emoji;
  final String text;
  final bool isPositive;
  double x;
  double y;
  double vx;
  double vy;

  BehaviorCapsule({
    required this.id,
    required this.emoji,
    required this.text,
    required this.isPositive,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });
}

class BasketEffect {
  final Offset position;
  final Color color;
  final String emoji;
  double opacity;
  double scale;

  BasketEffect({
    required this.position,
    required this.color,
    required this.emoji,
    this.opacity = 1.0,
    this.scale = 1.0,
  });
}
