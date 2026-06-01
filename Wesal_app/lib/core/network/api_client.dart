import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/device_helper.dart';

class ApiClient {
  final Dio _dio = Dio();
  
  // Set your local server IP here.
  // 10.0.2.2 is the default IP to access localhost from the Android emulator.
  // localhost or 127.0.0.1 can be used for iOS Simulators.
  // For real device testing, use your computer's local IP (e.g., 192.168.1.x)
  static const String baseUrl = 'http://192.168.1.212:5001/api';

  ApiClient() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);

    // Multi-Tenant SaaS dynamic header interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          final schoolId = prefs.getString('school_id');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (schoolId != null) {
            // Isolates the active request to the user's specific school database partition
            options.headers['x-school-id'] = schoolId;
          }

          // Inject dynamic device name for session tracking
          try {
            final deviceName = await DeviceHelper.getDeviceName();
            options.headers['x-device-name'] = deviceName;
          } catch (_) {}

          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Handle global network or token expiration errors gracefully
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;

  // Cache user ID for chat identification
  static String? _cachedUserId;

  String? get currentUserId => _cachedUserId;

  static void setCurrentUserId(String? id) {
    _cachedUserId = id;
  }

  static Future<String?> getCurrentUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString('user_id');
    return _cachedUserId;
  }
}
