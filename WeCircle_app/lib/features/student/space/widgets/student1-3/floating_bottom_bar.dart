import 'package:flutter/material.dart';
import '../../../widgets/student_bottom_nav_bar.dart';

class FloatingBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    StudentNavItem(icon: Icons.home_rounded, label: 'الرئيسية'),
    StudentNavItem(icon: Icons.explore_rounded, label: 'المهمات'),
    StudentNavItem(icon: Icons.card_giftcard_rounded, label: 'الشهادات'),
    StudentNavItem(icon: Icons.smart_toy_rounded, label: 'المساعد'),
  ];

  @override
  Widget build(BuildContext context) {
    return StudentBottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: _items,
    );
  }
}
