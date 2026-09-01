import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/network/api_client.dart';
import '../auth/login_screen.dart';

class DriverSettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? driver;
  final VoidCallback? onSaveSuccess;
  const DriverSettingsScreen({super.key, this.driver, this.onSaveSuccess});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _oldPwController = TextEditingController();
  TextEditingController _newPwController = TextEditingController();
  TextEditingController _confirmPwController = TextEditingController();

  String? _selectedPhoto;
  bool _isArabic = true, _isDarkMode = false;
  bool _savingPhone = false, _savingPw = false, _uploadingPhoto = false;
  bool _showOld = false, _showNew = false, _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.driver?['phone'] ?? '');
    _oldPwController = TextEditingController();
    _newPwController = TextEditingController();
    _confirmPwController = TextEditingController();
    _selectedPhoto = widget.driver?['personalPhoto'] ?? '';
    _loadPrefs();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _oldPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = (p.getString('app_theme') ?? (p.getBool('is_dark_mode') == true ? 'dark' : 'light')) == 'dark';
      _isArabic = (p.getString('app_lang') ?? (p.getBool('is_arabic') != false ? 'ar' : 'en')) == 'ar';
    });
  }

  String _t(String ar, String en) => _isArabic ? ar : en;

  void _msg(String t, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.sp, color: Colors.white)),
      backgroundColor: c, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ));
  }

  ImageProvider _getPhoto(String? photo) {
    if (photo == null || photo.isEmpty) return const NetworkImage('https://cdn-icons-png.flaticon.com/512/3544/3544117.png');
    if (photo.startsWith('data:image')) {
      try { return MemoryImage(base64Decode(photo.split('base64,')[1])); } catch (_) {}
    }
    if (photo.startsWith('http')) return NetworkImage(photo);
    return const NetworkImage('https://cdn-icons-png.flaticon.com/512/3544/3544117.png');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (image == null) return;
      Navigator.pop(context); // close picker sheet

      setState(() => _uploadingPhoto = true);
      final bytes = await image.readAsBytes();
      final mime = image.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      final res = await _apiClient.client.put('/mobile/transport/driver/profile', data: {'personalPhoto': dataUrl});
      setState(() => _uploadingPhoto = false);

      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() => _selectedPhoto = dataUrl);
        widget.onSaveSuccess?.call();
        _msg(_t("تم تحديث الصورة الشخصية بنجاح 📸", "Profile photo updated successfully 📸"), const Color(0xFF10B981));
      }
    } catch (e) {
      setState(() => _uploadingPhoto = false);
      _msg(_t("فشل في رفع الصورة", "Failed to upload photo"), Colors.red);
    }
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t("تعديل الصورة الشخصية", "Edit Profile Photo"),
            style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : const Color(0xFF1E293B))),
          SizedBox(height: 8.h),
          Text(_t("اختر طريقة رفع صورتك:", "Choose how to upload your photo:"),
            style: GoogleFonts.cairo(fontSize: 12.sp, color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          SizedBox(height: 24.h),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                padding: EdgeInsets.all(16.r), 
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.08), 
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15), width: 1.w),
                ),
                child: Column(children: [
                  Icon(Icons.camera_enhance_rounded, color: const Color(0xFF6366F1), size: 28.r), 
                  SizedBox(height: 8.h),
                  Text(_t("التقاط صورة", "Camera"), style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.sp, color: const Color(0xFF6366F1))),
                ]),
              ),
            )),
            SizedBox(width: 16.w),
            Expanded(child: GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                padding: EdgeInsets.all(16.r), 
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08), 
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15), width: 1.w),
                ),
                child: Column(children: [
                  Icon(Icons.photo_library_rounded, color: const Color(0xFF10B981), size: 28.r), 
                  SizedBox(height: 8.h),
                  Text(_t("معرض الصور", "Gallery"), style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.sp, color: const Color(0xFF10B981))),
                ]),
              ),
            )),
          ]),
          SizedBox(height: 12.h),
        ]),
      ),
    );
  }

  Future<void> _savePhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) { _msg(_t("يرجى إدخال رقم الهاتف", "Please enter phone number"), Colors.red); return; }
    setState(() => _savingPhone = true);
    try {
      final res = await _apiClient.client.put('/mobile/transport/driver/profile', data: {'phone': phone});
      if (res.statusCode == 200 && res.data['success'] == true) {
        _msg(_t("تم تحديث رقم الهاتف بنجاح ✅", "Phone updated successfully ✅"), const Color(0xFF10B981));
        widget.onSaveSuccess?.call();
      }
    } catch (_) { _msg(_t("فشل في تحديث رقم الهاتف", "Failed to update phone"), Colors.red); }
    finally { setState(() => _savingPhone = false); }
  }

  Future<void> _savePw() async {
    final newPw = _newPwController.text.trim(), confirmPw = _confirmPwController.text.trim();
    if (newPw.length < 6) { _msg(_t("كلمة المرور الجديدة 6 أحرف على الأقل", "New password min 6 chars"), Colors.red); return; }
    if (newPw != confirmPw) { _msg(_t("كلمة المرور غير متطابقة!", "Passwords don't match!"), Colors.red); return; }
    setState(() => _savingPw = true);
    try {
      final res = await _apiClient.client.put('/mobile/transport/driver/profile', data: {'newPassword': newPw});
      if (res.statusCode == 200 && res.data['success'] == true) {
        // Silent logout like supervisor — clear token and redirect to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (_) { _msg(_t("فشل في تغيير كلمة المرور", "Failed to change password"), Colors.red); }
    finally { setState(() => _savingPw = false); }
  }

  @override
  Widget build(BuildContext context) {
    final txt = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final sub = _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final card = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final bg = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final border = _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fill = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final name = _isArabic ? (widget.driver?['nameAr'] ?? widget.driver?['name'] ?? "السائق") : (widget.driver?['name'] ?? "Driver");

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: card, elevation: 0, centerTitle: true,
          leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: txt, size: 20.r), onPressed: () => Navigator.pop(context)),
          title: Text(_t("إعدادات السائق", "Driver Settings"), style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17.sp, color: txt)),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), padding: EdgeInsets.all(20.r),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Profile Header with tappable photo
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24.r), border: Border.all(color: border, width: 1.w)),
              child: Center(
                child: Column(children: [
                  Stack(alignment: Alignment.bottomRight, children: [
                    Container(
                      width: 96.r, height: 96.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, border: Border.all(color: const Color(0xFF6366F1), width: 3.w),
                        image: DecorationImage(image: _getPhoto(_selectedPhoto), fit: BoxFit.cover),
                      ),
                      child: _uploadingPhoto ? Container(
                        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: Center(child: SizedBox(width: 24.r, height: 24.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))),
                      ) : null,
                    ),
                    if (!_uploadingPhoto)
                      GestureDetector(
                        onTap: _showPhotoPicker,
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                          child: Icon(Icons.camera_alt_rounded, size: 16.r, color: Colors.white),
                        ),
                      ),
                  ]),
                  SizedBox(height: 12.h),
                  Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18.sp, color: txt)),
                  Text(_t("سائق الباص المدرسي", "School Bus Driver"), style: GoogleFonts.cairo(fontSize: 12.sp, color: sub, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

            SizedBox(height: 28.h),

            // Phone Section
            _sectionTitle(Icons.phone_android_rounded, _t("تغيير رقم الهاتف", "Change Phone Number"), const Color(0xFF3B82F6), txt),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: border, width: 1.w)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t("رقم الهاتف", "Phone Number"),
                  style: GoogleFonts.cairo(color: sub, fontSize: 11.sp, fontWeight: FontWeight.w500)),
                SizedBox(height: 14.h),
                _input(_phoneController, _t("رقم الهاتف الجديد", "New phone number"), Icons.phone_rounded, fill, txt, sub, border, keyboard: TextInputType.phone),
                SizedBox(height: 16.h),
                _actionBtn(_t("حفظ رقم الهاتف", "Save Phone"), Icons.save_rounded, _savingPhone, [const Color(0xFF3B82F6), const Color(0xFF2563EB)], _savePhone),
              ]),
            ),

            SizedBox(height: 28.h),

            // Password Section
            _sectionTitle(Icons.lock_rounded, _t("تغيير كلمة المرور", "Change Password"), const Color(0xFFF59E0B), txt),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: border, width: 1.w)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t("كلمة المرور الجديدة 6 أحرف على الأقل.", "New password must be at least 6 characters."),
                  style: GoogleFonts.cairo(color: sub, fontSize: 11.sp, fontWeight: FontWeight.w500)),
                SizedBox(height: 14.h),
                _input(_newPwController, _t("كلمة المرور الجديدة", "New Password"), Icons.lock_rounded, fill, txt, sub, border,
                  obscure: !_showNew, suffix: IconButton(icon: Icon(_showNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: sub, size: 20.r), onPressed: () => setState(() => _showNew = !_showNew))),
                SizedBox(height: 12.h),
                _input(_confirmPwController, _t("تأكيد كلمة المرور", "Confirm Password"), Icons.lock_rounded, fill, txt, sub, border,
                  obscure: !_showConfirm, suffix: IconButton(icon: Icon(_showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: sub, size: 20.r), onPressed: () => setState(() => _showConfirm = !_showConfirm))),
                SizedBox(height: 16.h),
                _actionBtn(_t("تغيير كلمة المرور", "Change Password"), Icons.lock_reset_rounded, _savingPw, [const Color(0xFFF59E0B), const Color(0xFFD97706)], _savePw),
              ]),
            ),
            SizedBox(height: 40.h),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, Color color, Color txt) => Row(children: [
    Container(
      padding: EdgeInsets.all(8.r), 
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)),
      child: Icon(icon, color: color, size: 18.r),
    ),
    SizedBox(width: 10.w),
    Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15.sp, color: txt)),
  ]);

  Widget _input(TextEditingController c, String hint, IconData icon, Color fill, Color txt, Color hintC, Color border,
      {bool obscure = false, Widget? suffix, TextInputType? keyboard}) => TextField(
    controller: c, obscureText: obscure, keyboardType: keyboard,
    style: GoogleFonts.cairo(color: txt, fontSize: 14.sp),
    decoration: InputDecoration(
      hintText: hint, hintStyle: GoogleFonts.cairo(color: hintC, fontSize: 12.sp),
      prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20.r), suffixIcon: suffix,
      filled: true, fillColor: fill, contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: border, width: 1.w)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: border, width: 1.w)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: const Color(0xFF6366F1), width: 2.w)),
    ),
  );

  Widget _actionBtn(String label, IconData icon, bool loading, List<Color> colors, VoidCallback onTap) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      width: double.infinity, height: 50.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: loading ? colors.map((c) => c.withOpacity(0.5)).toList() : colors),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.25), blurRadius: 10.r, offset: Offset(0, 4.h))],
      ),
      child: Center(child: loading
        ? SizedBox(width: 22.r, height: 22.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 18.r), SizedBox(width: 8.w),
            Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14.sp)),
          ])),
    ),
  );
}
