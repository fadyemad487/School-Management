import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../core/utils/profile_notifier.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  
  // User profile and active school context
  String? _schoolName;
  String? _schoolCode;
  String? _schoolId;
  String? _userRole;
  String? _fullName;
  String? _token;
  String? _userPhoto;

  bool get isLoading => _isLoading;
  String? get schoolName => _schoolName;
  String? get schoolCode => _schoolCode;
  String? get userRole => _userRole;
  String? get fullName => _fullName;
  String? get userPhoto => _userPhoto;
  bool get isAuthenticated => _token != null;

  AuthService() {
    _loadSession();
  }

  // Load existing session from storage if it exists
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _schoolId = prefs.getString('school_id');
    _schoolName = prefs.getString('school_name');
    _schoolCode = prefs.getString('school_code');
    _userRole = prefs.getString('user_role');
    _fullName = prefs.getString('user_fullname');
    _userPhoto = prefs.getString('user_photo');
    ApiClient.setCurrentUserId(prefs.getString('user_id'));
    if (_userRole == 'PARENT') {
      ProfileNotifier.parentPhoto.value = _userPhoto;
      ProfileNotifier.parentName.value = _fullName;
    }
    notifyListeners();
  }

  // Perform internet login request directly to Express SaaS backend
  Future<Map<String, dynamic>> login(String loginId, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.client.post('/auth/mobile/login', data: {
        'loginId': loginId,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        _token = data['token'];
        final school = data['school'];
        final user = data['user'];

        // Persist session parameters locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('school_id', school['id']);
        await prefs.setString('school_name', school['name']);
        await prefs.setString('school_code', school['code']);
        await prefs.setString('user_role', user['role']);
        await prefs.setString('user_fullname', user['fullName']);
        await prefs.setString('user_id', user['id'] ?? '');
        ApiClient.setCurrentUserId(user['id'] ?? '');
        await prefs.setBool('remember_me', rememberMe);

        if (user['photo'] != null) {
          await prefs.setString('user_photo', user['photo']);
          _userPhoto = user['photo'];
          if (user['role'] == 'PARENT') {
            ProfileNotifier.parentPhoto.value = user['photo'];
            ProfileNotifier.parentName.value = user['fullName'];
          } else if (user['role'] == 'STUDENT') {
            await prefs.setString('student_profile_image', user['photo']);
          }
        } else {
          await prefs.remove('user_photo');
          _userPhoto = null;
          if (user['role'] == 'PARENT') {
            ProfileNotifier.parentPhoto.value = null;
          }
        }

        if (user['role'] == 'STUDENT') {
          if (user['studentId'] != null) {
            await prefs.setString('student_id', user['studentId'].toString());
          }
          await prefs.setInt('student_points', user['points'] ?? 0);
          await prefs.setInt('student_g1_lvl', user['game1Lvl'] ?? 1);
          await prefs.setInt('student_g2_lvl', user['game2Lvl'] ?? 1);
          await prefs.setInt('student_g3_lvl', user['game3Lvl'] ?? 1);
          await prefs.setInt('student_g4_lvl', user['game4Lvl'] ?? 1);
          await prefs.setInt('student_g5_lvl', user['game5Lvl'] ?? 1);
        }

        _schoolId = school['id'];
        _schoolName = school['name'];
        _schoolCode = school['code'];
        _userRole = user['role'];
        _fullName = user['fullName'];

        _isLoading = false;
        notifyListeners();
        
        // Connect to global Real-time service after successful login
        await SocketService().connect();
        
        return {'success': true, 'role': _userRole};
      }
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      
      final String errorMsg = e.response?.data?['message'] ?? 'فشل الاتصال بالخادم، يرجى المحاولة لاحقاً';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': 'البيانات المدخلة غير صحيحة'};
  }

  // Perform social login request to Express SaaS backend
  Future<Map<String, dynamic>> socialLogin(String provider, String email, String socialId, {bool rememberMe = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.client.post('/auth/mobile/social-login', data: {
        'provider': provider,
        'socialId': socialId,
        'email': email,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        _token = data['token'];
        final school = data['school'];
        final user = data['user'];

        // Persist session parameters locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('school_id', school['id']);
        await prefs.setString('school_name', school['name']);
        await prefs.setString('school_code', school['code']);
        await prefs.setString('user_role', user['role']);
        await prefs.setString('user_fullname', user['fullName']);
        await prefs.setString('user_id', user['id'] ?? '');
        await prefs.setBool('remember_me', rememberMe);

        if (user['photo'] != null) {
          await prefs.setString('user_photo', user['photo']);
          _userPhoto = user['photo'];
          if (user['role'] == 'PARENT') {
            ProfileNotifier.parentPhoto.value = user['photo'];
            ProfileNotifier.parentName.value = user['fullName'];
          }
        } else {
          await prefs.remove('user_photo');
          _userPhoto = null;
          if (user['role'] == 'PARENT') {
            ProfileNotifier.parentPhoto.value = null;
          }
        }

        _schoolId = school['id'];
        _schoolName = school['name'];
        _schoolCode = school['code'];
        _userRole = user['role'];
        _fullName = user['fullName'];

        _isLoading = false;
        notifyListeners();
        
        await SocketService().connect();
        
        return {'success': true, 'role': _userRole};
      }
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      
      final String errorMsg = e.response?.data?['message'] ?? 'فشل الاتصال بالخادم، يرجى المحاولة لاحقاً';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': 'البيانات المدخلة غير صحيحة'};
  }

  /// Whether the app still has a stored auth token (user not logged out).
  static Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  // Check if user chose "Remember Me" and has a valid session
  static Future<bool> isRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final token = prefs.getString('auth_token');
    return rememberMe && token != null && token.isNotEmpty;
  }

  // Get the remembered user's role for routing
  static Future<String?> getRememberedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // Clear session data on logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('school_id');
    await prefs.remove('school_name');
    await prefs.remove('school_code');
    await prefs.remove('user_role');
    await prefs.remove('user_fullname');
    await prefs.remove('user_id');
    await prefs.remove('remember_me');
    await prefs.remove('use_biometrics');
    await prefs.remove('user_photo');
    await prefs.remove('student_profile_image');
    
    ProfileNotifier.parentPhoto.value = null;
    ProfileNotifier.parentName.value = null;
    ProfileNotifier.parentEmail.value = null;
    ProfileNotifier.parentPhone.value = null;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    // Disconnect global Real-time service
    SocketService().disconnect();

    _token = null;
    _schoolId = null;
    _schoolName = null;
    _schoolCode = null;
    _userRole = null;
    _fullName = null;
    _userPhoto = null;
    notifyListeners();
  }

  // Update mobile password (for any authenticated mobile credential)
  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.client.post('/auth/mobile/change-password', data: {
        'newPassword': newPassword,
      });

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': response.data['message'] ?? 'تم تغيير كلمة المرور بنجاح'};
      }
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      final String errorMsg = e.response?.data?['message'] ?? 'فشل تغيير كلمة المرور، يرجى المحاولة لاحقاً';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': 'حدث خطأ أثناء تغيير كلمة المرور'};
  }
}
