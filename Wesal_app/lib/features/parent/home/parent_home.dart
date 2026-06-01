import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../children/children_screen.dart';
import '../attendance/parent_attendance.dart';
import '../grades/parent_grades.dart';
import '../homework/parent_homework.dart';
import '../behavior/parent_behavior.dart';
import '../bus/parent_bus.dart';
import '../settings/parent_settings.dart';
import 'widgets/notification_sheet.dart';
import 'parent_announcements.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/utils/profile_notifier.dart';
import '../../../core/utils/notification_notifier.dart';
import 'dart:async';

class ParentHome extends StatefulWidget {
  const ParentHome({super.key});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  final ApiClient _apiClient = ApiClient();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _socketSubscription;
  bool _isLoading = true;
  String _parentName = '';
  String? _parentPhoto;
  String _dayName = '';
  String _todayFormatted = '';
  List<dynamic> _children = [];
  List<dynamic> _announcements = [];
  int _selectedChildIndex = 0;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _initSocket();
    ProfileNotifier.parentPhoto.addListener(_onPhotoChanged);
    ProfileNotifier.parentName.addListener(_onNameChanged);
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification_bell.wav'));
    } catch (e) {
      debugPrint('[ParentHome] Audio play error: $e');
    }
  }

  void _initSocket() {
    _socketSubscription = SocketService().onEvent.listen((eventData) {
      final event = eventData['event'];
      final data = eventData['data'];

      if (event == 'database:updated') {
        if (data != null &&
            (data['model'] == 'Student' ||
                data['model'] == 'Attendance' ||
                data['model'] == 'Bus' ||
                data['model'] == 'BusRoute')) {
          debugPrint('[ParentHome] Database Updated - Auto Refreshing...');
          _fetchDashboardData();
        }
      } else if (event == 'dashboard:update') {
        debugPrint(
            '[ParentHome] Transport/Attendance Dashboard Updated - Auto Refreshing...');
        _fetchDashboardData();
      } else if (event == 'announcement:created') {
        debugPrint(
            '[ParentHome] New Announcement - Playing sound and auto-refreshing...');
        _playNotificationSound();
        _fetchDashboardData();
        // Show in-app visual notification banner
        if (mounted) {
          final title = data?['title'] ?? 'إعلان جديد';
          final body = data?['body'] ?? '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.campaign_rounded,
                        color: Colors.white, size: 22.r),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📢 $title',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.sp,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (body.isNotEmpty)
                          Text(
                            body,
                            style: GoogleFonts.cairo(
                              fontSize: 11.sp,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF6366F1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r)),
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'عرض',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ParentAnnouncements(announcements: _announcements)),
                  );
                },
              ),
            ),
          );
        }
      } else if (event == 'announcement:deleted' ||
          event == 'homework:created' ||
          event == 'homework:updated' ||
          event == 'homework:deleted' ||
          event == 'exam:results_published' ||
          event == 'behavior:created' ||
          event == 'attendance:marked' ||
          event == 'attendance:bulk_marked' ||
          event == 'student:updated') {
        debugPrint('[ParentHome] Live event $event - Auto Refreshing...');
        _fetchDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _audioPlayer.dispose();
    ProfileNotifier.parentPhoto.removeListener(_onPhotoChanged);
    ProfileNotifier.parentName.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onPhotoChanged() {
    if (mounted) {
      setState(() {
        _parentPhoto = ProfileNotifier.parentPhoto.value;
      });
    }
  }

  void _onNameChanged() {
    if (mounted) {
      setState(() {
        _parentName = ProfileNotifier.parentName.value ?? _parentName;
      });
    }
  }

  ImageProvider _getProfileImageProvider(String? photo) {
    if (photo == null || photo.isEmpty) {
      return const NetworkImage(
          'https://cdn-icons-png.flaticon.com/512/149/149071.png');
    }
    if (photo.startsWith('data:image') || photo.startsWith('base64')) {
      final base64String =
          photo.contains('base64,') ? photo.split('base64,')[1] : photo;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return const NetworkImage(
            'https://cdn-icons-png.flaticon.com/512/149/149071.png');
      }
    }
    return NetworkImage(photo);
  }

  Future<void> _fetchDashboardData() async {
    try {
      final response = await _apiClient.client.get('/parents/mobile/dashboard');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _parentName = data['parentName'] ?? 'ولي الأمر';
          _parentPhoto = data['parentPhoto'];
          _dayName = data['dayName'] ?? '';
          _todayFormatted = data['todayFormatted'] ?? '';
          _children = data['children'] ?? [];
          _announcements = data['announcements'] ?? [];
          _isLoading = false;
        });
        ProfileNotifier.parentPhoto.value = data['parentPhoto'];
        ProfileNotifier.parentName.value = data['parentName'];
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

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1D4ED8),
          ),
        ),
      );
    }

    if (_errorMsg != null) {
      final errorDisplay = _errorMsg == 'FAILED_LOAD'
          ? (isArabic ? 'فشل تحميل البيانات' : 'Failed to load data')
          : (isArabic ? 'فشل الاتصال بالخادم' : 'Failed to connect to server');
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 64.r, color: AppColors.textLight),
              SizedBox(height: 16.h),
              Text(
                errorDisplay,
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMsg = null;
                  });
                  _fetchDashboardData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  isArabic ? 'إعادة المحاولة' : 'Try Again',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final selectedChild =
        _children.isNotEmpty ? _children[_selectedChildIndex] : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDashboardData();
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App bar
            SliverAppBar(
              expandedHeight: 90.h,
              floating: true,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => showParentSettingsSidebar(context),
                              child: Container(
                                width: 48.r,
                                height: 48.r,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16.r),
                                  image: DecorationImage(
                                    image:
                                        _getProfileImageProvider(_parentPhoto),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.15),
                                      blurRadius: 10.r,
                                      offset: Offset(0, 4.h),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isArabic ? 'مرحباً بك 👋' : 'Welcome back 👋',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.textMedium,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _parentName,
                                  style: GoogleFonts.cairo(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const NotificationSheet(),
                            );
                          },
                          child: Container(
                            width: 44.r,
                            height: 44.r,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color ??
                                  Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2D2D3F)
                                      : AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDark ? 0.2 : 0.03),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.h),
                                )
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.notifications_none_rounded,
                                    color: AppColors.textDark, size: 24.r),
                                ListenableBuilder(
                                  listenable: NotificationNotifier(),
                                  builder: (context, _) {
                                    final count =
                                        NotificationNotifier().unreadCount;
                                    if (count == 0)
                                      return const SizedBox.shrink();
                                    return Positioned(
                                      top: 4.h,
                                      right: 4.w,
                                      child: Container(
                                        padding: EdgeInsets.all(2.r),
                                        decoration: BoxDecoration(
                                          color: AppColors.rose,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1.r),
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 16.r,
                                          minHeight: 16.r,
                                        ),
                                        child: Center(
                                          child: Text(
                                            count > 9 ? '9+' : '$count',
                                            style: GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontSize: 7.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(16.r),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Child Switcher
                  _ChildSwitcher(
                    children: _children,
                    selectedIndex: _selectedChildIndex,
                    onSelected: (index) {
                      setState(() {
                        _selectedChildIndex = index;
                      });
                    },
                  ),
                  SizedBox(height: 20.h),

                  // Status Banner
                  _StatusBanner(
                    child: selectedChild,
                    dayName: _dayName,
                    todayFormatted: _todayFormatted,
                  ),
                  SizedBox(height: 24.h),

                  // Quick Stats
                  if (selectedChild != null) _QuickStats(child: selectedChild),
                  SizedBox(height: 24.h),

                  // Services Grid
                  _ServicesSection(children: _children),
                  SizedBox(height: 24.h),

                  // Latest Homework
                  if (selectedChild != null)
                    _LatestHomeworkSection(child: selectedChild),
                  SizedBox(height: 24.h),

                  // Announcements
                  _AnnouncementsSection(announcements: _announcements),
                  SizedBox(height: 32.h),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildSwitcher extends StatelessWidget {
  final List<dynamic> children;
  final int selectedIndex;
  final Function(int) onSelected;

  const _ChildSwitcher({
    required this.children,
    required this.selectedIndex,
    required this.onSelected,
  });

  ImageProvider _getChildImageProvider(String photo) {
    if (photo.isEmpty) {
      return const NetworkImage(
          'https://cdn-icons-png.flaticon.com/512/149/149071.png');
    }
    if (photo.startsWith('data:image') || photo.startsWith('base64')) {
      final base64String =
          photo.contains('base64,') ? photo.split('base64,')[1] : photo;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return const NetworkImage(
            'https://cdn-icons-png.flaticon.com/512/149/149071.png');
      }
    }
    return NetworkImage(photo);
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(children.length, (index) {
          final child = children[index];
          final isSelected = index == selectedIndex;
          return Padding(
            padding:
                EdgeInsets.only(left: index == children.length - 1 ? 0 : 12.w),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: _buildChildCard(
                context,
                name: (isArabic ? child['nameAr'] : child['nameEn']) ??
                    child['nameAr'] ??
                    '',
                grade: child['className'] ?? '',
                image: child['image'] ??
                    'https://images.unsplash.com/photo-1596870230751-ebdfce98ec42?w=100&h=100&fit=crop&crop=face',
                isSelected: isSelected,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChildCard(
    BuildContext context, {
    required String name,
    required String grade,
    required String image,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : (Theme.of(context).cardTheme.color ?? Colors.white),
        borderRadius: BorderRadius.circular(18.r),
        border: isSelected
            ? null
            : Border.all(
                color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image(
              image: _getChildImageProvider(image),
              width: 38.r,
              height: 38.r,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 38.r,
                height: 38.r,
                color: isDark ? const Color(0xFF2D2D3F) : AppColors.slateLight,
                child:
                    Icon(Icons.person, size: 20.r, color: AppColors.textLight),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textDark),
                ),
              ),
              Text(
                grade,
                style: GoogleFonts.cairo(
                  fontSize: 10.sp,
                  color: isSelected ? Colors.white70 : AppColors.textLight,
                ),
              ),
            ],
          ),
          if (isSelected) ...[
            SizedBox(width: 8.w),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white70, size: 18.r),
          ],
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final dynamic child;
  final String dayName;
  final String todayFormatted;

  const _StatusBanner({
    required this.child,
    required this.dayName,
    required this.todayFormatted,
  });

  @override
  Widget build(BuildContext context) {
    if (child == null) {
      return const SizedBox.shrink();
    }
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final attendance = child['attendance'];
    final String fullNameAr = child['nameAr'] ?? '';
    final String fullNameEn = child['nameEn'] ?? fullNameAr;
    final String fullName = isArabic ? fullNameAr : fullNameEn;
    final String firstName =
        fullName.trim().isNotEmpty ? fullName.trim().split(' ').first : '';
    final bool isFemale = child['gender'] == 'FEMALE';

    String statusText = isArabic
        ? (isFemale
            ? '$firstName لم تسجل حضور اليوم'
            : '$firstName لم يسجل حضور اليوم')
        : '$firstName has not checked in today';
    String timeText = isArabic
        ? 'الرجاء الانتظار لدخول المدرسة أو الباص'
        : 'Please wait for school or bus check-in';

    if (attendance != null) {
      final status = attendance['status'];
      final String timeInRaw = attendance['timeIn'] ?? '';
      final String timeIn = isArabic
          ? timeInRaw
          : timeInRaw.replaceAll('ص', 'AM').replaceAll('م', 'PM');

      if (status == 'PRESENT') {
        statusText = isArabic
            ? '$firstName في المدرسة حالياً'
            : '$firstName is currently at school';
        timeText = isArabic
            ? (isFemale
                ? 'وصلت في الساعة $timeIn ص • في الموعد'
                : 'وصل في الساعة $timeIn ص • في الموعد')
            : 'Arrived at $timeIn • On Time';
      } else if (status == 'LATE') {
        statusText = isArabic
            ? (isFemale
                ? '$firstName متأخرة عن الحضور'
                : '$firstName متأخر عن الحضور')
            : '$firstName is late today';
        timeText = isArabic
            ? (isFemale
                ? 'وصلت في الساعة $timeIn ص • متأخرة'
                : 'وصل في الساعة $timeIn ص • متأخر')
            : 'Arrived at $timeIn • Late';
      } else if (status == 'ABSENT') {
        statusText = isArabic
            ? (isFemale
                ? '$firstName غائبة عن المدرسة اليوم'
                : '$firstName غائب عن المدرسة اليوم')
            : '$firstName is absent today';
        timeText = isArabic
            ? 'تم تسجيل الغياب بواسطة المشرف'
            : 'Absent recorded by supervisor';
      } else if (status == 'EXCUSED') {
        statusText = isArabic
            ? '$firstName في إجازة معتمدة'
            : '$firstName is on excused leave';
        timeText =
            isArabic ? 'إجازة رسمية / عذر مقبول' : 'Official Leave / Excused';
      }
    }

    String translateDay(String day) {
      if (isArabic) return day;
      switch (day.trim()) {
        case 'السبت':
          return 'Saturday';
        case 'الأحد':
          return 'Sunday';
        case 'الاثنين':
          return 'Monday';
        case 'الثلاثاء':
          return 'Tuesday';
        case 'الأربعاء':
          return 'Wednesday';
        case 'الخميس':
          return 'Thursday';
        case 'الجمعة':
          return 'Friday';
        default:
          return day;
      }
    }

    String translateFormattedDate(String date) {
      if (isArabic) return date;
      return date
          .replaceAll('٠', '0')
          .replaceAll('١', '1')
          .replaceAll('٢', '2')
          .replaceAll('٣', '3')
          .replaceAll('٤', '4')
          .replaceAll('٥', '5')
          .replaceAll('٦', '6')
          .replaceAll('٧', '7')
          .replaceAll('٨', '8')
          .replaceAll('٩', '9')
          .replaceAll('يناير', 'January')
          .replaceAll('فبراير', 'February')
          .replaceAll('مارس', 'March')
          .replaceAll('أبريل', 'April')
          .replaceAll('مايو', 'May')
          .replaceAll('يونيو', 'June')
          .replaceAll('يوليو', 'July')
          .replaceAll('أغسطس', 'August')
          .replaceAll('سبتمبر', 'September')
          .replaceAll('أكتوبر', 'October')
          .replaceAll('نوفمبر', 'November')
          .replaceAll('ديسمبر', 'December');
    }

    final displayDay = translateDay(dayName);
    final displayDate = translateFormattedDate(todayFormatted);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.r,
            top: -20.r,
            child: Container(
              width: 100.r,
              height: 100.r,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'اليوم • $displayDay • $displayDate'
                            : 'Today • $displayDay • $displayDate',
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        statusText,
                        style: GoogleFonts.cairo(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        timeText,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(Icons.school_rounded,
                      color: Colors.white, size: 24.r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final dynamic child;
  const _QuickStats({required this.child});

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final attRate = child['attendanceRate']?.toString() ?? '100%';
    final pendingHw = child['pendingHomeworksCount']?.toString() ?? '0';
    final gpaGrade = child['gradeLetter']?.toString() ?? 'A';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            value: attRate,
            label: isArabic ? 'الحضور' : 'Attendance',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.emerald,
            bgColor: AppColors.emeraldLight,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ParentAttendance(child: child))),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            context,
            value: pendingHw,
            label: isArabic ? 'الواجبات' : 'Homework',
            icon: Icons.book_outlined,
            color: AppColors.orange,
            bgColor: AppColors.orangeLight,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ParentHomework(child: child))),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            context,
            value: gpaGrade,
            label: isArabic ? 'المعدل' : 'GPA',
            icon: Icons.emoji_events_outlined,
            color: AppColors.purple,
            bgColor: AppColors.purpleLight,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ParentGrades(child: child))),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2D2D3F)
                  : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(height: 10.h),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  final List<dynamic> children;
  const _ServicesSection({required this.children});

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? 'الخدمات' : 'Services',
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            Text(
              isArabic ? 'عرض الكل' : 'View All',
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildServiceItem(
              context,
              label: isArabic ? 'أطفالي' : 'Children',
              icon: Icons.people_alt_rounded,
              color: AppColors.primary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChildrenScreen())),
            ),
            _buildServiceItem(
              context,
              label: isArabic ? 'الباص' : 'Bus',
              icon: Icons.directions_bus_rounded,
              color: AppColors.teal,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ParentBus(children: children))),
            ),
            _buildServiceItem(
              context,
              label: isArabic ? 'السلوك' : 'Behavior',
              icon: Icons.sentiment_very_satisfied_rounded,
              color: AppColors.orange,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ParentBehavior())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2D2D3F)
                      : AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.2
                          : 0.03),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                )
              ],
            ),
            child: Icon(icon, color: color, size: 26.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestHomeworkSection extends StatelessWidget {
  final dynamic child;
  const _LatestHomeworkSection({required this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final List<dynamic> homeworks = child['homeworks'] ?? [];

    // Find the latest pending homework
    final pendingHomeworks =
        homeworks.where((hw) => hw['isSubmitted'] == false).toList();

    if (pendingHomeworks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'آخر الواجبات' : 'Latest Homework',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ParentHomework(child: child)),
                ),
                child: Text(
                  isArabic ? 'عرض الكل' : 'View All',
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(20.r),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2D2D3F)
                      : AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.2
                          : 0.03),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                )
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.emerald, size: 40.r),
                SizedBox(height: 12.h),
                Text(
                  isArabic ? 'لا توجد واجبات معلقة' : 'No pending homeworks',
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isArabic
                      ? 'أنجز طفلك جميع الواجبات المطلوبة!'
                      : 'Your child has completed all assigned homeworks!',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final latestHw = pendingHomeworks.first;
    final title = latestHw['title'] ?? '';
    final subjectName = isArabic
        ? (latestHw['subjectNameAr'] ?? '')
        : (latestHw['subjectNameEn'] ?? '');

    // Parse due date
    String dueText = '';
    if (latestHw['dueDate'] != null) {
      try {
        final dueDate = DateTime.parse(latestHw['dueDate']).toLocal();
        final now = DateTime.now();
        final difference =
            dueDate.difference(DateTime(now.year, now.month, now.day));
        if (difference.inDays == 0) {
          dueText = isArabic ? 'اليوم' : 'Today';
        } else if (difference.inDays == 1) {
          dueText = isArabic ? 'غداً' : 'Tomorrow';
        } else if (difference.inDays == 2) {
          dueText = isArabic ? 'بعد غد' : 'In 2 days';
        } else if (difference.inDays < 0) {
          dueText = isArabic ? 'متأخر' : 'Overdue';
        } else {
          dueText = isArabic
              ? 'خلال ${difference.inDays} أيام'
              : 'In ${difference.inDays} days';
        }
      } catch (_) {
        dueText = isArabic ? 'غير محدد' : 'Undefined';
      }
    } else {
      dueText = isArabic ? 'غير محدد' : 'Undefined';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? 'آخر الواجبات' : 'Latest Homework',
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ParentHomework(child: child)),
              ),
              child: Text(
                isArabic ? 'عرض الكل' : 'View All',
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ParentHomework(child: child)),
          ),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2D2D3F)
                      : AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.2
                          : 0.03),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(Icons.menu_book_rounded,
                      color: AppColors.primary, size: 24.r),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                      ),
                      Text(
                        isArabic
                            ? '$subjectName • الموعد: $dueText'
                            : '$subjectName • Due: $dueText',
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.roseLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    isArabic ? 'معلق' : 'Pending',
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.rose,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  final List<dynamic> announcements;
  const _AnnouncementsSection({super.key, required this.announcements});

  String _getAnnType(String title) {
    if (title.startsWith('[') && title.contains(']')) {
      final endIdx = title.indexOf(']');
      return title.substring(1, endIdx);
    }
    return 'عام';
  }

  String _getCleanTitle(String title) {
    if (title.startsWith('[') && title.contains(']')) {
      final endIdx = title.indexOf(']');
      return title.substring(endIdx + 1).trim();
    }
    return title;
  }

  Color _getColor(String type) {
    switch (type) {
      case 'اختبار':
        return AppColors.rose;
      case 'واجب':
        return AppColors.amber;
      case 'نشاط':
        return AppColors.emerald;
      case 'إجازة':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(String? dateStr, bool isArabic) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        final mins = difference.inMinutes;
        if (mins <= 1) return isArabic ? 'الآن' : 'Just now';
        return isArabic ? 'منذ $mins دقيقة' : '$mins mins ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        if (hours == 1) return isArabic ? 'منذ ساعة' : '1 hr ago';
        if (hours == 2) return isArabic ? 'منذ ساعتين' : '2 hrs ago';
        return isArabic ? 'منذ $hours ساعة' : '$hours hrs ago';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        if (days == 1) return isArabic ? 'أمس' : 'Yesterday';
        if (days == 2) return isArabic ? 'منذ يومين' : '2 days ago';
        return isArabic ? 'منذ $days أيام' : '$days days ago';
      } else {
        return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final recentAnnouncements = announcements.take(2).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? 'الإعلانات' : 'Announcements',
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ParentAnnouncements(announcements: announcements),
                ),
              ),
              child: Text(
                isArabic ? 'عرض الكل' : 'View All',
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (recentAnnouncements.isEmpty)
          Container(
            padding: EdgeInsets.all(20.r),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2D2D3F)
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.2
                          : 0.03),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                )
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.notifications_off_rounded,
                    color: AppColors.textLight, size: 40.r),
                SizedBox(height: 12.h),
                Text(
                  isArabic ? 'لا توجد إعلانات حالياً' : 'No announcements yet',
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isArabic
                      ? 'سنقوم بإشعارك عند نشر أي إعلان جديد من المدرسة.'
                      : 'We will notify you when new announcements are posted.',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          )
        else
          ...recentAnnouncements.map((ann) {
            final title = ann['title'] ?? '';
            final body = ann['body'] ?? '';
            final type = _getAnnType(title);
            final cleanTitle = _getCleanTitle(title);
            final color = _getColor(type);
            final timeStr = _formatTime(ann['createdAt'], isArabic);

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: _buildAnnouncementCard(
                context,
                category: type,
                categoryColor: color,
                categoryBg: color.withOpacity(0.1),
                time: timeStr,
                title: cleanTitle,
                body: body,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context, {
    required String category,
    required Color categoryColor,
    required Color categoryBg,
    required String time,
    required String title,
    required String body,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
            color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: categoryBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: categoryColor,
                  ),
                ),
              ),
              Text(
                time,
                style: GoogleFonts.cairo(
                  fontSize: 10.sp,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              color: AppColors.textMedium,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
