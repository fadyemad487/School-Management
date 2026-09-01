import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student_game_state.dart';

class Game4ContentmentGarden extends StatefulWidget {
  const Game4ContentmentGarden({super.key});

  @override
  State<Game4ContentmentGarden> createState() => _Game4ContentmentGardenState();
}

class _Game4ContentmentGardenState extends State<Game4ContentmentGarden> with TickerProviderStateMixin {
  int _score = 0; // Local session score
  int _currentLevel = 1;
  int _lives = 4;
  bool _isGameOver = false;
  bool _isWon = false;

  // Level Progression: 50 situations to solve per level!
  int _sortedCount = 0;
  final int _targetSorts = 50;

  // Active Situation and Options
  String _activeSituationText = '';
  Map<String, dynamic> _contentOption = {};
  Map<String, dynamic> _discontentOption1 = {};
  Map<String, dynamic> _discontentOption2 = {};

  // Custom Success Dialogue Overlay State
  bool _showSuccessOverlay = false;
  String _successTitle = '';
  String _successDesc = '';
  int _earnedPoints = 0;

  // Screen shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // ── 3-STEP REAL-TIME GARDENING SIMULATOR ENGINE ──
  // Steps: 'seed' (waiting for planting), 'water' (waiting for watering), 'harvest' (waiting to tap fruit)
  String _gardeningStep = 'seed'; 
  double _wateringProgress = 0.0; // 0.0 to 1.0
  bool _isWateringHovered = false;
  
  // Animation controllers for organic plant growth
  late AnimationController _growthController;
  late Animation<double> _growthScale;
  late Animation<double> _growthRotate;

  // Water droplets animation during watering
  late AnimationController _waterDropletsController;

