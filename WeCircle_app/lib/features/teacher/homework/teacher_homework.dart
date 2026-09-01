import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import 'package:intl/intl.dart';
import '../../../main.dart';

class TeacherHomework extends StatefulWidget {
  const TeacherHomework({super.key});

  @override
  State<TeacherHomework> createState() => _TeacherHomeworkState();
}

class _TeacherHomeworkState extends State<TeacherHomework> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = true;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedClassId;
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));

  List<dynamic> _classes = [];
  List<_TeacherHW> _activeHW = [];
  List<_TeacherHW> _pastHW = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeNotifications();
    _fetchData();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendNotificationWithSound({
    required String title,
    required String body,
  }) async {
    try {
      // Play notification sound
      await _audioPlayer.play(AssetSource('sounds/notification_bell.wav'));
      
      // Show notification with proper styling
      const androidDetails = AndroidNotificationDetails(
        'homework_notifications',
        'Homework Notifications',
        channelDescription: 'Notifications for homework assignments',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      // Silently handle notification errors
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final classRes = await _apiClient.client.get('/teachers/mobile/classes');
      final hwRes = await _apiClient.client.get('/homework');

      if (classRes.data['success'] == true) {
        _classes = classRes.data['data'] as List;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
        }
      }

      if (hwRes.data['success'] == true) {
        final List hws = hwRes.data['data'];
        final now = DateTime.now();
        List<_TeacherHW> active = [];
        List<_TeacherHW> past = [];

        for (var hw in hws) {
          final isClosed = hw['status'] == 'CLOSED' || 
              (hw['dueDate'] != null && DateTime.parse(hw['dueDate']).isBefore(now));
          
          final teacherHw = _TeacherHW(
            hw['id'] ?? '',
            hw['class']?['id'] ?? '',
            hw['class']?['name'] ?? 'فصل غير محدد',
            hw['title'] ?? 'بدون عنوان',
            hw['dueDate'] != null ? DateFormat('dd MMM').format(DateTime.parse(hw['dueDate'])) : 'بدون موعد',
            hw['_count']?['submissions'] ?? 0,
            hw['class']?['students']?.length ?? 30, // Mock total if not returned
            isClosed ? AppColors.textMedium : AppColors.primary,
            hw['description'] as String?,
          );

          if (isClosed) past.add(teacherHw);
          else active.add(teacherHw);
        }
        _activeHW = active;
        _pastHW = past;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: appScreenBackground(context),
      appBar: AppBar(
        title: Text(
          'إدارة الواجبات',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: appScreenBackground(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13.sp),
          unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13.sp),
          tabs: const [
            Tab(text: 'نشطة'),
            Tab(text: 'سابقة'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildHomeworkList(_activeHW, true),
              _buildHomeworkList(_pastHW, false),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHomeworkSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'واجب جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHomeworkList(List<_TeacherHW> list, bool isActive) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
      children: list.map((hw) => _buildHWCard(hw, isActive)).toList(),
    );
  }

  Widget _buildHWCard(_TeacherHW hw, bool isActive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double progress = hw.total > 0 ? hw.submitted / hw.total : 0;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: hw.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  hw.classLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: hw.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18.r, color: Colors.red),
                onPressed: () => _showDeleteDialog(hw.id, hw.title),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
              ),
              Icon(Icons.calendar_today_rounded, size: 12.r, color: AppColors.textLight),
              SizedBox(width: 6.w),
              Text(
                hw.deadline,
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            hw.title,
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نسبة التسليم',
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${hw.submitted} من ${hw.total}',
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: hw.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: isDark ? const Color(0xFF12121E) : AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(hw.color),
            ),
          ),
          if (isActive) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditHomeworkSheet(hw),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                    child: Text(
                      'تعديل',
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _showSubmissions(hw),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                    child: Text(
                      'عرض التسليمات',
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddHomeworkSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'إضافة واجب جديد',
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'سيتم إرسال إشعار فور النشر لجميع طلاب الفصل',
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildFieldLabel(context, 'اختر الفصل'),
                _buildClassSelector(context, setSheetState),
                SizedBox(height: 12.h),
                _buildFieldLabel(context, 'عنوان الواجب'),
                _buildTextField(context, hint: 'مثال: حل تمارين الضرب ص 20', controller: _titleCtrl),
                SizedBox(height: 12.h),
                _buildFieldLabel(context, 'وصف المهام (اختياري)'),
                _buildTextField(context, hint: 'اكتب تفاصيل الواجب هنا...', controller: _descCtrl, maxLines: 3),
                SizedBox(height: 12.h),
                _buildFieldLabel(context, 'تاريخ التسليم'),
                _buildDatePicker(context, setSheetState),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitHomework,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      'نشر الواجب الآن',
                      style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildClassSelector(BuildContext context, StateSetter setSheetState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121E) : AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          isExpanded: true,
          items: _classes
              .map((c) => DropdownMenuItem<String>(
                    value: c['id'],
                    child: Text(c['name'] ?? '', style: GoogleFonts.cairo(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black)),
                  ))
              .toList(),
          onChanged: (v) {
            setSheetState(() => _selectedClassId = v);
            setState(() => _selectedClassId = v);
          },
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, {required String hint, required TextEditingController controller, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.cairo(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight, fontSize: 12.sp),
        filled: true,
        fillColor: isDark ? const Color(0xFF12121E) : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, StateSetter setSheetState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _deadline,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark ? const ColorScheme.dark(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Color(0xFF1E1E2C),
                  onSurface: Colors.white,
                ) : const ColorScheme.light(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (d != null) {
          setSheetState(() => _deadline = d);
          setState(() => _deadline = d);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12121E) : AppColors.background,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20.r),
            SizedBox(width: 12.w),
            Text(
              '${_deadline.day} / ${_deadline.month} / ${_deadline.year}',
              style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitHomework() async {
    if (_selectedClassId == null) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال عنوان الواجب')));
      return;
    }

    Navigator.pop(context); // Close bottom sheet
    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.client.post('/homework', data: {
        'classId': _selectedClassId,
        'title': title,
        'description': _descCtrl.text.trim(),
        'dueDate': _deadline.toIso8601String(),
        'status': 'OPEN',
      });

      if (res.data['success'] == true) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _showSuccessFeedback();
        
        // Send notification with sound to parents
        final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
        await _sendNotificationWithSound(
          title: isArabic ? '📚 واجب جديد' : '📚 New Homework',
          body: isArabic 
              ? 'تم إرسال واجب جديد: $title'
              : 'A new homework has been assigned: $title',
        );
        
        _fetchData();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال')));
    }
  }

  void _showSuccessFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.send_rounded, color: Colors.white),
            SizedBox(width: 12.w),
            Text('تم إرسال الواجب لجميع الطلاب ✓',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }

  void _showDeleteDialog(String homeworkId, String homeworkTitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'تأكيد الحذف',
          style: GoogleFonts.cairo(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف الواجب "$homeworkTitle"؟',
          style: GoogleFonts.cairo(
            fontSize: 13.sp,
            color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textMedium,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHomework(homeworkId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHomework(String homeworkId) async {
    try {
      final res = await _apiClient.client.delete('/homework/$homeworkId');
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_rounded, color: Colors.white),
                SizedBox(width: 12.w),
                Text('تم حذف الواجب بنجاح',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
        );
        _fetchData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحذف',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
      );
    }
  }

  void _showEditHomeworkSheet(_TeacherHW hw) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editTitleCtrl = TextEditingController(text: hw.title);
    final editDescCtrl = TextEditingController(text: hw.description ?? '');
    DateTime editDeadline = DateTime.now();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'تعديل الواجب',
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildFieldLabel(context, 'عنوان الواجب'),
                _buildTextField(context, hint: 'مثال: حل تمارين الضرب ص 20', controller: editTitleCtrl),
                SizedBox(height: 12.h),
                _buildFieldLabel(context, 'وصف المهام (اختياري)'),
                _buildTextField(context, hint: 'اكتب تفاصيل الواجب هنا...', controller: editDescCtrl, maxLines: 3),
                SizedBox(height: 12.h),
                _buildFieldLabel(context, 'تاريخ التسليم'),
                _buildEditDatePicker(context, setSheetState, editDeadline),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _updateHomework(hw.id, editTitleCtrl.text.trim(), editDescCtrl.text.trim(), editDeadline),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      'حفظ التعديلات',
                      style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditDatePicker(BuildContext context, StateSetter setSheetState, DateTime selectedDate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark ? const ColorScheme.dark(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Color(0xFF1E1E2C),
                  onSurface: Colors.white,
                ) : const ColorScheme.light(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (d != null) {
          setSheetState(() => selectedDate = d);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12121E) : AppColors.background,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20.r),
            SizedBox(width: 12.w),
            Text(
              '${selectedDate.day} / ${selectedDate.month} / ${selectedDate.year}',
              style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateHomework(String homeworkId, String title, String description, DateTime dueDate) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال عنوان الواجب')));
      return;
    }

    Navigator.pop(context); // Close bottom sheet
    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.client.patch('/homework/$homeworkId', data: {
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
      });

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12.w),
                Text('تم تحديث الواجب بنجاح ✓',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              ],
            ),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
        );
        _fetchData();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التحديث')));
    }
  }

  Future<void> _showSubmissions(_TeacherHW hw) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    try {
      final res = await _apiClient.client.get('/homework/${hw.id}/submissions');
      
      if (res.data['success'] == true) {
        final List submissions = res.data['data'] ?? [];
        
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'تسليمات الواجب: ${hw.title}',
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'عدد التسليمات: ${submissions.length}',
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: submissions.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد تسليمات بعد',
                              style: GoogleFonts.cairo(
                                fontSize: 14.sp,
                                color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: submissions.length,
                            itemBuilder: (context, index) {
                              final sub = submissions[index];
                              final studentName = sub['student']?['user']?['fullName'] ?? 'طالب غير معروف';
                              final submittedAt = sub['submittedAt'] != null 
                                  ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(sub['submittedAt'])) 
                                  : 'غير محدد';
                              final fileUrl = sub['fileUrl'];
                              
                              return Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF12121E) : AppColors.background,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40.r,
                                      height: 40.r,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Center(
                                        child: Text(
                                          studentName.isNotEmpty ? studentName[0] : '?',
                                          style: GoogleFonts.cairo(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            studentName,
                                            style: GoogleFonts.cairo(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : AppColors.textDark,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            submittedAt,
                                            style: GoogleFonts.cairo(
                                              fontSize: 11.sp,
                                              color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (fileUrl != null)
                                      IconButton(
                                        icon: Icon(Icons.download_rounded, color: AppColors.primary),
                                        onPressed: () {
                                          // TODO: Implement file download
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('سيتم تنزيل الملف قريباً')),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF2D2D3F) : AppColors.background,
                        foregroundColor: isDark ? Colors.white : AppColors.textDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'إغلاق',
                        style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحميل التسليمات',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
      );
    }
  }
}

class _TeacherHW {
  final String id;
  final String classId;
  final String classLabel, title, deadline;
  final String? description;
  final int submitted, total;
  final Color color;
  const _TeacherHW(this.id, this.classId, this.classLabel, this.title, this.deadline, this.submitted, this.total, this.color, [this.description]);
}

