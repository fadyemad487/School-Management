import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart';
import '../../auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _apiClient.client.post(
        '/parents/mobile/change-password',
        data: {
          'newPassword': _newPasswordController.text,
        },
      );

      if (response.data['success'] == true) {
        // Show premium success dialog
        if (mounted) {
          _showSuccessDialog();
        }
      }
    } on DioException catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      final errorMsg = e.response?.data?['message'] ?? 
          (isArabic ? 'حدث خطأ أثناء تغيير كلمة المرور' : 'An error occurred during password change');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        );
      }
    } catch (_) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              padding: EdgeInsets.all(28.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: isDark ? const Color(0xFF2E2E40) : AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20.r,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Beautiful glowing checkmark
                  Container(
                    width: 72.r,
                    height: 72.r,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.emerald,
                        size: 48.r,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    isArabic ? 'تم تغيير كلمة المرور بنجاح!' : 'Password Changed Successfully!',
                    style: GoogleFonts.cairo(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    isArabic
                        ? 'سيتم توجيهك لصفحة تسجيل الدخول الآن لتسجيل الدخول بكلمة المرور الجديدة.'
                        : 'You will be redirected to the login page now to log in with your new password.',
                    style: GoogleFonts.cairo(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  // Progress indicator
                  SizedBox(
                    width: 24.r,
                    height: 24.r,
                    child: CircularProgressIndicator(
                      color: AppColors.emerald,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // After 2.5 seconds, clear session and route to Login Screen
    Future.delayed(const Duration(milliseconds: 2500), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('school_id');
      await prefs.remove('school_name');
      await prefs.remove('school_code');
      await prefs.remove('user_role');
      await prefs.remove('user_fullname');
      await prefs.remove('user_id');
      await prefs.remove('remember_me');
      await prefs.remove('user_photo');

      if (mounted) {
        // Close the dialog first
        Navigator.of(context).pop();
        
        // Wait a bit for the dialog to close
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Root navigator clears ParentMain + settings stack; avoids leaving sidebar overlay.
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          isArabic ? 'تغيير كلمة المرور' : 'Change Password',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic 
                    ? 'يرجى كتابة كلمة المرور الجديدة وتأكيدها لتحديثها لحسابك.'
                    : 'Please type and confirm your new password to update your account.',
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                ),
              ),
              SizedBox(height: 24.h),

              // New Password
              _buildLabel(isArabic ? 'كلمة المرور الجديدة' : 'New Password', isDark),
              SizedBox(height: 8.h),
              _buildPasswordField(
                controller: _newPasswordController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return isArabic ? 'يرجى إدخال كلمة المرور الجديدة' : 'New password is required';
                  }
                  if (val.length < 6) {
                    return isArabic ? 'يجب أن لا تقل عن 6 خانات' : 'Must be at least 6 characters';
                  }
                  return null;
                },
                hintText: isArabic ? 'أدخل كلمة المرور الجديدة' : 'Enter new password',
                isDark: isDark,
              ),
              SizedBox(height: 20.h),

              // Confirm New Password
              _buildLabel(isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password', isDark),
              SizedBox(height: 8.h),
              _buildPasswordField(
                controller: _confirmPasswordController,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return isArabic ? 'يرجى تأكيد كلمة المرور الجديدة' : 'Please confirm new password';
                  }
                  if (val != _newPasswordController.text) {
                    return isArabic ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
                  }
                  return null;
                },
                hintText: isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm new password',
                isDark: isDark,
              ),
              SizedBox(height: 40.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24.r,
                          height: 24.r,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isArabic ? 'تحديث كلمة المرور' : 'Update Password',
                          style: GoogleFonts.cairo(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required FormFieldValidator<String> validator,
    required String hintText,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.cairo(
        fontSize: 14.sp,
        color: isDark ? Colors.white : AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.cairo(
          fontSize: 13.sp,
          color: isDark ? const Color(0xFF6E6E82) : AppColors.textLight,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2E2E40) : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.rose, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.rose, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: isDark ? const Color(0xFF6E6E82) : AppColors.textLight,
            size: 20.r,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
