import 'package:flutter/material.dart';

class ProfileNotifier {
  static final ValueNotifier<String?> parentPhoto = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> parentName = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> parentEmail = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> parentPhone = ValueNotifier<String?>(null);

  static final ValueNotifier<String?> teacherPhoto = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> teacherName = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> teacherEmail = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> teacherPhone = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> teacherJobTitle = ValueNotifier<String?>(null);
}
