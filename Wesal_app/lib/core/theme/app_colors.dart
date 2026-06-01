import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryBg = Color(0xFFEFF6FF);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFFEFF6FF);

  // Green (success / present)
  static const Color green = Color(0xFF22C55E);
  static const Color greenLight = Color(0xFFDCFCE7);

  // Orange (warning / late)
  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFFF7ED);

  // Red (danger / absent)
  static const Color red = Color(0xFFEF4444);
  static const Color redLight = Color(0xFFFEF2F2);

  // Purple (grades)
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFF5F3FF);

  // Teal (messages)
  static const Color teal = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFFF0FDFA);

  // Colors from the new design
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFFECFDF5);
  static const Color rose = Color(0xFFF43F5E);
  static const Color roseLight = Color(0xFFFFF1F2);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFFFBEB);
  static const Color slate = Color(0xFF64748B);
  static const Color slateLight = Color(0xFFF1F5F9);
  static const Color slateDark = Color(0xFF0F172A);

  // Backgrounds & Neutrals
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMedium = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFFCBD5E1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
