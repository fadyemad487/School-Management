import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student_game_state.dart';

class Game3HonestyGuardian extends StatefulWidget {
  const Game3HonestyGuardian({super.key});

  @override
  State<Game3HonestyGuardian> createState() => _Game3HonestyGuardianState();
}

class _Game3HonestyGuardianState extends State<Game3HonestyGuardian> with TickerProviderStateMixin {
  int _score = 0; // Local session score (committed on level completion)
  int _currentLevel = 1; // 1 to 80 levels
  int _lives = 4; // 4 hearts total
  bool _isGameOver = false;
  bool _isWon = false;

  // Sorting stats
  int _sortedCount = 0;
  final int _targetSorts = 50; // 50 dynamic honesty situations to solve per level!

  // Active Situation Text and Choice Weights data
  String _activeSituationText = '';
  Map<String, dynamic> _honestWeight = {};
  Map<String, dynamic> _dishonestWeight = {};

  // Custom Spring Wobble physics animation for the Balance Scale
  late AnimationController _tiltController;
  late Animation<double> _tiltAnimation;
  double _currentTiltAngle = 0.0;
  double _targetTiltAngle = 0.0;

  // Screen shake animation on error
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Custom Success Dialogue Overlay State
  bool _showSuccessOverlay = false;
  String _successTitle = '';
  String _successDesc = '';
  int _earnedPoints = 0;

  // Procedural dynamic honesty scenario generator for 80 levels!
  Map<String, dynamic> _generateDynamicHonestySituation(int level, int index) {
    final int seed = level * 140 + index * 19 + 3;
    
    final List<String> names = ['خالد', 'فاطمة', 'علي', 'مريم', 'يوسف', 'سارة', 'أحمد', 'نور', 'ليلى', 'زياد', 'طارق', 'حمزة', 'عمر', 'روان'];
    final List<String> items = ['محفظة نقود', 'قلم تلوين مميز', 'ساعة يد حمراء', 'لعبة سيارة صغيرة', 'دفتر رسومات ملون', 'مظلة مطر جميلة', 'مفاتيح المنزل'];
    
    final String name = names[seed % names.length];
    final String item = items[(seed ~/ 2) % items.length];

    final List<Map<String, dynamic>> templates = [
      {
        'situation': 'وجد {name} {item} 💼 ملقاة في فناء المدرسة ولا أحد يراه.',
        'honest': {'emoji': '🏢', 'text': 'أسلمها فوراً للمشرفة لتجد صاحبها'},
        'dishonest': {'emoji': '❌', 'text': 'آخذها لنفسي وأخفيها بداخل حقيبتي'}
      },
      {
        'situation': 'أثناء اللعب بالفصل، كسر {name} زجاج نافذة المعمل عن طريق الخطأ 🪟.',
        'honest': {'emoji': '🤝', 'text': 'أعترف للمعلم بالخطأ وأعتذر بصدق'},
        'dishonest': {'emoji': '❌', 'text': 'أهرب بسرعة وأقول لا أعرف من كسرها'}
      },
      {
        'situation': 'أعطى البائع لـ {name} باقياً من النقود 💰 أكثر مما يستحق بالخطأ عند شراء العصير.',
        'honest': {'emoji': '🪙', 'text': 'أخطر البائع وأعيد له المال الزائد فوراً'},
        'dishonest': {'emoji': '❌', 'text': 'أفرح بالمال الزائد وأضعه في جيبي'}
      },
      {
        'situation': 'استعار {name} قصة مصورة 📚 من صديقه ووعده بإرجاعها غداً ولكنه نسيها بالمنزل.',
        'honest': {'emoji': '🗣️', 'text': 'أعتذر له بصدق وأعده بإحضارها غداً بالتأكيد'},
        'dishonest': {'emoji': '❌', 'text': 'أقول له أنني أرجعتها بالفعل وهو الواهم'}
      },
      {
        'situation': 'أثناء الاختبار 📝، وجد {name} ورقة زميله مكشوفة أمامه بجميع الإجابات الصعبة.',
        'honest': {'emoji': '🧠', 'text': 'أغمض عيني وأعتمد على نفسي ومذاكرتي'},
        'dishonest': {'emoji': '❌', 'text': 'أنقل الإجابات بسرعة لأحصل على الدرجة'}
      },
      {
        'situation': 'وجد {name} قسماً من زملائه يغشون باللعبة الرياضية ⚽ ليفوزوا بالبطولة.',
        'honest': {'emoji': '🕊️', 'text': 'أرفض الغش وأنسحب من اللعب معهم بكرامة'},
        'dishonest': {'emoji': '❌', 'text': 'أغش معهم لأضمن فوز فريقي بالكأس'}
      },
      {
        'situation': 'أخبر صديق {name} سراً خاصاً به 🤫 وطلب منه ألا يخبر به أحداً أبداً.',
        'honest': {'emoji': '🔒', 'text': 'أحفظ السر في قلبي ولا أخبر به أحداً'},
        'dishonest': {'emoji': '❌', 'text': 'أذهب لأحكيه لبقية الزملاء سراً وسخرية'}
      },
      {
        'situation': 'أضيع {name} قلم صديقه المفضل ✏️ الذي استعاره منه في حصة الرسم.',
        'honest': {'emoji': '🎁', 'text': 'أعترف له وأشتري له قلماً جديداً بديلاً'},
        'dishonest': {'emoji': '❌', 'text': 'أقول له ضاع مني بالمدرسة ولم ألمسه'}
      },
      {
        'situation': 'طلب المعلم من {name} تسليم الواجب، ولكنه لم يكتبه بسبب اللعب بالمنزل 🎮.',
        'honest': {'emoji': '📝', 'text': 'أقول الصدق للمعلم وأعده بكتابته ومضاعفته'},
        'dishonest': {'emoji': '❌', 'text': 'أقول نسيت الدفتر بالمنزل وأنا كاتب واجب'}
      },
      {
        'situation': 'أثناء تنظيف الغرفة، كسر {name} كوب والدته المفضل 🥛 دون قصد.',
        'honest': {'emoji': '💖', 'text': 'أخبر أمي فوراً وأعتذر لها بلطف وأدب'},
        'dishonest': {'emoji': '❌', 'text': 'أرمي الكسر بسلة المهملات وأدعي الجهل'}
      },
      {
        'situation': 'وجد {name} لعبة جميلة 🧸 منسية على مقعد الحافلة المدرسية ولا أحد يراها.',
        'honest': {'emoji': '🚌', 'text': 'أعطيها لسائق الحافلة ليسلمها للمفقودات'},
        'dishonest': {'emoji': '❌', 'text': 'آخذها للمنزل لألعب بها مع إخوتي'}
      },
      {
        'situation': 'نجح {name} في الحصول على علامة كاملة بغش سؤال واحد في الاختبار 📝.',
        'honest': {'emoji': '🧑‍🏫', 'text': 'أخبر المعلم وأطلب منه خصم علامة السؤال'},
        'dishonest': {'emoji': '❌', 'text': 'أصمت وأتباهى بالدرجة الكاملة أمام والدي'}
      }
    ];

    final int templateIndex = seed % templates.length;
    final Map<String, dynamic> rawTemp = templates[templateIndex];
    
    final String situation = rawTemp['situation']!
        .replaceAll('{name}', name)
        .replaceAll('{item}', item);
    
    return {
      'situation': situation,
      'honest': rawTemp['honest'],
      'dishonest': rawTemp['dishonest'],
    };
  }

