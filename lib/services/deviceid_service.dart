// lib/services/deviceid_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIDService {
  static const String _deviceIdKey = 'device_id';
  
  static Future<String> getDeviceID() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    // If we already have a stored ID, return it
    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }
    
    // Otherwise generate a new one - this will be unique per device installation
    deviceId = const Uuid().v4();
    
    // Store the ID for future use
    await prefs.setString(_deviceIdKey, deviceId);
    print('Created new device ID: $deviceId');
    return deviceId;
  }
}