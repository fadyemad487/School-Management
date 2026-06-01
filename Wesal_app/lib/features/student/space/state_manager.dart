import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight state for student space UI (avatar, grade band).
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal() {
    loadSettings();
  }

  static const String keyGradeBand = 'student_grade_band';
  static const String keyAvatar = 'student_space_avatar';

  final ValueNotifier<String> selectedStudentAvatar = ValueNotifier<String>('🚀');
  final ValueNotifier<String> selectedGradeLevel = ValueNotifier<String>('1-3');

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    selectedGradeLevel.value = prefs.getString(keyGradeBand) ?? '1-3';
    selectedStudentAvatar.value = prefs.getString(keyAvatar) ?? '🚀';
  }

  Future<void> setGradeBand(String band) async {
    selectedGradeLevel.value = band;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyGradeBand, band);
  }

  Future<void> setAvatar(String avatar) async {
    selectedStudentAvatar.value = avatar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAvatar, avatar);
  }
}
