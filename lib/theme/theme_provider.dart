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
  
  // Updated Dark Theme - Deep Blue with Teal Accents
  final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Color(0xFF1F9881), // Islamic teal-green
    scaffoldBackgroundColor: Color(0xFF001333), // Deep blue background
    cardColor: Color(0xFF0E2552), // Lighter blue for cards
    dividerColor: Color(0xFF1A3366), // Subtle blue divider
    
    // App Bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF001333), // Match scaffold
      elevation: 0,
      iconTheme: IconThemeData(
        color: Color(0xFF1F9881), // Teal accent
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    // Icon theme
    iconTheme: IconThemeData(
      color: Color(0xFF1F9881), // Teal accent
    ),
    
    // Text theme with better contrast
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.white),
      displayMedium: TextStyle(color: Colors.white),
      displaySmall: TextStyle(color: Colors.white),
      headlineLarge: TextStyle(color: Colors.white),
      headlineMedium: TextStyle(color: Color(0xFF1F9881), fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Color(0xFF1F9881)),
      titleLarge: TextStyle(color: Color(0xFF1F9881), fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
      bodySmall: TextStyle(color: Color(0xFFBDBDBD)),
      labelLarge: TextStyle(color: Color(0xFF1F9881)),
    ),
    
    // Color scheme
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF1F9881), // Teal primary
      secondary: Color(0xFF2EB086), // Lighter teal
      tertiary: Color(0xFF81C784), // Green variant for accents
      surface: Color(0xFF0E2552), // Lighter blue
      background: Color(0xFF001333), // Deep blue
      error: Color(0xFFFF6B6B), // More visible red
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFE0E0E0),
      onBackground: Color(0xFFE0E0E0),
      onError: Colors.white,
    ),
  );
  
  // Helper method for container decoration in light/dark mode
  BoxDecoration getContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: _isDarkMode ? Color(0xFF0E2552) : Colors.white,
      borderRadius: BorderRadius.circular(12), // Slightly smaller radius
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withOpacity(0.4)
              : Colors.black.withOpacity(0.05),
          spreadRadius: _isDarkMode ? -2 : 0,
          blurRadius: _isDarkMode ? 10 : 10,
          offset: Offset(0, 3),
        ),
      ],
      // Add a subtle border for more distinction
      border: _isDarkMode ? Border.all(color: Color(0xFF1A3366), width: 1) : null,
    );
  }

  // Helper method for elevated container decoration 
  BoxDecoration getElevatedContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: _isDarkMode ? Color(0xFF14305F) : Colors.white, // Slightly lighter blue
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withOpacity(0.6)
              : Colors.black.withOpacity(0.08),
          spreadRadius: _isDarkMode ? -2 : 0,
          blurRadius: _isDarkMode ? 12 : 15,
          offset: Offset(0, 4),
        ),
      ],
      // Add a subtle inner border
      border: _isDarkMode ? Border.all(color: Color(0xFF1F9881).withOpacity(0.2), width: 1) : null,
    );
  }

  // Helper method for card decoration
  BoxDecoration getCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: _isDarkMode ? Color(0xFF0E2552) : Colors.white, // Updated to blue shade
      borderRadius: BorderRadius.circular(16), // Updated radius
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.06),
          spreadRadius: 0,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
      border: _isDarkMode ? Border.all(color: Color(0xFF1A3366), width: 1) : null,
    );
  }

  // Helper method for gradients
  List<Color> getHeaderGradient() {
    return _isDarkMode 
      ? [Color(0xFF001333), Color(0xFF0A1F4C)] // Deep blue gradient
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