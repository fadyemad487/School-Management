import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import 'settings_account.dart';
import 'settings_notifications.dart';
import 'settings_privacy.dart';
import 'settings_appearance.dart';
import 'behavior_books.dart';
import '../../auth/auth_service.dart';
import '../../auth/login_screen.dart';
import '../../../core/utils/profile_notifier.dart';

Future<void> showParentSettingsSidebar(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Parent settings',
    barrierColor: Colors.black.withValues(alpha: 0.46),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, _, __) {
      return Align(
        alignment: Alignment.centerRight,
        child: ParentSettingsSidebar(hostContext: context),
      );
    },
    transitionBuilder: (_, animation, __, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(curved),
        child: child,
      );
    },
  );
}

class ParentSettingsSidebar extends StatefulWidget {
  final BuildContext hostContext;

  const ParentSettingsSidebar({super.key, required this.hostContext});

  @override
  State<ParentSettingsSidebar> createState() => _ParentSettingsSidebarState();
}

class _ParentSettingsSidebarState extends State<ParentSettingsSidebar> {
  final ApiClient _apiClient = ApiClient();
  String _parentName = 'ولي الأمر';
  String _parentPhone = '';
  String _parentEmail = '';
  String? _parentPhoto;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    ProfileNotifier.parentPhoto.addListener(_onProfileChanged);
    ProfileNotifier.parentName.addListener(_onProfileChanged);
    ProfileNotifier.parentPhone.addListener(_onProfileChanged);
    ProfileNotifier.parentEmail.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileNotifier.parentPhoto.removeListener(_onProfileChanged);
    ProfileNotifier.parentName.removeListener(_onProfileChanged);
    ProfileNotifier.parentPhone.removeListener(_onProfileChanged);
    ProfileNotifier.parentEmail.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    setState(() {
      _parentPhoto = ProfileNotifier.parentPhoto.value;
      _parentName = ProfileNotifier.parentName.value ?? _parentName;
      _parentPhone = ProfileNotifier.parentPhone.value ?? _parentPhone;
      _parentEmail = ProfileNotifier.parentEmail.value ?? _parentEmail;
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiClient.client.get('/parents/mobile/dashboard');
      if (!mounted) return;
      if (response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _parentName = data['parentName'] ?? _parentName;
          _parentPhoto = data['parentPhoto'];
          _parentPhone = data['parentPhone'] ?? '';
          _parentEmail = data['parentEmail'] ?? '';
        });
        ProfileNotifier.parentPhoto.value = data['parentPhoto'];
        ProfileNotifier.parentName.value = data['parentName'];
        ProfileNotifier.parentPhone.value = data['parentPhone'];
        ProfileNotifier.parentEmail.value = data['parentEmail'];
      }
    } catch (_) {}
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

  void _open(Widget page) {
    Navigator.of(context).pop();
    Future.microtask(() async {
      if (!widget.hostContext.mounted) return;
      await Navigator.of(widget.hostContext)
          .push(MaterialPageRoute(builder: (_) => page));
      // Do not reopen sidebar after logout / password-change redirect to login.
      if (!widget.hostContext.mounted) return;
      final stillLoggedIn = await AuthService.hasActiveSession();
      if (stillLoggedIn && widget.hostContext.mounted) {
        showParentSettingsSidebar(widget.hostContext);
      }
    });
  }

  Future<void> _logout() async {
    Navigator.of(context).pop();
    final authService = AuthService();
    await authService.logout();
    if (widget.hostContext.mounted) {
      Navigator.of(widget.hostContext).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = (screenWidth * 0.78).clamp(276.0, 338.0);
    final email = _parentEmail.isNotEmpty ? _parentEmail : 'parent@wecircle.edu';

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(34.r),
            bottomLeft: Radius.circular(34.r),
          ),
          child: Container(
            color: const Color(0xFFF4F7FB),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20.w, 34.h, 20.w, 24.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF2876F0), Color(0xFFAA35E8)],
                    ),
                    borderRadius:
                        BorderRadius.only(bottomLeft: Radius.circular(28.r)),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      CircleAvatar(
                        radius: 34.r,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        backgroundImage: _getProfileImageProvider(_parentPhoto),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _parentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 18.h),
                    children: [
                      _SidebarItem(
                        title: isArabic ? 'إعدادات الحساب' : 'Account Settings',
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFF2F74DF),
                        onTap: () => _open(SettingsAccount(
                          currentName: _parentName,
                          currentPhone: _parentPhone,
                          currentEmail: _parentEmail,
                          currentPhoto: _parentPhoto,
                        )),
                      ),
                      _SidebarItem(
                        title: isArabic ? 'الإشعارات' : 'Notifications',
                        icon: Icons.notifications_none_rounded,
                        iconColor: const Color(0xFFFFA51F),
                        onTap: () => _open(const SettingsNotifications()),
                      ),
                      _SidebarItem(
                        title: isArabic
                            ? 'اللغة و المظهر'
                            : 'Language & Appearance',
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF54BF5E),
                        onTap: () => _open(const SettingsAppearance()),
                      ),
                      _SidebarItem(
                        title: isArabic
                            ? 'الخصوصية والأمان'
                            : 'Privacy & Security',
                        icon: Icons.shield_rounded,
                        iconColor: const Color(0xFF172033),
                        onTap: () => _open(const SettingsPrivacy()),
                      ),
                      _SidebarItem(
                        title: isArabic ? 'الكتب السلوكية' : 'Behavior Books',
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFF149A8B),
                        onTap: () => _open(const BehaviorBooks()),
                      ),
                      _SidebarItem(
                        title: isArabic
                            ? 'استشارة سلوكية'
                            : 'Behavior Consultation',
                        icon: Icons.assignment_ind_rounded,
                        iconColor: const Color(0xFF9B2FE3),
                        onTap: () => _open(const _BehaviorConsultationPage()),
                      ),
                      SizedBox(height: 28.h),
                      _SidebarItem(
                        title: isArabic ? 'تسجيل الخروج' : 'Log Out',
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFE5484D),
                        textColor: const Color(0xFFE5484D),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Text(
                    'WeCircle v1.0.4',
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7A8596),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60.h.clamp(54, 66),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF20314F).withValues(alpha: 0.08),
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.chevron_left_rounded,
                color: const Color(0xFF637185), size: 24.r),
            const Spacer(),
            Text(
              title,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                color: textColor ?? const Color(0xFF1B2232),
              ),
            ),
            SizedBox(width: 14.w),
            Icon(icon, color: iconColor, size: 24.r),
          ],
        ),
      ),
    );
  }
}