  // Procedural dynamic contentment scenario generator for 80 levels!
  Map<String, dynamic> _generateDynamicContentmentSituation(int level, int index) {
    final int seed = level * 163 + index * 23 + 7;
    
    final List<String> names = ['أحمد', 'نورة', 'يوسف', 'سارة', 'عبد الله', 'لينا', 'عمر', 'ريم', 'خالد', 'فاطمة', 'سلمان', 'جود', 'فارس', 'روان'];
    final List<String> items = [
      'حاسوباً لوحياً حديثاً 📱',
      'حذاءً رياضياً مضيئاً 👟',
      'ساعة ذكية مميزة ⌚',
      'صندوق ألوان خشبي فاخر 🎨',
      'طائرة لاسلكية رائعة ✈️',
      'دراجة هوائية سريعة 🚲',
      'حقيبة مدرسية مشعة 🎒',
      'هاتفاً ذكياً جديداً 📱',
      'لعبة فيديو حديثة 🎮'
    ];
    final List<String> trips = [
      'نزهة عائلية لمدينة الألعاب 🎡',
      'رحلة شاطئية جميلة 🏖️',
      'عطلة صيفية ممتعة 🏔️',
      'نزهة برية ممتعة ⛺',
      'زيارة حديقة الحيوانات 🦁'
    ];
    final List<String> tasks = [
      'ترتيب غرفته ببراعة 🧹',
      'مساعدة والدته في إعداد الطعام 🍳',
      'تنظيف فناء المنزل 🏡',
      'الاعتناء بأخيه الصغير 👶'
    ];

    final String name = names[seed % names.length];
    final String item = items[(seed ~/ 2) % items.length];
    final String trip = trips[(seed ~/ 3) % trips.length];
    final String task = tasks[(seed ~/ 4) % tasks.length];

    final List<Map<String, dynamic>> templates = [
      {
        'situation': 'اشترى {name} {item} وكنت تتمنى الحصول على مثلها منذ زمن طويل.',
        'content': {'emoji': '🌸', 'text': 'أبارك له وأفرح لسعادته وأتمنى له البركة، وأدعو الله أن يرزقني مثله 💖'},
        'discontent1': {'emoji': '🥀', 'text': 'أغضب وأتمنى في سرّي لو تنكسر لعبته ليصبح مثلي 🥀'},
        'discontent2': {'emoji': '🌵', 'text': 'أعترض على رزقي وأقول لوالديّ أنهم مقصرون معي 🌵'}
      },
      {
        'situation': 'حصل {name} على الدرجة الكاملة 💯 في الامتحان وحصلت أنت على درجة متوسطة.',
        'content': {'emoji': '🌻', 'text': 'أهنئه على تفوقه وأطلب منه بلطف أن نذاكر معاً لنطور أنفسنا 💖'},
        'discontent1': {'emoji': '🥀', 'text': 'أشعر بالحسد والضيق وأقول للجميع إنه غش الأسئلة 🥀'},
        'discontent2': {'emoji': '🌵', 'text': 'أغضب وأمزق دفتري وأرفض الذهاب للمدرسة مجدداً 🌵'}
      },
      {
        'situation': 'حصل أخوك {name} على مكافأة مالية 💵 من والديك لتفوقه ومساعدته المستمرة.',
        'content': {'emoji': '🌷', 'text': 'أفرح لأخي وأقبل رأسه وأبادر بمساعدة والديّ طمعاً في رضاهما 💖'},
        'discontent1': {'emoji': '🥀', 'text': 'أغضب وأتهم والديّ بالتحيز والتمييز وأقاطع أخي حسداً 🥀'},
        'discontent2': {'emoji': '🌵', 'text': 'أصرخ في المنزل وأدعي أنهم يكرهونني ولا يبالون بي 🌵'}
      },
      {
        'situation': 'ذهبت عائلة {name} في {trip}، بينما بقيت أنت في المنزل لظروف عائلية.',
        'content': {'emoji': '🌹', 'text': 'أستمتع بوقتي بالمنزل بالقراءة وأتمنى لهم رحلة سعيدة وممتعة 💖'},
        'discontent1': {'emoji': '🥀', 'text': 'أتمنى لو تتعطل سيارتهم أو تلغى الرحلة لكي لا يفرحوا 🥀'},
        'discontent2': {'emoji': '🌵', 'text': 'أعترض وأفسد يوم عائلتي بالبكاء والصراخ والشكوى المستمرة 🌵'}
      },
      {
        'situation': 'أحضر زميلك {name} وجبة مدرسية شهية ومميزة جداً، بينما وجبتك بسيطة.',
        'content': {'emoji': '🌸', 'text': 'أحمد الله على وجبتي البسيطة برضا كامل وسعادة داخلية 💖'},
        'discontent1': {'emoji': '🥀', 'text': 'أنظر لوجبته بضيق وحسد وأتمنى لو تنسكب وجبته على الأرض 🥀'},
        'discontent2': {'emoji': '🌵', 'text': 'أغضب وأرفض تناول طعامي البسيط وأخجل منه أمام زملائي 🌵'}
      },
      {
        'situation': 'أثنى المعلم بشدة على زميلك {name} في الإذاعة المدرسية 🎤 أمام جميع الطلاب.',
        'content': {'emoji': '🌻', 'text': 'أصفق له بحرارة وأتمنى له التوفيق وأجتهد لأكون مثله غداً 💖'},
        'discontent1': {'emoji': '🥀', 'text': 'أقلل من شأنه أمام زملائي وأدعي أنه لا يستحق الثناء 🥀'},
        'discontent2': {'emoji': '🌵', 'text': 'أغضب وأتهم المعلم بمحاباة {name} وكراهية بقية الطلاب 🌵'}
      },
      {
        'situation': 'تم اختيار {name} للمشاركة في الرحلة المدرسية المجانية ولم يتم اختيارك.',
        'content': {'emoji': '🌷', 'text': 'أتمنى له رحلة ممتعة وأرضى بنصيبي عسى الله أن يعوضني خيراً 💖'},
        'discontent1': {'emoji': '🥀', 'text': 'أحسده وأحاول إقناع بقية زملائي بمقاطعة المعلم والرحلة 🥀'},
        'discontent2': {'emoji': '🌵', 'text': 'أصيح في المدرسة وأدعي أن المدرسة غير عادلة وظالمة 🌵'}
      },
      {
        'situation': 'أنجز {name} {task} ونال رضى الوالدين ودعاءهما الجميل.',
        'content': {'emoji': '🌹', 'text': 'أفرح لأخي وأبادر بفعل عمل طيب لأسعد قلبي والديّ أيضاً 💖'},
        'discontent1': {'emoji': '🥀', 'text': 'أحزن وأشعر بالغيرة وأقول أنه يفعل ذلك رياءً وخداعاً 🥀'},
        'discontent2': {'emoji': '🌵', 'text': 'أعترض وأقاطع والدتي غاضباً لمدحها لأخي دون مدحي 🌵'}
      },
    ];

    final Map<String, dynamic> selectedTemplate = templates[seed % templates.length];
    
    // Replace dynamic placeholders
    String situationText = selectedTemplate['situation']
        .replaceAll('{name}', name)
        .replaceAll('{item}', item)
        .replaceAll('{trip}', trip)
        .replaceAll('{task}', task);

    return {
      'situation': situationText,
      'content': selectedTemplate['content'],
      'discontent1': selectedTemplate['discontent1'],
      'discontent2': selectedTemplate['discontent2'],
    };
  }

