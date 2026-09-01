import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20.r),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(18.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.82),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            size: 45.r,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Center(
                        child: Text(
                          'استعادة كلمة المرور',
                          style: GoogleFonts.cairo(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Center(
                        child: Text(
                          'أدخل بريدك الإلكتروني لإرسال كود استعادة كلمة المرور',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13.sp,
                            color: AppColors.textMedium,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 28.h),
                      Text(
                        'البريد الإلكتروني',
                        style: GoogleFonts.cairo(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      _CustomInputField(
                        hintText: 'name@email.com',
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          color: AppColors.textLight,
                          size: 18.r,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال البريد الإلكتروني';
                          }
                          if (!_isValidEmail(value)) {
                            return 'يرجى إدخال بريد إلكتروني صحيح (مثال: @gmail.com)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24.h),
                      _PrimaryButton(
                        label: 'إرسال كود التحقق',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _showSuccessDialog(context);
                          }
                        },
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 75.r,
                    height: 75.r,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mark_email_unread_rounded,
                        color: AppColors.primary,
                        size: 38.r,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'تحقق من بريدك',
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        color: AppColors.textMedium,
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(
                          text: 'لقد أرسلنا كود استعادة كلمة المرور إلى البريد الإلكتروني ',
                        ),
                        TextSpan(
                          text: _identifierController.text,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _PrimaryButton(
                    label: 'فتح تطبيق البريد',
                    onPressed: () {
                      Navigator.pop(context); // Close Dialog
                      Navigator.pop(context); // Back to Login
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'لم يصلك الكود؟ أعد الإرسال',
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1D4ED8), // Royal blue brand color
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'تغيير البريد الإلكتروني',
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.4),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom Glassmorphic Input Field matching Login
class _CustomInputField extends StatelessWidget {
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _CustomInputField({
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(24.r), // Pill-shaped
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              prefixIcon!,
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                validator: validator,
                style: GoogleFonts.cairo(
                  fontSize: 13.sp,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.cairo(
                    color: AppColors.textLight,
                    fontSize: 13.sp,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (suffixIcon != null) suffixIcon!,
          ],
        ),
      ),
    );
  }
}

// Custom Royal Blue to Deep Purple Gradient Primary Button matching Login
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 46.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23.r), // Pill shape
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23.r)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