class _BehaviorConsultationPage extends StatelessWidget {
  const _BehaviorConsultationPage();

  static const _consultants = [
    _Consultant(
      name: 'د. أحمد منصور',
      title: 'استشاري تعديل سلوك وتربية إيجابية',
      details: [
        'خبرة 15 عاما في التعامل مع المراهقين',
        'متاح يوميا من 4 م إلى 9 م'
      ],
    ),
    _Consultant(
      name: 'د. سارة محمود',
      title: 'أخصائية نفسية أطفال وتنمية مهارات',
      details: [
        'متخصصة في علاج اضطرابات النطق والتوحد',
        'متاحة (سبت - اثنين - أربعاء)'
      ],
    ),
    _Consultant(
      name: 'د. محمد علي',
      title: 'خبير صعوبات تعلم وإرشاد أكاديمي',
      details: ['متابعة خطط تعديل السلوك المدرسي', 'متاح مساء من 5 م إلى 8 م'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5FF),
      body: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(painter: _ConsultationBgPainter())),
          SafeArea(
            bottom: false,
            child: Center(
              child: SizedBox(
                width:
                    MediaQuery.sizeOf(context).width.clamp(0, 390).toDouble(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 22.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: SizedBox(
                              width: 44.r,
                              height: 44.r,
                              child: Icon(Icons.chevron_right_rounded,
                                  color: const Color(0xFF8C35E8), size: 28.r),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'استشارة سلوكية'
                                  : 'Behavior Consultation',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF8C35E8),
                                fontSize: 23.sp.clamp(20, 24),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(width: 44.r),
                        ],
                      ),
                      SizedBox(height: 34.h),
                      ..._consultants.map((consultant) {
                        return _ConsultantCard(consultant: consultant);
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultantCard extends StatelessWidget {
  final _Consultant consultant;

  const _ConsultantCard({required this.consultant});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5147E8).withValues(alpha: 0.08),
            blurRadius: 22.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 52.r,
                height: 52.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF5C6AF4), Color(0xFFAE2BE8)],
                  ),
                ),
                child: Icon(Icons.assignment_ind_rounded,
                    color: Colors.white, size: 28.r),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      consultant.name,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF172033),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      consultant.title,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7060B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(height: 1.h, color: AppColors.border),
          ),
          ...consultant.details.map(
            (detail) => Padding(
              padding: EdgeInsets.only(bottom: 9.h),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(Icons.access_time_rounded,
                      color: const Color(0xFF6C7688), size: 20.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      detail,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF283247),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          _GradientButton(
            label: 'اتصال هاتفي',
            icon: Icons.phone_in_talk_rounded,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('سيتم تفعيل الاتصال بعد ربط رقم الاستشاري'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _OutlineActionButton(
                  label: 'حجز موعد',
                  icon: Icons.calendar_month_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          _ConsultationBookingPage(consultant: consultant),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _OutlineActionButton(
                  label: 'دردشة',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('الدردشة التجريبية جاهزة للربط لاحقا'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsultationBookingPage extends StatefulWidget {
  final _Consultant consultant;

  const _ConsultationBookingPage({required this.consultant});

  @override
  State<_ConsultationBookingPage> createState() =>
      _ConsultationBookingPageState();
}

class _ConsultationBookingPageState extends State<_ConsultationBookingPage> {
  int _selectedDay = 0;
  String _selectedTime = '05:00 م';
  final _days = const [
    ('السبت', '20 مايو'),
    ('الأحد', '21 مايو'),
    ('الاثنين', '22 مايو'),
    ('الثلاثاء', '23 مايو'),
  ];
  final _morning = const ['09:00 ص', '10:00 ص', '11:00 ص'];
  final _evening = const [
    '04:00 م',
    '05:00 م',
    '06:00 م',
    '07:00 م',
    '08:00 م'
  ];

  void _confirm() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) {
        final day = _days[_selectedDay].$1;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
          child: Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF3FAF7),
              borderRadius: BorderRadius.circular(28.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72.r,
                  height: 72.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CC45E).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded,
                      color: const Color(0xFF48BD57), size: 60.r),
                ),
                SizedBox(height: 22.h),
                Text(
                  'تم تأكيد الحجز بنجاح',
                  style: GoogleFonts.cairo(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF6960DC),
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(15.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _ConfirmationLine(
                          icon: Icons.person_outline_rounded,
                          text: 'الطبيب: ${widget.consultant.name}'),
                      _ConfirmationLine(
                          icon: Icons.calendar_month_rounded,
                          text: 'اليوم: $day'),
                      _ConfirmationLine(
                          icon: Icons.access_time_rounded,
                          text: 'الموعد: مسائية ($_selectedTime)'),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                _GradientButton(
                  label: 'حسناً',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 74.h,
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5C6AF4), Color(0xFFAE2BE8)],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 42.r),
                  ),
                  Expanded(
                    child: Text(
                      'حجز موعد الاستشارة',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(width: 42.r),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width:
                      MediaQuery.sizeOf(context).width.clamp(0, 390).toDouble(),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 104.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'اختر اليوم المفضل:',
                          style: GoogleFonts.cairo(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF172033),
                          ),
                        ),
                        SizedBox(height: 22.h),
                        SizedBox(
                          height: 98.h,
                          child: ListView.separated(
                            reverse: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: _days.length,
                            separatorBuilder: (_, __) => SizedBox(width: 16.w),
                            itemBuilder: (context, index) {
                              final selected = index == _selectedDay;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedDay = index),
                                child: Container(
                                  width: 84.w,
                                  decoration: BoxDecoration(
                                    gradient: selected
                                        ? const LinearGradient(colors: [
                                            Color(0xFF5C6AF4),
                                            Color(0xFFAE2BE8)
                                          ])
                                        : null,
                                    color: selected ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(24.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF20314F)
                                            .withValues(alpha: 0.06),
                                        blurRadius: 18.r,
                                        offset: Offset(0, 8.h),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _days[index].$1,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13.5.sp,
                                          fontWeight: FontWeight.w900,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF172033),
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        _days[index].$2,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: selected
                                              ? Colors.white
                                                  .withValues(alpha: 0.78)
                                              : AppColors.textMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 44.h),
                        _TimeSection(
                          title: 'الفترة الصباحية',
                          icon: Icons.wb_sunny_rounded,
                          times: _morning,
                          selectedTime: _selectedTime,
                          onSelect: (time) =>
                              setState(() => _selectedTime = time),
                        ),
                        SizedBox(height: 36.h),
                        _TimeSection(
                          title: 'الفترة المسائية',
                          icon: Icons.nightlight_round,
                          times: _evening,
                          selectedTime: _selectedTime,
                          onSelect: (time) =>
                              setState(() => _selectedTime = time),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 24.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18.r,
                    offset: Offset(0, -6.h),
                  ),
                ],
              ),
              child: _GradientButton(label: 'تأكيد الحجز', onTap: _confirm),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> times;
  final String selectedTime;
  final ValueChanged<String> onSelect;

  const _TimeSection({
    required this.title,
    required this.icon,
    required this.times,
    required this.selectedTime,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF172033),
              ),
            ),
            SizedBox(width: 8.w),
            Icon(icon, color: const Color(0xFF9B2FE3), size: 28.r),
          ],
        ),
        SizedBox(height: 18.h),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 16.w,
          runSpacing: 16.h,
          children: times.map((time) {
            final selected = time == selectedTime;
            return GestureDetector(
              onTap: () => onSelect(time),
              child: Container(
                width: 96.w,
                height: 50.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFF3F4FF) : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color:
                        selected ? const Color(0xFF6960DC) : AppColors.border,
                    width: selected ? 1.8 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF20314F).withValues(alpha: 0.04),
                      blurRadius: 12.r,
                      offset: Offset(0, 5.h),
                    ),
                  ],
                ),
                child: Text(
                  time,
                  style: GoogleFonts.cairo(
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w900,
                    color: selected
                        ? const Color(0xFF6960DC)
                        : const Color(0xFF172033),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF5C6AF4), Color(0xFFAE2BE8)]),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 21.r),
              SizedBox(width: 8.w),
            ],
            Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 15.5.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFF8C35E8), width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF8C35E8), size: 20.r),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF8C35E8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConfirmationLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: const Color(0xFF6C7688), size: 20.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF172033),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = const Color(0xFFBDE4FF).withValues(alpha: 0.32);
    final purple = Paint()
      ..color = const Color(0xFFE3D5FF).withValues(alpha: 0.42);
    final line = Paint()
      ..color = const Color(0xFF8795AD).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(
        Offset(size.width * .76, size.height * .08), 86.r, purple);
    canvas.drawCircle(Offset(size.width * .15, size.height * .36), 98.r, blue);
    canvas.drawCircle(
        Offset(size.width * .82, size.height * .78), 120.r, purple);
    for (var i = 0; i < 6; i++) {
      final x = size.width * (.08 + i * .17);
      canvas.drawLine(Offset(x, size.height * .14),
          Offset(x + 42, size.height * .05), line);
      canvas.drawCircle(
          Offset(x + 18, size.height * (.24 + i * .1)), 20.r, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Consultant {
  final String name;
  final String title;
  final List<String> details;

  const _Consultant({
    required this.name,
    required this.title,
    required this.details,
  });
}

class ParentSettings extends StatefulWidget {
  const ParentSettings({super.key});

  @override
  State<ParentSettings> createState() => _ParentSettingsState();
}

class _ParentSettingsState extends State<ParentSettings> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _parentName = '';
  String? _parentPhoto;
  String _parentPhone = '';
  String _parentEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    ProfileNotifier.parentPhoto.addListener(_onProfileChanged);
    ProfileNotifier.parentName.addListener(_onProfileChanged);
    ProfileNotifier.parentPhone.addListener(_onProfileChanged);
    ProfileNotifier.parentEmail.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileNotifier.parentPhoto.removeListener(_onProfileChanged);
    ProfileNotifier.parentName.removeListener(_onProfileChanged);
    ProfileNotifier.parentPhone.removeListener(_onProfileChanged);
    ProfileNotifier.parentEmail.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {
        _parentPhoto = ProfileNotifier.parentPhoto.value;
        _parentName = ProfileNotifier.parentName.value ?? _parentName;
        _parentPhone = ProfileNotifier.parentPhone.value ?? _parentPhone;
        _parentEmail = ProfileNotifier.parentEmail.value ?? _parentEmail;
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

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiClient.client.get('/parents/mobile/dashboard');
      if (mounted) {
        if (response.data['success'] == true) {
          final data = response.data['data'];
          setState(() {
            _parentName = data['parentName'] ?? 'ولي الأمر';
            _parentPhoto = data['parentPhoto'];
            _parentPhone = data['parentPhone'] ?? '';
            _parentEmail = data['parentEmail'] ?? '';
            _isLoading = false;
          });
          ProfileNotifier.parentPhoto.value = data['parentPhoto'];
          ProfileNotifier.parentName.value = data['parentName'];
          ProfileNotifier.parentPhone.value = data['parentPhone'];
          ProfileNotifier.parentEmail.value = data['parentEmail'];
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final defaultName = isArabic ? 'ولي الأمر' : 'Parent';
    final displayName = _parentName.isEmpty
        ? (_isLoading
            ? (isArabic ? 'جاري التحميل...' : 'Loading...')
            : defaultName)
        : _parentName;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
        elevation: 0,
        title: Text(
          isArabic ? 'الإعدادات' : 'Settings',
          style: GoogleFonts.cairo(
            color: isDark ? Colors.white : AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
            height: 1.h,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20.r),
          child: Column(
            children: [
              // User Profile Summary
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color:
                          isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundImage: _getProfileImageProvider(_parentPhoto),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.cairo(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          Text(
                            _parentPhone.isNotEmpty
                                ? _parentPhone
                                : (isArabic
                                    ? 'لا يوجد رقم هاتف'
                                    : 'No phone number'),
                            style: GoogleFonts.cairo(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              // Settings Categories
              _buildSettingsSection(
                title: isArabic ? 'الحساب' : 'Account',
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline_rounded,
                    title: isArabic ? 'إعدادات الحساب' : 'Account Settings',
                    subtitle: isArabic
                        ? 'تعديل الاسم، رقم الجوال والصورة لتطبيقك'
                        : 'Edit name, phone number & profile photo',
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primaryLight.withOpacity(0.1),
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SettingsAccount(
                                    currentName: displayName,
                                    currentPhone: _parentPhone,
                                    currentEmail: _parentEmail,
                                    currentPhoto: _parentPhoto,
                                  )));
                      _fetchProfile();
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              _buildSettingsSection(
                title: isArabic ? 'التفضيلات' : 'Preferences',
                items: [
                  _SettingsItem(
                    icon: Icons.notifications_none_rounded,
                    title: isArabic ? 'الإشعارات' : 'Notifications',
                    subtitle: isArabic
                        ? 'التحكم في إشعارات الحضور، الواجبات والسلوك'
                        : 'Control attendance, homework & behavior notifications',
                    iconColor: AppColors.orange,
                    bgColor: AppColors.orangeLight,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsNotifications())),
                  ),
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: isArabic ? 'المظهر واللغة' : 'Appearance & Language',
                    subtitle: isArabic
                        ? 'الوضع الليلي / النهاري وتغيير لغة التطبيق'
                        : 'Dark/Light mode & change app language',
                    iconColor: AppColors.purple,
                    bgColor: AppColors.purpleLight,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsAppearance())),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              _buildSettingsSection(
                title: isArabic ? 'الأمان' : 'Security',
                items: [
                  _SettingsItem(
                    icon: Icons.security_rounded,
                    title: isArabic ? 'الخصوصية والأمان' : 'Privacy & Security',
                    subtitle: isArabic
                        ? 'تفعيل بصمة الإصبع، الأجهزة المسجلة وكلمة المرور'
                        : 'Enable fingerprint, registered devices & password',
                    iconColor: AppColors.emerald,
                    bgColor: AppColors.emeraldLight,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsPrivacy())),
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () async {
                    final authService = AuthService();
                    await authService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roseLight,
                    foregroundColor: AppColors.rose,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: BorderSide(color: AppColors.rose.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 22.r),
                      SizedBox(width: 8.w),
                      Text(
                        isArabic ? 'تسجيل الخروج' : 'Log Out',
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 120.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      {required String title, required List<_SettingsItem> items}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 12.h),
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
                color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              )
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  item,
                  if (!isLast)
                    Divider(
                        height: 1.h,
                        thickness: 1.h,
                        color:
                            isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                        indent: 70.w),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 22.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textLight, size: 14.r),
          ],
        ),
      ),
    );
  }
}
