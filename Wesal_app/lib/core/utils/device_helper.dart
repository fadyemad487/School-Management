import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceHelper {
  static String? _cachedDeviceName;

  static Future<String> getDeviceName() async {
    if (_cachedDeviceName != null) return _cachedDeviceName!;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Check standard name first (usually "Fady's iPhone 16 Pro Max")
        String name = iosInfo.name;
        if (name.isEmpty || name == 'iPhone' || name == 'iPad') {
          name = iosInfo.utsname.machine; // Fallback e.g. "iPhone17,2"
        }
        _cachedDeviceName = name;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // brand + model e.g. "Samsung SM-G998B" or "Google Pixel 8 Pro"
        final brand = androidInfo.brand.toUpperCase();
        final model = androidInfo.model;
        if (model.toUpperCase().startsWith(brand)) {
          _cachedDeviceName = model;
        } else {
          _cachedDeviceName = '$brand $model';
        }
      } else {
        _cachedDeviceName = Platform.operatingSystem;
      }
    } catch (_) {
      _cachedDeviceName = Platform.isIOS ? 'iPhone' : 'Android Device';
    }
    return _cachedDeviceName!;
  }
}
