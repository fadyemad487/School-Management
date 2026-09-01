import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../main.dart';
import 'teacher_sidebar.dart';
import 'home/teacher_home.dart';
import 'classes/teacher_classes.dart';
import 'attendance/teacher_attendance.dart';
import 'messages/teacher_messages.dart';
import 'reports/teacher_reports.dart';
import '../../core/network/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

const LinearGradient _teacherMainAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
);

class TeacherMain extends StatefulWidget {
  const TeacherMain({super.key});

  @override
  State<TeacherMain> createState() => TeacherMainState();
}

class TeacherMainState extends State<TeacherMain> {
  int _currentIndex = 0;
  int _unreadMessageCount = 0;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _setupGlobalNotificationListener();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _setupGlobalNotificationListener() {
    _socketSubscription = SocketService().onEvent.listen((eventData) async {
      final String event = eventData['event'] ?? '';
      final dynamic data = eventData['data'];

      debugPrint('⚡ [TeacherMain] Received Socket Event: $event');
      final dataStr = data.toString();
      debugPrint('⚡ [TeacherMain] Socket Data Payload: ${dataStr.length > 200 ? dataStr.substring(0, 200) + '... [TRUNCATED]' : dataStr}');

      if (event == 'notification:new' || event == 'notification:system') {
        if (mounted && data != null) {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('user_id');
          final recipientId = data['recipientId'];
          
          debugPrint('⚡ [TeacherMain] Local userId from prefs: "$userId"');
          debugPrint('⚡ [TeacherMain] Packet recipientId: "$recipientId"');

          // Only show banner alert if it is a general notification or targeted directly to this user
          if (recipientId == null || recipientId == userId) {
            debugPrint('⚡ [TeacherMain] MATCH SUCCESSFUL! Showing notification banner.');
            _showGlobalInAppNotification(data);
          } else {
            debugPrint('⚡ [TeacherMain] MATCH FAILED: recipientId "$recipientId" != local userId "$userId"');
          }
        }
      } else if (event == 'message:new') {
        // Increment unread message count
        if (mounted) {
          setState(() {
            _unreadMessageCount++;
          });
        }
      }
    });
  }

  void _clearUnreadCount() {
    setState(() {
      _unreadMessageCount = 0;
    });
  }

  void _showGlobalInAppNotification(dynamic notif) {
    if (!mounted) return;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final title = notif['title'] ?? (isArabic ? 'إشعار جديد' : 'New Notification');
    final message = notif['message'] ?? '';

    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10.h,
        left: 16.w,
        right: 16.w,
        child: Material(
          color: Colors.transparent,
          child: _TopNotificationWidget(
            title: title,
            message: message,
            color: const Color(0xFF22C55E),
            onDismiss: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      try {
        overlayEntry.remove();
      } catch (_) {}
    });
  }

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<_NavItem> _navItems = const [
    _NavItem(
      Icons.home_rounded, 
      Icons.home_outlined, 
      'الرئيسية', 
      'Home'
    ),
    _NavItem(
      Icons.trending_up_rounded, 
      Icons.trending_up_rounded, 
      'فصولي', 
      'Progress'
    ),
    _NavItem(
      Icons.qr_code_scanner_rounded, 
      Icons.qr_code_scanner_rounded, 
      'الحضور', 
      'Check In'
    ),
    _NavItem(
      Icons.bar_chart_rounded, 
      Icons.bar_chart_outlined, 
      'التقارير', 
      'Result'
    ),
    _NavItem(
      Icons.forum_rounded, 
      Icons.forum_outlined, 
      'الرسائل', 
      'Messages'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, // Extends body under the curved bottom navigation bar
      drawer: isArabic ? null : TeacherSidebar(
        currentIndex: _currentIndex,
        onTabSelected: (index) => setState(() => _currentIndex = index),
      ),
      endDrawer: isArabic ? TeacherSidebar(
        currentIndex: _currentIndex,
        onTabSelected: (index) => setState(() => _currentIndex = index),
      ) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TeacherHome(),
          TeacherClasses(),
          TeacherAttendance(),
          TeacherReports(),
          TeacherMessages(onConversationOpened: _clearUnreadCount),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70.h,
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = i == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = i;
                      // Reset unread count when entering messages
                      if (i == 4 && _unreadMessageCount > 0) {
                        _unreadMessageCount = 0;
                      }
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          AnimatedScale(
                            scale: selected ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            child: selected
                                ? _GradientIcon(icon: item.activeIcon, size: 24.r)
                                : Icon(
                                    item.icon,
                                    color: isDark ? const Color(0xFFA0A0C0) : const Color(0xFF94A3B8),
                                    size: 24.r,
                                  ),
                          ),
                          if (i == 4 && _unreadMessageCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  _unreadMessageCount > 9 ? '9+' : _unreadMessageCount.toString(),
                                  style: GoogleFonts.cairo(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: selected
                            ? Column(
                                children: [
                                  SizedBox(height: 2.h),
                                  Text(
                                    isArabic ? item.labelAr : item.labelEn,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  )._withTeacherGradient(),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const _GradientIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => _teacherMainAccentGradient.createShader(bounds),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

extension _TeacherGradientText on Widget {
  Widget _withTeacherGradient() {
    return ShaderMask(
      shaderCallback: (bounds) => _teacherMainAccentGradient.createShader(bounds),
      child: this,
    );
  }
}

class _NavItem {
  final IconData activeIcon, icon;
  final String labelAr;
  final String labelEn;
  const _NavItem(this.activeIcon, this.icon, this.labelAr, this.labelEn);
}

class _TopNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final Color color;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.title,
    required this.message,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _dismiss,
        onPanUpdate: (details) {
          if (details.delta.dy < -5) {
            _dismiss();
          }
        },
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: widget.color.withOpacity(0.3), width: 1.5.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15.r,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: widget.color.withOpacity(0.15),
                blurRadius: 10.r,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_rounded, color: widget.color, size: 20.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.message,
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
      ),
    );
  }
}
