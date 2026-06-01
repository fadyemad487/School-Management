import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationNotifier extends ChangeNotifier {
  static final NotificationNotifier _instance = NotificationNotifier._internal();
  factory NotificationNotifier() => _instance;
  NotificationNotifier._internal() {
    _loadUnreadCount();
  }

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Future<void> _loadUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    _unreadCount = prefs.getInt('unread_notifications_count') ?? 0;
    notifyListeners();
  }

  Future<void> increment() async {
    _unreadCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_notifications_count', _unreadCount);
    notifyListeners();
  }

  Future<void> setUnreadCount(int count) async {
    _unreadCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_notifications_count', _unreadCount);
    notifyListeners();
  }

  Future<void> clear() async {
    _unreadCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_notifications_count', 0);
    notifyListeners();
  }
}
