import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../main.dart';
import '../../../core/utils/notification_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  State<TeacherNotificationsScreen> createState() => _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState extends State<TeacherNotificationsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  String? _errorMsg;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await _apiClient.client.get('/notifications');
      if (response.data['success'] == true) {
        final List<dynamic> fetched = response.data['data'] ?? [];
        setState(() {
          _notifications = fetched;
          _isLoading = false;
          _errorMsg = null;
        });

        // Automatically mark all unread notifications as read!
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');
        for (int i = 0; i < fetched.length; i++) {
          final notif = fetched[i];
          final isUnread = notif['readAt'] == null && notif['recipientId'] == userId;
          if (isUnread) {
            _markAsRead(notif['id'], i);
          }
        }
        
        // Clear global unread count notifier
        await NotificationNotifier().clear();
      } else {
        setState(() {
          _errorMsg = 'FAILED_LOAD';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'FAILED_CONN';
        _isLoading = false;
      });
    }
  }

  void _setupRealtimeListener() {
    // Listen to real-time socket events for new notifications
    _socketSubscription = SocketService().onEvent.listen((eventData) async {
      final String event = eventData['event'] ?? '';
      final dynamic data = eventData['data'];

      if (event == 'notification:new' || event == 'notification:system') {
        if (mounted && data != null) {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('user_id');
          final recipientId = data['recipientId'];

          // Only insert in local list if general or targeted to this user
          if (recipientId == null || recipientId == userId) {
            setState(() {
              // Prepend the new notification to the list in real-time!
              _notifications.insert(0, data);
            });
            
            // If this screen is open, automatically mark as read!
            if (recipientId == userId) {
              _markAsRead(data['id'], 0);
              await NotificationNotifier().clear();
            }
          }
        }
      }
    });
  }

  void _showInAppNotification(dynamic notif) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final title = notif['title'] ?? (isArabic ? 'إشعار جديد' : 'New Notification');
    final message = notif['message'] ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5.w),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 12.r,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      message,
                      style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11.sp),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _markAsRead(String id, int index) async {
    try {
      final response = await _apiClient.client.post('/notifications/$id/read');
      if (response.data['success'] == true) {
        setState(() {
          if (index < _notifications.length) {
            _notifications[index]['readAt'] = DateTime.now().toIso8601String();
          }
        });
      }
    } catch (_) {}
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'ABSENCE':
        return Icons.person_off_rounded;
      case 'HOMEWORK':
        return Icons.assignment_rounded;
      case 'RESULT':
        return Icons.auto_awesome_rounded;
      case 'FEE_DUE':
        return Icons.account_balance_wallet_rounded;
      case 'BUS':
        return Icons.directions_bus_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ABSENCE':
        return AppColors.rose;
      case 'HOMEWORK':
        return AppColors.primary;
      case 'RESULT':
        return AppColors.emerald;
      case 'FEE_DUE':
        return AppColors.amber;
      case 'BUS':
        return Colors.cyan;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: appScreenBackground(context),
      appBar: AppBar(
        title: Text(
          isArabic ? 'مركز الإشعارات' : 'Notification Center',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: appScreenBackground(context),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.textDark),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppColors.primary,
        child: _buildBody(isDark, isArabic),
      ),
    );
  }

  Widget _buildBody(bool isDark, bool isArabic) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64.r, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              isArabic ? 'فشل تحميل الإشعارات' : 'Failed to load notifications',
              style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchNotifications();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            )
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 80.r, color: isDark ? Colors.white24 : Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text(
              isArabic ? 'لا توجد إشعارات حتى الآن' : 'No notifications yet',
              style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : AppColors.textMedium),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final type = notif['type'] ?? 'GENERAL';
        final isUnread = notif['readAt'] == null && notif['recipientId'] != null;
        final icon = _getTypeIcon(type);
        final color = _getTypeColor(type);
        final date = DateTime.tryParse(notif['sentAt'] ?? '') ?? DateTime.now();

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isUnread 
                  ? color.withOpacity(0.5) 
                  : (isDark ? const Color(0xFF2D2D3F) : AppColors.border),
              width: isUnread ? 1.5.w : 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 10.r,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 22.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif['title'] ?? '',
                            style: GoogleFonts.cairo(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      notif['message'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: color.withOpacity(0.2), width: 0.5.w),
                          ),
                          child: Text(
                            type.toString().replaceAll('_', ' '),
                            style: GoogleFonts.cairo(
                              fontSize: 9.sp,
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (isUnread)
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.emerald),
                                iconSize: 18.r,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _markAsRead(notif['id'], index),
                              ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
