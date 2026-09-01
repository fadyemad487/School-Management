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

class TeacherTasksScreen extends StatefulWidget {
  const TeacherTasksScreen({super.key});

  @override
  State<TeacherTasksScreen> createState() => _TeacherTasksScreenState();
}

class _TeacherTasksScreenState extends State<TeacherTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = true;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '10');
  String? _selectedClassId;
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));

  List<dynamic> _classes = [];
  List<_TeacherTask> _activeTasks = [];
  List<_TeacherTask> _pastTasks = [];

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
    _pointsCtrl.dispose();
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
        'tasks_notifications',
        'Tasks Notifications',
        channelDescription: 'Notifications for student tasks',
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
      final taskRes = await _apiClient.client.get('/student-tasks');

      if (classRes.data['success'] == true) {
        _classes = classRes.data['data'] as List;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
        }
      }

      if (taskRes.data['success'] == true) {
        final List tasks = taskRes.data['data'];
        final now = DateTime.now();
        List<_TeacherTask> active = [];
        List<_TeacherTask> past = [];

        for (var t in tasks) {
          final isClosed = t['dueDate'] != null && DateTime.parse(t['dueDate']).isBefore(now);
          
          final teacherTask = _TeacherTask(
            t['id'],
            t['class']?['name'] ?? 'فصل غير محدد',
            t['title'] ?? 'بدون عنوان',
            t['dueDate'] != null ? DateFormat('dd MMM').format(DateTime.parse(t['dueDate'])) : 'بدون موعد',
            t['rewardPoints'] ?? 0,
            t['completions']?.length ?? 0,
            t['class']?['students']?.length ?? 30, // Fallback total
            isClosed ? AppColors.textMedium : const Color(0xFF8B5CF6),
            t['class']?['students'] ?? [],
            t['completions'] ?? [],
          );

          if (isClosed) past.add(teacherTask);
          else active.add(teacherTask);
        }
        _activeTasks = active;
        _pastTasks = past;
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
          'مهمات الطلاب',
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
          labelColor: const Color(0xFF8B5CF6),
          unselectedLabelColor: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
          indicatorColor: const Color(0xFF8B5CF6),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13.sp),
          unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13.sp),
          tabs: const [
            Tab(text: 'مهام نشطة'),
            Tab(text: 'مهام سابقة'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(_activeTasks, true),
              _buildTaskList(_pastTasks, false),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.emoji_events_rounded, color: Colors.white),
        label: Text(
          'مهمة جديدة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<_TeacherTask> list, bool isActive) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'لا توجد مهام حالياً',
          style: GoogleFonts.cairo(color: AppColors.textMedium, fontSize: 14.sp),
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
      children: list.map((t) => _buildTaskCard(t, isActive)).toList(),
    );
  }

  Widget _buildTaskCard(_TeacherTask task, bool isActive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double progress = task.total > 0 ? task.completed / task.total : 0;
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
                  color: task.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  task.classLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: task.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars_rounded, size: 12.r, color: const Color(0xFFF59E0B)),
                        SizedBox(width: 4.w),
                        Text(
                          '${task.points} نقطة',
                          style: GoogleFonts.cairo(
                            fontSize: 10.sp,
                            color: const Color(0xFFD97706),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _showDeleteTaskDialog(context, task),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16.r,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            task.title,
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
                'نسبة الإنجاز',
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${task.completed} من ${task.total}',
                style: GoogleFonts.cairo(
                  fontSize: 11.sp,
                  color: task.color,
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
              valueColor: AlwaysStoppedAnimation<Color>(task.color),
            ),
          ),
          if (isActive) ...[
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _showMarkCompleteDialog(context, task),
              style: ElevatedButton.styleFrom(
                backgroundColor: task.color.withOpacity(0.1),
                foregroundColor: task.color,
                elevation: 0,
                minimumSize: Size(double.infinity, 40.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                'تأكيد الإنجاز ومنح النقاط',
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMarkCompleteDialog(BuildContext context, _TeacherTask task) {
    // Basic dialog to select a student ID to grant points
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('منح النقاط للطالب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('أدخل Student ID لإتمام المهمة ${task.title}:', style: GoogleFonts.cairo()),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'Student ID'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _markTaskCompleted(task.id, ctrl.text.trim());
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _markTaskCompleted(String taskId, String studentId) async {
    if (studentId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.client.post('/student-tasks/$taskId/complete', data: {
        'studentId': studentId
      });
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم منح النقاط بنجاح!', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.emerald,
        ));
        _fetchData();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ: ${res.data['message']}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('حدث خطأ أثناء الاتصال.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showDeleteTaskDialog(BuildContext context, _TeacherTask task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'حذف المهمة',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه المهمة؟',
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size(100.w, 40.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.client.delete('/student-tasks/$taskId');
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم حذف المهمة بنجاح!', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.emerald,
        ));
        _fetchData();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ: ${res.data['message']}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('حدث خطأ أثناء الاتصال.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showAddTaskSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'إضافة مهمة تفاعلية',
                style: GoogleFonts.cairo(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              Text(
                'سيتلقى أولياء الأمور إشعاراً بالمهمة لتحفيز أبنائهم',
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 24.h),
              _buildFieldLabel(context, 'اختر الفصل'),
              _buildClassSelector(context, setSheetState),
              SizedBox(height: 16.h),
              _buildFieldLabel(context, 'عنوان المهمة'),
              _buildTextField(context, hint: 'مثال: قراءة قصة قصيرة', controller: _titleCtrl),
              SizedBox(height: 16.h),
              _buildFieldLabel(context, 'النقاط الممنوحة (مكافأة)'),
              _buildTextField(context, hint: '10', controller: _pointsCtrl, isNumber: true),
              SizedBox(height: 16.h),
              _buildFieldLabel(context, 'الوصف (اختياري)'),
              _buildTextField(context, hint: 'اكتب تفاصيل المهمة...', controller: _descCtrl, maxLines: 3),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'نشر المهمة',
                    style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildClassSelector(BuildContext context, StateSetter setSheetState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121E) : AppColors.background,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          isExpanded: true,
          items: _classes
              .map((c) => DropdownMenuItem<String>(
                    value: c['id'],
                    child: Text(c['name'] ?? '', style: GoogleFonts.cairo(fontSize: 14.sp, color: isDark ? Colors.white : Colors.black)),
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

  Widget _buildTextField(BuildContext context, {required String hint, required TextEditingController controller, int maxLines = 1, bool isNumber = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.cairo(fontSize: 14.sp, color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight, fontSize: 13.sp),
        filled: true,
        fillColor: isDark ? const Color(0xFF12121E) : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _submitTask() async {
    if (_selectedClassId == null) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال عنوان المهمة')));
      return;
    }

    Navigator.pop(context); // Close bottom sheet
    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.client.post('/student-tasks', data: {
        'classId': _selectedClassId,
        'title': title,
        'description': _descCtrl.text.trim(),
        'dueDate': _deadline.toIso8601String(),
        'rewardPoints': int.tryParse(_pointsCtrl.text) ?? 0,
      });

      if (res.data['success'] == true) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _pointsCtrl.text = '10';
        _showSuccessFeedback();
        
        // Send notification with sound to parents
        final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
        await _sendNotificationWithSound(
          title: isArabic ? '🎯 مهمة جديدة' : '🎯 New Task',
          body: isArabic 
              ? 'تم إرسال مهمة جديدة: $title'
              : 'A new task has been assigned: $title',
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
            const Icon(Icons.star_rounded, color: Colors.white),
            SizedBox(width: 12.w),
            Text('تم نشر المهمة وإشعار أولياء الأمور ✓',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
  }
}

class _TeacherTask {
  final String id, classLabel, title, deadline;
  final int points, completed, total;
  final Color color;
  final List<dynamic> students;
  final List<dynamic> completions;
  const _TeacherTask(this.id, this.classLabel, this.title, this.deadline, this.points, this.completed, this.total, this.color, this.students, this.completions);
}
