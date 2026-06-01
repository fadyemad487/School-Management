import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app_theme.dart';

class FocusLockScreen extends StatefulWidget {
  const FocusLockScreen({super.key});

  @override
  State<FocusLockScreen> createState() => _FocusLockScreenState();
}

class _FocusLockScreenState extends State<FocusLockScreen> {
  int _seconds = 1500; // 25 mins
  Timer? _timer;
  bool _isActive = false;

  void _startMission() {
    setState(() => _isActive = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
        _showSuccess();
      }
    });
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B0044),
        title: const Text(
          'المهمة تمت بنجاح! 🎊',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'لقد اكتملت كبسولة التركيز وحصلت على 50 كوينز.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رائع'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    int m = _seconds ~/ 60;
    int s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF03001C),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'كبسولة التركيز',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 250.w,
                    height: 250.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.skyBlue.withValues(alpha: 0.3),
                        width: 8,
                      ),
                    ),
                    child: CircularProgressIndicator(
                      value: _seconds / 1500,
                      strokeWidth: 10,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.skyBlue,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    children: [
                      const Text('👨‍🚀', style: TextStyle(fontSize: 50)),
                      Text(
                        _formatTime(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48.sp,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 60.h),
              if (!_isActive)
                ElevatedButton(
                  onPressed: _startMission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.skyBlue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(200.w, 60.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  child: const Text(
                    'Start Mission 🚀',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                )
              else
                Column(
                  children: [
                    Text(
                      'لا تغادر الكبسولة حتى تنتهي المهمة!',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.skyBlue.withValues(alpha: 0.5),
                      ),
                      strokeWidth: 2,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
