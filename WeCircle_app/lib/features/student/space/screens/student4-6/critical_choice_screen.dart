import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum DecisionState { presentation, selection, feedback, profiling }

class ScenarioChoice {
  final String text;
  final String consequence;
  final int qualityScore; // 0-100
  final String riskLevel; // Low, Medium, High
  final double logicWeight; // 0.0 to 1.0 (remainder is emotion)
  final String profileType; // Rational, Balanced, Emotional, etc.

  ScenarioChoice({
    required this.text,
    required this.consequence,
    required this.qualityScore,
    required this.riskLevel,
    required this.logicWeight,
    required this.profileType,
  });
}

class LifeScenario {
  final String title;
  final String description;
  final String category;
  final List<ScenarioChoice> choices;

  LifeScenario({
    required this.title,
    required this.description,
    required this.category,
    required this.choices,
  });
}

class CriticalChoiceScreen extends StatefulWidget {
  const CriticalChoiceScreen({super.key});

  @override
  State<CriticalChoiceScreen> createState() => _CriticalChoiceScreenState();
}

class _CriticalChoiceScreenState extends State<CriticalChoiceScreen>
    with TickerProviderStateMixin {
  DecisionState _gameState = DecisionState.presentation;
  int _currentLevel = 1;
  
  late LifeScenario _currentScenario;
  ScenarioChoice? _selectedChoice;
  
  final List<LifeScenario> _scenarios = [
    LifeScenario(
      title: 'إدارة الوقت الدراسي',
      description: 'لديك امتحان مهم غداً، لكن أصدقاؤك دعوك للعب لعبة فيديو جماعية جديدة ومنتظرة جداً. ماذا تفعل؟',
      category: 'الدراسة والإنتاجية',
      choices: [
        ScenarioChoice(
          text: 'أعتذر لأصدقائي وأركز في المذاكرة تماماً.',
          consequence: 'ستحصل على درجة عالية في الامتحان وتكون فخوراً بنفسك، لكن قد تشعر ببعض العزلة المؤقتة.',
          qualityScore: 95,
          riskLevel: 'منخفض',
          logicWeight: 0.9,
          profileType: 'عقلاني ومنضبط',
        ),
        ScenarioChoice(
          text: 'ألعب لمدة 30 دقيقة فقط كراحة ثم أذاكر.',
          consequence: 'توازن جيد، لكنه يتطلب إرادة قوية جداً لعدم الاستمرار في اللعب.',
          qualityScore: 80,
          riskLevel: 'متوسط',
          logicWeight: 0.6,
          profileType: 'متوازن استراتيجياً',
        ),
        ScenarioChoice(
          text: 'ألعب الآن وأذاكر في وقت متأخر من الليل.',
          consequence: 'ستعاني من الإراد الشديد في الامتحان وقد تنسى الكثير من المعلومات.',
          qualityScore: 40,
          riskLevel: 'مرتفع',
          logicWeight: 0.2,
          profileType: 'مندفع عاطفياً',
        ),
      ],
    ),
    LifeScenario(
      title: 'التعامل مع التنمر الإلكتروني',
      description: 'رأيت شخصاً يسخر من زميل لك في مجموعة واتساب عامة. كيف تتصرف؟',
      category: 'المسؤولية الاجتماعية',
      choices: [
        ScenarioChoice(
          text: 'أقوم بالرد بحكمة وأطلب من المتنمر التوقف.',
          consequence: 'ستدعم زميلك وتضع حداً للسلوك السيء، مما يعزز مكانتك كقائد مسؤول.',
          qualityScore: 90,
          riskLevel: 'منخفض',
          logicWeight: 0.7,
          profileType: 'قائد حكيم',
        ),
        ScenarioChoice(
          text: 'أتجاهل الأمر تماماً لتجنب المشاكل.',
          consequence: 'ستبقى آمناً لكن زميلك سيشعر بالوحدة وسيتمر المتنمر في أفعاله.',
          qualityScore: 50,
          riskLevel: 'متوسط',
          logicWeight: 0.5,
          profileType: 'متحفظ',
        ),
        ScenarioChoice(
          text: 'أقوم بالسخرية من المتنمر بنفس طريقته.',
          consequence: 'تحولت أنت أيضاً إلى متنمر، وهذا سيزيد من المشكلة ويجعل الجميع يراك بشكل سيء.',
          qualityScore: 30,
          riskLevel: 'مرتفع',
          logicWeight: 0.1,
          profileType: 'مندفع',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadScenario(0);
  }

  void _loadScenario(int index) {
    setState(() {
      _currentScenario = _scenarios[index % _scenarios.length];
      _gameState = DecisionState.selection;
      _selectedChoice = null;
    });
  }

  void _handleChoice(ScenarioChoice choice) {
    setState(() {
      _selectedChoice = choice;
      _gameState = DecisionState.feedback;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C14),
      body: Stack(
        children: [
          _buildAmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildMainContent(),
                ),
                _buildBottomAnalytics(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.5,
          colors: [Color(0xFF141A2E), Color(0xFF0A0C14)],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.05,
          child: Icon(Icons.psychology_outlined, size: 400.r, color: const Color(0xFF00F2FF)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white38),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'الاختيار الحاسم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'CRITICAL CHOICE SIMULATOR',
                style: TextStyle(color: const Color(0xFF00F2FF).withValues(alpha: 0.5), fontSize: 10.sp, letterSpacing: 2),
              ),
            ],
          ),
          _buildLevelIndicator(),
        ],
      ),
    );
  }

  Widget _buildLevelIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        'Lvl $_currentLevel',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_gameState == DecisionState.selection) _buildSelection(),
            if (_gameState == DecisionState.feedback) _buildFeedback(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag(String category) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF00F2FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF00F2FF).withValues(alpha: 0.3)),
      ),
      child: Text(
        category,
        style: TextStyle(color: const Color(0xFF00F2FF), fontSize: 10.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
      ),
    );
  }

  Widget _buildSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryTag(_currentScenario.category),
        SizedBox(height: 16.h),
        Text(
          _currentScenario.title,
          style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            _currentScenario.description,
            style: TextStyle(color: Colors.white70, fontSize: 15.sp, height: 1.5, fontFamily: 'Cairo'),
          ),
        ).animate().fadeIn(),
        SizedBox(height: 30.h),
        Text(
          'ما هو قرارك الحاسم؟',
          style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontFamily: 'Cairo'),
        ),
        SizedBox(height: 12.h),
        ..._currentScenario.choices.map((choice) => _buildChoiceCard(choice)),
      ],
    );
  }

  Widget _buildChoiceCard(ScenarioChoice choice) {
    return GestureDetector(
      onTap: () => _handleChoice(choice),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                choice.text,
                style: TextStyle(color: Colors.white, fontSize: 15.sp, height: 1.4, fontFamily: 'Cairo'),
              ),
            ),
            SizedBox(width: 12.w),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ).animate().slideX(begin: 0.1).fadeIn(),
    );
  }

  Widget _buildFeedback() {
    return Column(
      children: [
        _buildResultHeader(),
        SizedBox(height: 24.h),
        _buildAnalysisPanel(),
        SizedBox(height: 40.h),
        ElevatedButton(
          onPressed: () {
            _currentLevel++;
            _loadScenario(_currentLevel - 1);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F2FF),
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 16.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          ),
          child: const Text('التحدي التالي', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ),
      ],
    );
  }

  Widget _buildResultHeader() {
    bool isGood = (_selectedChoice?.qualityScore ?? 0) >= 70;
    return Column(
      children: [
        Icon(
          isGood ? Icons.verified_rounded : Icons.warning_amber_rounded,
          color: isGood ? Colors.greenAccent : Colors.orangeAccent,
          size: 60.r,
        ),
        SizedBox(height: 16.h),
        Text(
          isGood ? 'قرار استراتيجي حكيم' : 'قرار عالي المخاطر',
          style: TextStyle(
            color: isGood ? Colors.greenAccent : Colors.orangeAccent,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    ).animate().scale().fadeIn();
  }

  Widget _buildAnalysisPanel() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تحليل العواقب:', style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontFamily: 'Cairo')),
          SizedBox(height: 8.h),
          Text(
            _selectedChoice?.consequence ?? '',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp, height: 1.5, fontFamily: 'Cairo'),
          ),
          SizedBox(height: 20.h),
          _buildStatRow('جودة القرار', '${_selectedChoice?.qualityScore ?? 0}%'),
          _buildStatRow('مستوى المخاطرة', _selectedChoice?.riskLevel ?? '', isWarning: _selectedChoice?.riskLevel == 'مرتفع'),
          _buildStatRow('نمط الشخصية', _selectedChoice?.profileType ?? ''),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 12.sp, fontFamily: 'Cairo')),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? Colors.redAccent : const Color(0xFFBC00FF),
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAnalytics() {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildGauge('عقلاني', _selectedChoice?.logicWeight ?? 0.5, const Color(0xFF00F2FF)),
          _buildGauge('عاطفي', 1.0 - (_selectedChoice?.logicWeight ?? 0.5), Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _buildGauge(String label, double value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50.r,
              height: 50.r,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text('${(value * 100).toInt()}%', style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 8.h),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontFamily: 'Cairo')),
      ],
    );
  }
}
