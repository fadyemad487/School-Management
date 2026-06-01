import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../student_game_state.dart';
import '../utils/student_responsive.dart';
import '../../auth/login_screen.dart';
import '../../auth/auth_service.dart';
import '../space/widgets/student1-3/animated_space_background.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  String _fullName = 'بطل WeCircle';
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('user_fullname') ?? 'بطل WeCircle';
    });
  }

  ImageProvider _getProfileImageProvider(String? photo) {
    if (photo == null || photo.isEmpty) {
      return const NetworkImage('https://images.unsplash.com/photo-1596870230751-ebdfce98ec42?w=100&h=100&fit=crop&crop=face');
    }
    if (photo.startsWith('data:image') || photo.startsWith('base64')) {
      final base64String = photo.contains('base64,') ? photo.split('base64,')[1] : photo;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return const NetworkImage('https://images.unsplash.com/photo-1596870230751-ebdfce98ec42?w=100&h=100&fit=crop&crop=face');
      }
    }
    return NetworkImage(photo);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = pickedFile.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64String';

      if (mounted) {
        final gameState = Provider.of<StudentGameState>(context, listen: false);
        await gameState.updatePhoto(dataUrl);
      }
    }
  }

  void _showChangePasswordDialog() {
    final gameState = Provider.of<StudentGameState>(context, listen: false);
    _passwordController.clear();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                top: 20.h,
                left: 20.w,
                right: 20.w,
              ),
              decoration: BoxDecoration(
                color: gameState.cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                border: Border.all(color: gameState.borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تغيير كلمة المرور',
                    style: GoogleFonts.cairo(
                      color: gameState.textColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'أدخل كلمة المرور الجديدة مباشرةً لتأمين حساب البطل',
                    style: GoogleFonts.cairo(
                      color: gameState.subtitleColor,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: gameState.borderColor),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      enabled: !isSaving,
                      style: GoogleFonts.cairo(
                        color: gameState.textColor, 
                        fontSize: 13.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور الجديدة',
                        hintStyle: GoogleFonts.cairo(
                          color: gameState.mutedTextColor, 
                          fontSize: 13.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_rounded, 
                          color: gameState.mutedTextColor, 
                          size: 18,
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        elevation: 0,
                      ),
                      onPressed: isSaving 
                          ? null 
                          : () async {
                              final newPw = _passwordController.text.trim();
                              if (newPw.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                              });

                              final authService = AuthService();
                              final res = await authService.updatePassword(newPw);

                              if (context.mounted) {
                                setModalState(() {
                                  isSaving = false;
                                });

                                if (res['success'] == true) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'تم تغيير كلمة المرور بنجاح!',
                                        style: GoogleFonts.cairo(),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message'] ?? 'فشل تغيير كلمة المرور',
                                        style: GoogleFonts.cairo(),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'حفظ التغييرات',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<StudentGameState>();
    return Scaffold(
      backgroundColor: const Color(0xFF15264F),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedSpaceBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: StudentResponsive.screenPadding(context).copyWith(
                top: 16.h,
                bottom: 24.h + MediaQuery.paddingOf(context).bottom,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
            Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                Expanded(
                  child: Text(
                    'حساب البطل 👤',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                if (Navigator.of(context).canPop()) SizedBox(width: 40.w),
              ],
            ),
            SizedBox(height: 20.h),

            // ── Glassmorphic Profile Card ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
              decoration: BoxDecoration(
                color: gameState.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: gameState.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Photo
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 68.w,
                          height: 68.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF8B5CF6), width: 2.0),
                            image: DecorationImage(
                              image: _getProfileImageProvider(gameState.studentPhoto),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(5.w),
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 10.w),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  
                  // Full name
                  Text(
                    _fullName,
                    style: GoogleFonts.cairo(
                      color: gameState.textColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  
                  // Score Tag
                  Text(
                    'رصيدك: ${gameState.points} نقطة بطل',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFF59E0B),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Achievement Badges Section
                  Text(
                    'أوسمة البطل المفتوحة 🏅',
                    style: GoogleFonts.cairo(
                      color: gameState.subtitleColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadgeTile('🌬️', 'الهدوء', gameState.points >= 150, gameState),
                      SizedBox(width: 8.w),
                      _buildBadgeTile('💖', 'اللطف', gameState.points >= 300, gameState),
                      SizedBox(width: 8.w),
                      _buildBadgeTile('🛡️', 'الأمانة', gameState.points >= 500, gameState),
                      SizedBox(width: 8.w),
                      _buildBadgeTile('🌸', 'الرضا', gameState.points >= 800, gameState),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),

            // ── Settings Tiles ──
            _SettingsTile(
              icon: Icons.lock_rounded,
              title: 'تغيير كلمة المرور',
              color: const Color(0xFF8B5CF6),
              onTap: _showChangePasswordDialog,
            ),
            SizedBox(height: 10.h),

            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'تسجيل الخروج من الحساب',
              color: const Color(0xFFF43F5E),
              isLogout: true,
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeTile(String emoji, String title, bool unlocked, StudentGameState gameState) {
    return Container(
      width: 48.w,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: unlocked
            ? Colors.black.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: unlocked ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : gameState.borderColor,
          width: unlocked ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 16.sp,
              color: unlocked ? null : Colors.grey,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: GoogleFonts.cairo(
              color: unlocked ? gameState.textColor : gameState.mutedTextColor,
              fontSize: 7.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool isLogout;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<StudentGameState>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: gameState.cardColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: isLogout ? color.withValues(alpha: 0.15) : gameState.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  color: isLogout ? color : gameState.textColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: gameState.mutedTextColor,
              size: 11,
            ),
          ],
        ),
      ),
    );
  }
}
