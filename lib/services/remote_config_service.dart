import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:io';

class ConfigService {
  static FirebaseRemoteConfig? _remoteConfig;
  static bool _initialized = false;

  // Default values
  static final Map<String, dynamic> _defaults = {
    'quran_api_url': 'https://api.quran.com/api/v4',
    'quran_api_language': 'en',
  };

  // Keep existing loadEnvFile method
  static Future<void> loadEnvFile() async {
    await dotenv.load();
    
    // Initialize Remote Config only on supported platforms
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        _remoteConfig = FirebaseRemoteConfig.instance;
        await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ));

        await _remoteConfig!.setDefaults(_defaults);
        await _remoteConfig!.fetchAndActivate();
        _initialized = true;
      } catch (e) {
        print('Remote Config initialization error: $e');
      }
    }
  }

  static String get(String key) {
    // First try Remote Config if initialized
    if (_initialized && _remoteConfig != null) {
      final remoteValue = _remoteConfig!.getString(key);
      if (remoteValue.isNotEmpty) return remoteValue;
    }
    // Fallback to .env
    return dotenv.env[key] ?? '';
  }

  // Keep existing getters
  static String get openAiApiKey => get('OPENAI_API_KEY');
  
  static String get quranApiUrl {
    if (_initialized && _remoteConfig != null) {
      return _remoteConfig!.getString('quran_api_url');
    }
    return get('QURAN_API_URL');
  }
  
  static String get quranApiLanguage {
    if (_initialized && _remoteConfig != null) {
      return _remoteConfig!.getString('quran_api_language');
    }
    return get('QURAN_API_LANGUAGE');
  }
}