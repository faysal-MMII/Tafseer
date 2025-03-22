import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themePreferenceKey = 'isDarkMode';
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeData get themeData => _isDarkMode 
    ? _darkTheme 
    : _lightTheme;

  // Modern Light Theme
  final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Color(0xFF2D5F7C), // Subtle blue
    scaffoldBackgroundColor: Color(0xFFF8F9FA),
    cardColor: Colors.white,
    dividerColor: Color(0xFFEEEEEE),
    
    // App Bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(
        color: Color(0xFF2D5F7C),
      ),
      titleTextStyle: TextStyle(
        color: Color(0xFF2D5F7C),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    // Icon theme
    iconTheme: IconThemeData(
      color: Color(0xFF2D5F7C),
    ),
    
    // Text theme
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Color(0xFF212121)),
      displayMedium: TextStyle(color: Color(0xFF212121)),
      displaySmall: TextStyle(color: Color(0xFF212121)),
      headlineLarge: TextStyle(color: Color(0xFF212121)),
      headlineMedium: TextStyle(color: Color(0xFF2D5F7C), fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Color(0xFF2D5F7C)),
      titleLarge: TextStyle(color: Color(0xFF2D5F7C), fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Color(0xFF212121)),
      titleSmall: TextStyle(color: Color(0xFF212121)),
      bodyLarge: TextStyle(color: Color(0xFF212121)),
      bodyMedium: TextStyle(color: Color(0xFF424242)),
      bodySmall: TextStyle(color: Color(0xFF616161)),
      labelLarge: TextStyle(color: Color(0xFF2D5F7C)),
    ),
    
    // Color scheme
    colorScheme: ColorScheme.light(
      primary: Color(0xFF2D5F7C),
      secondary: Color(0xFF5C8EA9),
      surface: Colors.white,
      background: Color(0xFFF8F9FA),
      error: Color(0xFFB00020),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF212121),
      onBackground: Color(0xFF212121),
      onError: Colors.white,
    ),
  );
  
  // Modern Dark Theme - Inspired by popular apps
  final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.cyanAccent, // Better contrast 
    scaffoldBackgroundColor: Color(0xFF121212), // Explicitly defined background
    cardColor: Color(0xFF1E1E1E),
    dividerColor: Color(0xFF2C2C2C),
    
    // App Bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(
        color: Colors.cyanAccent, // Better contrast
      ),
      titleTextStyle: TextStyle(
        color: Colors.white, // Better visibility
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    // Icon theme
    iconTheme: IconThemeData(
      color: Colors.cyanAccent, // Better contrast
    ),
    
    // Text theme with better visibility
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.white),
      displayMedium: TextStyle(color: Colors.white),
      displaySmall: TextStyle(color: Colors.white),
      headlineLarge: TextStyle(color: Colors.white),
      headlineMedium: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.cyanAccent),
      titleLarge: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white54),
      labelLarge: TextStyle(color: Colors.cyanAccent),
    ),
    
    // Color scheme
    colorScheme: ColorScheme.dark(
      primary: Colors.cyanAccent,
      secondary: Color(0xFF5C8EA9),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: Color(0xFFCF6679),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Color(0xFFE0E0E0),
      onBackground: Color(0xFFE0E0E0),
      onError: Colors.black,
    ),
  );
  
  // Helper method for container decoration in light/dark mode
  BoxDecoration getContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: _isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withOpacity(0.4)
              : Colors.black.withOpacity(0.05),
          spreadRadius: 0,
          blurRadius: _isDarkMode ? 8 : 10,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  // Helper method for elevated container decoration 
  BoxDecoration getElevatedContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: _isDarkMode ? Color(0xFF252525) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withOpacity(0.5)
              : Colors.black.withOpacity(0.08),
          spreadRadius: 0,
          blurRadius: _isDarkMode ? 12 : 15,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
  
  // Helper method for card decoration
  BoxDecoration getCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: _isDarkMode ? Color(0xFF252525) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.06),
          spreadRadius: 0,
          blurRadius: _isDarkMode ? 6 : 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
  
  // Helper method for gradients
  List<Color> getHeaderGradient() {
    return _isDarkMode 
      ? [Color(0xFF252A30), Color(0xFF1A1D21)] 
      : [Color(0xFFF0F5FA), Color(0xFFE6EEF5)];
  }
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }
  
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }
  
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isDarkMode);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }
}