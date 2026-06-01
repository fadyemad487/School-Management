import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../auth/login_screen.dart';
import 'supervisor_settings_screen.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  StreamSubscription? _socketSubscription;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, String> _attendanceMap = {}; // studentId -> status (BOARDED, ABSENT)

  // Preferences
  bool _isDarkMode = false;
  bool _isArabic = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _fetchDashboard();
    _initSocket();
  }

  void _initSocket() {
    _socketSubscription = SocketService().onEvent.listen((eventData) {
      final event = eventData['event'];
      final data = eventData['data'];

      if (event == 'database:updated') {
        if (data != null && (data['model'] == 'Driver' || data['model'] == 'Bus' || data['model'] == 'BusRoute' || data['model'] == 'Student')) {
          debugPrint('[SupervisorDashboard] Database Updated - Auto Refreshing...');
          _fetchDashboard();
        }
      } else if (event == 'dashboard:update') {
        debugPrint('[SupervisorDashboard] Transport Dashboard Updated - Auto Refreshing...');
        _fetchDashboard();
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
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

  String _translate(String ar, String en) {
    return _isArabic ? ar : en;
  }

  Future<void> _fetchDashboard({bool isPullToRefresh = false}) async {
    if (!isPullToRefresh) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await _apiClient.client.get('/mobile/transport/supervisor/dashboard');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final attendances = data['attendances'] as List<dynamic>? ?? [];
        
        final Map<String, String> loadedAttendances = {};
        for (var att in attendances) {
          loadedAttendances[att['studentId']] = att['status'];
        }

        setState(() {
          _dashboardData = data;
          _attendanceMap = loadedAttendances;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate("حدث خطأ أثناء تحميل لوحة المشرفة", "Error loading supervisor dashboard"),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitAttendance(String studentId, String status, String studentName, String gender) async {
    // Optimistic UI update
    setState(() {
      _attendanceMap[studentId] = status;
    });

    try {
      final response = await _apiClient.client.post(
        '/mobile/transport/supervisor/attendance',
        data: {
          'studentId': studentId,
          'status': status,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Success without showing any snackbars/toasts (Complete Silent Action)
      }
    } catch (e) {
      // Revert status on failure
      _fetchDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate("فشل في تسجيل حضور الطالب", "Failed to submit attendance"),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.toString().trim().isEmpty) return;
    final cleanPhone = phone.toString().trim().replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse("tel:$cleanPhone");
    try {
      final success = await launchUrl(url);
      if (!success) {
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _translate("تم نسخ الرقم $cleanPhone إلى الحافظة", "Copied $cleanPhone to clipboard"),
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF6366F1),
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _translate("تم نسخ الرقم $cleanPhone إلى الحافظة", "Copied $cleanPhone to clipboard"),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      }
    }
  }

  void _showContactsBottomSheet(Map<String, dynamic> student, Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    final father = student['father'];
    final mother = student['mother'];
    final guardian = student['guardian'];
    final studentName = _isArabic
        ? (student['nameAr']?.toString().isNotEmpty == true ? student['nameAr'] : (student['user']?['fullName'] ?? "الطالب"))
        : (student['nameEn']?.toString().isNotEmpty == true ? student['nameEn'] : (student['nameAr'] ?? student['user']?['fullName'] ?? "Student"));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  _translate("الاتصال بأولياء أمور $studentName", "Contact Parents of $studentName"),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _translate("يرجى تحديد جهة الاتصال المطلوبة لإجراء المكالمة:", "Please choose a contact to place the call:"),
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: subTextColor,
                  ),
                ),
                SizedBox(height: 20.h),
                if (father != null && father['phone'] != null && father['phone'].toString().isNotEmpty)
                  _buildContactTile(
                    title: _translate("الأب: ${father['nameAr'] ?? 'والد الطالب'}", "Father: ${father['nameEn'] ?? 'Father'}"),
                    phone: father['phone'],
                    icon: Icons.face_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    tileBg: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                  ),
                if (mother != null && mother['phone'] != null && mother['phone'].toString().isNotEmpty)
                  _buildContactTile(
                    title: _translate("الأم: ${mother['nameAr'] ?? 'والدة الطالب'}", "Mother: ${mother['nameEn'] ?? 'Mother'}"),
                    phone: mother['phone'],
                    icon: Icons.face_3_rounded,
                    iconColor: const Color(0xFFEC4899),
                    tileBg: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                  ),
                if (guardian != null && guardian['phone'] != null && guardian['phone'].toString().isNotEmpty)
                  _buildContactTile(
                    title: _translate("الوصي: ${guardian['nameAr'] ?? 'وصي الطالب'}", "Guardian: ${guardian['nameEn'] ?? 'Guardian'}"),
                    phone: guardian['phone'],
                    icon: Icons.person_pin_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    tileBg: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                  ),
                if ((father == null || father['phone'] == null) &&
                    (mother == null || mother['phone'] == null) &&
                    (guardian == null || guardian['phone'] == null))
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      _translate("لا توجد أرقام هواتف مسجلة لأولياء الأمور.", "No registered parent contact numbers found."),
                      style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactTile({
    required String title,
    required String phone,
    required IconData icon,
    required Color iconColor,
    required Color tileBg,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
        leading: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20.sp),
        ),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
            color: textColor,
          ),
        ),
        subtitle: Text(
          phone,
          style: GoogleFonts.cairo(
            fontSize: 11.sp,
            color: subTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.phone_in_talk_rounded, color: const Color(0xFF10B981), size: 18.sp),
          onPressed: () {
            Navigator.pop(context);
            _makeCall(phone);
          },
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFECFDF5),
            padding: EdgeInsets.all(8.r),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supervisor = _dashboardData?['supervisor'];
    final bus = _dashboardData?['bus'];
    final school = _dashboardData?['supervisor']?['school'] ?? _dashboardData?['school'];
    final students = _dashboardData?['students'] as List<dynamic>? ?? [];
    final schoolName = _isArabic ? (school?['nameAr'] ?? school?['name'] ?? "مدرسة WeCircle النموذجية") : (school?['nameEn'] ?? school?['name'] ?? "WeCircle Model School");

    // Fallback route name from bus routes list if student's custom route is null
    final busRoutes = bus?['routes'] as List<dynamic>? ?? [];
    final String fallbackRouteName = busRoutes.isNotEmpty 
        ? (busRoutes[0][_isArabic ? 'nameAr' : 'nameEn'] ?? busRoutes[0]['name'] ?? "خط سير الباص الرئيسي") 
        : _translate("خط سير الباص الرئيسي", "Main Bus Route");

    // Robust Supervisor Name Fallback to avoid empty names on missing English translations in DB
    final String supervisorName = _isArabic
        ? (supervisor?['nameAr']?.toString().isNotEmpty == true ? supervisor!['nameAr'] : (supervisor?['name'] ?? "مشرفة الباص"))
        : (supervisor?['nameEn']?.toString().isNotEmpty == true ? supervisor!['nameEn'] : (supervisor?['nameAr'] ?? supervisor?['name'] ?? "Bus Supervisor"));

    // Theme Variables
    final themeColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0.5,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate("بوابة مشرفة الباص", "Supervisor Bus Portal"),
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: textColor,
                ),
              ),
              Text(
                schoolName,
                style: GoogleFonts.cairo(
                  fontSize: 10.sp,
                  color: subTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_rounded, color: const Color(0xFF6366F1), size: 20.sp),
              onPressed: () {
                final supervisorData = _dashboardData?['supervisor'];
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SupervisorSettingsScreen(
                      supervisor: supervisorData,
                      onSaveSuccess: () {
                        _fetchDashboard();
                      },
                    ),
                  ),
                ).then((_) {
                  _loadPrefs();
                });
              },
            ),
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: IconButton(
                icon: Icon(Icons.logout_rounded, color: const Color(0xFFEF4444), size: 20.sp),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : RefreshIndicator(
                onRefresh: () => _fetchDashboard(isPullToRefresh: true),
                color: const Color(0xFF6366F1),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ultra-Premium Profile Card
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.support_agent_rounded,
                                size: 28.sp,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supervisorName,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    _translate(
                                      "باص رقم: ${bus?['number'] ?? 'غير محدد'} | اللوحة: ${bus?['plateNumber'] ?? 'N/A'}",
                                      "Bus No: ${bus?['number'] ?? 'N/A'} | Plate: ${bus?['plateNumber'] ?? 'N/A'}",
                                    ),
                                    style: GoogleFonts.cairo(
                                      color: subTextColor,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      _translate(
                                        "رمز المشرفة: ${supervisor?['code'] ?? 'S001'}",
                                        "Supervisor Code: ${supervisor?['code'] ?? 'S001'}",
                                      ),
                                      style: GoogleFonts.cairo(
                                        color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              title: _translate("الطلاب المعينين", "Assigned Students"),
                              value: "${students.length}",
                              icon: Icons.people_outline,
                              color: const Color(0xFF6366F1),
                              bgColor: const Color(0xFFEEF2FF),
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              borderColor: borderColor,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _buildStatItem(
                              title: _translate("ركبوا الباص اليوم", "Boarded Today"),
                              value: "${_attendanceMap.values.where((v) => v == 'BOARDED').length}",
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF10B981),
                              bgColor: const Color(0xFFECFDF5),
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _translate("قائمة تحضير وحضور الطلاب", "Student Attendance List"),
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5.sp,
                              color: textColor,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              _translate("تحديث لحظي", "Realtime Updates"),
                              style: GoogleFonts.cairo(
                                fontSize: 9.sp,
                                color: subTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // Students List
                      if (students.isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 16.w),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.people_alt_outlined, size: 40.sp, color: const Color(0xFF94A3B8)),
                              SizedBox(height: 10.h),
                              Text(
                                _translate("لا يوجد طلاب مسجلين في هذا الباص حالياً.", "No students assigned to this bus."),
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final item = students[index];
                            final student = item['student'];
                            final route = item['route'];
                            final studentId = student['id'] as String;
                            final currentStatus = _attendanceMap[studentId];
                            
                            // Robust Route Name Fallback
                            final String activeRouteName = _isArabic 
                                ? (route?['nameAr']?.toString().isNotEmpty == true ? route!['nameAr'] : (route?['name'] ?? fallbackRouteName)) 
                                : (route?['nameEn']?.toString().isNotEmpty == true ? route!['nameEn'] : (route?['nameAr'] ?? route?['name'] ?? fallbackRouteName));

                            // Student gender settings
                            final String gender = student['gender'] ?? 'MALE';
                            final bool isFemale = gender == 'FEMALE';

                            // Robust Student Name Fallback
                            final String studentName = _isArabic
                                ? (student['nameAr']?.toString().isNotEmpty == true ? student['nameAr'] : (student['user']?['fullName'] ?? "طالب"))
                                : (student['nameEn']?.toString().isNotEmpty == true ? student['nameEn'] : (student['nameAr'] ?? student['user']?['fullName'] ?? "Student"));

                            // Dynamic Action wording based on gender
                            final String boardedButtonText = isFemale 
                                ? _translate("ركبت الباص", "Boarded Bus") 
                                : _translate("ركب الباص", "Boarded Bus");
                            final String absentButtonText = isFemale 
                                ? _translate("غائبة اليوم", "Absent Today") 
                                : _translate("غائب اليوم", "Absent Today");

                            // Photo loading and placeholders
                            final String? studentPhotoUrl = student['photo'];
                            final bool hasPhoto = studentPhotoUrl != null && studentPhotoUrl.isNotEmpty && studentPhotoUrl.startsWith("http");

                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: currentStatus == "BOARDED"
                                      ? const Color(0xFF10B981).withOpacity(0.3)
                                      : currentStatus == "ABSENT"
                                          ? const Color(0xFFEF4444).withOpacity(0.3)
                                          : borderColor,
                                  width: currentStatus != null ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A).withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Dynamic profile photo or stylized gender-specific avatar placeholder
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12.r),
                                          child: SizedBox(
                                            width: 48.w,
                                            height: 48.w,
                                            child: hasPhoto
                                                ? Image.network(
                                                    studentPhotoUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return _buildGenderPlaceholder(isFemale);
                                                    },
                                                  )
                                                : _buildGenderPlaceholder(isFemale),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      studentName,
                                                      style: GoogleFonts.cairo(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13.sp,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 2.h),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on_rounded, color: const Color(0xFF3B82F6), size: 12.sp),
                                                  SizedBox(width: 4.w),
                                                  Expanded(
                                                    child: Text(
                                                      "${_translate("محطة النزول:", "Dropoff:")} $activeRouteName",
                                                      style: GoogleFonts.cairo(
                                                        color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                                        fontSize: 10.5.sp,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        // Quick Action Button for Dual-Parent contact list
                                        IconButton(
                                          icon: Icon(Icons.phone_in_talk_rounded, color: const Color(0xFF10B981), size: 18.sp),
                                          onPressed: () => _showContactsBottomSheet(student, cardColor, textColor, subTextColor, borderColor),
                                          style: IconButton.styleFrom(
                                            backgroundColor: const Color(0xFFECFDF5),
                                            padding: EdgeInsets.all(8.r),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    Divider(color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9), height: 1),
                                    SizedBox(height: 10.h),
                                    
                                    // High-End Custom Action Chips (Filling and Outlining)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        // 1. Boarded Option
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                                            child: InkWell(
                                              onTap: () => _submitAttendance(studentId, "BOARDED", studentName, gender),
                                              borderRadius: BorderRadius.circular(10.r),
                                              child: Container(
                                                height: 40.h,
                                                decoration: BoxDecoration(
                                                  color: currentStatus == "BOARDED"
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(10.r),
                                                  border: Border.all(
                                                    color: currentStatus == "BOARDED"
                                                        ? const Color(0xFF10B981)
                                                        : const Color(0xFF10B981).withOpacity(0.2),
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: currentStatus == "BOARDED"
                                                      ? [
                                                          BoxShadow(
                                                            color: const Color(0xFF10B981).withOpacity(0.2),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 3),
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                                alignment: Alignment.center,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      currentStatus == "BOARDED" ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                                      color: currentStatus == "BOARDED" ? Colors.white : const Color(0xFF047857),
                                                      size: 14.sp,
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      boardedButtonText,
                                                      style: GoogleFonts.cairo(
                                                        color: currentStatus == "BOARDED" ? Colors.white : const Color(0xFF047857),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11.sp,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // 2. Absent Option
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                                            child: InkWell(
                                              onTap: () => _submitAttendance(studentId, "ABSENT", studentName, gender),
                                              borderRadius: BorderRadius.circular(10.r),
                                              child: Container(
                                                height: 40.h,
                                                decoration: BoxDecoration(
                                                  color: currentStatus == "ABSENT"
                                                      ? const Color(0xFFEF4444)
                                                      : const Color(0xFFFEF2F2),
                                                  borderRadius: BorderRadius.circular(10.r),
                                                  border: Border.all(
                                                    color: currentStatus == "ABSENT"
                                                        ? const Color(0xFFEF4444)
                                                        : const Color(0xFFEF4444).withOpacity(0.2),
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: currentStatus == "ABSENT"
                                                      ? [
                                                          BoxShadow(
                                                            color: const Color(0xFFEF4444).withOpacity(0.2),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 3),
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                                alignment: Alignment.center,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      currentStatus == "ABSENT" ? Icons.cancel_rounded : Icons.cancel_outlined,
                                                      color: currentStatus == "ABSENT" ? Colors.white : const Color(0xFFB91C1C),
                                                      size: 14.sp,
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      absentButtonText,
                                                      style: GoogleFonts.cairo(
                                                        color: currentStatus == "ABSENT" ? Colors.white : const Color(0xFFB91C1C),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11.sp,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                        ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildGenderPlaceholder(bool isFemale) {
    return Container(
      color: isFemale ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: Text(
        isFemale ? "👧" : "👦",
        style: TextStyle(fontSize: 22.sp),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(fontSize: 10.sp, color: subTextColor, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(fontSize: 16.sp, color: textColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
