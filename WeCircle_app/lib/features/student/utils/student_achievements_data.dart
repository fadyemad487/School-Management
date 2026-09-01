import 'package:flutter/material.dart';
import '../student_game_state.dart';

class StudentAchievementBadge {
  final String id;
  final String title;
  final String icon;
  final Color color;
  final String gameId;
  final int maxLevel;

  const StudentAchievementBadge({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.gameId,
    this.maxLevel = 5,
  });
}

List<StudentAchievementBadge> studentAchievementBadges = const [
  StudentAchievementBadge(
    id: 'a1',
    title: 'صرف الغضب',
    icon: '🧘‍♂️',
    color: Color(0xFF00FF95),
    gameId: 'game1',
  ),
  StudentAchievementBadge(
    id: 'a2',
    title: 'بطل اللطف',
    icon: '🛡️',
    color: Color(0xFFFF4B8D),
    gameId: 'game2',
  ),
  StudentAchievementBadge(
    id: 'a3',
    title: 'حارس الأمانة',
    icon: '🎁',
    color: Color(0xFFFF9D00),
    gameId: 'game3',
  ),
  StudentAchievementBadge(
    id: 'a4',
    title: 'حديقة الرضا',
    icon: '🔭',
    color: Color(0xFFBC00FF),
    gameId: 'game4',
  ),
  StudentAchievementBadge(
    id: 'a5',
    title: 'تحدي الذاكرة',
    icon: '🚀',
    color: Color(0xFFFFD700),
    gameId: 'game5',
  ),
  StudentAchievementBadge(
    id: 'a6',
    title: 'بطل الأبطال',
    icon: '⭐',
    color: Color(0xFF00F2FF),
    gameId: 'legend',
    maxLevel: 1,
  ),
];

extension StudentAchievements on StudentGameState {
  int progressForBadge(StudentAchievementBadge badge) {
    if (badge.gameId == 'legend') {
      return points >= 1500 ? 1 : 0;
    }
    return getUnlockedLevel(badge.gameId).clamp(0, badge.maxLevel);
  }

  bool isBadgeLocked(StudentAchievementBadge badge) {
    if (badge.gameId == 'legend') return points < 1500;
    return getUnlockedLevel(badge.gameId) <= 1 && points < 200;
  }
}
