import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvUtils {
  static String getApiKey() {
    return dotenv.env['OPENAI_API_KEY'] ?? '';
  }
  
  static String getQuranApiUrl() {
    return dotenv.env['QURAN_API_URL'] ?? '';
  }
  
  static String getQuranApiLanguage() {
    return dotenv.env['QURAN_API_LANGUAGE'] ?? '';
  }
}