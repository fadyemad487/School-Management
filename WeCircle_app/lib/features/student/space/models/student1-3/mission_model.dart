import 'package:flutter/material.dart';

class MissionModel {
  final String id;
  final String title;
  final String type; 
  final IconData? icon;
  final String? imagePath;
  final Color color;
  final bool isLocked;
  final bool isActive;
  final double progress;

  MissionModel({
    required this.id,
    required this.title,
    required this.type,
    this.icon,
    this.imagePath,
    required this.color,
    this.isLocked = false,
    this.isActive = false,
    this.progress = 0.0,
  });
}
