import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart';
import '../../auth/login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.client.post(
        '/teachers/mobile/change-password',
        data: {
          'newPassword': _newPasswordController.text.trim(),
        },
      );

      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic 
                    ? 'تم تغيير كلمة المرور بنجاح، يرجى تسجيل الدخول مجدداً'
                    : 'Password changed successfully, please log in again',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.emerald,
            ),
          );
          
          // Wait a moment for the snackbar to be visible, then redirect
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // Close any open drawers before navigation
          try {
            if (Scaffold.of(context).isDrawerOpen || Scaffold.of(context).isEndDrawerOpen) {
              Navigator.pop(context); // Close the drawer
              await Future.delayed(const Duration(milliseconds: 300)); // Wait for animation
            }
          } catch (_) {
            // If there's no scaffold context, just continue
          }
          
          // Redirect to login screen since password changed (this revokes all active device sessions!)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        throw Exception();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'حدث خطأ أثناء تغيير كلمة المرور' : 'An error occurred while changing your password',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.textDark, size: 20.r),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'تغيير كلمة المرور' : 'Change Password',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic 
                    ? 'اكتب كلمة مرورك الجديدة لتحديثها. ستقوم العملية بتسجيل خروجك من جميع الأجهزة النشطة لحماية حسابك.'
                    : 'Enter your new password to update it. This process will log you out from all other active devices for account protection.',
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),

              // Form inputs
              Container(
                padding: EdgeInsets.all(20.r),
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
                child: Column(
                  children: [
                    // New Password input
                    _buildPasswordField(
                      label: isArabic ? 'كلمة المرور الجديدة' : 'New Password',
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isArabic ? 'يرجى إدخال كلمة المرور الجديدة' : 'Please enter new password';
                        }
                        if (val.trim().length < 6) {
                          return isArabic ? 'كلمة المرور يجب أن لا تقل عن 6 خانات' : 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    // Confirm New Password input
                    _buildPasswordField(
                      label: isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isArabic ? 'يرجى تأكيد كلمة المرور الجديدة' : 'Please confirm new password';
                        }
                        if (val != _newPasswordController.text) {
                          return isArabic ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Save Password Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.r,
                          height: 24.r,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isArabic ? 'تغيير كلمة المرور' : 'Update Password',
                          style: GoogleFonts.cairo(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required FormFieldValidator<String> validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.cairo(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textLight, size: 20.r),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textLight,
                size: 20.r,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E2C) : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.rose),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.rose),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}
