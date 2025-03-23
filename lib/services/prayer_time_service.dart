import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class PrayerTime {
  final String name;
  final TimeOfDay time;
  final DateTime dateTime;
  
  PrayerTime({required this.name, required this.time, required this.dateTime});
  
  String get formattedTime {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// Create a callback typdef for prayer notifications
typedef PrayerNotificationCallback = void Function(PrayerTime prayer);

class PrayerTimeService {
  // API endpoint for prayer times
  final String apiUrl = 'https://api.aladhan.com/v1/timingsByCity';
  final String dateApiUrl = 'https://api.aladhan.com/v1/timingsByCity';
  
  // Prayer times for the current day
  List<PrayerTime> _prayerTimes = [];
  List<PrayerTime> get prayerTimes => _prayerTimes;
  
  // Next prayer time
  PrayerTime? _nextPrayer;
  PrayerTime? get nextPrayer => _nextPrayer;
  
  // Current location
  String? _city;
  String? _country;
  Position? _position;
  
  // Timer for checking prayer times
  Timer? _prayerCheckTimer;
  
  // Notification callback
  final PrayerNotificationCallback? onPrayerTime;
  
  // Basic constructor with optional callback
  PrayerTimeService({this.onPrayerTime});
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      await _checkLocationPermission();
      print("Location permission checked");
    } catch (e) {
      print("Location permission check failed: $e");
    }
    
    try {
      await _loadSavedLocation();
      print("Saved location loaded");
    } catch (e) {
      print("Failed to load saved location: $e");
      // Try to get location again or set defaults
      _city = "Default";
      _country = "Default";
    }
    
    try {
      await getPrayerTimes();
      print("Prayer times retrieved");
    } catch (e) {
      print("Failed to get prayer times: $e");
      // Set minimal data
    }
    
    // Start timer to check for prayer times
    _startPrayerCheckTimer();
    print("Prayer check timer started");
  }
  
  void _startPrayerCheckTimer() {
    // Cancel existing timer if any
    _prayerCheckTimer?.cancel();
    
    // Check every minute if it's time for prayer
    _prayerCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      
      // Check if any prayer time matches current time (within 1 minute)
      for (final prayer in _prayerTimes) {
        if (prayer.dateTime.difference(now).inMinutes.abs() <= 1) {
          // It's prayer time! Notify via callback
          if (onPrayerTime != null) {
            HapticFeedback.vibrate(); // Simple vibration
            SystemSound.play(SystemSoundType.click); // Simple beep sound
            onPrayerTime!(prayer);
          }
          break;
        }
      }
    });
  }
  
  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return;
      }
      
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium
      );
      
      await _getAddressFromLatLng(_position!);
    } catch (e) {
      print('Error getting location: $e');
      // Try to load saved location as fallback
      await _loadSavedLocation();
    }
  }
  
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      // For simplicity, we'll just use the coordinates directly
      final latitude = position.latitude.toStringAsFixed(3);
      final longitude = position.longitude.toStringAsFixed(3);
      
      // Ideally, use a geocoding service here to get actual city/country names
      _city = "Location ${latitude}";
      _country = "Location ${longitude}";
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('city', _city!);
      await prefs.setString('country', _country!);
    } catch (e) {
      print('Error handling location: $e');
      await _loadSavedLocation();
    }
  }
  
  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _city = prefs.getString('city');
    _country = prefs.getString('country');
    
    // Try to get location first or use saved location
    if (_city == null || _country == null) {
      try {
        await _checkLocationPermission();
      } catch (e) {
        // If location can't be determined, use generic defaults
        _city = "Unknown";
        _country = "Unknown";
      }
    }
  }
  
  Future<void> saveLocation(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', city);
    await prefs.setString('country', country);
    _city = city;
    _country = country;
    await getPrayerTimes();
  }
  
  // Get prayer times for today
  Future<void> getPrayerTimes() async {
    // Get prayer times for the current date
    return getPrayerTimesForDate(DateTime.now());
  }
  
  // Get prayer times for a specific date
  Future<void> getPrayerTimesForDate(DateTime date) async {
    if (_city == null || _country == null) {
      // Try to get location first or use saved location
      try {
        await _checkLocationPermission();
      } catch (e) {
        // If location can't be determined, use generic defaults
        _city = "Unknown";
        _country = "Unknown";
      }
    }
    
    // Format the date as required by the API (DD-MM-YYYY)
    final formattedDate = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    
    final url = '$dateApiUrl?city=$_city&country=$_country&method=2&date=$formattedDate';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];
        
        _prayerTimes = [];
        
        _addPrayerTime('Fajr', timings['Fajr'], date);
        _addPrayerTime('Dhuhr', timings['Dhuhr'], date);
        _addPrayerTime('Asr', timings['Asr'], date);
        _addPrayerTime('Maghrib', timings['Maghrib'], date);
        _addPrayerTime('Isha', timings['Isha'], date);
        
        _prayerTimes.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        
        // Only find next prayer if we're looking at today's date
        if (_isToday(date)) {
          _findNextPrayer();
        }
      }
    } catch (e) {
      print('Error fetching prayer times: $e');
    }
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  void _addPrayerTime(String name, String timeString, DateTime date) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final time = TimeOfDay(hour: hour, minute: minute);
    
    final dateTime = DateTime(
      date.year, 
      date.month, 
      date.day, 
      hour, 
      minute
    );
    
    _prayerTimes.add(PrayerTime(
      name: name, 
      time: time, 
      dateTime: dateTime
    ));
  }
  
  void _findNextPrayer() {
    final now = DateTime.now();
    _nextPrayer = null;
    
    for (var prayer in _prayerTimes) {
      if (prayer.dateTime.isAfter(now)) {
        _nextPrayer = prayer;
        break;
      }
    }
    
    if (_nextPrayer == null && _prayerTimes.isNotEmpty) {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final firstPrayer = _prayerTimes.first;
      
      _nextPrayer = PrayerTime(
        name: firstPrayer.name,
        time: firstPrayer.time,
        dateTime: DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          firstPrayer.time.hour,
          firstPrayer.time.minute
        )
      );
    }
  }
  
  String getTimeUntilNextPrayer() {
    if (_nextPrayer == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = _nextPrayer!.dateTime.difference(now);
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes min';
    }
  }
  
  void dispose() {
    _prayerCheckTimer?.cancel();
  }
}