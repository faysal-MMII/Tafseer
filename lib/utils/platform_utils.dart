import 'package:flutter/services.dart';

class PlatformUtils {
  static const MethodChannel _channel = MethodChannel('app.channel/info');
  
  static Future<int> getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    
    try {
      final String version = await _channel.invokeMethod('getAndroidVersion');
      // Android version might be like "15" or "15.0.1", so we take just the major number
      return int.parse(version.split('.').first);
    } catch (e) {
      print("Error getting Android version: $e");
      return 0; // Safe fallback
    }
  }
}
