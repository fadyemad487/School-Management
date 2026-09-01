import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/socket_service.dart';
import '../../core/network/api_client.dart';

class StudentGameState extends ChangeNotifier {
  final _apiClient = ApiClient();
  int _points = 0;
  final Map<String, int> _unlockedLevels = {
    'game1': 1,
    'game2': 1,
    'game3': 1,
    'game4': 1,
    'game5': 1,
  };
  String? _studentPhoto;

  int get points => _points;
  /// Student area uses light mode only.
  bool get isLightMode => true;
  String? get studentPhoto => _studentPhoto;

  Color get backgroundColor => const Color(0xFFF8FAFC);
  Color get scaffoldColor => const Color(0xFFF8FAFC);
  Color get cardColor => Colors.white;
  Color get textColor => const Color(0xFF0F172A);
  Color get subtitleColor => const Color(0xFF475569);
  Color get mutedTextColor => const Color(0xFF94A3B8);
  Color get borderColor => Colors.black.withOpacity(0.08);

  int getUnlockedLevel(String gameId) => _unlockedLevels[gameId] ?? 1;

  StudentGameState() {
    _loadState();
    _listenToSockets();
  }

  void _listenToSockets() {
    SocketService().onEvent.listen((eventData) {
      final eventName = eventData['event'];
      final data = eventData['data'];

      if (eventName == 'student:updated' && data != null) {
        debugPrint('[WS] Student state updated from server in real-time: $data');
        _points = data['points'] ?? _points;
        _unlockedLevels['game1'] = data['game1Lvl'] ?? _unlockedLevels['game1']!;
        _unlockedLevels['game2'] = data['game2Lvl'] ?? _unlockedLevels['game2']!;
        _unlockedLevels['game3'] = data['game3Lvl'] ?? _unlockedLevels['game3']!;
        _unlockedLevels['game4'] = data['game4Lvl'] ?? _unlockedLevels['game4']!;
        _unlockedLevels['game5'] = data['game5Lvl'] ?? _unlockedLevels['game5']!;

        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('student_points', _points);
          prefs.setInt('student_g1_lvl', _unlockedLevels['game1']!);
          prefs.setInt('student_g2_lvl', _unlockedLevels['game2']!);
          prefs.setInt('student_g3_lvl', _unlockedLevels['game3']!);
          prefs.setInt('student_g4_lvl', _unlockedLevels['game4']!);
          prefs.setInt('student_g5_lvl', _unlockedLevels['game5']!);
        });

        notifyListeners();
      }
    });
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _points = prefs.getInt('student_points') ?? 0;
    await prefs.setBool('is_light_mode', true);
    _studentPhoto = prefs.getString('student_profile_image');
    _unlockedLevels['game1'] = prefs.getInt('student_g1_lvl') ?? 1;
    _unlockedLevels['game2'] = prefs.getInt('student_g2_lvl') ?? 1;
    _unlockedLevels['game3'] = prefs.getInt('student_g3_lvl') ?? 1;
    _unlockedLevels['game4'] = prefs.getInt('student_g4_lvl') ?? 1;
    _unlockedLevels['game5'] = prefs.getInt('student_g5_lvl') ?? 1;
    notifyListeners();

    _syncWithBackend();
  }

  Future<void> _syncWithBackend() async {
    try {
      final response = await _apiClient.client.get('/students/mobile/game-state');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        _points = data['points'] ?? 0;
        _unlockedLevels['game1'] = data['game1Lvl'] ?? 1;
        _unlockedLevels['game2'] = data['game2Lvl'] ?? 1;
        _unlockedLevels['game3'] = data['game3Lvl'] ?? 1;
        _unlockedLevels['game4'] = data['game4Lvl'] ?? 1;
        _unlockedLevels['game5'] = data['game5Lvl'] ?? 1;
        _studentPhoto = data['photo'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('student_points', _points);
        await prefs.setInt('student_g1_lvl', _unlockedLevels['game1']!);
        await prefs.setInt('student_g2_lvl', _unlockedLevels['game2']!);
        await prefs.setInt('student_g3_lvl', _unlockedLevels['game3']!);
        await prefs.setInt('student_g4_lvl', _unlockedLevels['game4']!);
        await prefs.setInt('student_g5_lvl', _unlockedLevels['game5']!);
        if (_studentPhoto != null) {
          await prefs.setString('student_profile_image', _studentPhoto!);
        } else {
          await prefs.remove('student_profile_image');
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing game state with backend: $e');
    }
  }

  Future<void> updatePhoto(String base64Image) async {
    _studentPhoto = base64Image;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_profile_image', base64Image);
    notifyListeners();

    try {
      await _apiClient.client.post('/students/mobile/game-state', data: {
        'photo': base64Image,
      });
    } catch (e) {
      debugPrint('Error saving photo to backend: $e');
    }
  }

  Future<void> _updateBackendState() async {
    try {
      await _apiClient.client.post('/students/mobile/game-state', data: {
        'points': _points,
        'game1Lvl': _unlockedLevels['game1'],
        'game2Lvl': _unlockedLevels['game2'],
        'game3Lvl': _unlockedLevels['game3'],
        'game4Lvl': _unlockedLevels['game4'],
        'game5Lvl': _unlockedLevels['game5'],
      });
    } catch (e) {
      debugPrint('Error saving game state to backend: $e');
    }
  }

  Future<void> refreshState() async {
    await _loadState();
  }

  Future<void> addPoints(int amount) async {
    _points += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('student_points', _points);

    final studentId = prefs.getString('student_id') ?? prefs.getString('user_fullname') ?? 'unknown';
    final schoolId = prefs.getString('school_id') ?? 'unknown';

    SocketService().emit('student_points_updated', {
      'studentId': studentId,
      'schoolId': schoolId,
      'points': _points,
      'earned': amount,
    });

    await _updateBackendState();
    notifyListeners();
  }

  Future<void> unlockNextLevel(String gameId) async {
    int current = _unlockedLevels[gameId] ?? 1;
    _unlockedLevels[gameId] = current + 1;

    final prefs = await SharedPreferences.getInstance();
    final prefKey = gameId == 'game1'
        ? 'student_g1_lvl'
        : gameId == 'game2'
            ? 'student_g2_lvl'
            : gameId == 'game3'
                ? 'student_g3_lvl'
                : gameId == 'game4'
                    ? 'student_g4_lvl'
                    : 'student_g5_lvl';
    await prefs.setInt(prefKey, current + 1);

    await _updateBackendState();
    notifyListeners();
  }
}
