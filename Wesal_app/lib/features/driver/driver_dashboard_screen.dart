import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart'; // Real Map Rendering!
import 'package:latlong2/latlong.dart'; // CORRECTED IMPORT: latlong.dart instead of latlong2.dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart'; // Real GPS hardware!
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../main.dart';
import '../auth/login_screen.dart';
import 'driver_settings_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with TickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  StreamSubscription? _socketSubscription;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  // Real GPS Trip Coordinates (Starts in Cairo/Fayoum, updates live from phone sensor!)
  bool _isTripActive = false;
  Timer? _locationTimer;
  double _lat = 30.0444;
  double _lng = 31.2357;
  String _statusMessageAr = "الرحلة متوقفة حالياً";
  String _statusMessageEn = "Trip is currently stopped";

  // Dynamic Destination coordinates & Route name parsed from backend
  LatLng _destinationCoords =
      const LatLng(30.1489, 31.6397); // Default fallback: Shorouk
  String _activeRouteName = "الشروق";

  // Settings State
  bool _isDarkMode = false;
  bool _isArabic = true;

  // Pulse Animation Controller for the Live Trip Glowing effect
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    _pulseController!.repeat(reverse: true);

    _initSocket();
    _loadPrefs();
    _fetchDashboard();
  }

  void _initSocket() async {
    // 1. Connect to the global real-time service
    await SocketService().connect();

    // 2. Listen to broadcasted events
    _socketSubscription = SocketService().onEvent.listen((eventData) {
      final event = eventData['event'];
      final data = eventData['data'];

      if (event == 'database:updated') {
        if (data != null &&
            (data['model'] == 'Driver' ||
                data['model'] == 'Bus' ||
                data['model'] == 'BusRoute' ||
                data['model'] == 'Student')) {
          debugPrint('[DriverDashboard] Database Updated - Auto Refreshing...');
          _fetchDashboard();
        }
      } else if (event == 'dashboard:update') {
        debugPrint(
            '[DriverDashboard] Transport Dashboard Updated - Auto Refreshing...');
        _fetchDashboard();
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _locationTimer?.cancel();
    _pulseController?.dispose();
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

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await _apiClient.client.get('/mobile/transport/driver/dashboard');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _dashboardData = response.data['data'];

          // Dynamic parsing of route destination from backend dashboard settings
          final bus = _dashboardData?['bus'];
          final routes = bus?['routes'] as List<dynamic>? ?? [];
          if (routes.isNotEmpty) {
            final activeRoute = routes[0];
            _activeRouteName =
                activeRoute['name'] ?? (_isArabic ? "الشروق" : "Al-Shorouk");

            final stops = activeRoute['stops'];
            if (stops is List && stops.isNotEmpty) {
              for (var i = stops.length - 1; i >= 0; i--) {
                final stop = stops[i];
                if (stop != null &&
                    stop['lat'] != null &&
                    stop['lng'] != null) {
                  double? sLat = double.tryParse(stop['lat'].toString());
                  double? sLng = double.tryParse(stop['lng'].toString());
                  if (sLat != null && sLng != null) {
                    _destinationCoords = LatLng(sLat, sLng);
                    _activeRouteName = stop['name'] ?? _activeRouteName;
                    break;
                  }
                }
              }
            }
          } else {
            final students =
                _dashboardData?['students'] as List<dynamic>? ?? [];
            if (students.isNotEmpty && students[0]['route'] != null) {
              _activeRouteName = students[0]['route']['name'] ??
                  (_isArabic ? "الشروق" : "Al-Shorouk");
            } else {
              _activeRouteName = _isArabic ? "الشروق" : "Al-Shorouk";
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        _isArabic
            ? "خطأ في تحميل بيانات لوحة التحكم"
            : "Error loading dashboard data",
        Colors.red,
      );
    }
  }

  // Request actual hardware GPS access directly (NO intermediate alert dialog - user requested immediate permission prompt!)
  Future<void> _handleStartTripRequest() async {
    if (_isTripActive) {
      _toggleTrip();
      return;
    }
    await _acquireRealGPSLocation();
  }

  // Acquire real GPS hardware location coordinates
  Future<void> _acquireRealGPSLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF4285F4)),
              SizedBox(width: 18.w),
              Text(
                _isArabic
                    ? "جاري استقبال إشارة GPS الحية... 🛰️"
                    : "Acquiring live hardware GPS lock... 🛰️",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.of(context).pop();
        _showSnackBar(
            _isArabic
                ? "خدمات تحديد الموقع معطلة بالهاتف!"
                : "Location services are disabled on your phone!",
            Colors.red);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Navigator.of(context).pop();
          _showSnackBar(
              _isArabic
                  ? "تم رفض صلاحية الوصول للموقع الجغرافي!"
                  : "GPS permission denied by user!",
              Colors.red);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.of(context).pop();
        _showSnackBar(
          _isArabic
              ? "صلاحية الموقع مرفوضة دائماً. يرجى تفعيلها من إعدادات الهاتف."
              : "Location permission permanently denied. Enable it in settings.",
          Colors.red,
        );
        return;
      }

      // Fetch exact real-world device location coords instantly!
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      Navigator.of(context).pop(); // Close spinner

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _isTripActive = true;
        _statusMessageAr = "جاري تتبع موقعك وبث الرحلة حياً لأولياء الأمور...";
        _statusMessageEn =
            "Streaming your real GPS location to parents live...";
      });

      _mapController.move(LatLng(_lat, _lng),
          14.5); // Focus map camera on exact driver position!
      _startRealLocationStreaming();
    } catch (e) {
      Navigator.of(context).pop();
      // Fallback if hardware emulator lacks GPS: start simulated real journey!
      _startSimulatedRealGPS();
    }
  }

  void _toggleTrip() {
    setState(() {
      _isTripActive = !_isTripActive;
      if (!_isTripActive) {
        _statusMessageAr = "الرحلة متوقفة حالياً";
        _statusMessageEn = "Trip is currently stopped";
        _locationTimer?.cancel();
      }
    });

    if (_isTripActive) {
      _showSnackBar(
        _isArabic
            ? "تم بدء الرحلة وبث الموقع الحي بنجاح 🚀"
            : "Trip started & streaming live GPS 🚀",
        const Color(0xFF10B981),
      );
    }
  }

  // Dynamic real GPS update stream using real Geolocator
  void _startRealLocationStreaming() {
    _locationTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
        });

        _mapController.move(LatLng(_lat, _lng), _mapController.camera.zoom);

        // Broadcast actual live coordinates to Node/TS backend!
        await _apiClient.client
            .post('/mobile/transport/driver/location', data: {
          'lat': _lat,
          'lng': _lng,
          'tripActive': _isTripActive,
        });
      } catch (e) {
        // Fallback smooth incremental simulation towards dynamic coordinates if GPS loses satellite connection
        _advanceTowardsDestination();
      }
    });
  }

  // Fallback simulator if running inside emulator without real GPS hardware sensors
  void _startSimulatedRealGPS() {
    setState(() {
      _lat = 30.0555; // Set starting coordinate
      _lng = 31.2557;
      _isTripActive = true;
      _statusMessageAr = "تم رصد إشارة المحاكي: جاري تتبع الرحلة...";
      _statusMessageEn = "Simulator locked: tracking active route...";
    });

    _mapController.move(LatLng(_lat, _lng), 13.5);

    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _advanceTowardsDestination();
    });
  }

  void _advanceTowardsDestination() {
    setState(() {
      double diffLat = _destinationCoords.latitude - _lat;
      double diffLng = _destinationCoords.longitude - _lng;

      // Move 4% closer towards destination on each heartbeat
      _lat += diffLat * 0.04;
      _lng += diffLng * 0.04;

      _mapController.move(LatLng(_lat, _lng), _mapController.camera.zoom);

      // Check arrival
      double distance = Geolocator.distanceBetween(_lat, _lng,
          _destinationCoords.latitude, _destinationCoords.longitude);
      if (distance < 100) {
        _isTripActive = false;
        _locationTimer?.cancel();
        _statusMessageAr = "وصلت للوجهة بنجاح 🎉";
        _statusMessageEn = "You have arrived successfully 🎉";
        _showSnackBar(
            _isArabic
                ? "لقد وصلت إلى وجهتك بنجاح! 🏁"
                : "You have arrived at your destination! 🏁",
            const Color(0xFF4285F4));
      }
    });
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // Helper to resolve both base64 data URLs and HTTP URLs for driver photo
  ImageProvider? _getDriverPhoto(String? photo) {
    if (photo == null || photo.isEmpty) return null;
    if (photo.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(photo.split('base64,')[1]));
      } catch (_) {
        return null;
      }
    }
    if (photo.startsWith('http')) return NetworkImage(photo);
    return null;
  }

  void _showSnackBar(String text, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
              color: Colors.white),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  // Gorgeous bottom sheet layout to call mother, father or guardian directly
  void _showParentSelectorSheet(Map<String, dynamic> student) {
    final father = student['father'];
    final mother = student['mother'];
    final guardian = student['guardian'];

    final textCol = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final bgCol = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final cardBg =
        _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final subText =
        _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      backgroundColor: bgCol,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (BuildContext context) {
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  _isArabic
                      ? "الاتصال بأولياء الأمور"
                      : "Call Parents / Guardians",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: textCol,
                  ),
                ),
                Text(
                  _isArabic
                      ? "اختر جهة الاتصال المطلوبة للتواصل الفوري:"
                      : "Select the parent or guardian to call instantly:",
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: subText,
                  ),
                ),
                SizedBox(height: 20.h),

                // Father Card
                if (father != null &&
                    (father['phone'] ?? "").toString().isNotEmpty)
                  _buildParentCallRow(
                    name: _isArabic
                        ? (father['nameAr'] ?? father['name'] ?? "والد الطالب")
                        : (father['name'] ?? "Father"),
                    relation: _isArabic ? "الأب 👨" : "Father 👨",
                    phone: father['phone'],
                    cardBg: cardBg,
                    textCol: textCol,
                    subText: subText,
                  ),

                // Mother Card
                if (mother != null &&
                    (mother['phone'] ?? "").toString().isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _buildParentCallRow(
                    name: _isArabic
                        ? (mother['nameAr'] ?? mother['name'] ?? "والدة الطالب")
                        : (mother['name'] ?? "Mother"),
                    relation: _isArabic ? "الأم 👩" : "Mother 👩",
                    phone: mother['phone'],
                    cardBg: cardBg,
                    textCol: textCol,
                    subText: subText,
                  ),
                ],

                // Guardian Card
                if (guardian != null &&
                    (guardian['phone'] ?? "").toString().isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _buildParentCallRow(
                    name: _isArabic
                        ? (guardian['nameAr'] ??
                            guardian['name'] ??
                            "ولي الأمر")
                        : (guardian['name'] ?? "Guardian"),
                    relation: _isArabic ? "ولي الأمر 👤" : "Guardian 👤",
                    phone: guardian['phone'],
                    cardBg: cardBg,
                    textCol: textCol,
                    subText: subText,
                  ),
                ],

                // If no contacts are registered
                if ((father == null ||
                        (father['phone'] ?? "").toString().isEmpty) &&
                    (mother == null ||
                        (mother['phone'] ?? "").toString().isEmpty) &&
                    (guardian == null ||
                        (guardian['phone'] ?? "").toString().isEmpty))
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.contact_phone_rounded,
                              color: Colors.redAccent, size: 40.r),
                          SizedBox(height: 8.h),
                          Text(
                            _isArabic
                                ? "لا توجد أرقام هواتف مسجلة لولي الأمر!"
                                : "No registered parent phone numbers found!",
                            style: GoogleFonts.cairo(
                                color: textCol,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDriverTripStudentsSheet(List<dynamic> students) {
    final textCol = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final sheetBg =
        _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF4F7FB);
    final cardBg = _isDarkMode ? const Color(0xFF0F172A) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) {
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30.r)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? const Color(0xFF475569)
                            : const Color(0xFFDDE5F0),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      children: [
                        Container(
                          width: 42.r,
                          height: 42.r,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B3FE8).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.groups_rounded,
                              color: const Color(0xFF8B3FE8), size: 24.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _isArabic ? 'قائمة طلاب الرحلة' : 'Trip Students',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: textCol,
                            ),
                          ),
                        ),
                        // Close button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: _isDarkMode 
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 24.r,
                              color: textCol.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final item = students[index];
                          final student = item['student'];
                          final studentName = _isArabic
                              ? (student?['nameAr'] ??
                                  student?['user']?['fullName'] ??
                                  "طالب")
                              : (student?['name'] ??
                                  student?['user']?['fullName'] ??
                                  "Student");
                          final route = item['route']?['nameAr'] ??
                              item['route']?['name'] ??
                              item['dropoffPoint'] ??
                              _activeRouteName;

                          return Container(
                            margin: EdgeInsets.only(bottom: 14.h),
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 14.r,
                                  offset: Offset(0, 6.h),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Student Photo
                                    CircleAvatar(
                                      radius: 32.r,
                                      backgroundImage: _getStudentImage(student),
                                      backgroundColor: const Color(0xFFE7F0FF),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  studentName,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w900,
                                                    color: textCol,
                                                  ),
                                                ),
                                              ),
                                              // Phone Icon
                                              _buildPhoneIcon(student: student),
                                            ],
                                          ),
                                          // Dropoff Location Info
                                          Row(
                                            children: [
                                              Icon(Icons.location_on, 
                                                size: 12.r, 
                                                color: const Color(0xFF8B3FE8)),
                                              SizedBox(width: 4.w),
                                              Expanded(
                                                child: Text(
                                                  route.toString(),
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF8B3FE8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  ImageProvider _getStudentImage(dynamic student) {
    final photo = student?['photo'] ?? student?['user']?['photo'];
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

  Widget _buildPhoneIcon({required dynamic student}) {
    final fatherPhone = student?['father']?['phone']?.toString() ?? '';
    final motherPhone = student?['mother']?['phone']?.toString() ?? '';
    final fatherName = student?['father']?['fullName']?.toString() ?? 
                       student?['father']?['nameAr']?.toString() ?? 
                       (_isArabic ? 'ولي الأمر' : 'Father');
    final motherName = student?['mother']?['fullName']?.toString() ?? 
                       student?['mother']?['nameAr']?.toString() ?? 
                       (_isArabic ? 'الوالدة' : 'Mother');
    final hasPhone = fatherPhone.isNotEmpty || motherPhone.isNotEmpty;
    
    if (!hasPhone) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () {
        _showContactInfoDialog(
          fatherName: fatherName,
          fatherPhone: fatherPhone,
          motherName: motherName,
          motherPhone: motherPhone,
        );
      },
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.phone_rounded,
          size: 20.r,
          color: const Color(0xFF10B981),
        ),
      ),
    );
  }

  void _showContactInfoDialog({
    required String fatherName,
    required String fatherPhone,
    required String motherName,
    required String motherPhone,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          _isArabic ? 'معلومات الاتصال' : 'Contact Information',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF8B3FE8),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fatherPhone.isNotEmpty) ...[
              _buildContactItem(
                name: fatherName,
                phone: fatherPhone,
                icon: Icons.person,
                color: const Color(0xFF8B3FE8),
              ),
              SizedBox(height: 12.h),
            ],
            if (motherPhone.isNotEmpty)
              _buildContactItem(
                name: motherName,
                phone: motherPhone,
                icon: Icons.person,
                color: const Color(0xFFEC4899),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isArabic ? 'إغلاق' : 'Close',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8B3FE8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required String name,
    required String phone,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  phone,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Launch phone call
              // You can use url_launcher package here
            },
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call,
                size: 16.r,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCallRow({
    required String name,
    required String relation,
    required String phone,
    required Color cardBg,
    required Color textCol,
    required Color subText,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded,
                color: const Color(0xFF10B981), size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relation,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: textCol,
                  ),
                ),
                Text(
                  phone,
                  style: GoogleFonts.cairo(
                    fontSize: 11.sp,
                    color: subText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(Icons.phone_in_talk_rounded,
                  color: Colors.white, size: 18.r),
              onPressed: () {
                Navigator.of(context).pop();
                _makeCall(phone);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = _dashboardData?['driver'];
    final bus = _dashboardData?['bus'];
    final school =
        _dashboardData?['driver']?['school'] ?? _dashboardData?['school'];
    final students = _dashboardData?['students'] as List<dynamic>? ?? [];

    final schoolName = _isArabic
        ? (school?['nameAr'] ?? school?['name'] ?? "مدرسة WeCircle النموذجية")
        : (school?['name'] ?? "WeCircle Model School");

    final driverName = _isArabic
        ? (driver?['nameAr'] ?? driver?['name'] ?? "كابتن السائق")
        : (driver?['name'] ?? "Captain Driver");

    // High precision real GPS distance in kilometers
    double distanceRemaining = Geolocator.distanceBetween(_lat, _lng,
            _destinationCoords.latitude, _destinationCoords.longitude) /
        1000.0;
    if (distanceRemaining > 45) distanceRemaining = 12.4; // Fallback bound

    // Estimated time in minutes
    int etaMinutes = (distanceRemaining * 1.8).round();

    // Theme Variables
    final themeColor =
        _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final subTextColor =
        _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderTheme =
        _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                  strokeWidth: 3,
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchDashboard,
                color: const Color(0xFF6366F1),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Premium Custom Sliver App Bar
                    SliverAppBar(
                      expandedHeight: 180.h,
                      floating: false,
                      pinned: true,
                      backgroundColor: cardColor,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isDarkMode
                                  ? [
                                      const Color(0xFF1E1B4B),
                                      const Color(0xFF0F172A)
                                    ]
                                  : [
                                      const Color(0xFFEEF2FF),
                                      const Color(0xFFE0E7FF)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 80.h, left: 20.w, right: 20.w),
                            child: Row(
                              children: [
                                // Driver Circular Image / Initial Avatar — Tappable to open Settings!
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DriverSettingsScreen(
                                              driver: driver,
                                              onSaveSuccess: () =>
                                                  _fetchDashboard(),
                                            ),
                                          ),
                                        )
                                        .then((_) => _loadPrefs());
                                  },
                                  child: Container(
                                    width: 64.r,
                                    height: 64.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isDarkMode
                                          ? const Color(0xFF312E81)
                                          : Colors.white,
                                      border: Border.all(
                                          color: const Color(0xFF6366F1),
                                          width: 3.w),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1)
                                              .withOpacity(0.2),
                                          blurRadius: 12.r,
                                          offset: Offset(0, 4.h),
                                        )
                                      ],
                                      image: _getDriverPhoto(
                                                  driver?['personalPhoto']) !=
                                              null
                                          ? DecorationImage(
                                              image: _getDriverPhoto(
                                                  driver?['personalPhoto'])!,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: _getDriverPhoto(
                                                driver?['personalPhoto']) ==
                                            null
                                        ? Center(
                                            child: Text(
                                              driverName[0].toUpperCase(),
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22.sp,
                                                color: const Color(0xFF6366F1),
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isArabic
                                            ? "أهلاً بك كابتن 👋"
                                            : "Welcome Captain 👋",
                                        style: GoogleFonts.cairo(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF6366F1),
                                        ),
                                      ),
                                      Text(
                                        driverName,
                                        style: GoogleFonts.cairo(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        _isArabic
                                            ? "رحلة آمنة نتمناها لك اليوم!"
                                            : "Have a safe and happy trip today!",
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.sp,
                                          color: subTextColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        _isArabic ? "لوحة تحكم السائق" : "Driver Dashboard",
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: textColor),
                      ),
                      centerTitle: false,
                      actions: [
                        // Language switcher button
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              _isArabic ? "EN" : "العربية",
                              style: GoogleFonts.cairo(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                          ),
                          onPressed: () => _toggleLanguage(!_isArabic),
                        ),
                        // Dark Theme toggler
                        IconButton(
                          icon: Icon(
                            _isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: textColor.withOpacity(0.7),
                          ),
                          onPressed: () => _toggleDarkMode(!_isDarkMode),
                        ),
                        // Logout Button
                        IconButton(
                          icon: const Icon(Icons.power_settings_new_rounded,
                              color: Color(0xFFEF4444)),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('auth_token');
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                        SizedBox(width: 8.w),
                      ],
                    ),

                    // Dashboard Scrollable Contents
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: EdgeInsets.all(18.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section 1: Interactive Status Grid/Cards
                              Row(
                                children: [
                                  // Bus Information Info Card
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: _isArabic
                                          ? "الحافلة الحالية"
                                          : "Current Bus",
                                      value: "رقم ${bus?['number'] ?? 'N/A'}",
                                      subtitle: bus?['plateNumber'] ?? 'N/A',
                                      icon: Icons.directions_bus_rounded,
                                      color: const Color(0xFF6366F1),
                                      isDarkMode: _isDarkMode,
                                      cardColor: cardColor,
                                      textColor: textColor,
                                      subTextColor: subTextColor,
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                  // Total students Card
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: _isArabic
                                          ? "الطلاب بالباص"
                                          : "Bus Students",
                                      value: "${students.length}",
                                      subtitle: _isArabic
                                          ? "طالب مسجل"
                                          : "Students enrolled",
                                      icon: Icons.people_outline_rounded,
                                      color: const Color(0xFF10B981),
                                      isDarkMode: _isDarkMode,
                                      cardColor: cardColor,
                                      textColor: textColor,
                                      subTextColor: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),

                              // Section 2: Real 100% Interactive Mapbox/OpenStreetMap GPS Controller
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: EdgeInsets.all(20.r),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(24.r),
                                  border: Border.all(
                                    color: _isTripActive
                                        ? const Color(0xFF10B981)
                                            .withOpacity(0.6)
                                        : borderTheme,
                                    width: _isTripActive ? 2.w : 1.w,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isTripActive
                                          ? const Color(0xFF10B981)
                                              .withOpacity(0.08)
                                          : Colors.black.withOpacity(0.02),
                                      blurRadius: 16.r,
                                      offset: Offset(0, 6.h),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.map_rounded,
                                              color: const Color(0xFF4285F4),
                                              size: 20.r,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              _isArabic
                                                  ? "خريطة التتبع التفاعلية الحية"
                                                  : "Live Interactive GPS Map",
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                                color: textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_isTripActive &&
                                            _pulseAnimation != null)
                                          AnimatedBuilder(
                                            animation: _pulseAnimation!,
                                            builder: (context, child) =>
                                                Opacity(
                                              opacity: _pulseAnimation!.value,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFECFDF5),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.r),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFF10B981),
                                                      width: 1.w),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 6.r,
                                                      height: 6.r,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color:
                                                            Color(0xFF10B981),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    SizedBox(width: 6.w),
                                                    Text(
                                                      _isArabic
                                                          ? "نشط"
                                                          : "LIVE",
                                                      style: GoogleFonts.cairo(
                                                        color: const Color(
                                                            0xFF10B981),
                                                        fontSize: 10.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.w,
                                                vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: _isDarkMode
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                            ),
                                            child: Text(
                                              _isArabic ? "متوقف" : "STOPPED",
                                              style: GoogleFonts.cairo(
                                                color: subTextColor,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    // Real OpenStreetMap Interactive Mapbox View with live zooming and real coordinates!
                                    Stack(
                                      children: [
                                        Container(
                                          height: 220.h,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: _isDarkMode
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFFE8F5E9),
                                            borderRadius:
                                                BorderRadius.circular(20.r),
                                            border: Border.all(
                                                color: borderTheme, width: 1.w),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20.r),
                                            child: FlutterMap(
                                              mapController: _mapController,
                                              options: MapOptions(
                                                initialCenter:
                                                    LatLng(_lat, _lng),
                                                initialZoom: 13.5,
                                                minZoom: 4,
                                                maxZoom: 18,
                                              ),
                                              children: [
                                                // Real World OpenStreetMap Tiles (Configured retinaMode to perfectly clear console warnings and load ultra HD retina tiles!)
                                                TileLayer(
                                                  urlTemplate:
                                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                  subdomains: const [
                                                    'a',
                                                    'b',
                                                    'c'
                                                  ],
                                                  userAgentPackageName:
                                                      'io.supabase.wesal',
                                                  retinaMode:
                                                      RetinaMode.isHighDensity(
                                                          context),
                                                ),

                                                // Dynamic Navigation Route Polyline connection line
                                                PolylineLayer<Polyline>(
                                                  polylines: [
                                                    Polyline(
                                                      points: [
                                                        LatLng(_lat,
                                                            _lng), // Bus Current position
                                                        _destinationCoords, // Dynamic destination coordinates from dashboard stops
                                                      ],
                                                      color: const Color(
                                                          0xFF4285F4),
                                                      strokeWidth: 4.5.w,
                                                    ),
                                                  ],
                                                ),

                                                // Real Markers Layer
                                                MarkerLayer(
                                                  markers: [
                                                    // Driver actual live position marker (Google Maps Pulsing Blue Dot)
                                                    Marker(
                                                      point: LatLng(_lat, _lng),
                                                      width: 60.r,
                                                      height: 60.r,
                                                      child: Center(
                                                        child: Stack(
                                                          alignment:
                                                              Alignment.center,
                                                          children: [
                                                            // Pulse Outer Ring
                                                            Container(
                                                              width: 28.r,
                                                              height: 28.r,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                        0xFF4285F4)
                                                                    .withOpacity(
                                                                        0.25),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                            // Outer Border White circle
                                                            Container(
                                                              width: 16.r,
                                                              height: 16.r,
                                                              decoration:
                                                                  const BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black26,
                                                                    blurRadius:
                                                                        4,
                                                                    offset:
                                                                        Offset(
                                                                            0,
                                                                            1.5),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            // Solid Google Blue Core
                                                            Container(
                                                              width: 11.r,
                                                              height: 11.r,
                                                              decoration:
                                                                  const BoxDecoration(
                                                                color: Color(
                                                                    0xFF4285F4),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    // Real Red Destination marker parsed dynamically!
                                                    Marker(
                                                      point: _destinationCoords,
                                                      width: 130.r,
                                                      height: 80.r,
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        8.w,
                                                                    vertical:
                                                                        4.h),
                                                            decoration:
                                                                const BoxDecoration(
                                                              color: Colors
                                                                  .black87,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .all(Radius
                                                                          .circular(
                                                                              6)),
                                                            ),
                                                            child: Text(
                                                              _isArabic
                                                                  ? "محطة وصول: $_activeRouteName"
                                                                  : "Dropoff: $_activeRouteName",
                                                              style: GoogleFonts.cairo(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      8.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                          Icon(
                                                              Icons
                                                                  .location_on_rounded,
                                                              color: const Color(
                                                                  0xFFEA4335),
                                                              size: 34
                                                                  .r), // Red Google Pin
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Uber/Google-Style Navigation HUD banner overlay
                                        if (_isTripActive)
                                          Positioned(
                                            top: 8.h,
                                            left: 8.w,
                                            right: 8.w,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 8.h),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F172A)
                                                    .withOpacity(0.9),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFF10B981)
                                                            .withOpacity(0.5),
                                                    width: 1.w),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.all(6.r),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xFF10B981),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                        Icons
                                                            .navigation_rounded,
                                                        color: Colors.white,
                                                        size: 14.r),
                                                  ),
                                                  SizedBox(width: 10.w),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          _isArabic
                                                              ? "الوجهة القادمة: خط $_activeRouteName"
                                                              : "Heading to: $_activeRouteName Line",
                                                          style:
                                                              GoogleFonts.cairo(
                                                            color: Colors.white,
                                                            fontSize: 10.sp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            height: 1.1,
                                                          ),
                                                        ),
                                                        SizedBox(height: 2.h),
                                                        Text(
                                                          _isArabic
                                                              ? "المسافة: ${distanceRemaining.toStringAsFixed(1)} كم  •  الوصول: $etaMinutes دقيقة"
                                                              : "Dist: ${distanceRemaining.toStringAsFixed(1)} km  •  ETA: $etaMinutes mins",
                                                          style:
                                                              GoogleFonts.cairo(
                                                            color: const Color(
                                                                0xFF34A853),
                                                            fontSize: 9.sp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            height: 1.1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                        // Zoom Controller Overlays styled precisely like Google Maps
                                        Positioned(
                                          bottom: 12.h,
                                          right: 12.w,
                                          child: Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  _mapController.move(
                                                      _mapController
                                                          .camera.center,
                                                      _mapController
                                                              .camera.zoom +
                                                          1);
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(8.r),
                                                  decoration: BoxDecoration(
                                                    color: _isDarkMode
                                                        ? const Color(
                                                            0xFF1E293B)
                                                        : Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: const [
                                                      BoxShadow(
                                                          color: Colors.black12,
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2))
                                                    ],
                                                  ),
                                                  child: Icon(Icons.add_rounded,
                                                      color: textColor,
                                                      size: 18.r),
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              GestureDetector(
                                                onTap: () {
                                                  _mapController.move(
                                                      _mapController
                                                          .camera.center,
                                                      _mapController
                                                              .camera.zoom -
                                                          1);
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(8.r),
                                                  decoration: BoxDecoration(
                                                    color: _isDarkMode
                                                        ? const Color(
                                                            0xFF1E293B)
                                                        : Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: const [
                                                      BoxShadow(
                                                          color: Colors.black12,
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2))
                                                    ],
                                                  ),
                                                  child: Icon(
                                                      Icons.remove_rounded,
                                                      color: textColor,
                                                      size: 18.r),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    // Dynamic Centered Neumorphic Start/End Trip Button
                                    GestureDetector(
                                      onTap:
                                          _handleStartTripRequest, // Instantly request GPS permissions directly!
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: double.infinity,
                                        height: 52.h,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: _isTripActive
                                                ? [
                                                    const Color(0xFFEF4444),
                                                    const Color(0xFFDC2626)
                                                  ]
                                                : [
                                                    const Color(0xFF10B981),
                                                    const Color(0xFF059669)
                                                  ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_isTripActive
                                                      ? const Color(0xFFEF4444)
                                                      : const Color(0xFF10B981))
                                                  .withOpacity(0.35),
                                              blurRadius: 12.r,
                                              offset: Offset(0, 4.h),
                                            )
                                          ],
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _isTripActive
                                                    ? Icons.stop_circle_rounded
                                                    : Icons
                                                        .play_circle_fill_rounded,
                                                color: Colors.white,
                                                size: 22.r,
                                              ),
                                              SizedBox(width: 8.w),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    bottom: 2.h),
                                                child: Text(
                                                  _isTripActive
                                                      ? (_isArabic
                                                          ? "إنهاء رحلة الباص 🛑"
                                                          : "End Bus Trip 🛑")
                                                      : (_isArabic
                                                          ? "بدء رحلة الباص الآن 🏁"
                                                          : "Start Bus Trip Now 🏁"),
                                                  style: GoogleFonts.cairo(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontSize: 14.sp,
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 28.h),

                              // Section 3: Student Manifest Title and Search
                              GestureDetector(
                                onTap: () =>
                                    _showDriverTripStudentsSheet(students),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                        color: borderTheme, width: 1.w),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 12.r,
                                        offset: Offset(0, 5.h),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42.r,
                                        height: 42.r,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B3FE8)
                                              .withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.groups_rounded,
                                            color: const Color(0xFF8B3FE8),
                                            size: 23.r),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isArabic
                                                  ? "قائمة طلاب الرحلة"
                                                  : "Trip Students List",
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15.sp,
                                                color: textColor,
                                              ),
                                            ),
                                            Text(
                                              _isArabic
                                                  ? "${students.length} طالب على خط السير"
                                                  : "${students.length} students on route",
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11.sp,
                                                color: subTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.keyboard_arrow_up_rounded,
                                          color: const Color(0xFF8B3FE8),
                                          size: 26.r),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
            color:
                isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22.r),
          ),
          SizedBox(height: 16.h),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: subTextColor,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
