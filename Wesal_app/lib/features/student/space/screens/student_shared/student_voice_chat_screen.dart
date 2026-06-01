/*
🎙️ اسم الملف: student_voice_chat_screen.dart

📌 بيعمل إيه؟
شاشة محادثة صوتية كاملة على طراز ChatGPT Voice Mode.
الطالب يضغط على زر الميكروفون فيتكلم، الـ AI يسمعه ويرد عليه صوتياً.

💡 الفكرة:
تجربة محادثة صوتية غامرة مع رفيق الفضاء (Space Buddy) - orb متحرك + حالات بصرية مختلفة.
*/

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../../../services/student_ai_service.dart';

enum VoiceChatState { idle, listening, thinking, speaking }

class StudentVoiceChatScreen extends StatefulWidget {
  final bool isGroupB;
  const StudentVoiceChatScreen({super.key, this.isGroupB = false});

  @override
  State<StudentVoiceChatScreen> createState() => _StudentVoiceChatScreenState();
}

class _StudentVoiceChatScreenState extends State<StudentVoiceChatScreen>
    with TickerProviderStateMixin {
  // ── Colors ──
  static const Color primaryCyan = Color(0xFF00F2FF);
  static const Color primaryPurple = Color(0xFFBC00FF);
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryPurpleA = Color(0xFF9C27B0);

  // ── State ──
  VoiceChatState _state = VoiceChatState.idle;
  String _displayText = '';
  String _lastResponse = '';
  final List<Map<String, dynamic>> _history = [];

  // ── Services ──
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final StudentAiService _aiService = StudentAiService();
  bool _speechAvailable = false;

  // ── Animations ──
  late AnimationController _orbController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  Color get _primary => widget.isGroupB ? primaryCyan : primaryBlue;
  Color get _secondary => widget.isGroupB ? primaryPurple : primaryPurpleA;

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initServices();
  }

  Future<void> _initServices() async {
    // Configure iOS Audio Session to playAndRecord to avoid microphone lockouts
    try {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
      );
    } catch (e) {
      debugPrint("TTS iOS Audio Category Error: $e");
    }

    // TTS setup
    await _tts.setLanguage("ar");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);

    _tts.setCompletionHandler(() {
      if (mounted && _state == VoiceChatState.speaking) {
        setState(() {
          _state = VoiceChatState.idle;
          _displayText = 'اضغط على الزر للتحدث...';
        });
      }
    });

    // STT setup
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'notListening' || status == 'done') && mounted) {
            if (_state == VoiceChatState.listening) {
              _onListeningDone();
            }
          }
        },
        onError: (error) {
          debugPrint('STT Error: $error');
          if (mounted) {
            setState(() {
              _state = VoiceChatState.idle;
              _displayText = 'حصل خطأ، جرّب تاني...';
            });
          }
        },
      );
    } catch (e) {
      debugPrint("STT Init Error: $e");
    }

    // Greet
    setState(() {
      _displayText = 'أهلاً بك! اضغط على الزر للتحدث 🚀';
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _speakAndShow(widget.isGroupB
            ? 'مرحباً يا بطل! أنا رفيقك في الفضاء. اضغط على الزر وقولي أي حاجة!'
            : 'أهلاً يا بطل المجرة! أنا رفيقك الفضائي. اضغط على الزر واتكلم معايا!');
      }
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  // ── Core Flow ──

  void _toggleListening() async {
    if (_state == VoiceChatState.listening) {
      await _speech.stop();
      _onListeningDone();
      return;
    }

    // Always ensure TTS is stopped and give iOS audio system a small break to switch routes
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 350));

    if (!_speechAvailable) {
      // Try initializing one more time if not available
      try {
        _speechAvailable = await _speech.initialize();
      } catch (_) {}
    }

    if (!_speechAvailable) {
      setState(() {
        _displayText = 'الميكروفون غير متاح. تأكد من الصلاحيات.';
      });
      return;
    }

    setState(() {
      _state = VoiceChatState.listening;
      _displayText = 'بسمعك...';
    });

    await _speech.listen(
      localeId: "ar-EG",
      onResult: (result) {
        if (mounted) {
          setState(() {
            _displayText = result.recognizedWords.isNotEmpty
                ? result.recognizedWords
                : 'بسمعك...';
          });
        }
      },
    );
  }

  void _onListeningDone() {
    final recognizedText = _displayText;
    if (recognizedText.isEmpty ||
        recognizedText == 'بسمعك...' ||
        recognizedText == 'اضغط على الزر للتحدث...') {
      setState(() {
        _state = VoiceChatState.idle;
        _displayText = 'مسمعتش حاجة... جرّب تاني!';
      });
      return;
    }

    setState(() {
      _state = VoiceChatState.thinking;
      _displayText = 'بفكر...';
    });

    _sendToAi(recognizedText);
  }

  Future<void> _sendToAi(String userMsg) async {
    _history.add({
      'role': 'user',
      'parts': [{'text': userMsg}],
    });

    try {
      final response = await _aiService.chat(
        message: userMsg,
        history: _history,
      );

      _history.add({
        'role': 'model',
        'parts': [{'text': response}],
      });

      if (mounted) {
        _speakAndShow(response);
      }
    } catch (_) {
      if (mounted) {
        _speakAndShow('عذراً يا بطل، حصل مشكلة بسيطة. جرّب تاني!');
      }
    }
  }

  Future<void> _speakAndShow(String text) async {
    setState(() {
      _state = VoiceChatState.speaking;
      _lastResponse = text;
      _displayText = text;
    });

    String cleanText = text
        .replaceAll(RegExp(r'[^\w\s\u0621-\u064A\u0660-\u0669.,!?؟،]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleanText.isEmpty) cleanText = text;

    await _tts.speak(cleanText);
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF020412),
        body: Stack(
          children: [
            // Animated Background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _orbController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _VoiceBgPainter(
                      animValue: _orbController.value,
                      primary: _primary,
                      secondary: _secondary,
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: Colors.white, size: 28.sp),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          'المحادثة الصوتية',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const Spacer(),
                        SizedBox(width: 48.w),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ─── Central Orb ───
                  _buildOrb(),

                  SizedBox(height: 40.h),

                  // ─── Display Text ───
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _displayText,
                        key: ValueKey(_displayText),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16.sp,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ─── State Label ───
                  Text(
                    _stateLabel,
                    style: TextStyle(
                      color: _primary.withValues(alpha: 0.7),
                      fontSize: 12.sp,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ─── Mic Button ───
                  _buildMicButton(),

                  SizedBox(height: 50.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _stateLabel {
    switch (_state) {
      case VoiceChatState.idle:
        return 'جاهز';
      case VoiceChatState.listening:
        return '🎙️ بسمعك...';
      case VoiceChatState.thinking:
        return '🧠 بفكر...';
      case VoiceChatState.speaking:
        return '🔊 بتكلم...';
    }
  }

  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbController, _pulseController, _waveController]),
      builder: (context, _) {
        double orbSize = 180.w;
        double pulseScale = 1.0;
        double glowIntensity = 0.3;

        switch (_state) {
          case VoiceChatState.idle:
            pulseScale = 1.0 + (_pulseController.value * 0.03);
            glowIntensity = 0.2;
            break;
          case VoiceChatState.listening:
            pulseScale = 1.0 + (_pulseController.value * 0.12);
            glowIntensity = 0.6;
            break;
          case VoiceChatState.thinking:
            pulseScale = 1.0 + (math.sin(_waveController.value * math.pi * 2) * 0.06);
            glowIntensity = 0.4;
            break;
          case VoiceChatState.speaking:
            pulseScale = 1.0 + (math.sin(_waveController.value * math.pi * 4) * 0.08);
            glowIntensity = 0.55;
            break;
        }

        return Transform.scale(
          scale: pulseScale,
          child: Container(
            width: orbSize,
            height: orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                startAngle: _orbController.value * math.pi * 2,
                colors: [
                  _primary,
                  _secondary,
                  _primary.withValues(alpha: 0.6),
                  _secondary.withValues(alpha: 0.8),
                  _primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: glowIntensity),
                  blurRadius: 60 + (glowIntensity * 40),
                  spreadRadius: 10 + (glowIntensity * 20),
                ),
                BoxShadow(
                  color: _secondary.withValues(alpha: glowIntensity * 0.5),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0A0E21).withValues(alpha: 0.9),
                    const Color(0xFF020412),
                  ],
                ),
              ),
              child: Center(
                child: _buildOrbIcon(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrbIcon() {
    IconData icon;
    double size = 50.sp;
    Color color = Colors.white;

    switch (_state) {
      case VoiceChatState.idle:
        icon = Icons.mic_none_rounded;
        color = Colors.white60;
        break;
      case VoiceChatState.listening:
        icon = Icons.mic_rounded;
        color = Colors.redAccent;
        size = 55.sp;
        break;
      case VoiceChatState.thinking:
        return SizedBox(
          width: 40.r,
          height: 40.r,
          child: CircularProgressIndicator(
            color: _primary,
            strokeWidth: 3,
          ),
        );
      case VoiceChatState.speaking:
        icon = Icons.volume_up_rounded;
        color = _primary;
        size = 50.sp;
        break;
    }

    return Icon(icon, color: color, size: size);
  }

  Widget _buildMicButton() {
    final bool isActive = _state == VoiceChatState.listening;
    final Color btnColor = isActive ? Colors.redAccent : _primary;

    return GestureDetector(
      onTap: _state == VoiceChatState.thinking ? null : _toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isActive ? 80.w : 70.w,
        height: isActive ? 80.w : 70.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: btnColor.withValues(alpha: 0.15),
          border: Border.all(color: btnColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: btnColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isActive ? Icons.stop_rounded : Icons.mic_rounded,
          color: btnColor,
          size: isActive ? 36.sp : 32.sp,
        ),
      ),
    );
  }
}

// ── Background Painter ──
class _VoiceBgPainter extends CustomPainter {
  final double animValue;
  final Color primary, secondary;
  _VoiceBgPainter({required this.animValue, required this.primary, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;

    double spacing = 60;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Floating particles
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double phase = random.nextDouble() * math.pi * 2;
      double yOffset = math.sin(animValue * math.pi * 2 + phase) * 15;
      double opacity = 0.05 + (math.sin(animValue * math.pi * 2 + phase) + 1) / 2 * 0.1;

      canvas.drawCircle(
        Offset(x, y + yOffset),
        1.5 + random.nextDouble() * 1.5,
        dotPaint..color = primary.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceBgPainter old) => old.animValue != animValue;
}
