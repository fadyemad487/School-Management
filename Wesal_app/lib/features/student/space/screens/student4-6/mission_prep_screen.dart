/*
🧠 اسم الملف: mission_prep_screen.dart

📌 بيعمل إيه؟
الملف ده عبارة عن لعبة "تجهيز المستكشف" اللي بتخلي الطالب يجهز شنطة الرحلة بتاعته بذكاء ويختار الأدوات الواقعية اللي هيحتاجها.

👤 موجه لمين؟
- طلاب (المرحلة من 4 لـ 6 ابتدائي)

💡 فكرته:
بيعلم الطالب مهارة التخطيط وترتيب الأولويات وإدارة الموارد المتاحة بشكل واقعي وجذاب.
*/

import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MissionItem {
  final String id;
  final String name;
  final String imagePath;
  final double weight;
  final int importance; 
  final String description;
  final List<String> solves;

  MissionItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.weight,
    required this.importance,
    required this.description,
    required this.solves,
  });
}

class MissionPrepScreen extends StatefulWidget {
  const MissionPrepScreen({super.key});

  @override
  State<MissionPrepScreen> createState() => _MissionPrepScreenState();
}

class _MissionPrepScreenState extends State<MissionPrepScreen> with TickerProviderStateMixin {
  final List<MissionItem> _availableItems = [
    MissionItem(
      id: 'ruler', 
      name: 'مسطرة', 
      imagePath: 'C:/Users/hp/.gemini/antigravity/brain/411d440e-450d-4c7c-980f-81666922e2ae/realistic_ruler_1778937775494.png', 
      weight: 0.2, importance: 4, description: 'للقياس الدقيق.', solves: ['measurement']
    ),
    MissionItem(
      id: 'ball', 
      name: 'كورة', 
      imagePath: 'C:/Users/hp/.gemini/antigravity/brain/411d440e-450d-4c7c-980f-81666922e2ae/realistic_ball_1778937790490.png', 
      weight: 0.5, importance: 3, description: 'للعب في وقت الفراغ.', solves: ['fun']
    ),
    MissionItem(
      id: 'controller', 
      name: 'ذراع بلايستيشن', 
      imagePath: 'C:/Users/hp/.gemini/antigravity/brain/411d440e-450d-4c7c-980f-81666922e2ae/realistic_ps_controller_1778937804349.png', 
      weight: 0.6, importance: 1, description: 'للتسلية الرقمية.', solves: ['gaming']
    ),
    MissionItem(
      id: 'lunchbox', 
      name: 'لانش بوكس', 
      imagePath: 'C:/Users/hp/.gemini/antigravity/brain/411d440e-450d-4c7c-980f-81666922e2ae/realistic_lunchbox_1778937818501.png', 
      weight: 1.2, importance: 10, description: 'وجبات الطاقة الأساسية.', solves: ['hunger']
    ),
    MissionItem(
      id: 'toy', 
      name: 'لعبة', 
      imagePath: 'C:/Users/hp/.gemini/antigravity/brain/411d440e-450d-4c7c-980f-81666922e2ae/realistic_nutcracker_1778937832895.png', 
      weight: 0.4, importance: 2, description: 'لعبة خشبية تقليدية.', solves: ['entertainment']
    ),
    MissionItem(
      id: 'bottle', 
      name: 'زمزمية', 
      imagePath: 'C:/Users/hp/.gemini/antigravity/brain/411d440e-450d-4c7c-980f-81666922e2ae/realistic_bottle_1778937844230.png', 
      weight: 0.8, importance: 10, description: 'مياه شرب نقية.', solves: ['thirst']
    ),
  ];

  final List<MissionItem> _selectedItems = [];
  final double _maxWeight = 5.0;

  void _toggleItem(MissionItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        double currentWeight = _selectedItems.fold(0.0, (sum, i) => sum + i.weight);
        if (currentWeight + item.weight <= _maxWeight) {
          _selectedItems.add(item);
          HapticFeedback.lightImpact();
        } else {
          _showWeightWarning();
        }
      }
    });
  }

  void _showWeightWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الوزن تجاوز الحد المسموح به! تخلص من بعض الأشياء غير الضرورية.', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF020412),
        body: Stack(
          children: [
            _buildStarsBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildStatsBar(),
                  _buildWarningBar(),
                  SizedBox(height: 30.h),
                  _buildMainBackpack(),
                  SizedBox(height: 30.h),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                      ),
                      itemCount: _availableItems.length,
                      itemBuilder: (context, index) {
                        final item = _availableItems[index];
                        final isSelected = _selectedItems.contains(item);
                        return _buildItemCard(item, isSelected);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28.sp),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              Text(
                'تجهيز المستكشف',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(width: 8.w),
              Text('🚀', style: TextStyle(fontSize: 24.sp)),
            ],
          ),
          SizedBox(width: 48.w), // To balance the back button
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F).withOpacity(0.5),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('3', 'مستوى', Icons.star_rounded, Colors.amber),
          _buildDivider(),
          _buildStatItem('1', '', Icons.local_fire_department_rounded, Colors.orange),
          _buildDivider(),
          _buildStatItem('210', '', Icons.diamond_rounded, Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color iconColor) {
    return Row(
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontFamily: 'Cairo')),
          SizedBox(width: 8.w),
        ],
        Text(value, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        SizedBox(width: 4.w),
        Icon(icon, color: iconColor, size: 20.sp),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 20.h, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildWarningBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            'احذر! هناك أشياء غير مهمة تشتت الانتباه.',
            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBackpack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220.r,
          height: 220.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        Container(
          width: 180.r,
          height: 180.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.cyanAccent.withOpacity(0.4),
                Colors.cyanAccent.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Image.file(
              File('C:/Users/hp/.gemini/antigravity/brain/411d440e-450d-4c7c-980f-81666922e2ae/realistic_backpack_icon_1778937857877.png'),
              width: 140.r,
              height: 140.r,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              '${_selectedItems.length} / 0',
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(MissionItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleItem(item),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.4),
                    Colors.purple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(
                  color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
                  width: 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 10),
                ] : [],
              ),
              child: Image.file(
                File(item.imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            item.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarsBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.5,
          colors: [Color(0xFF0A0E21), Color(0xFF020412)],
        ),
      ),
      child: Stack(
        children: List.generate(60, (index) {
          final random = math.Random();
          return Positioned(
            left: random.nextDouble() * 1.sw,
            top: random.nextDouble() * 1.sh,
            child: Container(
              width: random.nextDouble() * 2 + 0.5,
              height: random.nextDouble() * 2 + 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(random.nextDouble() * 0.7 + 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .fadeOut(duration: (random.nextInt(2000) + 1000).ms);
        }),
      ),
    );
  }
}
