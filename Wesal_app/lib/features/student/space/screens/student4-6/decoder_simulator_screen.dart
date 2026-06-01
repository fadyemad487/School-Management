import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum DecoderGameState { idle, showingPath, playerInput, success, failure }

class DecoderSimulatorScreen extends StatefulWidget {
  const DecoderSimulatorScreen({super.key});

  @override
  State<DecoderSimulatorScreen> createState() => _DecoderSimulatorScreenState();
}

class _DecoderSimulatorScreenState extends State<DecoderSimulatorScreen>
    with TickerProviderStateMixin {
  // Game Configuration
  int _gridSize = 4;
  int _pathLength = 4;
  int _currentLevel = 1;
  int _score = 0;
  int _streak = 0;

  DecoderGameState _gameState = DecoderGameState.idle;
  List<int> _targetPath = []; // Indices of nodes in the path
  List<int> _playerPath = [];
  double _timerProgress = 1.0;
  Timer? _gameTimer;

  late AnimationController _glitchController;
  late AnimationController _gridPulseController;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _gridPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    // Start game after a short delay
    Future.delayed(const Duration(milliseconds: 800), () => _startNewLevel());
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _glitchController.dispose();
    _gridPulseController.dispose();
    super.dispose();
  }

  void _startNewLevel() {
    setState(() {
      _gameState = DecoderGameState.showingPath;
      _playerPath = [];
      _timerProgress = 1.0;
      
      // Progression logic
      if (_currentLevel > 4) _gridSize = 5;
      if (_currentLevel > 8) _gridSize = 6;
      _pathLength = 4 + (_currentLevel ~/ 3);
      
      _generatePath();
    });

    _showSequence();
  }

  void _generatePath() {
    _targetPath = [];
    math.Random random = math.Random();
    
    int lastNode = random.nextInt(_gridSize * _gridSize);
    _targetPath.add(lastNode);

    while (_targetPath.length < _pathLength) {
      int row = lastNode ~/ _gridSize;
      int col = lastNode % _gridSize;

      // Possible moves: Up, Down, Left, Right
      List<int> possibleMoves = [];
      if (row > 0) possibleMoves.add(lastNode - _gridSize);
      if (row < _gridSize - 1) possibleMoves.add(lastNode + _gridSize);
      if (col > 0) possibleMoves.add(lastNode - 1);
      if (col < _gridSize - 1) possibleMoves.add(lastNode + 1);

      // Filter out moves that would revisit the immediate previous node (to avoid back-and-forth)
      if (_targetPath.length > 1) {
        possibleMoves.removeWhere((move) => move == _targetPath[_targetPath.length - 2]);
      }

      if (possibleMoves.isEmpty) break; // Should not happen on grid
      
      int nextNode = possibleMoves[random.nextInt(possibleMoves.length)];
      _targetPath.add(nextNode);
      lastNode = nextNode;
    }
  }

  Future<void> _showSequence() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _gameState = DecoderGameState.playerInput;
    });
    
    _startCountdown();
  }

  void _startCountdown() {
    _gameTimer?.cancel();
    const duration = Duration(milliseconds: 50);
    double totalTime = 5.0 + (_pathLength * 0.5); // Time based on path length
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

  void _onNodeTap(int index) {
    if (_gameState != DecoderGameState.playerInput) return;

    setState(() {
      // Must follow order
      int expectedIndex = _playerPath.length;
      if (_targetPath[expectedIndex] == index) {
        _playerPath.add(index);
        HapticFeedback.lightImpact();
        
        if (_playerPath.length == _targetPath.length) {
          _handleSuccess();
        }
      } else {
        _handleFailure();
      }
    });
  }

  void _handleSuccess() {
    _gameTimer?.cancel();
    setState(() {
      _gameState = DecoderGameState.success;
      _score += 100 + (_streak * 20);
      _streak++;
    });

    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _currentLevel++;
      _startNewLevel();
    });
  }

  void _handleFailure() {
    _gameTimer?.cancel();
    _glitchController.forward(from: 0);
    setState(() {
      _gameState = DecoderGameState.failure;
      _streak = 0;
    });

    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      // Reset or retry logic
      _startNewLevel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020412),
      body: Stack(
        children: [
          _buildSpaceBackground(),
          _buildGlitchOverlay(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildMissionStatus(),
                const Spacer(),
                _buildDecoderGrid(),
                const Spacer(),
                _buildFooter(),
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
      child: Stack(
        children: [
          // Stars/Particles
          ...List.generate(30, (i) {
            return Positioned(
              left: math.Random().nextDouble() * 1.sw,
              top: math.Random().nextDouble() * 1.sh,
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: math.Random().nextDouble() * 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          // Ambient glows
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FF).withValues(alpha: 0.05),
              ),
            ),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'محاكي فك التشفير',
                style: TextStyle(
                  color: const Color(0xFF00F2FF),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'DECODER SIMULATOR v1.0.4',
                style: TextStyle(color: Colors.white38, fontSize: 10.sp, letterSpacing: 1),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.yellowAccent, size: 16),
                SizedBox(width: 4.w),
                Text(
                  '$_streak',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStatus() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: _buildGlassPanel(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            _buildStatusItem('المستوى', '$_currentLevel', const Color(0xFF00F2FF)),
            const Spacer(),
            _buildStatusItem('النتيجة', '$_score', const Color(0xFFBC00FF)),
            const Spacer(),
            _buildStatusItem('الاستقرار', '${(_timerProgress * 100).toInt()}%', 
              _timerProgress > 0.3 ? const Color(0xFF00FF95) : Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontFamily: 'Cairo')),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
          ),
        ),
      ],
    );
  }

  Widget _buildDecoderGrid() {
    return Container(
      width: 320.r,
      height: 320.r,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFF00F2FF).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F2FF).withValues(alpha: 0.05),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Grid lines
          CustomPaint(
            size: Size(300.r, 300.r),
            painter: GridPainter(gridSize: _gridSize, pulse: _gridPulseController.value),
          ),
          
          // Path rendering
          CustomPaint(
            size: Size(300.r, 300.r),
            painter: PathPainter(
              gridSize: _gridSize,
              targetPath: _targetPath,
              playerPath: _playerPath,
              gameState: _gameState,
            ),
          ),

          // Nodes
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _gridSize * _gridSize,
            itemBuilder: (context, index) {
              bool isInTargetPath = _gameState == DecoderGameState.showingPath && _targetPath.contains(index);
              bool isInPlayerPath = _playerPath.contains(index);

              return GestureDetector(
                onTap: () => _onNodeTap(index),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isInPlayerPath || isInTargetPath ? 20.r : 8.r,
                      height: isInPlayerPath || isInTargetPath ? 20.r : 8.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isInPlayerPath 
                            ? const Color(0xFF00F2FF) 
                            : isInTargetPath 
                                ? const Color(0xFFBC00FF) 
                                : Colors.white24,
                        boxShadow: [
                          if (isInPlayerPath || isInTargetPath)
                            BoxShadow(
                              color: isInPlayerPath ? const Color(0xFF00F2FF) : const Color(0xFFBC00FF),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    String instructionText = '';
    Color statusColor = Colors.white;

    switch (_gameState) {
      case DecoderGameState.idle:
        instructionText = 'جاري تهيئة النظام...';
        break;
      case DecoderGameState.showingPath:
        instructionText = 'لاحظ تسلسل التشفير بدقة';
        statusColor = const Color(0xFFBC00FF);
        break;
      case DecoderGameState.playerInput:
        instructionText = 'أعد رسم المسار الآن!';
        statusColor = const Color(0xFF00F2FF);
        break;
      case DecoderGameState.success:
        instructionText = 'تم فك التشفير بنجاح!';
        statusColor = const Color(0xFF00FF95);
        break;
      case DecoderGameState.failure:
        instructionText = 'فشل النظام! أعد المحاولة';
        statusColor = Colors.redAccent;
        break;
    }

    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          Text(
            instructionText,
            style: TextStyle(
              color: statusColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              letterSpacing: 1.5,
            ),
          ).animate(target: _gameState == DecoderGameState.playerInput ? 1 : 0)
           .shimmer(duration: 1.seconds),
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

  Widget _buildGlassPanel({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}

class GridPainter extends CustomPainter {
  final int gridSize;
  final double pulse;

  GridPainter({required this.gridSize, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F2FF).withValues(alpha: 0.05 + (0.05 * pulse))
      ..strokeWidth = 1;

    double stepX = size.width / (gridSize - 1);
    double stepY = size.height / (gridSize - 1);

    // Draw dots at intersections instead of lines for a cleaner HUD look
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        canvas.drawCircle(Offset(i * stepX, j * stepY), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(GridPainter old) => old.pulse != pulse;
}

class PathPainter extends CustomPainter {
  final int gridSize;
  final List<int> targetPath;
  final List<int> playerPath;
  final DecoderGameState gameState;

  PathPainter({
    required this.gridSize,
    required this.targetPath,
    required this.playerPath,
    required this.gameState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetPath.isEmpty) return;

    double stepX = size.width / (gridSize - 1);
    double stepY = size.height / (gridSize - 1);

    Offset getPos(int index) {
      int row = index ~/ gridSize;
      int col = index % gridSize;
      // In GridView, row is index / size, col is index % size
      // But we want col for X, row for Y
      return Offset(col * stepX, row * stepY);
    }

    // Draw Target Path (Only during showing phase or success/failure)
    if (gameState == DecoderGameState.showingPath || 
        gameState == DecoderGameState.success || 
        gameState == DecoderGameState.failure) {
      final targetPaint = Paint()
        ..color = (gameState == DecoderGameState.failure ? Colors.redAccent : const Color(0xFFBC00FF)).withValues(alpha: 0.4)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(getPos(targetPath[0]).dx, getPos(targetPath[0]).dy);
      for (int i = 1; i < targetPath.length; i++) {
        path.lineTo(getPos(targetPath[i]).dx, getPos(targetPath[i]).dy);
      }
      canvas.drawPath(path, targetPaint);
    }

    // Draw Player Path
    if (playerPath.isNotEmpty) {
      final playerPaint = Paint()
        ..color = const Color(0xFF00F2FF)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      final glowPaint = Paint()
        ..color = const Color(0xFF00F2FF).withValues(alpha: 0.3)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(getPos(playerPath[0]).dx, getPos(playerPath[0]).dy);
      for (int i = 1; i < playerPath.length; i++) {
        path.lineTo(getPos(playerPath[i]).dx, getPos(playerPath[i]).dy);
      }
      
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, playerPaint);
    }
  }

  @override
  bool shouldRepaint(PathPainter old) => true;
}
