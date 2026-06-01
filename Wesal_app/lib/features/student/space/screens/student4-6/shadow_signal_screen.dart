import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ShadowGameState { idle, observation, selection, success, failure }

class SignalNode {
  final int id;
  final IconData icon;
  final Color color;
  bool isTarget;
  Offset position;

  SignalNode({
    required this.id,
    required this.icon,
    required this.color,
    this.isTarget = false,
    required this.position,
  });
}

class ShadowSignalScreen extends StatefulWidget {
  const ShadowSignalScreen({super.key});

  @override
  State<ShadowSignalScreen> createState() => _ShadowSignalScreenState();
}

class _ShadowSignalScreenState extends State<ShadowSignalScreen>
    with TickerProviderStateMixin {
  ShadowGameState _gameState = ShadowGameState.idle;
  int _currentLevel = 1;
  int _score = 0;
  int _streak = 0;
  double _timerProgress = 1.0;
  Timer? _gameTimer;

  List<SignalNode> _nodes = [];
  SignalNode? _targetNode;
  
  late AnimationController _scannerController;
  late AnimationController _glitchController;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _glitchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    
    Future.delayed(const Duration(milliseconds: 800), () => _startNewRound());
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _scannerController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  void _startNewRound() {
    _gameTimer?.cancel();
    setState(() {
      _gameState = ShadowGameState.observation;
      _timerProgress = 1.0;
      _generateNodes();
    });

    // Duration of visibility depends on level
    double visibleTime = 3.0 - (_currentLevel * 0.3);
    if (visibleTime < 0.8) visibleTime = 0.8;

    Future.delayed(Duration(milliseconds: (visibleTime * 1000).toInt()), () {
      if (!mounted) return;
      setState(() => _gameState = ShadowGameState.selection);
      _startCountdown();
    });
  }

  void _generateNodes() {
    _nodes = [];
    int nodeCount = 4 + (_currentLevel ~/ 2);
    if (nodeCount > 12) nodeCount = 12;

    List<IconData> icons = [
      Icons.bolt_rounded,
      Icons.auto_awesome_rounded,
      Icons.language_rounded,
      Icons.security_rounded,
      Icons.psychology_rounded,
      Icons.radar_rounded,
      Icons.rocket_launch_rounded,
    ];

    List<Color> colors = [
      const Color(0xFF00F2FF),
      const Color(0xFFBC00FF),
      Colors.greenAccent,
      Colors.amberAccent,
    ];

    // Create target node first
    _targetNode = SignalNode(
      id: 0,
      icon: icons[_random.nextInt(icons.length)],
      color: colors[_random.nextInt(colors.length)],
      isTarget: true,
      position: Offset.zero,
    );
    _nodes.add(_targetNode!);

    // Create decoys
    for (int i = 1; i < nodeCount; i++) {
      _nodes.add(SignalNode(
        id: i,
        icon: icons[_random.nextInt(icons.length)],
        color: colors[_random.nextInt(colors.length)],
        isTarget: false,
        position: Offset.zero,
      ));
    }
    
    _nodes.shuffle();
  }



  void _startCountdown() {
    const duration = Duration(milliseconds: 50);
    double totalTime = 5.0 - (_currentLevel * 0.2);
    if (totalTime < 2.0) totalTime = 2.0;
    double decrement = duration.inMilliseconds / (totalTime * 1000);

    _gameTimer = Timer.periodic(duration, (timer) {
      if (!mounted) return;
      setState(() {
        _timerProgress -= decrement;
        if (_timerProgress <= 0) {
          _timerProgress = 0;
          _handleFailure();
        }
      });
    });
  }

  void _onNodeTap(SignalNode node) {
    if (_gameState != ShadowGameState.selection) return;

    if (node.id == _targetNode?.id) {
      _handleSuccess();
    } else {
      _handleFailure();
    }
  }

  void _handleSuccess() {
    _gameTimer?.cancel();
    setState(() {
      _gameState = ShadowGameState.success;
      _score += 100 + (_streak * 20);
      _streak++;
    });

    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _currentLevel++;
      _startNewRound();
    });
  }

  void _handleFailure() {
    _gameTimer?.cancel();
    _glitchController.forward(from: 0);
    setState(() {
      _gameState = ShadowGameState.failure;
      _streak = 0;
    });

    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _startNewRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020412),
      body: Stack(
        children: [
          _buildCyberBackground(),
          _buildGlitchOverlay(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildMissionStatus(),
                Expanded(
                  child: _buildSignalField(),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020412), Color(0xFF0A0E21)],
        ),
      ),
      child: Stack(
        children: [
          // Grid Effect
          Opacity(
            opacity: 0.05,
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: GridPainter(),
            ),
          ),
          // Scanner Beam
          AnimatedBuilder(
            animation: _scannerController,
            builder: (context, child) {
              return Positioned(
                top: _scannerController.value * 1.sh,
                left: 0,
                right: 0,
                child: Container(
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F2FF).withValues(alpha: 0.3),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00F2FF).withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlitchOverlay() {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        if (_glitchController.value == 0) return const SizedBox.shrink();
        return Container(
          color: Colors.red.withValues(alpha: 0.1 * (1 - _glitchController.value)),
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
                'إشارة الظل',
                style: TextStyle(
                  color: const Color(0xFF00F2FF),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'SHADOW SIGNAL PROTOCOL',
                style: TextStyle(color: Colors.white38, fontSize: 10.sp, letterSpacing: 1),
              ),
            ],
          ),
          _buildStreakMeter(),
        ],
      ),
    );
  }

  Widget _buildStreakMeter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_tethering_rounded, color: Color(0xFFBC00FF), size: 16),
          SizedBox(width: 4.w),
          Text(
            '$_streak',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStatus() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStat('المستوى', '$_currentLevel'),
          _buildStat('النقاط', '$_score'),
          _buildStat('الاستقرار', '${(_timerProgress * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white24, fontSize: 10.sp, fontFamily: 'Cairo')),
        Text(value, style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSignalField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If nodes haven't been positioned for these constraints yet, do it now
        if (_nodes.isNotEmpty && _nodes[0].position == Offset.zero) {
          _repositionNodes(constraints.maxWidth, constraints.maxHeight);
        }
        
        return Stack(
          children: _nodes.map((node) => _buildNodeWidget(node)).toList(),
        );
      },
    );
  }

  void _repositionNodes(double width, double height) {
    for (var node in _nodes) {
      node.position = _getSafeRandomPosition(width, height);
    }
  }

  Offset _getSafeRandomPosition(double width, double height) {
    double nodeSize = 60.r; // Estimated node size with padding
    return Offset(
      nodeSize / 2 + _random.nextDouble() * (width - nodeSize),
      nodeSize / 2 + _random.nextDouble() * (height - nodeSize),
    );
  }

  Widget _buildNodeWidget(SignalNode node) {
    bool isTarget = node.isTarget;
    
    // In selection phase, all look the same to the user (unless they remember)
    Color displayColor = (_gameState == ShadowGameState.observation || _gameState == ShadowGameState.success || _gameState == ShadowGameState.failure) 
        ? node.color 
        : Colors.white38;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      left: node.position.dx,
      top: node.position.dy,
      child: GestureDetector(
        onTap: () => _onNodeTap(node),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: displayColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isTarget && _gameState == ShadowGameState.observation) 
                  ? const Color(0xFF00F2FF) 
                  : displayColor.withValues(alpha: 0.3),
              width: (isTarget && _gameState == ShadowGameState.observation) ? 2 : 1,
            ),
            boxShadow: [
              if (isTarget && _gameState == ShadowGameState.observation)
                BoxShadow(color: const Color(0xFF00F2FF).withValues(alpha: 0.5), blurRadius: 15),
            ],
          ),
          child: Icon(
            node.icon,
            color: (isTarget && _gameState == ShadowGameState.observation) ? const Color(0xFF00F2FF) : displayColor,
            size: 28.sp,
          ),
        ).animate(onPlay: (c) => (isTarget && _gameState == ShadowGameState.observation) ? c.repeat(reverse: true) : null)
         .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds)
         .shimmer(duration: 2.seconds, color: Colors.white12),
      ),
    );
  }

  Widget _buildFooter() {
    String message = '';
    Color msgColor = Colors.white;

    switch (_gameState) {
      case ShadowGameState.observation:
        message = 'راقب الإشارة المستهدفة بدقة...';
        msgColor = const Color(0xFF00F2FF);
        break;
      case ShadowGameState.selection:
        message = 'حدد موقع الإشارة المخفية الآن!';
        msgColor = Colors.amberAccent;
        break;
      case ShadowGameState.success:
        message = 'تم رصد الإشارة بنجاح!';
        msgColor = const Color(0xFF00FF95);
        break;
      case ShadowGameState.failure:
        message = 'فشل الرصد! تداخل في الإشارة';
        msgColor = Colors.redAccent;
        break;
      default:
        message = '';
    }

    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(color: msgColor, fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ).animate(onPlay: (c) => c.repeat()).shimmer(),
          SizedBox(height: 20.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _timerProgress,
              minHeight: 6.h,
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
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F2FF).withValues(alpha: 0.1)
      ..strokeWidth = 1;

    double step = 30.r;
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
