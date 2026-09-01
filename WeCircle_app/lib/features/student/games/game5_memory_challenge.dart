import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student_game_state.dart';

class Game5MemoryChallenge extends StatefulWidget {
  const Game5MemoryChallenge({super.key});

  @override
  State<Game5MemoryChallenge> createState() => _Game5MemoryChallengeState();
}

class _Game5MemoryChallengeState extends State<Game5MemoryChallenge> with TickerProviderStateMixin {
  // Game state
  bool _showWizard = true;
  int _wizardStep = 0;
  int _score = 0;
  int _combo = 0;
  int _currentLevel = 1;
  int _lives = 4;
  bool _isPlayingSequence = false;
  bool _isGameOver = false;
  bool _isWon = false;
  
  // Game sequences
  List<int> _sequence = [];
  List<int> _userInputs = [];
  int? _flashingIndex;
  Timer? _sequenceTimer;

  // Custom Success Overlay State
  bool _showSuccessOverlay = false;
  String _successTitle = '';
  String _successDesc = '';
  int _earnedPoints = 0;

  // Screen shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Feedback animations for buttons
  List<AnimationController> _glowControllers = [];
  List<Animation<double>> _glowAnimations = [];

  // Define the 9 unique squares (each has unique colors, icons, and gradients)
  final List<Map<String, dynamic>> _allSquares = [
    {
      'icon': Icons.whatshot_rounded, // Flame
      'color': const Color(0xFF10B981), // Green
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF065F46), Color(0xFF047857)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'glowColor': const Color(0xFF34D399),
    },
    {
      'icon': Icons.bolt_rounded, // Lightning
      'color': const Color(0xFFEF4444), // Red
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF991B1B), Color(0xFFB91C1C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'glowColor': const Color(0xFFF87171),
    },
    {
      'icon': Icons.star_rounded, // Star
      'color': const Color(0xFF3B82F6), // Blue
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'glowColor': const Color(0xFF60A5FA),
    },
    {
      'icon': Icons.spa_rounded, // Leaf
      'color': const Color(0xFF1E40AF), // Navy Blue
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'glowColor': const Color(0xFF38BDF8),
    },
    {
      'icon': Icons.diamond_rounded, // Diamond
      'color': const Color(0xFF8B5CF6), // Purple
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF5B21B6), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'glowColor': const Color(0xFFA78BFA),
    },
    {
      'icon': Icons.shield_rounded, // Shield
      'color': const Color(0xFFF59E0B), // Yellow/Amber
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF78350F), Color(0xFFB45309)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'glowColor': const Color(0xFFFBBF24),
    },
    {
      'icon': Icons.explore_rounded, // Compass
      'color': const Color(0xFFEA580C), // Orange/Brown
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF451A03), Color(0xFF7C2D12)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'glowColor': const Color(0xFFFB923C),
    },
    {
      'icon': Icons.sports_esports_rounded, // Gamepad
      'color': const Color(0xFF84CC16), // Lime Green
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF3F6212), Color(0xFF4D7C0F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'glowColor': const Color(0xFFA3E635),
    },
    {
      'icon': Icons.favorite_rounded, // Heart
      'color': const Color(0xFFEC4899), // Pink
      'bgGradient': const LinearGradient(
        colors: [Color(0xFF9D174D), Color(0xFFBE185D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'glowColor': const Color(0xFFF472B6),
    },
  ];

  // Dynamically get the squares available for the current level
  // First level displays 3 squares. Each level adds 1 square up to 9 squares max.
  int get _gridSize => (2 + _currentLevel).clamp(3, 9);
  List<Map<String, dynamic>> get _currentSquares => _allSquares.sublist(0, _gridSize);

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

    // Set up glow controllers for the 9 buttons
    for (int i = 0; i < 9; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      );
      _glowControllers.add(controller);
      _glowAnimations.add(Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ));
    }
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _shakeController.dispose();
    for (var controller in _glowControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Load progress
  Future<void> _loadGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLevel = prefs.getInt('g5_current_level') ?? 1;
      _score = prefs.getInt('g5_session_score') ?? 0;
      _lives = prefs.getInt('g5_lives') ?? 4;
      _showWizard = prefs.getBool('g5_show_wizard') ?? true;
    });

    if (!_showWizard) {
      _startNewLevelSequence();
    }
  }

  // Save progress
  Future<void> _saveGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('g5_current_level', _currentLevel);
    await prefs.setInt('g5_session_score', _score);
    await prefs.setInt('g5_lives', _lives);
    await prefs.setBool('g5_show_wizard', _showWizard);
  }

  // Start the challenge after wizard
  void _startChallenge() {
    setState(() {
      _showWizard = false;
      _lives = 4;
      _score = 0;
      _combo = 0;
      _isGameOver = false;
      _isWon = false;
      _showSuccessOverlay = false;
    });
    _saveGameProgress();
    _startNewLevelSequence();
  }

  // Generates and plays a new pattern sequence
  void _startNewLevelSequence() {
    _sequenceTimer?.cancel();
    _userInputs.clear();
    
    // Slow sequence length growth: levels 1-2 = 3 steps, levels 3-4 = 4 steps, etc. up to 10 max.
    final seqLength = (3 + (_currentLevel - 1) ~/ 2).clamp(3, 10);
    final random = javaRandom(); // Select random from available squares
    
    final List<int> newSeq = [];
    for (int i = 0; i < seqLength; i++) {
      newSeq.add(random.nextInt(_gridSize));
    }

    setState(() {
      _sequence = newSeq;
      _isPlayingSequence = true;
      _flashingIndex = null;
    });

    // Start playing pattern after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _playSequenceIndex(0);
      }
    });
  }

  // Helper random generator
  javaRandom() {
    return javaRandomSeed(DateTime.now().millisecondsSinceEpoch);
  }

  javaRandomSeed(int seed) {
    return _RandomGenerator(seed);
  }

  // Plays sequence item at given index
  void _playSequenceIndex(int index) {
    if (index >= _sequence.length) {
      setState(() {
        _isPlayingSequence = false;
        _flashingIndex = null;
      });
      return;
    }

    final squareIndex = _sequence[index];

    setState(() {
      _flashingIndex = squareIndex;
    });
    
    // Animate glow of the flashing item
    _glowControllers[squareIndex].forward(from: 0.0);
    HapticFeedback.lightImpact();

    // Speed gets slightly faster at higher levels!
    final flashDuration = (600 - (_currentLevel * 10)).clamp(250, 600);
    final restDuration = (300 - (_currentLevel * 5)).clamp(120, 300);

    _sequenceTimer = Timer(Duration(milliseconds: flashDuration), () {
      if (mounted) {
        setState(() {
          _flashingIndex = null;
        });
        _glowControllers[squareIndex].reverse();

        _sequenceTimer = Timer(Duration(milliseconds: restDuration), () {
          if (mounted) {
            _playSequenceIndex(index + 1);
          }
        });
      }
    });
  }

  // When child taps a square
  void _handleSquareTap(int index) {
    if (_isPlayingSequence || _isGameOver || _isWon || _showSuccessOverlay) return;

    _glowControllers[index].forward(from: 0.0).then((_) {
      _glowControllers[index].reverse();
    });

    HapticFeedback.mediumImpact();
    setState(() {
      _userInputs.add(index);
    });

    // Check correctness
    final currentStep = _userInputs.length - 1;
    if (_userInputs[currentStep] == _sequence[currentStep]) {
      // Correct tap!
      if (_userInputs.length == _sequence.length) {
        // Complete sequence correct!
        setState(() {
          _combo += 1;
          _score += 1; // Increment session score by 1 point
        });
        
        context.read<StudentGameState>().addPoints(10);
        _triggerLevelComplete();
      }
    } else {
      // Incorrect tap!
      _triggerFailureAnimation();
    }
  }

  // Handle wrong pattern input
  void _triggerFailureAnimation() {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) => _shakeController.reset());

    setState(() {
      _lives -= 1;
      _combo = 0;
    });

    if (_lives <= 0) {
      setState(() {
        _isGameOver = true;
      });
      _saveGameProgress();
    } else {
      // Show failure banner and replay pattern
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أوبس! الترتيب غير صحيح ❌ حاول التركيز وحفظ الوميض ثانية!',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.sp),
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Replay sequence after SnackBar pops
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isGameOver) {
          setState(() {
            _userInputs.clear();
            _isPlayingSequence = true;
          });
          _playSequenceIndex(0);
        }
      });
    }
    _saveGameProgress();
  }

  // Level success celebration
  void _triggerLevelComplete() {
    setState(() {
      _showSuccessOverlay = true;
      _earnedPoints = 2;
      _successTitle = 'رائع يا بطل! كفء! 🎉🏆';
      _successDesc = 'لقد قمت بمحاكاة النمط المعقد بنجاح تام! ذاكرتك حديدية وتركيزك خارق.';
    });

    context.read<StudentGameState>().unlockNextLevel('game5');

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('g5_current_level', _currentLevel + 1);
      prefs.setInt('g5_session_score', _score);
    });
  }

  // Load next level
  void _advanceToNextLevel() {
    setState(() {
      _currentLevel += 1;
      _showSuccessOverlay = false;
    });
    _saveGameProgress();
    _startNewLevelSequence();
  }

  // Restart
  void _restartGame() {
    setState(() {
      _lives = 4;
      _score = 0;
      _combo = 0;
      _currentLevel = 1;
      _isGameOver = false;
      _isWon = false;
      _showSuccessOverlay = false;
    });
    _saveGameProgress();
    _startNewLevelSequence();
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = true; // Hardcoded default for child local apps
    
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _saveGameProgress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF030712),
        body: Stack(
          children: [
            // Glowing dark gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F081D), Color(0xFF050209), Color(0xFF020412)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Main screen layout
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: _showWizard ? _buildWizardView() : _buildGameView(),
              ),
            ),

            // Game Over Screen Overlay
            if (_isGameOver) _buildGameOverOverlay(),

            // Level Complete Celebration Overlay
            if (_showSuccessOverlay) _buildSuccessOverlay(),
          ],
        ),
      ),
    );
  }

  // ── WIZARD / INSTRUCTIONS SCREEN ──
  Widget _buildWizardView() {
    final List<Map<String, dynamic>> steps = [
      {
        'title': 'الخطوة 1',
        'desc': 'ركز كويس يا بطل! اللعبة دي هي اختبار لذاكرتك الحديدية وقدرتك على حفظ الأنماط.',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'الخطوة 2',
        'desc': 'هتظهر لك ألوان وأشكال بالترتيب، حاول تحفظهم ودوس عليهم بنفس الترتيب.',
        'icon': Icons.access_time_rounded,
        'color': const Color(0xFFEC4899),
      },
      {
        'title': 'الخطوة 3',
        'desc': 'كل ما تنجح، التحدي هيكبر والسرعة هتزيد.. وريني ذاكرتك هتوصل لفين!',
        'icon': Icons.speed_rounded,
        'color': const Color(0xFF10B981),
      },
    ];

    final currentStepData = steps[_wizardStep];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        SizedBox(height: 20.h),
        Text(
          'كيفية اللعب',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 26.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          'تحدي الذاكرة (الصاروخ والساعة)',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: const Color(0xFFA78BFA),
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const Spacer(),

        // Glassmorphic Center Card
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rotating Icon Sphere
              Container(
                width: 90.r,
                height: 90.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentStepData['color'].withOpacity(0.12),
                  boxShadow: [
                    BoxShadow(
                      color: currentStepData['color'].withOpacity(0.3),
                      blurRadius: 20.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    currentStepData['icon'],
                    color: currentStepData['color'],
                    size: 42.r,
                  ),
                ),
              ),
              SizedBox(height: 25.h),
              
              // Step Counter Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: currentStepData['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Text(
                  currentStepData['title'],
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 15.h),

              // Description Text
              Text(
                currentStepData['desc'],
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Page Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final active = index == _wizardStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: active ? 22.w : 7.w,
              height: 7.h,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFC084FC) : Colors.white24,
                borderRadius: BorderRadius.circular(4.r),
              ),
            );
          }),
        ),
        SizedBox(height: 35.h),

        // Start/Next Button
        GestureDetector(
          onTap: () {
            if (_wizardStep < 2) {
              setState(() {
                _wizardStep++;
              });
            } else {
              _startChallenge();
            }
          },
          child: Container(
            height: 52.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF84CC16), Color(0xFF65A30D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF84CC16).withOpacity(0.3),
                  blurRadius: 15.r,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _wizardStep == 2 ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  _wizardStep == 2 ? 'بدء التحدي الآن' : 'الخطوة التالية',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  // ── CORE GAMEPLAY VIEW ──
  Widget _buildGameView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row controls
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
            
            Text(
              'تحدي الذاكرة 🧠🚀',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
              ),
            ),

            // Lives display (4 Hearts)
            Row(
              children: List.generate(4, (index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: index < _lives ? const Color(0xFFEC4899) : Colors.white10,
                    size: 18.w,
                  ),
                );
              }),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Scores & level summary panel
        Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 18.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatsBadge('المستوى', '$_currentLevel', const Color(0xFF06B6D4)),
              _buildStatsBadge('النقاط', '$_score', const Color(0xFFF59E0B)),
              _buildStatsBadge('كومبو', 'x$_combo', const Color(0xFFEC4899)),
            ],
          ),
        ),
        
        SizedBox(height: 20.h),

        // Action Status bar (Show instructions to watch or copy)
        Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: _isPlayingSequence 
                ? const Color(0xFF06B6D4).withOpacity(0.12)
                : const Color(0xFF10B981).withOpacity(0.12),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: _isPlayingSequence 
                  ? const Color(0xFF06B6D4).withOpacity(0.3)
                  : const Color(0xFF10B981).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPlayingSequence ? Icons.visibility_rounded : Icons.touch_app_rounded,
                color: _isPlayingSequence ? const Color(0xFF22D3EE) : const Color(0xFF34D399),
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                _isPlayingSequence ? 'ركز واحفظ الترتيب!' : 'كرر النمط المضيء بالترتيب!',
                style: GoogleFonts.cairo(
                  color: _isPlayingSequence ? const Color(0xFF22D3EE) : const Color(0xFF34D399),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Dynamic Growing Grid of Squares!
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value * math.sin(math.pi * _shakeController.value * 10), 0),
              child: child,
            );
          },
          child: Center(
            child: _buildDynamicGrid(),
          ),
        ),

        const Spacer(),

        // Replay Button (If not playing, allow them to see the sequence again)
        if (!_isPlayingSequence)
          GestureDetector(
            onTap: () {
              setState(() {
                _userInputs.clear();
                _isPlayingSequence = true;
              });
              _playSequenceIndex(0);
            },
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.replay_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 8.w),
                    Text(
                      'إعادة عرض الوميض',
                      style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        SizedBox(height: 20.h),
      ],
    );
  }

  // Helper stats badge inside top panel
  Widget _buildStatsBadge(String label, String value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.r,
              height: 6.r,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 5.w),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // Generates custom layout for grid according to gridSize (3 to 9)
  Widget _buildDynamicGrid() {
    final squares = _currentSquares;
    final int count = squares.length;

    // We can lay them out in a GridView with columns dynamically decided
    int crossAxisCount = 3;
    if (count <= 3) {
      crossAxisCount = 3; // 1 row of 3
    } else if (count == 4) {
      crossAxisCount = 2; // 2x2 grid
    } else {
      crossAxisCount = 3; // 3 columns max
    }

    return Container(
      width: 280.w,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final sq = squares[index];

          return AnimatedBuilder(
            animation: _glowControllers[index],
            builder: (context, child) {
              final isFlashing = _flashingIndex == index;
              final glowAnim = _glowAnimations[index].value;

              // Calculate scale: shrink on tap, grow on auto-flash
              double scale = 1.0;
              if (isFlashing) {
                scale = 1.1; // Grow during pattern flash
              } else if (glowAnim > 0) {
                scale = 1.0 - (glowAnim * 0.12); // Shrink up to 12% on user tap down
              }

              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: () => _handleSquareTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      gradient: sq['bgGradient'],
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isFlashing 
                            ? Colors.white 
                            : sq['glowColor'].withOpacity(0.2 + (glowAnim * 0.8)),
                        width: isFlashing ? 3.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isFlashing 
                              ? Colors.white.withOpacity(0.6)
                              : sq['glowColor'].withOpacity(0.1 + (glowAnim * 0.6)),
                          blurRadius: isFlashing ? 18.r : 8.r + (glowAnim * 8.r),
                          spreadRadius: isFlashing ? 2.r : 0.r + (glowAnim * 1.r),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        sq['icon'],
                        color: Colors.white.withOpacity(isFlashing ? 1.0 : 0.85),
                        size: 32.sp,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── GAME OVER DIALOG OVERLAY ──
  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black87,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 300.w,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '💔 انتهت المحاولات',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: Colors.redAccent,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'لقد نفدت قلوبك يا بطل، لكن لا بأس بالخطأ! فالتكرار يعلم الشطار. جرب مرة أخرى لتنمية ذاكرتك الحديدية.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 25.h),
              
              // Try Again Button
              GestureDetector(
                onTap: _restartGame,
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      'أعد المحاولة 🔁',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // Go Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Text(
                    'العودة للرئيسية',
                    style: GoogleFonts.cairo(
                      color: Colors.white38,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LEVEL SUCCESS DIALOG OVERLAY ──
  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black87,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 300.w,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _successTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF10B981),
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                _successDesc,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 15.h),

              // Points earned badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Text(
                  'كسبت: $_earnedPoints نقطة ⭐',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFFBBF24),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              
              SizedBox(height: 25.h),
              
              // Next Level Button
              GestureDetector(
                onTap: _advanceToNextLevel,
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      'المستوى التالي ➡️',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // Go Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Text(
                    'العودة للرئيسية',
                    style: GoogleFonts.cairo(
                      color: Colors.white38,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Random Generator with seed to match Java random behaviour
class _RandomGenerator {
  int seed;
  _RandomGenerator(this.seed);

  int nextInt(int max) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed % max;
  }
}
