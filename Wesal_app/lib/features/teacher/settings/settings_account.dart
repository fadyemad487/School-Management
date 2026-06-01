import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/profile_notifier.dart';
import '../../../main.dart';

class SettingsAccount extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentEmail;
  final String? currentPhoto;

  const SettingsAccount({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
    this.currentPhoto,
  });

  @override
  State<SettingsAccount> createState() => _SettingsAccountState();
}

class _SettingsAccountState extends State<SettingsAccount> {
  final ApiClient _apiClient = ApiClient();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _selectedPhoto;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _selectedPhoto = widget.currentPhoto;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final response =
          await _apiClient.client.get('/teachers/mobile/dashboard');
      if (response.data['success'] == true) {
        final profile = response.data['data']['profile'];
        if (profile != null && mounted) {
          setState(() {
            _nameController.text = profile['fullName'] ?? widget.currentName;
            _phoneController.text = profile['phone'] ?? widget.currentPhone;
            _selectedPhoto = profile['photo'] ?? widget.currentPhoto;
            _isLoading = false;
          });
          // Update profile notifier so the entire app is in sync
          ProfileNotifier.teacherName.value = profile['fullName'];
          ProfileNotifier.teacherPhoto.value = profile['photo'];
          ProfileNotifier.teacherPhone.value = profile['phone'];
          ProfileNotifier.teacherEmail.value = profile['email'];
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    setState(() {
      _isSaving = true;
    });

    try {
      final response = await _apiClient.client.put(
        '/teachers/mobile/profile',
        data: {
          'phone': _phoneController.text.trim(),
          'photo': _selectedPhoto,
        },
      );

      if (response.data['success'] == true) {
        if (mounted) {
          ProfileNotifier.teacherPhone.value = _phoneController.text.trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'تم حفظ التعديلات بنجاح'
                    : 'Changes saved successfully',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.emerald,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'حدث خطأ أثناء حفظ التعديلات، يرجى المحاولة لاحقاً'
                  : 'An error occurred while saving changes, please try again later',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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

  Future<void> _pickImage(ImageSource source) async {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        if (!mounted) return;
        Navigator.pop(context); // Dismiss the picker bottom sheet

        setState(() {
          _isSaving = true;
        });

        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType =
            image.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
        final dataUrl = 'data:$mimeType;base64,$base64String';

        if (!mounted) return;
        // Instant upload to server
        final response = await _apiClient.client.put(
          '/teachers/mobile/profile',
          data: {
            'phone': _phoneController.text.trim(),
            'photo': dataUrl,
          },
        );

        if (!mounted) return;
        if (response.data['success'] == true) {
          setState(() {
            _selectedPhoto = dataUrl;
          });
          // Update profile notifier so all other views update instantly!
          ProfileNotifier.teacherPhoto.value = dataUrl;
        } else {
          throw Exception();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'حدث خطأ أثناء رفع وتحديث الصورة الشخصية تلقائياً'
                  : 'An error occurred while uploading and updating your profile picture',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showAvatarPicker() {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تحديث صورة الملف الشخصي' : 'Update Profile Photo',
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isArabic
                      ? 'اختر طريقة رفع صورتك الشخصية لتسجيلها في لوحة التحكم وقاعدة البيانات للتحكم الفوري'
                      : 'Select a method to upload your profile photo to register it in the backend database instantly',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color:
                        isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickImage(ImageSource.camera),
                        child: Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.camera_enhance_rounded,
                                  color: AppColors.primary, size: 32.r),
                              SizedBox(height: 12.h),
                              Text(
                                isArabic ? 'التقاط صورة' : 'Take a Photo',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                                color: AppColors.purple.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.photo_library_rounded,
                                  color: AppColors.purple, size: 32.r),
                              SizedBox(height: 12.h),
                              Text(
                                isArabic ? 'معرض الصور' : 'Photo Gallery',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  color: AppColors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
          isArabic ? 'إعدادات الحساب' : 'Account Settings',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  // Avatar Edit
                  Center(
                    child: GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Stack(
                        children: [
                          Container(
                            width: 100.r,
                            height: 100.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2D2D3F)
                                      : AppColors.border,
                                  width: 4.r),
                              image: DecorationImage(
                                image: _getProfileImageProvider(_selectedPhoto),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: _isSaving
                                ? Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24.r,
                                        height: 24.r,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32.r,
                              height: 32.r,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF1E1E2C)
                                        : Colors.white,
                                    width: 2.r),
                              ),
                              child: Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Edit Form
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: isDark
                              ? const Color(0xFF2D2D3F)
                              : AppColors.border),
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
                        _buildTextField(
                          label: isArabic ? 'الاسم الكامل' : 'Full Name',
                          icon: Icons.person_outline_rounded,
                          controller: _nameController,
                          enabled: false, // Disallowed editing
                        ),
                        SizedBox(height: 20.h),
                        _buildTextField(
                          label: isArabic ? 'رقم الهاتف' : 'Phone Number',
                          icon: Icons.phone_outlined,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 24.r,
                              height: 24.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isArabic ? 'حفظ التعديلات' : 'Save Changes',
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
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool enabled = true,
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
            color: enabled
                ? (isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium)
                : AppColors.textLight,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          style: GoogleFonts.cairo(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: enabled
                ? (isDark ? Colors.white : AppColors.textDark)
                : AppColors.textLight,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20.r),
            filled: true,
            fillColor: enabled
                ? (isDark ? const Color(0xFF1E1E2C) : AppColors.background)
                : (isDark
                    ? const Color(0xFF2D2D3F).withOpacity(0.5)
                    : AppColors.border.withOpacity(0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF2D2D3F).withOpacity(0.5)
                      : AppColors.border.withOpacity(0.5)),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}
