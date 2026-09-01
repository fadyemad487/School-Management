import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../main.dart'; // To fetch the current language code
import '../../../core/network/api_client.dart';

class ParentAnnouncements extends StatefulWidget {
  final List<dynamic> announcements;
  const ParentAnnouncements({super.key, required this.announcements});

  @override
  State<ParentAnnouncements> createState() => _ParentAnnouncementsState();
}

class _ParentAnnouncementsState extends State<ParentAnnouncements> {
  String _selectedFilter = 'الكل'; // 'الكل' (All), 'عام', 'اختبار', 'واجب', 'نشاط', 'إجازة'
  late List<dynamic> _announcementsList;

  // Map to hold expansion state of each announcement ID
  final Map<String, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _announcementsList = widget.announcements;
  }

  Future<void> _handleRefresh() async {
    try {
      final res = await ApiClient().client.get('/parents/mobile/dashboard');
      if (res.data['success'] == true) {
        final announcements = res.data['data']['announcements'] as List?;
        if (announcements != null) {
          setState(() {
            _announcementsList = announcements;
          });
        }
      }
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  String _getAnnType(String title) {
    if (title.startsWith('[') && title.contains(']')) {
      final endIdx = title.indexOf(']');
      return title.substring(1, endIdx);
    }
    return 'عام';
  }

  String _getCleanTitle(String title) {
    if (title.startsWith('[') && title.contains(']')) {
      final endIdx = title.indexOf(']');
      return title.substring(endIdx + 1).trim();
    }
    return title;
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'اختبار':
        return Icons.assignment_late_rounded;
      case 'واجب':
        return Icons.edit_calendar_rounded;
      case 'نشاط':
        return Icons.groups_rounded;
      case 'إجازة':
        return Icons.event_available_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'اختبار':
        return AppColors.rose;
      case 'واجب':
        return AppColors.amber;
      case 'نشاط':
        return AppColors.emerald;
      case 'إجازة':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(String? dateStr, bool isArabic) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        final mins = difference.inMinutes;
        if (mins <= 1) return isArabic ? 'الآن' : 'Just now';
        return isArabic ? 'منذ $mins دقيقة' : '$mins mins ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        if (hours == 1) return isArabic ? 'منذ ساعة' : '1 hr ago';
        if (hours == 2) return isArabic ? 'منذ ساعتين' : '2 hrs ago';
        return isArabic ? 'منذ $hours ساعة' : '$hours hrs ago';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        if (days == 1) return isArabic ? 'أمس' : 'Yesterday';
        if (days == 2) return isArabic ? 'منذ يومين' : '2 days ago';
        return isArabic ? 'منذ $days أيام' : '$days days ago';
      } else {
        return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Localized Filters
    final filters = isArabic
        ? ['الكل', 'عام', 'اختبار', 'واجب', 'نشاط', 'إجازة']
        : ['All', 'General', 'Exam', 'Homework', 'Activity', 'Holiday'];

    // Map selected filter back to Arabic for comparison
    String filterToMatch = _selectedFilter;
    if (!isArabic) {
      final index = ['All', 'General', 'Exam', 'Homework', 'Activity', 'Holiday'].indexOf(_selectedFilter);
      if (index != -1) {
        filterToMatch = ['الكل', 'عام', 'اختبار', 'واجب', 'نشاط', 'إجازة'][index];
      }
    }

    final filteredList = _announcementsList.where((ann) {
      if (filterToMatch == 'الكل') return true;
      final type = _getAnnType(ann['title'] ?? '');
      return type == filterToMatch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121E) : AppColors.background,
      appBar: AppBar(
        title: Text(
          isArabic ? 'الإعلانات المدرسية' : 'School Announcements',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF12121E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: Column(
          children: [
          // Filters Row
          Container(
            color: isDark ? const Color(0xFF12121E) : Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: filters.map((f) {
                  final isSelected = _selectedFilter == f;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = f;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 8.w, right: 8.w),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E1E2C) : AppColors.background),
                        borderRadius: BorderRadius.circular(14.r),
                        border: isSelected ? null : Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : (isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Announcements List
          Expanded(
            child: filteredList.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: constraints.maxHeight,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24.r),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: 64.r,
                                color: AppColors.textLight,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              isArabic ? 'لا توجد إعلانات حالياً' : 'No announcements found',
                              style: GoogleFonts.cairo(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              isArabic
                                  ? 'لم يتم نشر إعلانات من هذا النوع بعد.'
                                  : 'No broadcasts matching this category.',
                              style: GoogleFonts.cairo(
                                fontSize: 13.sp,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final ann = filteredList[index];
                      final id = ann['id'] ?? index.toString();
                      final title = ann['title'] ?? '';
                      final body = ann['body'] ?? '';
                      final type = _getAnnType(title);
                      final cleanTitle = _getCleanTitle(title);
                      final color = _getColor(type);
                      final icon = _getIcon(type);
                      final timeStr = _formatTime(ann['createdAt'], isArabic);
                      final isPinned = ann['pinned'] == true;

                      final isExpanded = _expandedState[id] ?? false;

                      return Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Header
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.04),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: color,
                                      size: 18.r,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isArabic ? type : type, // Keep Arabic tags or translate (we keep same tags since teacher posts them)
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w900,
                                          color: color,
                                        ),
                                      ),
                                      Text(
                                        timeStr,
                                        style: GoogleFonts.cairo(
                                          fontSize: 10.sp,
                                          color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (isPinned)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.push_pin_rounded, color: AppColors.primary, size: 10.r),
                                          SizedBox(width: 4.w),
                                          Text(
                                            isArabic ? 'مثبت' : 'Pinned',
                                            style: GoogleFonts.cairo(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Card Body
                            Padding(
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cleanTitle,
                                    style: GoogleFonts.cairo(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : AppColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    body,
                                    maxLines: isExpanded ? null : 3,
                                    overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13.sp,
                                      color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                                      height: 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (body.length > 120) ...[
                                    SizedBox(height: 8.h),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _expandedState[id] = !isExpanded;
                                        });
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            isExpanded
                                                ? (isArabic ? 'عرض أقل' : 'Show Less')
                                                : (isArabic ? 'عرض المزيد...' : 'Read More...'),
                                            style: GoogleFonts.cairo(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
}
