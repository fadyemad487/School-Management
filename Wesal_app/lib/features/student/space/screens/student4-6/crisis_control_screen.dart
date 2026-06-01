import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum CrisisGameState { briefing, decision, outcome }

class CrisisScenario {
  final String title;
  final String description;
  final String icon;
  final List<CrisisOption> options;

  CrisisScenario({
    required this.title,
    required this.description,
    required this.icon,
    required this.options,
  });
}

class CrisisOption {
  final String title;
  final String risk;
  final String reward;
  final String consequenceText;
  final bool isSuccess;
  final Color color;

  CrisisOption({
    required this.title,
    required this.risk,
    required this.reward,
    required this.consequenceText,
    required this.isSuccess,
    required this.color,
  });
}

class CrisisControlScreen extends StatefulWidget {
  const CrisisControlScreen({super.key});

  @override
  State<CrisisControlScreen> createState() => _CrisisControlScreenState();
}

class _CrisisControlScreenState extends State<CrisisControlScreen>
    with TickerProviderStateMixin {
  CrisisGameState _gameState = CrisisGameState.briefing;
  late CrisisScenario _currentScenario;
  CrisisOption? _selectedOption;
  
  double _timerProgress = 1.0;
  Timer? _gameTimer;
  int _currentLevel = 1;
  int _score = 0;

  late AnimationController _alarmController;
  late AnimationController _hologramController;

  final List<CrisisScenario> _scenarios = [
    CrisisScenario(
      title: 'تسريب وقود حاد',
      description: 'تم اكتشاف تسريب في خزان الوقود الرئيسي. المحركات ستبدأ العمل خلال 10 ثوانٍ!',
      icon: '🚀',
      options: [
        CrisisOption(
          title: 'إصلاح يدوي',
          risk: 'بطيء جداً - خطر الفشل',
          reward: 'آمن على الطاقة',
          consequenceText: 'تأخرت كثيراً! الوقود اشتعل قبل إغلاق الصمام. انفجار في القطاع 4.',
          isSuccess: false,
          color: Colors.orangeAccent,
        ),
        CrisisOption(
          title: 'روبوت الإصلاح',
          risk: 'يستهلك 50% من طاقة المحطة',
          reward: 'سريع ودقيق',
          consequenceText: 'تم بنجاح! الروبوت أغلق التسريب في ثوانٍ، لكن طاقة المحطة انخفضت.',
          isSuccess: true,
          color: const Color(0xFF00F2FF),
        ),
        CrisisOption(
          title: 'تجاهل وانطلاق',
          risk: 'احتمالية انفجار عالية',
          reward: 'أسرع حل ممكن',
          consequenceText: 'كارثة! تسرب الوقود تسبب في انفجار هائل عند تشغيل المحركات.',
          isSuccess: false,
          color: Colors.redAccent,
        ),
      ],
    ),
    CrisisScenario(
      title: 'اصطدام نيزكي وشيك',
      description: 'نيزك ضخم يتجه نحو وحدة الأكسجين. لديك وقت محدود للتصرف!',
      icon: '☄️',
      options: [
        CrisisOption(
          title: 'تفعيل الدرع',
          risk: 'استهلاك عالي للبطاريات',
          reward: 'حماية كاملة',
          consequenceText: 'ممتاز! الدرع صد النيزك وحافظ على وحدة الأكسجين سليمة.',
          isSuccess: true,
          color: const Color(0xFF00F2FF),
        ),
        CrisisOption(
          title: 'إطلاق ليزر',
          risk: 'دقة منخفضة تحت الضغط',
          reward: 'تفتيت النيزك',
          consequenceText: 'الليزر أخطأ الهدف! النيزك دمر وحدة الأكسجين الثانوية.',
          isSuccess: false,
          color: Colors.purpleAccent,
        ),
        CrisisOption(
          title: 'إخلاء الوحدة',
          risk: 'فقدان مخزون الأكسجين',
          reward: 'سلامة الطاقم',
          consequenceText: 'الطاقم نجا، لكن المحطة فقدت 40% من مخزون الهواء.',
          isSuccess: false,
          color: Colors.amber,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _alarmController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _hologramController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    
    _startScenario(0);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _alarmController.dispose();
    _hologramController.dispose();
    super.dispose();
  }

  void _startScenario(int index) {
    setState(() {
      _currentScenario = _scenarios[index % _scenarios.length];
      _gameState = CrisisGameState.briefing;
      _timerProgress = 1.0;
      _selectedOption = null;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _gameState = CrisisGameState.decision);
      _startTimer();
    });
  }

  void _startTimer() {
    _gameTimer?.cancel();
    const duration = Duration(milliseconds: 50);
    double totalTime = 8.0 - (_currentLevel * 0.5);
    if (totalTime < 4.0) totalTime = 4.0;
    double decrement = duration.inMilliseconds / (totalTime * 1000);

    _gameTimer = Timer.periodic(duration, (timer) {
      if (!mounted) return;
      setState(() {
        _timerProgress -= decrement;
        if (_timerProgress <= 0) {
          _timerProgress = 0;
          _handleDecision(null); // Timeout
        }
      });
    });
  }

  void _handleDecision(CrisisOption? option) {
    _gameTimer?.cancel();
    setState(() {
      _selectedOption = option;
      _gameState = CrisisGameState.outcome;
      if (option?.isSuccess == true) {
        _score += 200;
      }
    });

    if (option?.isSuccess == true) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020412),
      body: Stack(
        children: [
          _buildSpaceBackground(),
          _buildEmergencyOverlay(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildMainStage(),
                ),
                _buildFooterControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF020412), Color(0xFF0A0E21), Color(0xFF020412)],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.1,
          child: Icon(Icons.grid_4x4_rounded, size: 400.r, color: const Color(0xFF00F2FF)),
        ),
      ),
    );
  }

  Widget _buildEmergencyOverlay() {
    return AnimatedBuilder(
      animation: _alarmController,
      builder: (context, child) {
        bool showAlarm = _gameState == CrisisGameState.decision && _timerProgress < 0.4;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red.withValues(alpha: showAlarm ? 0.3 * _alarmController.value : 0),
              width: 10,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'محاكي إدارة الأزمات',
                style: TextStyle(
                  color: const Color(0xFF00F2FF),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'CRISIS CONTROL v1.0',
                style: TextStyle(color: Colors.white24, fontSize: 10.sp, letterSpacing: 2),
              ),
            ],
          ),
          _buildScoreBadge(),
        ],
      ),
    );
  }

  Widget _buildScoreBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '$_score',
        style: TextStyle(color: const Color(0xFFBC00FF), fontWeight: FontWeight.bold, fontSize: 14.sp),
      ),
    );
  }

  Widget _buildMainStage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_gameState == CrisisGameState.briefing) _buildBriefingView(),
          if (_gameState == CrisisGameState.decision) _buildDecisionView(),
          if (_gameState == CrisisGameState.outcome) _buildOutcomeView(),
        ],
      ),
    );
  }

  Widget _buildBriefingView() {
    return Column(
      children: [
        _buildHologramIcon(_currentScenario.icon),
        SizedBox(height: 32.h),
        Text(
          'تنبيه: حالة طوارئ!',
          style: TextStyle(color: Colors.redAccent, fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ).animate(onPlay: (c) => c.repeat()).shimmer(),
        SizedBox(height: 16.h),
        Text(
          _currentScenario.description,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 15.sp, height: 1.5, fontFamily: 'Cairo'),
        ).animate().fadeIn().slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildDecisionView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('تحليل الخيارات المتاحة:', style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontFamily: 'Cairo')),
            Text(
              '${(_timerProgress * 10).toStringAsFixed(1)}s',
              style: TextStyle(
                color: _timerProgress < 0.3 ? Colors.redAccent : Colors.amber,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        ..._currentScenario.options.map((opt) => _buildOptionCard(opt)),
      ],
    );
  }

  Widget _buildOptionCard(CrisisOption option) {
    return GestureDetector(
      onTap: () => _handleDecision(option),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: option.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: option.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(option.title, style: TextStyle(color: option.color, fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const Spacer(),
                const Icon(Icons.touch_app_rounded, color: Colors.white24, size: 16),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                _buildOptionTag(Icons.warning_amber_rounded, option.risk, Colors.redAccent),
                SizedBox(width: 12.w),
                _buildOptionTag(Icons.auto_awesome_rounded, option.reward, Colors.greenAccent),
              ],
            ),
          ],
        ),
      ).animate().slideX(begin: 0.1).fadeIn(),
    );
  }

  Widget _buildOptionTag(IconData icon, String text, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white54, fontSize: 10.sp, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeView() {
    bool isSuccess = _selectedOption?.isSuccess ?? false;
    return Column(
      children: [
        _buildHologramIcon(isSuccess ? '✅' : '💥'),
        SizedBox(height: 32.h),
        Text(
          isSuccess ? 'تمت السيطرة على الأزمة' : 'فشل المهمة',
          style: TextStyle(
            color: isSuccess ? const Color(0xFF00FF95) : Colors.redAccent,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          _selectedOption?.consequenceText ?? 'انتهى الوقت المسموح به! المحطة تعرضت لضرر جسيم.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14.sp, height: 1.5, fontFamily: 'Cairo'),
        ),
        SizedBox(height: 40.h),
        ElevatedButton(
          onPressed: () {
            _currentLevel++;
            _startScenario(_currentLevel - 1);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F2FF),
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          ),
          child: const Text('المهمة التالية', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ),
      ],
    );
  }

  Widget _buildHologramIcon(String icon) {
    return AnimatedBuilder(
      animation: _hologramController,
      builder: (context, child) {
        return Container(
          width: 120.r,
          height: 120.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00F2FF).withValues(alpha: 0.1),
            border: Border.all(color: const Color(0xFF00F2FF).withValues(alpha: 0.2 + 0.1 * _hologramController.value)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF00F2FF).withValues(alpha: 0.1), blurRadius: 20 * _hologramController.value),
            ],
          ),
          child: Center(
            child: Text(icon, style: TextStyle(fontSize: 50.sp)),
          ),
        );
      },
    );
  }

  Widget _buildFooterControls() {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatHUD('سلامة المحطة', '85%'),
              _buildStatHUD('استقرار النظام', '${(_timerProgress * 100).toInt()}%'),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _timerProgress,
              minHeight: 4.h,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                _timerProgress > 0.3 ? const Color(0xFF00F2FF) : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatHUD(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white24, fontSize: 9.sp, fontFamily: 'Cairo')),
        Text(value, style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
