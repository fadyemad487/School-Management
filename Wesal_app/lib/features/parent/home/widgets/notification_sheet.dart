import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../main.dart';
import '../../../../core/utils/notification_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class NotificationSheet extends StatefulWidget {
  const NotificationSheet({super.key});

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
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
              _notifications.insert(0, data);
            });
            
            // Immediately mark it as read since sheet is active!
            if (recipientId == userId) {
              _markAsRead(data['id'], 0);
              await NotificationNotifier().clear();
            }
          }
        }
      }
    });
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121E) : AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                )
              ],
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 48.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'الإشعارات والتنبيهات' : 'Notifications & Alerts',
                      style: GoogleFonts.cairo(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : AppColors.textMedium),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ],
            ),
          ),

          // Notification List
          Expanded(
            child: _buildList(isDark, isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isDark, bool isArabic) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48.r, color: Colors.grey),
            SizedBox(height: 12.h),
            Text(
              isArabic ? 'فشل تحميل الإشعارات' : 'Failed to load notifications',
              style: GoogleFonts.cairo(fontSize: 14.sp, color: isDark ? Colors.white : AppColors.textDark),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 64.r, color: Colors.grey.shade400),
            SizedBox(height: 12.h),
            Text(
              isArabic ? 'لا توجد إشعارات حتى الآن' : 'No notifications yet',
              style: GoogleFonts.cairo(fontSize: 13.sp, color: isDark ? Colors.white54 : AppColors.textMedium),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.r),
      physics: const BouncingScrollPhysics(),
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
                              fontWeight: FontWeight.bold,
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
                            color: isDark ? Colors.white38 : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notif['message'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            type.toString().replaceAll('_', ' '),
                            style: GoogleFonts.cairo(
                              fontSize: 8.sp,
                              color: color,
                              fontWeight: FontWeight.w700,
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