  @override
  void initState() {
    super.initState();
    _loadGameProgress();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _growthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _growthScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _growthController, curve: Curves.bounceOut),
    );
    _growthRotate = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _growthController, curve: Curves.easeOutBack),
    );

    _waterDropletsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _growthController.dispose();
    _waterDropletsController.dispose();
    super.dispose();
  }

  // Load progress
  Future<void> _loadGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLevel = prefs.getInt('g4_current_level') ?? 1;
      _sortedCount = prefs.getInt('g4_sorted_count') ?? 0;
      _lives = prefs.getInt('g4_lives') ?? 4;
      _score = prefs.getInt('g4_session_score') ?? 0;

      if (_lives <= 0) {
        _lives = 4;
        _sortedCount = 0;
        _score = 0;
      }
      
      _loadNewSituation();
    });
  }

  // Save progress
  Future<void> _saveGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('g4_current_level', _currentLevel);
    await prefs.setInt('g4_sorted_count', _sortedCount);
    await prefs.setInt('g4_lives', _lives);
    await prefs.setInt('g4_session_score', _score);
  }

  // Load next situation
  void _loadNewSituation() {
    if (_sortedCount >= _targetSorts) {
      _triggerLevelComplete();
      return;
    }

    final data = _generateDynamicContentmentSituation(_currentLevel, _sortedCount);
    setState(() {
      _activeSituationText = data['situation'];
      _contentOption = data['content'];
      _discontentOption1 = data['discontent1'];
      _discontentOption2 = data['discontent2'];
      
      // Reset gardening step
      _gardeningStep = 'seed';
      _wateringProgress = 0.0;
      _isWateringHovered = false;
      _growthController.reset();
      _waterDropletsController.reset();
    });
    _saveGameProgress();
  }

  // Step 1: Handle Seed planted
  void _handleSeedPlanted(String type) {
    if (_isGameOver || _isWon) return;

    if (type == 'content') {
      // Correct seed planted! Transition to watering step
      HapticFeedback.lightImpact();
      setState(() {
        _gardeningStep = 'water';
      });
    } else {
      // Incorrect seed planted: Inflict punishment!
      _triggerFailureAnimation(type);
    }
  }

  // Step 2: Handle Watering progress increments
  void _handleWateringHover() {
    if (_gardeningStep != 'water') return;

    setState(() {
      _isWateringHovered = true;
      _wateringProgress += 0.125; // 8 swipes/water cycles to fully grow!
      
      // Trigger water droplets animation
      _waterDropletsController.forward(from: 0.0);
      HapticFeedback.lightImpact();

      if (_wateringProgress >= 1.0) {
        // Fully watered! Transition to harvesting step
        _gardeningStep = 'harvest';
        _growthController.forward(); // Trigger full bloom animation!
      }
    });
  }

  // Step 3: Handle Harvesting Golden Blessing Fruit
  void _handleHarvestFruit() {
    if (_gardeningStep != 'harvest') return;

    HapticFeedback.mediumImpact();
    setState(() {
      _score += 1;
      _sortedCount += 1;
      _gardeningStep = 'seed'; // Reset loop
    });

    context.read<StudentGameState>().addPoints(10);

    // Save progress and load next situation
    _saveGameProgress();
    _loadNewSituation();
  }

  // Handle failure path
  void _triggerFailureAnimation(String type) {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) => _shakeController.reset());

    final failedText = type == 'discontent1' ? _discontentOption1['text'] : _discontentOption2['text'];
    final failedEmoji = type == 'discontent1' ? _discontentOption1['emoji'] : _discontentOption2['emoji'];

    // Instantly grow dry weed to show immediate visual failure!
    setState(() {
      _gardeningStep = 'failed';
    });
    _growthController.forward();

    setState(() {
      _lives -= 1;
      if (_score >= 2) {
        _score -= 2;
      } else {
        _score = 0;
      }
    });

    if (_lives <= 0) {
      setState(() {
        _isGameOver = true;
      });
      _triggerGameOver();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لقد زرعت نية أنانية ($failedEmoji)! فنبتت أشواك جافة ذبلت بستانك 🥀',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5.sp),
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _loadNewSituation();
        }
      });
    }
    _saveGameProgress();
  }

  // Level complete celebration
  void _triggerLevelComplete() {
    setState(() {
      _isWon = true;
      _showSuccessOverlay = true;
      _earnedPoints = _score;
      _successTitle = 'رائع! مستوى $_currentLevel مكتمل! 🏆🌸';
      _successDesc = 'لقد نجحت في غرس بذور الرضا الصالحة ورويتها بالحمد وحصدت ثمار البركة السخية كاملة! بستانك الآن يزدهر بالسلام والرخاء.';
    });

    context.read<StudentGameState>().unlockNextLevel('game4');

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('g4_current_level', _currentLevel + 1);
      prefs.setInt('g4_sorted_count', 0);
      prefs.setInt('g4_lives', 4);
      prefs.setInt('g4_session_score', 0);
    });
  }

  // Game over reset
  void _triggerGameOver() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('g4_sorted_count', 0);
      prefs.setInt('g4_lives', 4);
      prefs.setInt('g4_session_score', 0);
    });
  }

  // Restart
  void _restartGame() {
    setState(() {
      _lives = 4;
      _score = 0;
      _sortedCount = 0;
      _isGameOver = false;
      _isWon = false;
      _showSuccessOverlay = false;
      _loadNewSituation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    // Shuffled packet elements tray logic (to avoid memorization)
    final List<Map<String, dynamic>> seedPackets = [
      {'type': 'content', 'text': _contentOption['text'] ?? '', 'emoji': _contentOption['emoji'] ?? '🌸'},
      {'type': 'discontent1', 'text': _discontentOption1['text'] ?? '', 'emoji': _discontentOption1['emoji'] ?? '🥀'},
      {'type': 'discontent2', 'text': _discontentOption2['text'] ?? '', 'emoji': _discontentOption2['emoji'] ?? '🌵'},
    ];
    // Dynamic seed order seed hashing
    final int seedHash = _currentLevel * 100 + _sortedCount;
    seedPackets.shuffle(math.Random(seedHash));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _saveGameProgress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF030712),
        body: Stack(
          children: [
            // Gorgeous glowing cyber garden space nebula background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF021D12), Color(0xFF020905), Color(0xFF020412)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Top Status Bar (Back Button, Title, Hearts)
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
                                'مُحاكي بستان الرضا 🌿🌸',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                _gardeningStep == 'seed' 
                                    ? 'الخطوة 1: اسحب بذرة الرضا الصالحة واغرسها بالتربة' 
                                    : _gardeningStep == 'water'
                                        ? 'الخطوة 2: اسحب مرش الماء السحري واسقِ التربة بحرّية'
                                        : _gardeningStep == 'harvest'
                                            ? 'الخطوة 3: تفتحت زهرة البركة! انقر على الثمرة الذهبية لحصادها!'
                                            : 'نبتت أشواك ضارة بسبب القرار الأناني 🥀',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  color: _gardeningStep == 'seed' 
                                      ? const Color(0xFF34D399) 
                                      : _gardeningStep == 'water'
                                          ? const Color(0xFF60A5FA)
                                          : _gardeningStep == 'harvest'
                                              ? const Color(0xFFFBBF24)
                                              : const Color(0xFFEF4444),
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 4 Hearts Counter
                        Row(
                          children: List.generate(4, (index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: index < _lives ? const Color(0xFF10B981) : Colors.white10,
                                size: 18.w,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // Top situation card
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF047857), Color(0xFF10B981)],
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  'مستوى $_currentLevel • مهمة ${_sortedCount + 1}',
                                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Golden Points Badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                                ),
                                child: Text(
                                  'نقاطي: $_score ⭐',
                                  style: GoogleFonts.cairo(
                                    color: const Color(0xFFFBBF24),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            _activeSituationText,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Progress indicator bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 8.h,
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
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    ),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '$_sortedCount / $_targetSorts',
                          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // ── REAL-TIME GRAPHICAL SIMULATION ZONE ──
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value * math.sin(math.pi * _shakeController.value * 10), 0),
                            child: child,
                          );
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  
                                  // 🌸 BACKGROUND: Garden Glassmorphic Flower Pot (The main DragTarget!)
                                  Positioned(
                                    bottom: 30.h,
                                    child: DragTarget<String>(
                                      onWillAcceptWithDetails: (details) => _gardeningStep == 'seed' && seedPackets.any((element) => element['type'] == details.data),
                                      onAcceptWithDetails: (details) {
                                        _handleSeedPlanted(details.data);
                                      },
                                      builder: (context, candidateData, rejectedData) {
                                        final bool isHovered = candidateData.isNotEmpty;

                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            
                                            // 🌿 Seedling & Flower growth layer
                                            Container(
                                              width: 160.w,
                                              height: 140.h,
                                              alignment: Alignment.bottomCenter,
                                              child: Stack(
                                                alignment: Alignment.bottomCenter,
                                                children: [
                                                  
                                                  // Water droplets custom paint animation during Step 2
                                                  if (_gardeningStep == 'water' && _isWateringHovered)
                                                    Positioned(
                                                      top: 0,
                                                      child: AnimatedBuilder(
                                                        animation: _waterDropletsController,
                                                        builder: (context, child) {
                                                          return CustomPaint(
                                                            size: Size(100.w, 60.h),
                                                            painter: WaterDropletsSimPainter(
                                                              progress: _waterDropletsController.value,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),

                                                  // Organic blooming flower (Step 3: Bloom)
                                                  if (_gardeningStep == 'harvest')
                                                    ScaleTransition(
                                                      scale: _growthScale,
                                                      child: RotationTransition(
                                                        turns: _growthRotate,
                                                        child: Stack(
                                                          alignment: Alignment.topCenter,
                                                          children: [
                                                            // Beautiful neon fully bloomed flower
                                                            Text(
                                                              _contentOption['emoji'] ?? '🌸',
                                                              style: TextStyle(fontSize: 64.sp),
                                                            ),
                                                            
                                                            // Golden Blessing Fruit (Tappable!)
                                                            Positioned(
                                                              top: 5.h,
                                                              child: GestureDetector(
                                                                onTap: _handleHarvestFruit,
                                                                child: Container(
                                                                  padding: EdgeInsets.all(5.w),
                                                                  decoration: BoxDecoration(
                                                                    color: const Color(0xFFF59E0B),
                                                                    shape: BoxShape.circle,
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: const Color(0xFFFBBF24).withOpacity(0.8),
                                                                        blurRadius: 15,
                                                                        spreadRadius: 2,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  child: Icon(
                                                                    Icons.star_rounded,
                                                                    color: Colors.white,
                                                                    size: 24.w,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                  // Dry thorn weed if failed
                                                  if (_gardeningStep == 'failed')
                                                    ScaleTransition(
                                                      scale: _growthScale,
                                                      child: Text(
                                                        '🥀🌵',
                                                        style: TextStyle(fontSize: 54.sp),
                                                      ),
                                                    ),

                                                  // Tiny healthy green seedling sprout if in Step 2 (Watering)
                                                  if (_gardeningStep == 'water')
                                                    Container(
                                                      padding: EdgeInsets.only(bottom: 5.h),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text('🌱', style: TextStyle(fontSize: 34.sp)),
                                                          SizedBox(height: 2.h),
                                                          // Real-time watering progress indicator badge
                                                          Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF3B82F6).withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(10.r),
                                                              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                                                            ),
                                                            child: Text(
                                                              'الرطوبة: ${(_wateringProgress * 100).toInt()}%',
                                                              style: GoogleFonts.cairo(
                                                                color: const Color(0xFF60A5FA),
                                                                fontSize: 8.sp,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  
                                                  // Empty waiting for seed state
                                                  if (_gardeningStep == 'seed')
                                                    Padding(
                                                      padding: EdgeInsets.only(bottom: 25.h),
                                                      child: Icon(
                                                        Icons.arrow_downward_rounded,
                                                        color: isHovered ? Colors.white : Colors.white24,
                                                        size: 32.sp,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 4.h),

                                            // Glassmorphic Glowing Plant Pot
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 150),
                                              width: 150.w,
                                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isHovered
                                                      ? [const Color(0xFF10B981), const Color(0xFF047857)]
                                                      : _gardeningStep == 'water'
                                                          ? [const Color(0xFF3B82F6).withOpacity(0.2), const Color(0xFF1D4ED8).withOpacity(0.1)]
                                                          : _gardeningStep == 'harvest'
                                                              ? [const Color(0xFFF59E0B).withOpacity(0.2), const Color(0xFFB45309).withOpacity(0.1)]
                                                              : _gardeningStep == 'failed'
                                                                  ? [const Color(0xFFEF4444).withOpacity(0.2), const Color(0xFFB91C1C).withOpacity(0.1)]
                                                                  : [Colors.white.withOpacity(0.04), Colors.white.withOpacity(0.01)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(22.r),
                                                border: Border.all(
                                                  color: isHovered 
                                                      ? Colors.white
                                                      : _gardeningStep == 'water'
                                                          ? const Color(0xFF3B82F6).withOpacity(0.4)
                                                          : _gardeningStep == 'harvest'
                                                              ? const Color(0xFFF59E0B).withOpacity(0.4)
                                                              : _gardeningStep == 'failed'
                                                                  ? const Color(0xFFEF4444).withOpacity(0.4)
                                                                  : Colors.white.withOpacity(0.1),
                                                  width: isHovered ? 2.5 : 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isHovered
                                                        ? const Color(0xFF10B981).withOpacity(0.35)
                                                        : Colors.black12,
                                                    blurRadius: 15,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'أصيص النوايا والقلوب 🏺',
                                                    style: GoogleFonts.cairo(
                                                      color: Colors.white,
                                                      fontSize: 10.sp,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2.h),
                                                  Text(
                                                    _gardeningStep == 'seed' 
                                                        ? 'اسحب البذرة الصالحة هنا 🌱' 
                                                        : _gardeningStep == 'water'
                                                            ? 'اسحب مرش الماء فوقي 💦'
                                                            : _gardeningStep == 'harvest'
                                                                ? 'احصد ثمرة البركة الذهبية 🌟'
                                                                : 'ذبلت التربة بسبب الاختيار 🥀',
                                                    style: GoogleFonts.cairo(
                                                      color: Colors.white70,
                                                      fontSize: 7.5.sp,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),

                                  // 🚿 STEP 2: Interactive Water Can (Tappable & Hover target)
                                  if (_gardeningStep == 'water')
                                    Positioned(
                                      top: 20.h,
                                      right: 25.w,
                                      child: DragTarget<String>(
                                        onWillAcceptWithDetails: (details) => details.data == 'water_can',
                                        onAcceptWithDetails: (details) {
                                          _handleWateringHover();
                                        },
                                        builder: (context, candidateData, rejectedData) {
                                          final bool isHovered = candidateData.isNotEmpty;
                                          if (isHovered) {
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              _handleWateringHover();
                                            });
                                          }
                                          return Draggable<String>(
                                            data: 'water_can',
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: Transform.rotate(
                                                angle: -0.4,
                                                child: Text('🚿💧', style: TextStyle(fontSize: 44.sp)),
                                              ),
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.2,
                                              child: Text('🚿', style: TextStyle(fontSize: 38.sp)),
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(12.w),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6).withOpacity(0.15),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                                                  width: 1.5.w,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                              child: Text('🚿', style: TextStyle(fontSize: 34.sp)),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                  // Helper helper labels according to step
                                  if (_gardeningStep == 'seed')
                                    Positioned(
                                      top: 15.h,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(16.r),
                                        ),
                                        child: Text(
                                          '🌱 اسحب بذرة النية الطيبة وضعها داخل الأصيص',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white70,
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  
                                  if (_gardeningStep == 'water')
                                    Positioned(
                                      top: 15.h,
                                      left: 20.w,
                                      right: 120.w,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(16.r),
                                        ),
                                        child: Text(
                                          '💦 اسحب مرشة الماء من اليمين وحركها فوق الأصيص لسقاية البذرة!',
                                          textAlign: TextAlign.right,
                                          style: GoogleFonts.cairo(
                                            color: Colors.white70,
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.bold,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ),

                                  if (_gardeningStep == 'harvest')
                                    Positioned(
                                      top: 15.h,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(16.r),
                                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          '🌟 انقر فوق النجمة الذهبية لحصاد ثمرة بركتك! 🌟',
                                          style: GoogleFonts.cairo(
                                            color: const Color(0xFFFBBF24),
                                            fontSize: 9.5.sp,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // ── STEP 1: Tray holding 3 Seed Packets ──
                    if (_gardeningStep == 'seed')
                      Row(
                        children: seedPackets.map((packet) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Draggable<String>(
                                data: packet['type'],
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: 110.w,
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      packet['text'],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 7.5.sp, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.2,
                                  child: _buildSeedPacketCard(packet['type'], packet['text'], packet['emoji']),
                                ),
                                child: _buildSeedPacketCard(packet['type'], packet['text'], packet['emoji']),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    
                    // Simple placeholder if waiting for watering/harvest
                    if (_gardeningStep != 'seed')
                      Container(
                        height: 80.h,
                        alignment: Alignment.center,
                        child: Text(
                          _gardeningStep == 'water' 
                              ? '💧 اسقِ النبتة بالحب والحمد لتكبر وتورق 💧' 
                              : _gardeningStep == 'harvest'
                                  ? '🎉 تمنيت الخير للجميع، فجاءت البركة لتملأ قلبك! 🎉'
                                  : '🥀 الرفض والغضب يقتلان أزهار الرضا...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: _gardeningStep == 'water' 
                                ? const Color(0xFF60A5FA) 
                                : _gardeningStep == 'harvest'
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFEF4444),
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),

            // Success Dialogue Overlay
            if (_showSuccessOverlay)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.92),
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF041A10),
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
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text('🏆', style: TextStyle(fontSize: 48.sp)),
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
                          SizedBox(height: 8.h),
                          Text(
                            _successDesc,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: 18.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              'النقاط المحققة: +$_earnedPoints ⭐',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF10B981),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'العودة للقائمة 🗺️',
                              style: GoogleFonts.cairo(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Game Over Overlay
            if (_isGameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.95),
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0A0A),
                        borderRadius: BorderRadius.circular(28.r),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text('💀', style: TextStyle(fontSize: 48.sp)),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'نفدت المحاولات! 💔',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'لقد ذبلت الحديقة بسبب الأنانية والغل. يجب أن تسقي بستانك بالرضا وتمني الخير للجميع ليزدهر قلبك مجدداً!',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _restartGame,
                                  child: Text(
                                    'حاول مجدداً 🔄',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'الخروج 🚪',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  // Builder for beautiful seed packet cards
  Widget _buildSeedPacketCard(String type, String text, String emoji) {
    final bool isContent = type == 'content';
    final Color packetColor = isContent 
        ? const Color(0xFF10B981) 
        : type.startsWith('discontent1') 
            ? const Color(0xFFEF4444) 
            : const Color(0xFFFBBF24);

    return Container(
      padding: EdgeInsets.all(10.w),
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: packetColor.withOpacity(0.35),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: packetColor.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: 18.sp)),
          SizedBox(height: 3.h),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 7.2.sp,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM VECTOR PAINTER: Falling water droplets ──
class WaterDropletsSimPainter extends CustomPainter {
  final double progress;

  WaterDropletsSimPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final random = math.Random(5678);
    for (int i = 0; i < 12; i++) {
      double startX = random.nextDouble() * size.width;
      double speed = 0.6 + random.nextDouble() * 0.4;
      double yOffset = progress * size.height * speed;
      double currentY = yOffset % size.height;

      Path path = Path();
      path.moveTo(startX, currentY);
      path.quadraticBezierTo(startX - 2.w, currentY + 3.h, startX - 2.w, currentY + 5.h);
      path.quadraticBezierTo(startX, currentY + 7.h, startX + 2.w, currentY + 5.h);
      path.quadraticBezierTo(startX + 2.w, currentY + 3.h, startX, currentY);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaterDropletsSimPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
