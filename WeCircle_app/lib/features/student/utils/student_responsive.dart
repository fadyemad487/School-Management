import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive helpers for student space UI — aligned with app design size 390×844.
abstract class StudentResponsive {
  static const Size designSize = Size(390, 844);

  static bool isCompact(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.height < 700 || size.width < 360;
  }

  static bool isVerySmall(BuildContext context) => MediaQuery.sizeOf(context).width < 340;

  static EdgeInsets screenPadding(BuildContext context) {
    final horizontal = isVerySmall(context) ? 14.w : (isCompact(context) ? 16.w : 20.w);
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  /// Total height occupied by bottom nav + system gesture area.
  static double bottomNavTotalHeight(BuildContext context) {
    return 110.h + MediaQuery.paddingOf(context).bottom;
  }

  static double scrollBottomPadding(BuildContext context) {
    return bottomNavTotalHeight(context) + 12.h;
  }

  static double missionPlanetIconSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scaled = width * 0.19;
    final clamped = scaled.clamp(52.0, 86.0);
    return isCompact(context) ? clamped * 0.92 : clamped;
  }

  static double adaptiveSp(BuildContext context, double value) {
    if (isCompact(context)) return (value * 0.92).sp;
    return value.sp;
  }
}

/// Clamps system text scaling so layouts stay stable on all phones.
class StudentResponsiveScope extends StatelessWidget {
  final Widget child;

  const StudentResponsiveScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final systemScale = mq.textScaler.scale(1.0);
    final clamped = systemScale.clamp(0.85, 1.15);

    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(clamped)),
      child: child,
    );
  }
}
