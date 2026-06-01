import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart';

class ParentBus extends StatefulWidget {
  final List<dynamic> children;
  const ParentBus({super.key, required this.children});

  @override
  State<ParentBus> createState() => _ParentBusState();
}

class _ParentBusState extends State<ParentBus>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final MapController _mapController = MapController();
  StreamSubscription? _socketSubscription;
  final ApiClient _apiClient = ApiClient();

  int _selectedChildIndex = 0;
  late List<dynamic> _children;

  // Live bus state variables
  double _busLat = 24.7136; // Default to Riyadh center fallback
  double _busLng = 46.6753;
  bool _isTripActive = false;

  @override
  void initState() {
    super.initState();
    _children = List.from(widget.children);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initBusLocationForSelectedChild();
    _initSocketListener();
  }

  void _initBusLocationForSelectedChild() {
    if (_children.isEmpty) return;
    final child = _children[_selectedChildIndex];
    final bus = child['bus'];
    if (bus != null) {
      // If we have static/initial coordinates, we could set them here.
      // For now, let's keep Riyadh as base and update when sockets fire or driver moves.
      _busLat = 24.7136;
      _busLng = 46.6753;
    }
  }

  Future<void> _refreshBusData() async {
    try {
      final response = await _apiClient.client.get('/parents/mobile/dashboard');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted) {
          setState(() {
            _children = data['children'] ?? [];
          });
          _initBusLocationForSelectedChild();
        }
      }
    } catch (_) {}
  }

  void _initSocketListener() {
    _socketSubscription = SocketService().onEvent.listen((event) {
      if (event['event'] == 'bus:location_updated') {
        final data = event['data'];
        if (data != null) {
          final busId = data['busId'];
          // Find if the currently selected child's bus matches this updated busId
          if (_children.isNotEmpty) {
            final child = _children[_selectedChildIndex];
            final childBus = child['bus'];
            if (childBus != null && childBus['busId'] == busId) {
              if (mounted) {
                setState(() {
                  _busLat = (data['lat'] as num).toDouble();
                  _busLng = (data['lng'] as num).toDouble();
                  _isTripActive = data['tripActive'] ?? false;
                });
                _mapController.move(
                    LatLng(_busLat, _busLng), _mapController.camera.zoom);
              }
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.toString().trim().isEmpty) return;
    final cleanPhone =
        phone.toString().trim().replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse("tel:$cleanPhone");
    try {
      final success =
          await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!success) {
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم نسخ الرقم $cleanPhone إلى الحافظة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary,
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
              'تم نسخ الرقم $cleanPhone إلى الحافظة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  ImageProvider _getAvatarImageProvider(String? photo, bool isDriver) {
    if (photo == null || photo.isEmpty) {
      return NetworkImage(isDriver
          ? 'https://cdn-icons-png.flaticon.com/512/149/149071.png'
          : 'https://cdn-icons-png.flaticon.com/512/149/149071.png');
    }
    if (photo.startsWith('data:image') || photo.startsWith('base64')) {
      final base64String =
          photo.contains('base64,') ? photo.split('base64,')[1] : photo;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (_) {}
    }
    return NetworkImage(photo);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_children.isEmpty) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : AppColors.background,
        appBar: AppBar(
          title: Text(
            isArabic ? 'تتبع الباص' : 'Bus Tracking',
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          backgroundColor:
              isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.9),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.textDark, size: 20.r),
          ),
          actions: [
            IconButton(
              onPressed: _refreshBusData,
              icon: Icon(Icons.refresh_rounded,
                  color: isDark ? Colors.white : AppColors.textDark,
                  size: 22.r),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshBusData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  MediaQuery.of(context).padding.top,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_bus_rounded,
                        color: AppColors.slate, size: 72.r),
                    SizedBox(height: 16.h),
                    Text(
                      isArabic
                          ? 'لا يوجد أطفال مسجلين حالياً'
                          : 'No children registered currently',
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final currentChild = _children[_selectedChildIndex];
    final childBus = currentChild['bus'];
    final childName = isArabic
        ? (currentChild['nameAr'] ?? '')
        : (currentChild['nameEn'] ?? currentChild['nameAr'] ?? '');

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            isArabic ? 'تتبع الباص' : 'Bus Tracking',
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          backgroundColor: isDark
              ? const Color(0xFF1E293B).withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.textDark, size: 20.r),
          ),
          actions: [
            IconButton(
              onPressed: _refreshBusData,
              icon: Icon(Icons.refresh_rounded,
                  color: isDark ? Colors.white : AppColors.textDark,
                  size: 22.r),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Map background
            Positioned.fill(
              child: childBus == null
                  ? _buildNoBusFallback(childName, isArabic, isDark)
                  : _buildRealMap(childBus, isDark),
            ),

            if (_children.length > 1)
              Positioned(
                top: 105.h,
                left: 16.w,
                right: 16.w,
                child: _buildChildSelector(isArabic, isDark),
              ),

            // Bottom Floating Live Status Panel
            if (childBus != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildLiveStatusSheet(childBus, isArabic, isDark),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBusFallback(String childName, bool isArabic, bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshBusData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height -
              AppBar().preferredSize.height -
              MediaQuery.of(context).padding.top -
              40.h,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bus_alert_rounded,
                  color: AppColors.orange, size: 80.r),
              SizedBox(height: 24.h),
              Text(
                isArabic
                    ? 'طفلك $childName غير مسجل في أي باص مدرسي حالياً.'
                    : 'Your child $childName is not currently assigned to any school bus.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                isArabic
                    ? 'الرجاء التواصل مع إدارة المدرسة لتسجيل طفلك وتخصيص باص ومسار له.'
                    : 'Please contact the school administration to enroll your child and assign a bus route.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : AppColors.textLight,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildSelector(bool isArabic, bool isDark) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        itemCount: _children.length,
        itemBuilder: (context, index) {
          final child = _children[index];
          final childName = isArabic
              ? (child['nameAr'] ?? '')
              : (child['nameEn'] ?? child['nameAr'] ?? '');
          final isSelected = index == _selectedChildIndex;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedChildIndex = index;
                  _initBusLocationForSelectedChild();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? const Color(0xFF334155)
                          : AppColors.slateLight),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12.r,
                      backgroundColor: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.1),
                      child: Text(
                        childName.toString().isNotEmpty
                            ? childName.toString().substring(0, 1)
                            : 'ط',
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      childName,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRealMap(dynamic bus, bool isDark) {
    // Standard school coordinate or Riyadh center as placeholder route coordinates
    final schoolLatLng = LatLng(24.7236, 46.6853);
    final busLatLng = LatLng(_busLat, _busLng);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: busLatLng,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains:
              isDark ? const ['a', 'b', 'c', 'd'] : const ['a', 'b', 'c'],
          userAgentPackageName: 'io.supabase.wesal',
        ),

        // Polyline connecting bus to school for aesthetic route
        PolylineLayer(
          polylines: [
            Polyline(
              points: [busLatLng, schoolLatLng],
              color: AppColors.primary.withOpacity(0.7),
              strokeWidth: 4.0,
            ),
          ],
        ),

        MarkerLayer(
          markers: [
            // School Marker
            Marker(
              point: schoolLatLng,
              width: 50.r,
              height: 50.r,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Icon(Icons.school_rounded,
                        color: Colors.white, size: 18.r),
                  ),
                ],
              ),
            ),

            // Bus Marker
            Marker(
              point: busLatLng,
              width: 70.r,
              height: 70.r,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 50.r * _pulseAnimation.value,
                      height: 50.r * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 10.r,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(Icons.directions_bus_rounded,
                          color: Colors.white, size: 20.r),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveStatusSheet(dynamic bus, bool isArabic, bool isDark) {
    final driver = bus['driver'];
    final supervisor = bus['supervisor'];

    final driverName = driver != null
        ? (driver['name'] ?? '')
        : (isArabic ? 'غير محدد' : 'Not assigned');
    final supervisorName = supervisor != null
        ? (supervisor['name'] ?? '')
        : (isArabic ? 'غير محدد' : 'Not assigned');
    final busNum = bus['number'] ?? 'N/A';
    final plateNum = bus['plateNumber'] ?? 'N/A';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.r, 16.r, 24.r, 32.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20.r,
            offset: const Offset(0, -8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF475569) : AppColors.border,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 18.h),

          // Header with live indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'حالة الباص الحية' : 'Live Bus Status',
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${isArabic ? "باص رقم" : "Bus No."} $busNum • $plateNum',
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      color: isDark ? Colors.white60 : AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _isTripActive
                      ? const Color(0xFFECFDF5)
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20.r),
                  border: _isTripActive
                      ? Border.all(color: const Color(0xFF10B981), width: 1.w)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        color: _isTripActive
                            ? const Color(0xFF10B981)
                            : AppColors.slate,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _isTripActive
                          ? (isArabic ? 'على الطريق' : 'ON THE ROUTE')
                          : (isArabic ? 'متوقف حالياً' : 'STOPPED'),
                      style: GoogleFonts.cairo(
                        color: _isTripActive
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white70 : AppColors.textLight),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const Divider(height: 1),
          SizedBox(height: 20.h),

          // Driver Information Details Card
          if (driver != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor:
                      isDark ? const Color(0xFF334155) : AppColors.slateLight,
                  backgroundImage:
                      _getAvatarImageProvider(driver['photo'], true),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'سائق الباص' : 'Bus Driver',
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          color: isDark
                              ? AppColors.emerald
                              : const Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        driverName,
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      if (driver['phone'] != null)
                        Text(
                          driver['phone'],
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color:
                                isDark ? Colors.white60 : AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
                if (driver['phone'] != null &&
                    driver['phone'].toString().isNotEmpty)
                  GestureDetector(
                    onTap: () => _makeCall(driver['phone']),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(Icons.phone_in_talk_rounded,
                          color: const Color(0xFF10B981), size: 18.r),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
          ],

          // Supervisor Information Details Card
          if (supervisor != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor:
                      isDark ? const Color(0xFF334155) : AppColors.slateLight,
                  backgroundImage:
                      _getAvatarImageProvider(supervisor['photo'], false),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'مشرفة الباص' : 'Bus Supervisor',
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          color: isDark ? AppColors.purple : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        supervisorName,
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      if (supervisor['phone'] != null)
                        Text(
                          supervisor['phone'],
                          style: GoogleFonts.cairo(
                            fontSize: 11.sp,
                            color:
                                isDark ? Colors.white60 : AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
                if (supervisor['phone'] != null &&
                    supervisor['phone'].toString().isNotEmpty)
                  GestureDetector(
                    onTap: () => _makeCall(supervisor['phone']),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(Icons.phone_in_talk_rounded,
                          color: AppColors.primary, size: 18.r),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20.h),
          ],

          // Current Trip location details HUD
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : AppColors.slateLight,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: AppColors.rose, size: 20.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'مسار التوصيل' : 'Delivery Route',
                        style: GoogleFonts.cairo(
                          fontSize: 9.sp,
                          color: isDark ? Colors.white60 : AppColors.textLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        bus['routeName'] ??
                            (isArabic ? 'غير محدد' : 'Not assigned'),
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
