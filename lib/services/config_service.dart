import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  // Loads the .env file
  static Future<void> loadEnvFile() async {
    await dotenv.load(); 
  }

  
  static String get(String key) {
    return dotenv.env[key] ?? ''; 
  }

  static String get openAiApiKey => get('OPENAI_API_KEY');
  static String get quranApiUrl => get('QURAN_API_URL');
  static String get quranApiLanguage => get('QURAN_API_LANGUAGE');
}
