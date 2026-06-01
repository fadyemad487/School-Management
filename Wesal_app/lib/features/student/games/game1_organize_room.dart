import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../student_game_state.dart';
import 'dart:math';

class Game1OrganizeRoom extends StatefulWidget {
  const Game1OrganizeRoom({super.key});

  @override
  State<Game1OrganizeRoom> createState() => _Game1OrganizeRoomState();
}

class _Game1OrganizeRoomState extends State<Game1OrganizeRoom> {
  int _currentLevel = 1;
  int _score = 0;
  bool _levelComplete = false;

  final Map<String, String> _categories = {
    'toy': '📦 صندوق الألعاب',
    'clothes': '🚪 الدولاب',
    'book': '📚 المكتبة',
  };

  late List<_GameItem> _items;

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  void _loadLevel() {
    // Generate items based on level
    _items = [];
    final random = Random();
    int itemCount = 3 + (_currentLevel * 2); // gets harder
    
    final types = ['toy', 'clothes', 'book'];
    final emojis = {
      'toy': ['🧸', '🚗', '⚽', '🤖', '🧩'],
      'clothes': ['👕', '👖', '🧦', '👗', '🧥'],
      'book': ['📕', '📘', '📗', '📓', '📔'],
    };

    for (int i = 0; i < itemCount; i++) {
      String type = types[random.nextInt(types.length)];
      String emoji = emojis[type]![random.nextInt(emojis[type]!.length)];
      _items.add(_GameItem(id: i, type: type, emoji: emoji));
    }
    _levelComplete = false;
    setState(() {});
  }

  void _onItemDropped(_GameItem item, String targetType) {
    if (item.type == targetType) {
      setState(() {
        item.isPlaced = true;
        _score += 10;
      });

      if (_items.every((element) => element.isPlaced)) {
        // Level complete!
        _levelComplete = true;
        context.read<StudentGameState>().addPoints(10);
        context.read<StudentGameState>().unlockNextLevel('game1');
        _showSuccessDialog();
      }
    } else {
      // Wrong category! Minus points.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حاول مرة أخرى! هذا ليس المكان الصحيح.',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFF43F5E),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: Text(
          'أحسنت يا بطل! 🎉',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'لقد رتبت الغرفة بنجاح وكسبت ${100 * _currentLevel} نقطة!',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentLevel++;
                _loadLevel();
              });
            },
            child: Text('المستوى التالي', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'البطل المنظم - مستوى $_currentLevel',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Score Board
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نقاط اللعبة: $_score',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFC084FC),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'اسحب الأشياء لمكانها!',
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // Drop Targets (Containers)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _categories.entries.map((entry) {
                return _buildDragTarget(entry.key, entry.value);
              }).toList(),
            ),
          ),
          SizedBox(height: 48.h),

          // Draggable Items (Scattered)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Stack(
                children: _items
                    .where((item) => !item.isPlaced)
                    .map((item) => _buildDraggableItem(item))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragTarget(String type, String label) {
    return DragTarget<_GameItem>(
      onAcceptWithDetails: (details) {
        _onItemDropped(details.data, type);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100.w,
          height: 120.h,
          decoration: BoxDecoration(
            color: isHovered ? const Color(0xFF8B5CF6).withOpacity(0.3) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isHovered ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.1),
              width: isHovered ? 3 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label.split(' ')[0], // emoji
                style: TextStyle(fontSize: 40.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                label.substring(label.indexOf(' ') + 1), // text
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableItem(_GameItem item) {
    // Random initial positioning for the scattering effect
    final random = Random(item.id);
    final left = 20.w + random.nextDouble() * (1.sw - 100.w);
    final top = 20.h + random.nextDouble() * (300.h);

    return Positioned(
      left: left,
      top: top,
      child: Draggable<_GameItem>(
        data: item,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.2,
            child: Text(item.emoji, style: TextStyle(fontSize: 50.sp)),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.2,
          child: Text(item.emoji, style: TextStyle(fontSize: 50.sp)),
        ),
        child: Text(item.emoji, style: TextStyle(fontSize: 50.sp)),
      ),
    );
  }
}

class _GameItem {
  final int id;
  final String type;
  final String emoji;
  bool isPlaced;

  _GameItem({
    required this.id,
    required this.type,
    required this.emoji,
    this.isPlaced = false,
  });
}
