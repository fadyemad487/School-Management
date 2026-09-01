class StudentRankHelper {
  static String rankForPoints(int points) {
    if (points >= 1500) return 'البطل الأسطوري الماسي 💎';
    if (points >= 1000) return 'حارس النوايا الذهبي 🥇';
    if (points >= 500) return 'ناشر السلام الفضي 🥈';
    return 'البطل الصغير الناشئ 🥉';
  }

  static String shortRankForPoints(int points) {
    if (points >= 1500) return 'أسطورة المجرة';
    if (points >= 1000) return 'حارس النوايا';
    if (points >= 500) return 'ناشر السلام';
    return 'مجند كوني';
  }
}
