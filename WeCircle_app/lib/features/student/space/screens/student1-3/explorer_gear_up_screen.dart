import 'dart:math' as math;
import 'dart:ui';
/*
🧠 اسم الملف: explorer_gear_up_screen.dart

📌 بيعمل إيه؟
شاشة "تجهيز المستكشف" اللي بتعلم الطفل إزاي يجهز نفسه وأدواته للمدرسة أو لأي مهمة جديدة.

👤 موجه لمين؟
- طلاب (المرحلة من 1 لـ 3 ابتدائي)

💡 فكرته:
تعزيز حس المسؤولية والاعتماد على النفس عند الطفل الصغير.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/student1-3/animated_space_background.dart';

class GearItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isRequired;

  GearItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isRequired,
  });
}

class ExplorerGearUpScreen extends StatefulWidget {
  const ExplorerGearUpScreen({super.key});

  @override
  State<ExplorerGearUpScreen> createState() => _ExplorerGearUpScreenState();
}

class _ExplorerGearUpScreenState extends State<ExplorerGearUpScreen> {
  int _currentLevel = 1;
  int _score = 0;
  int _combo = 0;
  bool _isSuccessAnim = false;
  bool _isBackpackShaking = false;
  Color _backpackGlow = Colors.cyanAccent;

  List<GearItem> _availableItems = [];
  int _totalRequired = 0;
  int _packedCount = 0;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _generateItemsForLevel();
  }

  void _generateItemsForLevel() {
    final rng = math.Random();
    List<GearItem> items = [];

    // Base difficulty scaling
    int requiredCount = math.min(3 + (_currentLevel - 1), 6); // Max 6 required items
    int decoyCount = _currentLevel > 1 ? math.min((_currentLevel - 1) * 2, 6) : 0; // Decoys start at lvl 2

    _totalRequired = requiredCount;
    _packedCount = 0;

    // Pool of good items (Real school items in Egyptian colloquial)
    final List<Map<String, dynamic>> goodPool = [
      {'name': 'كشكول', 'icon': Icons.menu_book_rounded, 'color': Colors.blueAccent},
      {'name': 'زمزمية', 'icon': Icons.water_drop_rounded, 'color': Colors.cyanAccent},
      {'name': 'قلم رصاص', 'icon': Icons.edit_rounded, 'color': Colors.amberAccent},
      {'name': 'لانش بوكس', 'icon': Icons.lunch_dining_rounded, 'color': Colors.greenAccent},
      {'name': 'أستيكة', 'icon': Icons.crop_portrait_rounded, 'color': Colors.pinkAccent},
      {'name': 'مسطرة', 'icon': Icons.straight_rounded, 'color': Colors.purpleAccent},
      {'name': 'مقلمة', 'icon': Icons.cases_rounded, 'color': Colors.orangeAccent},
      {'name': 'براية', 'icon': Icons.rotate_right_rounded, 'color': Colors.tealAccent},
    ];

    // Pool of bad items (decoys - Distractions)
    final List<Map<String, dynamic>> badPool = [
      {'name': 'تابلت', 'icon': Icons.tablet_mac_rounded, 'color': Colors.redAccent},
      {'name': 'حلويات', 'icon': Icons.icecream_rounded, 'color': Colors.pink},
      {'name': 'كورة', 'icon': Icons.sports_soccer_rounded, 'color': Colors.grey},
      {'name': 'لعبة', 'icon': Icons.smart_toy_rounded, 'color': Colors.amber},
      {'name': 'دراع بلايستيشن', 'icon': Icons.sports_esports_rounded, 'color': Colors.deepPurpleAccent},
    ];

    goodPool.shuffle(rng);
    badPool.shuffle(rng);

    for (int i = 0; i < requiredCount; i++) {
      final item = goodPool[i % goodPool.length];
      items.add(GearItem(
        id: 'good_$i',
        name: item['name'],
        icon: item['icon'],
        color: item['color'],
        isRequired: true,
      ));
    }

    for (int i = 0; i < decoyCount; i++) {
      final item = badPool[i % badPool.length];
      items.add(GearItem(
        id: 'bad_$i',
        name: item['name'],
        icon: item['icon'],
        color: item['color'],
        isRequired: false,
      ));
    }

    items.shuffle(rng);

    setState(() {
      _availableItems = items;
      _isSuccessAnim = false;
      _backpackGlow = Colors.cyanAccent;
    });
  }

  void _onItemDropped(GearItem item) async {
    if (item.isRequired) {
      // Success
      HapticFeedback.heavyImpact();
      setState(() {
        _packedCount++;
        _score += 20 + (_combo * 10);
        _combo++;
        _availableItems.removeWhere((i) => i.id == item.id);
        _backpackGlow = Colors.greenAccent;
      });

      if (_packedCount == _totalRequired) {
        // Level complete!
        _handleLevelComplete();
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _backpackGlow = Colors.cyanAccent);
      }
    } else {
      // Wrong item
      HapticFeedback.vibrate();
      setState(() {
        _combo = 0;
        _isBackpackShaking = true;
        _backpackGlow = Colors.redAccent;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isBackpackShaking = false;
          _backpackGlow = Colors.cyanAccent;
        });
      }
    }
  }

  void _handleLevelComplete() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSuccessAnim = true;
      _backpackGlow = Colors.amberAccent;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _currentLevel++;
      });
      _startLevel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03001C),
      body: Stack(
        children: [
          const AnimatedSpaceBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 10.h),
                _buildHUD(),
                SizedBox(height: 20.h),
                _buildLevelInfo(),
                SizedBox(height: 20.h),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: _buildBackpack(),
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  flex: 4,
                  child: _buildItemGrid(),
                ),
              ],
            ),
          ),
          if (_isSuccessAnim)
            Positioned.fill(
              child: Center(
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.amberAccent, size: 150)
                    .animate(onPlay: (c) => c.forward())
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 600.ms, curve: Curves.easeOutBack)
                    .moveY(begin: 0, end: -300, duration: 1.5.seconds, curve: Curves.easeIn)
                    .fadeOut(delay: 1.seconds, duration: 500.ms),
              ),
            ),
        ],
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'تجهيز المستكشف 🚀',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.amberAccent.withValues(alpha: 0.8), blurRadius: 15),
              ],
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amberAccent, size: 28.sp),
                    SizedBox(width: 5.w),
                    Text(
                      "مستوى $_currentLevel",
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                    ).animate(key: ValueKey(_currentLevel)).scale(duration: 300.ms),
                  ],
                ),
                Container(width: 1, height: 30.h, color: Colors.white24),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "$_combo",
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ).animate(key: ValueKey(_combo)).scale(duration: 200.ms),
                  ],
                ),
                Container(width: 1, height: 30.h, color: Colors.white24),
                Row(
                  children: [
                    Icon(Icons.diamond_rounded, color: Colors.cyanAccent, size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "$_score",
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ).animate(key: ValueKey(_score)).scale(duration: 200.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelInfo() {
    String text = "اسحب الأشياء المهمة للمدرسة وضعها في الحقيبة!";
    if (_currentLevel > 2) {
      text = "احذر! هناك أشياء غير مهمة تشتت الانتباه.";
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 24.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackpack() {
    Widget backpack = DragTarget<GearItem>(
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 180.w + (isHovering ? 20.w : 0),
          height: 180.w + (isHovering ? 20.w : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _backpackGlow.withValues(alpha: isHovering ? 0.6 : 0.2),
                _backpackGlow.withValues(alpha: isHovering ? 0.3 : 0.05),
              ],
            ),
            border: Border.all(
              color: _backpackGlow.withValues(alpha: isHovering ? 1.0 : 0.5),
              width: isHovering ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _backpackGlow.withValues(alpha: 0.4),
                blurRadius: isHovering ? 40 : 20,
                spreadRadius: isHovering ? 10 : 5,
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Placeholder for the 3D Backpack image
              Image.asset(
                'assets/images/math_asteroid.png',
                width: 120.w,
                fit: BoxFit.contain,
              ).animate(target: isHovering ? 1 : 0).scale(end: const Offset(1.1, 1.1)),
              
              // Progress text
              Positioned(
                bottom: 15.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Text(
                    "$_packedCount / $_totalRequired",
                    style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _onItemDropped(details.data);
      },
    );

    if (_isBackpackShaking) {
      backpack = backpack.animate().shakeX(duration: 400.ms, hz: 6);
    } else if (_isSuccessAnim) {
      backpack = backpack.animate().scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms).then().scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 200.ms);
    }

    return backpack;
  }

  Widget _buildItemGrid() {
    return Container(
      padding: EdgeInsets.only(top: 20.h, left: 15.w, right: 15.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(40.r), topRight: Radius.circular(40.r)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 15.w,
          mainAxisSpacing: 15.h,
        ),
        itemCount: _availableItems.length,
        itemBuilder: (context, index) {
          final item = _availableItems[index];
          return _buildDraggableItem(item).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildDraggableItem(GearItem item) {
    final Widget itemWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70.w,
          height: 70.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: item.color.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: item.color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)
            ],
          ),
          child: Center(
            child: Icon(item.icon, color: Colors.white, size: 35.sp),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          item.name,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );

    return Draggable<GearItem>(
      data: item,
      feedback: Transform.scale(
        scale: 1.2,
        child: Opacity(opacity: 0.8, child: itemWidget),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: itemWidget,
      ),
      child: itemWidget,
    );
  }
}
