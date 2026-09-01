import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app_theme.dart';

class HomeTaskScreen extends StatefulWidget {
  const HomeTaskScreen({super.key});

  @override
  State<HomeTaskScreen> createState() => _HomeTaskScreenState();
}

class _HomeTaskScreenState extends State<HomeTaskScreen> {
  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'إرسال تقرير المذاكرة',
      'status': 'جاهزة',
      'icon': '📝',
      'color': AppTheme.royalBlue,
    },
    {
      'title': 'تنظيف محطة النوم',
      'status': 'مهمة عاجلة',
      'icon': '🧹',
      'color': AppTheme.vibrantOrange,
    },
    {
      'title': 'مراجعة وقود الرياضيات',
      'status': 'مكتملة',
      'icon': '🔢',
      'color': AppTheme.emeraldGreen,
      'done': true,
    },
  ];

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
            'مهام الأرض (البيت)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView.separated(
          padding: EdgeInsets.all(24.r),
          itemCount: _tasks.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final t = _tasks[index];
            bool isDone = t['done'] ?? false;
            return Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: isDone
                      ? AppTheme.emeraldGreen.withValues(alpha: 0.3)
                      : Colors.white10,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: (t['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        t['icon'],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['title'],
                          style: TextStyle(
                            color: isDone ? Colors.white38 : Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          t['status'],
                          style: TextStyle(
                            color: isDone
                                ? Colors.white24
                                : AppTheme.accentGold,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isDone)
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white24,
                      ),
                      onPressed: () => setState(() => t['done'] = true),
                    )
                  else
                    const Icon(
                      Icons.verified_rounded,
                      color: AppTheme.emeraldGreen,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