  @override
  void initState() {
    super.initState();

    // Load progress from SharedPreferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGameProgress();
    });

    // 1. Spring Wobble physics controller for scale tilt
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _tiltAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_tiltController);

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
    _tiltController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // Persistent Game Load Progress
  Future<void> _loadGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final gameState = Provider.of<StudentGameState>(context, listen: false);
    
    setState(() {
      _currentLevel = prefs.getInt('g3_current_level') ?? gameState.getUnlockedLevel('game3');
      _score = prefs.getInt('g3_session_score') ?? 0;
      _sortedCount = prefs.getInt('g3_sorted_count') ?? 0;
      _lives = prefs.getInt('g3_lives') ?? 4; 
      _isGameOver = false;
      _isWon = false;
      _showSuccessOverlay = false;
      _loadActiveHonestySituation();
    });
  }

  // Persistent Game Save Progress
  Future<void> _saveGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('g3_current_level', _currentLevel);
    await prefs.setInt('g3_session_score', _score);
    await prefs.setInt('g3_sorted_count', _sortedCount);
    await prefs.setInt('g3_lives', _lives);
  }

  // Dynamically load situation and populate decisions
  void _loadActiveHonestySituation() {
    final sitData = _generateDynamicHonestySituation(_currentLevel, _sortedCount);
    
    setState(() {
      _activeSituationText = sitData['situation'];
      _honestWeight = sitData['honest'];
      _dishonestWeight = sitData['dishonest'];

      // Smoothly spring back the balance scale to neutral center!
      _tiltScale(0.0);
    });
  }

  // Animate the balance scale tilt with gorgeous spring physics wobble!
  void _tiltScale(double targetAngle) {
    _currentTiltAngle = _tiltAnimation.value;
    _targetTiltAngle = targetAngle;

    _tiltAnimation = Tween<double>(
      begin: _currentTiltAngle,
      end: _targetTiltAngle,
    ).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.elasticOut),
    )..addListener(() {
        setState(() {});
      });

    _tiltController.forward(from: 0.0);
  }

  // Handles dropping a decision weight onto a scale pan
  void _handleDecisionWeightDrop(String decisionType, String targetPan) {
    if (_isGameOver || _isWon) return;

    if (decisionType == 'honest' && targetPan == 'honest_pan') {
      // CORRECT: Dropped Honest decision onto the Honesty Scale!
      HapticFeedback.lightImpact();
      _tiltScale(-0.16); // Tilt left to signify honesty weight!

      setState(() {
        _score += 1;
        _sortedCount++;
        _saveGameProgress(); // Save dynamic situation progress
      });

      // Show temporary positive success prompt, then load next situation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أمانة رائعة! لقد حافظت على الميزان الأخلاقي سليماً 💚⚖️!',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF10B981).withOpacity(0.95),
          duration: const Duration(milliseconds: 1000),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          if (_sortedCount >= _targetSorts) {
            _triggerLevelCompleted();
          } else {
            _loadActiveHonestySituation();
          }
        }
      });
    } else if (decisionType == 'dishonest' && targetPan == 'dishonest_pan') {
      // CORRECT: Dropped Dishonest decision onto the Deceit Scale (Acknowledging & rejecting dishonesty!)
      HapticFeedback.mediumImpact();
      _tiltScale(0.16); // Tilt right to signify dishonesty weighed!

      setState(() {
        _score += 1;
        _sortedCount++;
        _saveGameProgress(); // Save dynamic situation progress
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'رائع! قمت بفرز السلوك الخاطئ بمكانه وعرفت ضرره 🛡️⚖️!',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFF59E0B).withOpacity(0.95),
          duration: const Duration(milliseconds: 1000),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          if (_sortedCount >= _targetSorts) {
            _triggerLevelCompleted();
          } else {
            _loadActiveHonestySituation();
          }
        }
      });
    } else {
      // WRONG: Dropped decision onto the wrong scale pan!
      _triggerSortError();
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
      _successTitle = 'حارس الأمانة الذهبي! 🏆⚖️';
      _successDesc = 'لقد قمت بوزن القرارات وتقويم الأفعال بنجاح باهر عبر 50 موقفاً أمانياً رائعاً! تم حفظ تقدمك.';
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
      if (_currentLevel == gameState.getUnlockedLevel('game3')) {
        gameState.unlockNextLevel('game3');
      }

      if (_currentLevel < 80) {
        _currentLevel++;
        _score = 0; // Reset session score for the new level
        _sortedCount = 0;
        _lives = 4; // Reset to 4 hearts
        _loadActiveHonestySituation();
        _saveGameProgress(); // Save level start progress
      } else {
        // Finished all 80 levels! Complete Victory!
        _isWon = true;
        _showFinishDialog(true);
      }
    });
  }

  void _showFinishDialog(bool won) {
    _tiltController.stop();

    if (won) {
      context.read<StudentGameState>().addPoints(10);
      context.read<StudentGameState>().unlockNextLevel('game3');
    } else {
      // Reset level session values on game over so next entry is fresh!
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('g3_session_score', 0);
        prefs.setInt('g3_sorted_count', 0);
        prefs.setInt('g3_lives', 4);
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
                won ? '👑' : '⚖️',
                style: TextStyle(fontSize: 48.sp),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              won ? 'البروفيسور حارس الأمانة! 🏆' : 'خسرت في المستوى $_currentLevel 💔',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              won
                  ? 'مذهل يا بطل الأبطال! لقد وازنت موازين الأخلاق والصدق عبر 80 مستوى كاملاً، وأصبحت قدوة للأمانة المدرسية والوطنية! +25 نقطة 👑🌟'
                  : 'لقد خسرت في المستوى $_currentLevel لأنك قمت بوزن القرارات بشكل خاطئ.. تذكر دائماً أن الأمانة والصدق يوضعان بكفتهم الخضراء، والقرارات غير الأمينة بمكانها المخصص لنعترف بها ونتفاداها! حاول مجدداً.',
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
    final double tiltAngle = _tiltAnimation.value;

    // Geometric coordinates of the tilting Balance Scale relative to center of middle zone
    final double beamLength = size.width * 0.55;
    final double pivotX = size.width / 2 - 20.w;
    final double pivotY = 100.h;

    // Calculate left/right beam connection points dynamically based on tilt angle!
    final double leftBeamX = pivotX - (beamLength / 2) * math.cos(tiltAngle);
    final double leftBeamY = pivotY - (beamLength / 2) * math.sin(tiltAngle);

    final double rightBeamX = pivotX + (beamLength / 2) * math.cos(tiltAngle);
    final double rightBeamY = pivotY + (beamLength / 2) * math.sin(tiltAngle);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _saveGameProgress(); // Guarantees saving current level progress on exit
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF030712),
        body: Stack(
          children: [
            // Gorgeous Space-Purple-Gold Sky Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF050312), Color(0xFF0A071E), Color(0xFF1B0F2A)],
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
                                'حارس الأمانة: مستوى $_currentLevel 🛡️⚖️',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'وازن قراراتك بعناية وصدق',
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
                                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  'موقف الأمانة المعروض 🚨',
                                  style: GoogleFonts.cairo(color: const Color(0xFFFBBF24), fontSize: 9.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withOpacity(0.3),
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
                            _activeSituationText.isNotEmpty ? _activeSituationText : 'جاري تحميل الموقف...',
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
                                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
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
                            color: const Color(0xFFF59E0B).withOpacity(0.15),
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

                    // ── Spring-Physics Tilting Balance Scale Arena ──
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
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // ── DRAW BALANCE SCALE PIECES GEOMETRICALLY ──
                              
                              // 1. Central scale stand (The static vertical pillar and base)
                              Positioned(
                                left: pivotX - 8.w,
                                top: pivotY - 10.h,
                                child: Container(
                                  width: 14.w,
                                  height: 110.h,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF475569), Color(0xFF1E293B)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: pivotX - 35.w,
                                top: pivotY + 100.h,
                                child: Container(
                                  width: 70.w,
                                  height: 10.h,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                ),
                              ),

                              // 2. Pivot knob at the center
                              Positioned(
                                left: pivotX - 12.w,
                                top: pivotY - 12.h,
                                child: Container(
                                  width: 24.w,
                                  height: 24.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                                    ),
                                    border: Border.all(color: Colors.white38),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B).withOpacity(0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 3. Tilting Beam (The dynamic horizontal golden beam)
                              Positioned(
                                left: pivotX - (beamLength / 2),
                                top: pivotY - 4.h,
                                child: Transform.rotate(
                                  angle: tiltAngle,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: beamLength,
                                    height: 8.h,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFBBF24), Color(0xFFD97706), Color(0xFFFBBF24)],
                                      ),
                                      borderRadius: BorderRadius.circular(4.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFBBF24).withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 4. HANGING LEFT SCALE PAN: "كفة الأمانة والصدق" 🟢 (DragTarget!)
                              Positioned(
                                left: leftBeamX - 40.w,
                                top: leftBeamY,
                                child: Column(
                                  children: [
                                    // Hanging Strings
                                    Container(
                                      width: 80.w,
                                      height: 40.h,
                                      child: CustomPaint(
                                        painter: ScaleStringsPainter(color: const Color(0xFF10B981).withOpacity(0.4)),
                                      ),
                                    ),
                                    // Scale Pan Container
                                    DragTarget<String>(
                                      onWillAcceptWithDetails: (details) => true,
                                      onAcceptWithDetails: (details) {
                                        _handleDecisionWeightDrop(details.data, 'honest_pan');
                                      },
                                      builder: (context, candidateData, rejectedData) {
                                        final bool isHovered = candidateData.isNotEmpty;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          width: 80.w,
                                          height: 40.h,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isHovered
                                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                                  : [const Color(0xFF10B981).withOpacity(0.12), const Color(0xFF059669).withOpacity(0.06)],
                                            ),
                                            borderRadius: BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: isHovered ? Colors.white : const Color(0xFF10B981).withOpacity(0.4),
                                              width: isHovered ? 2.0 : 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withOpacity(isHovered ? 0.35 : 0.08),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.favorite_rounded, color: Color(0xFF10B981), size: 12),
                                              SizedBox(height: 1.h),
                                              Text(
                                                'كفة الأمانة 🟢',
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontSize: 7.5.sp,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // 5. HANGING RIGHT SCALE PAN: "كفة الخداع والتقصير" 🔴 (DragTarget!)
                              Positioned(
                                left: rightBeamX - 40.w,
                                top: rightBeamY,
                                child: Column(
                                  children: [
                                    // Hanging Strings
                                    Container(
                                      width: 80.w,
                                      height: 40.h,
                                      child: CustomPaint(
                                        painter: ScaleStringsPainter(color: const Color(0xFFEF4444).withOpacity(0.4)),
                                      ),
                                    ),
                                    // Scale Pan Container
                                    DragTarget<String>(
                                      onWillAcceptWithDetails: (details) => true,
                                      onAcceptWithDetails: (details) {
                                        _handleDecisionWeightDrop(details.data, 'dishonest_pan');
                                      },
                                      builder: (context, candidateData, rejectedData) {
                                        final bool isHovered = candidateData.isNotEmpty;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          width: 80.w,
                                          height: 40.h,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isHovered
                                                  ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                                                  : [const Color(0xFFEF4444).withOpacity(0.12), const Color(0xFFB91C1C).withOpacity(0.06)],
                                            ),
                                            borderRadius: BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: isHovered ? Colors.white : const Color(0xFFEF4444).withOpacity(0.4),
                                              width: isHovered ? 2.0 : 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFEF4444).withOpacity(isHovered ? 0.35 : 0.08),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.published_with_changes_rounded, color: Color(0xFFEF4444), size: 12),
                                              SizedBox(height: 1.h),
                                              Text(
                                                'كفة الخداع 🔴',
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontSize: 7.5.sp,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // ── Dynamic Decision Weights/Stones Below the scale! ──
                    if (_honestWeight.isNotEmpty && _dishonestWeight.isNotEmpty)
                      Row(
                        children: [
                          // Left Decision Weight: Honest choice (Draggable!)
                          Expanded(
                            child: Draggable<String>(
                              data: 'honest',
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width: 120.w,
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.4),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_honestWeight['emoji'], style: TextStyle(fontSize: 20.sp)),
                                      SizedBox(height: 3.h),
                                      Text(
                                        _honestWeight['text'],
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 8.5.sp,
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
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_honestWeight['emoji'], style: TextStyle(fontSize: 18.sp)),
                                    SizedBox(height: 3.h),
                                    Text(
                                      _honestWeight['text'],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 8.5.sp,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),

                          // Right Decision Weight: Dishonest choice (Draggable!)
                          Expanded(
                            child: Draggable<String>(
                              data: 'dishonest',
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width: 120.w,
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withOpacity(0.4),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_dishonestWeight['emoji'], style: TextStyle(fontSize: 20.sp)),
                                      SizedBox(height: 3.h),
                                      Text(
                                        _dishonestWeight['text'],
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 8.5.sp,
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
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_dishonestWeight['emoji'], style: TextStyle(fontSize: 18.sp)),
                                    SizedBox(height: 3.h),
                                    Text(
                                      _dishonestWeight['text'],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 8.5.sp,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
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
            if (_score == 0 && _honestWeight.isEmpty && !_showSuccessOverlay)
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
                        '⚖️ ميزان الأمانة والصدق',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'مرحباً بك يا حامي الأمانة والفضيلة! 🛡️⚖️\n\nأمامك ميزان ذو كفتين لتقييم ميزان الأعمال وحل المشاكل المدرسية الصعبة بالأمانة.\n\nطريقة اللعب الاحترافية:\n1. اسحب "أوزان القرارات" الصالحة (الأمينة) وضعها في "كفة الأمانة 🟢" (الجهة اليسرى).\n2. اسحب "أوزان القرارات" الخاطئة (غير الأمينة) وضعها في "كفة الخداع 🔴" (الجهة اليمنى) لنعزلها ونتفاداها! (+3 نقاط).\n\nبكل سحبة صحيحة، سيميل الميزان بفيزياء ارتداد حقيقية ويتغير الموقف فوراً! قم بفرز 50 موقفاً لتخطي المستوى!',
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
                          _loadActiveHonestySituation();
                        },
                        child: Text(
                          'أنا مستعد للوزن والعدل! ⚖️🚀',
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

// Custom Painter to draw suspension strings from beam end down to the pan
class ScaleStringsPainter extends CustomPainter {
  final Color color;
  ScaleStringsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.w
      ..style = PaintingStyle.stroke;

    final path = Path();
    // String from top-center of beam end to the left corner of pan
    path.moveTo(size.width / 2, 0);
    path.lineTo(5.w, size.height);

    // String from top-center of beam end to the right corner of pan
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width - 5.w, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
