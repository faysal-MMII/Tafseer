import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../data/islamic_facts_data.dart';

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

class CitySearchResult {
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String displayName;
  
  CitySearchResult({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

typedef PrayerNotificationCallback = void Function(PrayerTime prayer);

class PrayerTimeService {
  List<PrayerTime> _prayerTimes = [];
  List<PrayerTime> get prayerTimes => _prayerTimes;

  PrayerTime? _nextPrayer;
  PrayerTime? get nextPrayer => _nextPrayer;

  String? _city;
  String? _country;
  double? _latitude;
  double? _longitude;
  String? _locationDisplayName;

  bool _isInitialized = false;
  final PrayerNotificationCallback? onPrayerTime;

  static const String _lastReminderKey = 'last_reading_reminder';

  PrayerTimeService({this.onPrayerTime});

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print("=== PRAYER SERVICE INITIALIZE START ===");
    
    await _initializeNotifications();
    
    bool locationSuccess = false;
    
    try {
      await _getGPSLocation();
      locationSuccess = true;
      print("GPS location successful");
    } catch (e) {
      print("GPS failed: $e");
    }
    
    if (!locationSuccess) {
      try {
        await _loadCachedLocation();
        locationSuccess = true;
        print("Cached location successful");
      } catch (e) {
        print("Cached location failed: $e");
      }
    }
    
    if (!locationSuccess) {
      try {
        await _setSmartDefaultLocation();
        print("Smart default location set");
      } catch (e) {
        _city = "Mecca";
        _country = "Saudi Arabia";
        _locationDisplayName = "Mecca, Saudi Arabia";
        print("Using Mecca as final fallback");
      }
    }
    
    await _loadTodaysPrayerTimes();
    await _scheduleNotificationsForToday();
    await _scheduleDailyFunFactNotifications();
    
    _isInitialized = true;
    print("=== PRAYER SERVICE INITIALIZE COMPLETE ===");
  }

  static Future<void> _scheduleReadingReminder(Map<String, String> sessionData) async {
    final prefs = await SharedPreferences.getInstance();
    final lastReminder = prefs.getString(_lastReminderKey);
    final now = DateTime.now();

    // Don't send more than one reminder per day
    if (lastReminder != null) {
      final lastReminderDate = DateTime.parse(lastReminder);
      if (now.difference(lastReminderDate).inHours < 24) {
        return;
      }
    }

    // Schedule reminder for 6 hours from now
    final reminderTime = now.add(Duration(hours: 6));

    final surahName = sessionData['surah_name']!;
    final lastVerse = sessionData['last_verse']!;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 777777,
          channelKey: 'reading_reminders_channel',
          title: 'Continue Your Spiritual Journey 📖',
          body: 'You were reading $surahName (verse $lastVerse). Continue where you left off!',
          notificationLayout: NotificationLayout.BigText,
          largeIcon: 'resource://drawable/ic_notification',
          wakeUpScreen: false,
        ),
        schedule: NotificationCalendar.fromDate(
          date: reminderTime,
          allowWhileIdle: true,
        ),
      );
      
      await prefs.setString(_lastReminderKey, now.toIso8601String());
      print("Scheduled reading reminder for $surahName in 6 hours ($reminderTime)");
      
    } catch (e) {
      print("Failed to schedule reading reminder: $e");
    }
  }

  Future<void> _scheduleDailyFunFactNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScheduled = prefs.getString('last_fun_fact_scheduled');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    
    if (lastScheduled == todayStr) {
      print("Fun fact notifications already scheduled for today");
      return;
    }
    
    await AwesomeNotifications().cancel(999999);
    
    final notificationTime = DateTime(today.year, today.month, today.day, 14, 0);
    
    final scheduleTime = notificationTime.isBefore(DateTime.now()) 
        ? notificationTime.add(Duration(days: 1))
        : notificationTime;
    
    final randomFacts = IslamicFactsData.getRandomFacts(1);
    if (randomFacts.isNotEmpty) {
      final fact = randomFacts.first;
      
      try {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 999999,
            channelKey: 'fun_facts_channel',
            title: 'DID YOU KNOW? 💡',
            body: fact.description,
            notificationLayout: NotificationLayout.BigText,
            largeIcon: 'resource://drawable/ic_notification',
            wakeUpScreen: false,
          ),
          schedule: NotificationCalendar.fromDate(
            date: scheduleTime,
            allowWhileIdle: true,
          ),
        );
        
        await prefs.setString('last_fun_fact_scheduled', todayStr);
        print("Scheduled fun fact notification for: $scheduleTime");
        print("Fact: ${fact.title}");
        
      } catch (e) {
        print("Failed to schedule fun fact notification: $e");
      }
    }
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelKey: 'prayer_time_channel',
          channelName: 'Prayer Times',
          channelDescription: 'Notifications for prayer times',
          defaultColor: Color(0xFF001333),
          importance: NotificationImportance.High,
          enableVibration: true,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: 'fun_facts_channel',
          channelName: 'Islamic Fun Facts',
          channelDescription: 'Daily amazing Islamic facts',
          defaultColor: Color(0xFF2D5F7C),
          importance: NotificationImportance.Default,
          enableVibration: true,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: 'reading_reminders_channel',
          channelName: 'Reading Reminders',
          channelDescription: 'Reminders to continue reading Quran',
          defaultColor: Color(0xFF4A90E2),
          importance: NotificationImportance.Default,
          enableVibration: true,
          playSound: true,
        ),
      ],
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> _setSmartDefaultLocation() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json')).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latitude = data['lat']?.toDouble();
        _longitude = data['lon']?.toDouble();
        _city = data['city'] ?? "Unknown";
        _country = data['country'] ?? "Unknown";
        _locationDisplayName = "$_city, $_country";
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('latitude', _latitude!);
        await prefs.setDouble('longitude', _longitude!);
        await prefs.setString('location_name', _locationDisplayName!);
        
        print("IP-based location: $_locationDisplayName");
      }
    } catch (e) {
      throw Exception("IP geolocation failed: $e");
    }
  }

  Future<void> _getGPSLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }
    
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    
    _latitude = position.latitude;
    _longitude = position.longitude;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', _latitude!);
    await prefs.setDouble('longitude', _longitude!);
    await prefs.setString('last_update', DateTime.now().toIso8601String());
    
    await _getLocationName();
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _latitude = prefs.getDouble('latitude');
    _longitude = prefs.getDouble('longitude');
    final lastUpdate = prefs.getString('last_update');
    
    if (_latitude == null || _longitude == null) {
      throw Exception('No cached coordinates');
    }
    
    if (lastUpdate != null) {
      final lastUpdateTime = DateTime.parse(lastUpdate);
      final daysSince = DateTime.now().difference(lastUpdateTime).inDays;
      if (daysSince > 7) {
        throw Exception('Cached coordinates too old');
      }
    }
    
    await _getLocationName();
  }

  Future<void> _getLocationName() async {
    try {
      final url = 'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${_latitude!}&longitude=${_longitude!}&localityLanguage=en';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final city = data['city'] ?? data['locality'] ?? data['principalSubdivision'] ?? 'Unknown';
        final country = data['countryName'] ?? 'Unknown';
        
        _city = city;
        _country = country;
        _locationDisplayName = '$city, $country';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('location_name', _locationDisplayName!);
        
        print("Location: $_locationDisplayName");
        return;
      }
    } catch (e) {
      print("Geocoding failed: $e");
    }
    
    final prefs = await SharedPreferences.getInstance();
    _locationDisplayName = prefs.getString('location_name') ?? 'Current Location';
  }

  Future<void> _loadTodaysPrayerTimes() async {
    final today = DateTime.now();
    print("Loading prayer times for: ${today.day}/${today.month}/${today.year}");
    
    if (_latitude != null && _longitude != null) {
      await _getPrayerTimesByCoordinates(today);
    } else if (_city != null && _country != null) {
      await _getPrayerTimesByCity(today);
    } else {
      throw Exception('No location available for prayer times');
    }
  }

  Future<void> _getPrayerTimesByCoordinates(DateTime date) async {
    final dateStr = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final url = 'https://api.aladhan.com/v1/timings?latitude=${_latitude!}&longitude=${_longitude!}&method=2&date=$dateStr';
    
    print("API URL: $url");
    
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
      _findNextPrayer();
      
      print("Prayer times loaded successfully:");
      for (var prayer in _prayerTimes) {
        print("${prayer.name}: ${prayer.dateTime}");
      }
      print("Next prayer: ${_nextPrayer?.name} at ${_nextPrayer?.dateTime}");
    } else {
      throw Exception('Failed to load prayer times: ${response.statusCode}');
    }
  }

  Future<void> _getPrayerTimesByCity(DateTime date) async {
    final dateStr = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final url = 'https://api.aladhan.com/v1/timingsByCity?city=$_city&country=$_country&method=2&date=$dateStr';
    
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
      _findNextPrayer();
    } else {
      throw Exception('Failed to load prayer times for $_city, $_country');
    }
  }

  void _addPrayerTime(String name, String timeString, DateTime date) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final time = TimeOfDay(hour: hour, minute: minute);
    final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
    _prayerTimes.add(PrayerTime(name: name, time: time, dateTime: dateTime));
  }

  void _findNextPrayer() {
    final now = DateTime.now();
    _nextPrayer = null;
    
    for (var prayer in _prayerTimes) {
      if (prayer.dateTime.isAfter(now)) {
        _nextPrayer = prayer;
        return;
      }
    }
    
    if (_prayerTimes.isNotEmpty) {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final firstPrayer = _prayerTimes.first;
      _nextPrayer = PrayerTime(
        name: firstPrayer.name,
        time: firstPrayer.time,
        dateTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 
                          firstPrayer.time.hour, firstPrayer.time.minute),
      );
    }
  }

  Future<void> _scheduleNotificationsForToday() async {
    await AwesomeNotifications().cancelAll();
    
    final now = DateTime.now();
    int scheduled = 0;
    
    for (final prayer in _prayerTimes) {
      if (prayer.dateTime.isAfter(now)) {
        try {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: prayer.name.hashCode,
              channelKey: 'prayer_time_channel',
              title: 'Prayer Time',
              body: 'It\'s time for ${prayer.name} prayer',
            ),
            schedule: NotificationCalendar.fromDate(date: prayer.dateTime),
          );
          scheduled++;
          print("Scheduled notification for ${prayer.name}");
        } catch (e) {
          print("Failed to schedule ${prayer.name}: $e");
        }
      }
    }
    
    print("Scheduled $scheduled notifications for today");
  }

  Future<String> getLocationDisplayName() async {
    return _locationDisplayName ?? 'Current Location';
  }

  Future<void> setLocationByCoordinates(double lat, double lng, String displayName) async {
    _latitude = lat;
    _longitude = lng;
    _locationDisplayName = displayName;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', lat);
    await prefs.setDouble('longitude', lng);
    await prefs.setString('location_name', displayName);
    await prefs.setString('last_update', DateTime.now().toIso8601String());
    
    await _loadTodaysPrayerTimes();
    await _scheduleNotificationsForToday();
  }

  Future<void> saveLocation(String city, String country) async {
    _city = city;
    _country = country;
    _locationDisplayName = '$city, $country';
    _latitude = null;
    _longitude = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('latitude');
    await prefs.remove('longitude');
    await prefs.setString('location_name', _locationDisplayName!);
    
    await _loadTodaysPrayerTimes();
    await _scheduleNotificationsForToday();
  }

  Future<List<CitySearchResult>> searchCitiesFreely(String query) async {
    if (query.length < 2) return [];
    
    try {
      final url = 'http://api.geonames.org/searchJSON?name_startsWith=${Uri.encodeComponent(query)}&maxRows=10&featureClass=P&username=demo';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geonames = data['geonames'] as List?;
        
        if (geonames != null) {
          return geonames.map((city) {
            return CitySearchResult(
              name: city['name'] ?? '',
              country: city['countryName'] ?? '',
              latitude: double.tryParse(city['lat']?.toString() ?? '') ?? 0.0,
              longitude: double.tryParse(city['lng']?.toString() ?? '') ?? 0.0,
              displayName: '${city['name']}, ${city['countryName']}',
            );
          }).toList();
        }
      }
    } catch (e) {
      print('City search error: $e');
    }
    
    return [];
  }

  Future<void> refreshPrayerTimes() async {
    await _loadTodaysPrayerTimes();
    await _scheduleNotificationsForToday();
    await _scheduleDailyFunFactNotifications();
  }

  Future<void> getPrayerTimes() async {
    await refreshPrayerTimes();
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
    // Clean up if needed
  }
}