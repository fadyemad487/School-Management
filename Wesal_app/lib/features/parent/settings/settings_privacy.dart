import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';
import 'change_password_screen.dart';

class SettingsPrivacy extends StatefulWidget {
  const SettingsPrivacy({super.key});

  @override
  State<SettingsPrivacy> createState() => _SettingsPrivacyState();
}

class _SettingsPrivacyState extends State<SettingsPrivacy> {
  final ApiClient _apiClient = ApiClient();
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _useBiometrics = false;
  List<dynamic> _devices = [];
  bool _isLoadingDevices = true;
  bool _isLinking = false;

  // Social account linking state
  bool _isLoadingSocial = true;
  bool _googleLinked = false;
  String? _googleEmail;
  bool _appleLinked = false;
  String? _appleEmail;

  @override
  void initState() {
    super.initState();
    _loadBiometricsPreference();
    _fetchDevices();
    _fetchSocialStatus();

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null && session.user != null) {
        if (!_isLinking) return; // Prevent automatic trigger on page load
        _isLinking = false;
        
        final email = session.user!.email;
        final provider = session.user!.appMetadata?['provider'] ?? 'google';
        final socialId = 'social_${provider}_${session.user!.id}';
        if (email != null) {
          _linkSocial(provider, email, socialId);
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBiometricsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useBiometrics = prefs.getBool('use_biometrics') ?? false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_biometrics', value);
    setState(() {
      _useBiometrics = value;
    });
  }

  Future<void> _fetchDevices() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDevices = true;
    });
    try {
      final response = await _apiClient.client.get('/parents/mobile/devices');
      if (response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _devices = response.data['data'] ?? [];
            _isLoadingDevices = false;
          });
        }
      } else {
        throw Exception();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDevices = false;
        });
      }
    }
  }

  Future<void> _fetchSocialStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSocial = true;
    });
    try {
      final response = await _apiClient.client.get('/parents/mobile/social/status');
      if (response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _googleLinked = response.data['googleLinked'] ?? false;
            _googleEmail = response.data['googleEmail'];
            _appleLinked = response.data['appleLinked'] ?? false;
            _appleEmail = response.data['appleEmail'];
            _isLoadingSocial = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSocial = false;
        });
      }
    }
  }

  Future<void> _linkSocial(String provider, String email, String socialId) async {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    try {
      final response = await _apiClient.client.post(
        '/parents/mobile/social/link',
        data: {
          'provider': provider,
          'socialId': socialId,
          'email': email,
        },
      );
      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic 
                    ? 'تم ربط الحساب بنجاح!'
                    : 'Account linked successfully!',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
        _fetchSocialStatus();
      }
    } catch (e) {
      if (mounted) {
        String msg = isArabic 
            ? 'حدث خطأ أثناء الربط'
            : 'Error linking account';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    }
  }

  Future<void> _unlinkSocial(String provider) async {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    try {
      final response = await _apiClient.client.post(
        '/parents/mobile/social/unlink',
        data: {'provider': provider},
      );
      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic 
                    ? 'تم إلغاء ربط الحساب بنجاح!'
                    : 'Account unlinked successfully!',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
        _fetchSocialStatus();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'حدث خطأ أثناء إلغاء الربط' : 'Error unlinking account',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    }
  }

  Future<void> _logoutDevice(String sessionId) async {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    try {
      final response = await _apiClient.client.post(
        '/parents/mobile/devices/logout',
        data: {'sessionId': sessionId},
      );
      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'تم تسجيل خروج الجهاز بنجاح' : 'Device logged out successfully',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
        _fetchDevices();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'حدث خطأ أثناء تسجيل الخروج' : 'An error occurred during logout',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    }
  }

  Future<void> _logoutAllOtherDevices() async {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    try {
      final response = await _apiClient.client.post('/parents/mobile/devices/logout-all');
      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic 
                    ? 'تم تسجيل الخروج من جميع الأجهزة الأخرى بنجاح'
                    : 'Successfully logged out from all other devices',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
        _fetchDevices();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'حدث خطأ أثناء تسجيل الخروج من الأجهزة الأخرى' : 'An error occurred during logout of other devices',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    }
  }

  void _showLinkDialog(String provider) async {
    setState(() {
      _isLinking = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider == 'google' ? OAuthProvider.google : OAuthProvider.apple,
        redirectTo: 'io.supabase.wesal://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: const {'prompt': 'select_account'},
      );
    } catch (e) {
      setState(() {
        _isLinking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherDevicesCount = _devices.where((d) => d['isCurrent'] != true).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).appBarTheme.iconTheme?.color ?? AppColors.textDark, size: 20.r),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'الخصوصية والأمان' : 'Privacy & Security',
          style: GoogleFonts.cairo(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? AppColors.textDark,
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
        onRefresh: () async {
          await _fetchDevices();
          await _fetchSocialStatus();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Biometrics Toggle
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fingerprint_rounded,
                                  color: AppColors.emerald, size: 20.r),
                              SizedBox(width: 8.w),
                              Text(
                                isArabic ? 'تفعيل البصمة / Face ID' : 'Enable Fingerprint / Face ID',
                                style: GoogleFonts.cairo(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            isArabic 
                                ? 'تسجيل الدخول السريع باستخدام المقاييس الحيوية'
                                : 'Quick login using biometric options',
                            style: GoogleFonts.cairo(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _useBiometrics,
                      activeColor: AppColors.emerald,
                      onChanged: (val) => _toggleBiometrics(val),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Password Change
              Text(
                isArabic ? 'الأمان' : 'Security',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    )
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                          color: AppColors.primary, size: 22.r),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            isArabic ? 'تغيير كلمة المرور' : 'Change Password',
                            style: GoogleFonts.cairo(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: AppColors.textLight, size: 14.r),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Devices Section
              Text(
                isArabic ? 'الأجهزة المسجلة' : 'Registered Devices',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    )
                  ],
                ),
                child: _isLoadingDevices
                    ? Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Center(
                          child: SizedBox(
                            width: 24.r,
                            height: 24.r,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    : _devices.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(24.r),
                            child: Center(
                              child: Text(
                                isArabic ? 'لا توجد أجهزة مسجلة حالياً' : 'No registered devices found',
                                style: GoogleFonts.cairo(
                                  fontSize: 14.sp,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _devices.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1.h,
                              thickness: 1.h,
                              color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                            ),
                            itemBuilder: (context, index) {
                              final d = _devices[index];
                              return _buildDeviceItem(
                                id: d['id'] ?? '',
                                name: d['deviceName'] ?? 'Unknown Device',
                                location: d['location'] ?? (isArabic ? 'الفيوم، مصر' : 'Faiyum, Egypt'),
                                isActive: d['isActive'] ?? true,
                                isCurrent: d['isCurrent'] ?? false,
                              );
                            },
                          ),
              ),
              SizedBox(height: 32.h),

              // Logout All button (only if there are other devices active)
              if (!_isLoadingDevices && otherDevicesCount > 0)
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: OutlinedButton(
                    onPressed: _logoutAllOtherDevices,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose,
                      side: BorderSide(color: AppColors.rose),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_cell_rounded, size: 20.r),
                        SizedBox(width: 8.w),
                        Text(
                          isArabic ? 'تسجيل الخروج من جميع الأجهزة الأخرى' : 'Logout from all other devices',
                          style: GoogleFonts.cairo(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceItem({
    required String id,
    required String name,
    required String location,
    required bool isActive,
    required bool isCurrent,
  }) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon = Icons.phone_iphone_rounded;
    if (name.toLowerCase().contains('mac') || name.toLowerCase().contains('apple')) {
      icon = Icons.laptop_mac_rounded;
    } else if (name.toLowerCase().contains('android') || name.toLowerCase().contains('samsung') || name.toLowerCase().contains('xiaomi')) {
      icon = Icons.phone_android_rounded;
    } else if (name.toLowerCase().contains('windows') || name.toLowerCase().contains('pc')) {
      icon = Icons.laptop_windows_rounded;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium, size: 22.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldLight,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          isArabic ? 'نشط الآن' : 'Active Now',
                          style: GoogleFonts.cairo(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emerald,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
                Text(
                  location,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              icon: Icon(Icons.logout_rounded,
                  color: AppColors.rose, size: 20.r),
              onPressed: () => _logoutDevice(id),
            ),
        ],
      ),
    );
  }
}
