import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/network/api_client.dart';
import '../../main.dart';
import '../auth/login_screen.dart';

class SupervisorSettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? supervisor;
  final VoidCallback onSaveSuccess;

  const SupervisorSettingsScreen({
    super.key,
    required this.supervisor,
    required this.onSaveSuccess,
  });

  @override
  State<SupervisorSettingsScreen> createState() => _SupervisorSettingsScreenState();
}

class _SupervisorSettingsScreenState extends State<SupervisorSettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();

  // Text Editing Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? _selectedPhoto;
  
  // Password Controllers
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Settings State
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  bool _isArabic = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    final name = widget.supervisor?['nameAr'] ?? widget.supervisor?['name'] ?? "";
    final phone = widget.supervisor?['phone'] ?? "";
    _selectedPhoto = widget.supervisor?['personalPhoto'] ?? "";

    _nameController = TextEditingController(text: name);
    _phoneController = TextEditingController(text: phone);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final themeStr = prefs.getString('app_theme');
      if (themeStr != null) {
        _isDarkMode = themeStr == 'dark';
      } else {
        _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      }

      final langStr = prefs.getString('app_lang');
      if (langStr != null) {
        _isArabic = langStr == 'ar';
      } else {
        _isArabic = prefs.getBool('is_arabic') ?? true;
      }
    });
  }

  Future<void> _toggleDarkMode(bool v) async {
    setState(() => _isDarkMode = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', v ? 'dark' : 'light');
    await prefs.setBool('is_dark_mode', v);
    
    if (mounted) {
      WeCircleApp.setThemeMode(context, v ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _toggleLanguage(bool isAr) async {
    setState(() => _isArabic = isAr);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', isAr ? 'ar' : 'en');
    await prefs.setBool('is_arabic', isAr);
    
    if (mounted) {
      WeCircleApp.setLocale(context, Locale(isAr ? 'ar' : 'en'));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Dismiss the picker bottom sheet
        Navigator.pop(context);

        setState(() {
          _isUploadingPhoto = true;
        });

        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = image.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
        final dataUrl = 'data:$mimeType;base64,$base64String';

        // Instant upload to server database!
        final response = await _apiClient.client.put(
          '/mobile/transport/supervisor/profile',
          data: {
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'personalPhoto': dataUrl,
          },
        );

        setState(() {
          _isUploadingPhoto = false;
        });

        if (response.statusCode == 200 && response.data['success'] == true) {
          setState(() {
            _selectedPhoto = dataUrl;
          });
          // Immediately sync with the dashboard avatar in real-time
          widget.onSaveSuccess();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isArabic ? "تم تحديث الصورة الشخصية بنجاح 📸" : "Profile photo updated successfully 📸",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception();
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingPhoto = false;
      });
      _showError(
        context,
        _isArabic 
            ? "حدث خطأ أثناء رفع وتحديث الصورة الشخصية" 
            : "An error occurred while uploading profile photo",
      );
    }
  }

  ImageProvider _getProfileImageProvider(String? photo) {
    if (photo == null || photo.isEmpty) {
      return const NetworkImage('https://cdn-icons-png.flaticon.com/512/149/149071.png');
    }
    if (photo.startsWith('data:image') || photo.startsWith('base64')) {
      final base64String = photo.contains('base64,') ? photo.split('base64,')[1] : photo;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return const NetworkImage('https://cdn-icons-png.flaticon.com/512/149/149071.png');
      }
    }
    return NetworkImage(photo);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    // Password validation if they filled any password fields
    final bool passwordChanged = _newPasswordController.text.isNotEmpty;
    if (passwordChanged) {
      if (_newPasswordController.text.length < 6) {
        _showError(context, _isArabic ? "كلمة المرور يجب ألا تقل عن 6 أحرف" : "Password must be at least 6 characters");
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showError(context, _isArabic ? "كلمتا المرور الجديدتان غير متطابقتين" : "Confirm password does not match");
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> body = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'personalPhoto': _selectedPhoto ?? "",
      };

      if (passwordChanged) {
        body['newPassword'] = _newPasswordController.text;
      }

      final response = await _apiClient.client.put(
        '/mobile/transport/supervisor/profile',
        data: body,
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (passwordChanged) {
          // Clear credentials stored in preferences to secure the session
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');

          // Force silent logout redirect to Login page, clearing routing stack!
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          // Refresh the dashboard only if the session continues!
          widget.onSaveSuccess();

          // Regular success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isArabic ? "تم حفظ التغييرات بنجاح 💾" : "Changes saved successfully 💾",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = _isArabic ? "حدث خطأ أثناء حفظ الإعدادات" : "Error saving settings";
      _showError(context, errorMsg);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isArabic ? "تعديل الصورة الشخصية" : "Edit Personal Photo",
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              _isArabic 
                  ? "اختر طريقة التقاط صورتك الشخصية لحفظها في الحساب:" 
                  : "Select a method to upload your profile photo:",
              style: GoogleFonts.cairo(
                fontSize: 11.sp,
                color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.camera_enhance_rounded, color: const Color(0xFF6366F1), size: 24.sp),
                          SizedBox(height: 6.h),
                          Text(
                            _isArabic ? "التقاط صورة" : "Camera",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.photo_library_rounded, color: const Color(0xFF10B981), size: 24.sp),
                          SizedBox(height: 6.h),
                          Text(
                            _isArabic ? "معرض الصور" : "Gallery",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: themeColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 16.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isArabic ? "الإعدادات" : "Settings",
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Top Account Banner
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEEF2FF),
                                border: Border.all(color: const Color(0xFF6366F1), width: 2.5.w),
                                image: DecorationImage(
                                  image: _getProfileImageProvider(_selectedPhoto),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: _isUploadingPhoto
                                  ? Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.0,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            if (!_isUploadingPhoto)
                              GestureDetector(
                                onTap: _showAvatarPicker,
                                child: Container(
                                  padding: EdgeInsets.all(5.r),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6366F1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : (_isArabic ? "مشرفة الباص" : "Bus Supervisor"),
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          _phoneController.text.isNotEmpty ? _phoneController.text : (_isArabic ? "لم يتم تسجيل هاتف" : "No phone number"),
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Section 2: Personal Profile Inputs
                  _buildSectionHeader(_isArabic ? "تعديل الحساب" : "Edit Profile", Icons.person_outline_rounded, textColor),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: _isDarkMode ? Colors.transparent : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          label: _isArabic ? "الاسم الكامل" : "Full Name",
                          controller: _nameController,
                          icon: Icons.badge_outlined,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          enabled: false,
                        ),
                        SizedBox(height: 12.h),
                        _buildTextField(
                          label: _isArabic ? "رقم الهاتف" : "Phone Number",
                          controller: _phoneController,
                          icon: Icons.phone_android_rounded,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? (_isArabic ? "لا يمكن ترك الهاتف فارغاً" : "Phone cannot be empty") : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Section 3: Restored App preferences (Language / Theme)
                  _buildSectionHeader(_isArabic ? "تفضيلات التطبيق" : "App Preferences", Icons.palette_outlined, textColor),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: _isDarkMode ? Colors.transparent : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        // Theme Switcher Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(_isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: const Color(0xFF6366F1), size: 18.sp),
                                SizedBox(width: 10.w),
                                Text(
                                  _isArabic ? "مظهر داكن (Dark Mode)" : "Dark Theme",
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.sp, color: textColor),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isDarkMode,
                              activeColor: const Color(0xFF6366F1),
                              onChanged: _toggleDarkMode,
                            ),
                          ],
                        ),
                        Divider(height: 20.h, color: const Color(0xFFE2E8F0)),
                        // Language Switcher Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.language_rounded, color: const Color(0xFF10B981), size: 18.sp),
                                SizedBox(width: 10.w),
                                Text(
                                  _isArabic ? "لغة التطبيق (Language)" : "App Language",
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.sp, color: textColor),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleLanguage(true),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                    decoration: BoxDecoration(
                                      color: _isArabic ? const Color(0xFF6366F1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      "العربية",
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.sp,
                                        color: _isArabic ? Colors.white : subTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                GestureDetector(
                                  onTap: () => _toggleLanguage(false),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                    decoration: BoxDecoration(
                                      color: !_isArabic ? const Color(0xFF6366F1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      "EN",
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.sp,
                                        color: !_isArabic ? Colors.white : subTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Section 4: Password Inputs
                  _buildSectionHeader(_isArabic ? "تغيير كلمة المرور" : "Change Password", Icons.lock_outline_rounded, textColor),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: _isDarkMode ? Colors.transparent : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          label: _isArabic ? "كلمة المرور الجديدة" : "New Password",
                          controller: _newPasswordController,
                          icon: Icons.vpn_key_outlined,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          obscureText: _isObscureNew,
                          suffixIcon: IconButton(
                            icon: Icon(_isObscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16.sp),
                            onPressed: () => setState(() => _isObscureNew = !_isObscureNew),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildTextField(
                          label: _isArabic ? "تأكيد كلمة المرور الجديدة" : "Confirm New Password",
                          controller: _confirmPasswordController,
                          icon: Icons.check_circle_outline_rounded,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          obscureText: _isObscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(_isObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16.sp),
                            onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Section 5: Dynamic Save Button
                  Container(
                    width: double.infinity,
                    height: 46.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isArabic ? "حفظ التغييرات" : "Save Changes",
                              style: GoogleFonts.cairo(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15.sp, color: const Color(0xFF6366F1)),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color textColor,
    required Color subTextColor,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.cairo(
        fontSize: 12.5.sp,
        color: enabled ? textColor : subTextColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: subTextColor, fontSize: 11.sp),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 15.sp),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled 
            ? (_isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
            : (_isDarkMode ? const Color(0xFF151D2A) : Colors.grey[100]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: _isDarkMode ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: _isDarkMode ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: _isDarkMode ? Colors.transparent : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
    );
  }
}
