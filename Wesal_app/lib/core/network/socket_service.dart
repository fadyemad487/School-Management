import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/notification_notifier.dart';
import 'api_client.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  
  // Stream controller to broadcast events across the entire app
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onEvent => _eventController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getString('school_id');
    final userRole = prefs.getString('user_role');
    final userId = prefs.getString('user_id');

    if (schoolId == null) {
      debugPrint('[SocketService] Cannot connect: missing schoolId');
      return;
    }

    final socketUrl = ApiClient.baseUrl.replaceAll('/api', '');
    
    debugPrint('[SocketService] Connecting with userId: $userId, role: $userRole, schoolId: $schoolId');
    
    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({
            'schoolId': schoolId, 
            'role': userRole ?? 'USER',
            'userId': userId ?? '',
          })
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('🟢 [SocketService] Connected to Real-time Server');
    });

    _socket?.onDisconnect((_) {
      debugPrint('🔴 [SocketService] Disconnected from Real-time Server');
    });

    final eventsToListen = [
      'notification:new',
      'notification:system',
      'dashboard:update',
      'student:updated',
      'attendance:marked',
      'attendance:bulk_marked',
      'bus:attendance_updated',
      'bus:location_updated',
      'behavior:created',
      'announcement:created',
      'announcement:deleted',
      'homework:created',
      'homework:updated',
      'homework:deleted',
      'exam:results_published',
      'studentTask:created',
      'message:new',
      'conversation:updated',
    ];

    for (final event in eventsToListen) {
      _socket?.on(event, (data) async {
        debugPrint('⚡ [SocketService] Received Event: $event');
        _eventController.add({
          'event': event,
          'data': data,
        });

        if (event == 'notification:new' || event == 'notification:system' ||
            event == 'homework:created' || event == 'exam:results_published' || event == 'studentTask:created') {
          if (data != null) {
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('user_id');
            final recipientId = data['recipientId'];
            
            if (recipientId == null || recipientId == userId) {
              // Increment global unread count
              await NotificationNotifier().increment();

              // Play standard system sound & vibrate
              try {
                await SystemSound.play(SystemSoundType.click);
                await HapticFeedback.vibrate();
                await Future.delayed(const Duration(milliseconds: 150));
                await HapticFeedback.vibrate();
              } catch (_) {}
            }
          }
        }
      });
    }
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
      debugPrint('⚡ [SocketService] Emitted Event: $event with data: $data');
    } else {
      debugPrint('⚠️ [SocketService] Cannot emit: socket is not connected');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('🔴 [SocketService] Manually Disconnected');
  }
}
