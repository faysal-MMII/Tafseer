import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../data/islamic_facts_data.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:isolate';

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

class PrayerTimeService with ChangeNotifier {
  List<PrayerTime> _prayerTimes = [];
  List<PrayerTime> get prayerTimes => _prayerTimes;

  PrayerTime? _nextPrayer;
  PrayerTime? get nextPrayer => _nextPrayer;

  String? _city;
  String? _country;
  Position? _position;
  double? _latitude;
  double? _longitude;

  Timer? _prayerCheckTimer;

  bool _isInitialized = false;
  final PrayerNotificationCallback? onPrayerTime;
  Timer? _updateTimer;

  static const String _lastReminderKey = 'last_reading_reminder';
  final Map<String, DateTime> _lastRequestTimes = {};
  bool _isInitializing = false;
  DateTime? _lastScheduleTime;

  PrayerTimeService({this.onPrayerTime});
  
  Future<void> debugForegroundService() async {
    print("🔧 DEBUG: Checking foreground service status...");
    
    final notificationAllowed = await AwesomeNotifications().isNotificationAllowed();
    print("🔧 Notification permission: $notificationAllowed");
    
    if (!notificationAllowed) {
      print("❌ REQUESTING notification permission...");
      await AwesomeNotifications().requestPermissionToSendNotifications();
      final nowAllowed = await AwesomeNotifications().isNotificationAllowed();
      print("🔧 After request - notification permission: $nowAllowed");
      
      if (!nowAllowed) {
        print("❌ CRITICAL: User denied notifications - service can't start");
        return;
      }
    }
    
    final isRunning = await FlutterForegroundTask.isRunningService;
    print("🔧 Foreground service running: $isRunning");
    
    if (!isRunning) {
      print("❌ PROBLEM: Service not running - attempting start...");
      
      try {
        final success = await FlutterForegroundTask.startService(
          notificationTitle: 'DEBUG: Prayer Times Active',
          notificationText: 'Testing persistent notification',
          callback: startCallback,
        );
        print("🔧 Start service returned: $success");
        
        await Future.delayed(Duration(seconds: 2));
        final nowRunning = await FlutterForegroundTask.isRunningService;
        print("🔧 After manual start - running: $nowRunning");
        
        if (!nowRunning) {
          print("❌ FAILED: Service still not running after start attempt");
        }
      } catch (e) {
        print("❌ Manual start EXCEPTION: $e");
      }
    } else {
      print("✅ Service is running - persistent notification should be visible!");
    }
  }

  Future<void> debugNotifications() async {
    print("=== NOTIFICATION DEBUG ===");
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 12345,
          channelKey: 'prayer_time_channel',
          title: 'DEBUG TEST',
          body: 'If you see this, notifications work!',
        ),
      );
      print("✅ Immediate notification sent");
    } catch (e) {
      print("❌ Immediate notification FAILED: $e");
    }
    
    try {
      final scheduled = await AwesomeNotifications().listScheduledNotifications();
      print("📋 Scheduled notifications: ${scheduled.length}");
      for (var notif in scheduled) {
        print("   - ID: ${notif.content?.id}, Title: ${notif.content?.title}");
      }
    } catch (e) {
      print("❌ Can't list scheduled notifications: $e");
    }
    
    try {
      final allowed = await AwesomeNotifications().isNotificationAllowed();
      print("🔐 Notifications allowed: $allowed");
    } catch (e) {
      print("❌ Can't check permissions: $e");
    }
  }

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    try {
      await _initializeNotifications();
      print("Notifications initialized");
      
      await _checkLocationPermission();
      print("Location permission checked");
      
      await _loadSavedLocation();
      print("Saved location loaded");
      
      await getPrayerTimes();
      print("Prayer times retrieved");
      
      await setupScheduledNotifications();
      print("All notifications scheduled");
      
      await _initializeTimezone();
      print("Timezone initialized");
    } catch (e) {
      print("Error during initialization: $e");
      _city ??= "Default";
      _country ??= "Default";
    } finally {
      _isInitializing = false;
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
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          channelShowBadge: false,
        ),
      ],
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    }

    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Prayer Times Active',
        notificationText: 'Prayer notifications running in background',
        callback: startCallback,
      );
    }
    
    await _initializeTimezone();
    
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
    await _scheduleMultipleDays();
    await _scheduleDailyFunFactNotifications();
    
    _isInitialized = true;
    startAutoUpdate();
    print("=== PRAYER SERVICE INITIALIZE COMPLETE ===");
  }

  Future<void> setupScheduledNotifications() async {
    final now = DateTime.now();
    if (_lastScheduleTime != null && 
        now.difference(_lastScheduleTime!).inSeconds < 60) {
      print("Skipping notification scheduling - too soon");
      return;
    }
    _lastScheduleTime = now;

    await AwesomeNotifications().cancelAll();
    print("Previous notifications canceled");

    print("Current time when scheduling: ${now.toString()}");

    await _schedulePrayersForDate(DateTime.now(), 0);
    await _schedulePrayersForDate(DateTime.now().add(Duration(days: 1)), 1);
    await _schedulePrayersForDate(DateTime.now().add(Duration(days: 2)), 2);
  }

  Future<void> _schedulePrayersForDate(DateTime date, int dayOffset) async {
    print("Scheduling prayers for ${date.toString().split(' ')[0]}");

    List<PrayerTime> prayerTimes = [];

    if (dayOffset == 0) {
      prayerTimes = _prayerTimes;
    } else {
      try {
        final formattedDate = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
        
        final url = _latitude != null && _longitude != null
            ? 'https://api.aladhan.com/v1/timings?latitude=${_latitude!}&longitude=${_longitude!}&method=2&date=$formattedDate'
            : 'https://api.aladhan.com/v1/timingsByCity?city=$_city&country=$_country&method=2&date=$formattedDate';
        
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final timings = data['data']['timings'];
          prayerTimes = [];
          _addPrayerTimeToList(prayerTimes, 'Fajr', timings['Fajr'], date);
          _addPrayerTimeToList(prayerTimes, 'Dhuhr', timings['Dhuhr'], date);
          _addPrayerTimeToList(prayerTimes, 'Asr', timings['Asr'], date);
          _addPrayerTimeToList(prayerTimes, 'Maghrib', timings['Maghrib'], date);
          _addPrayerTimeToList(prayerTimes, 'Isha', timings['Isha'], date);
          prayerTimes.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        }
      } catch (e) {
        print("Error fetching prayer times for ${date.toString().split(' ')[0]}: $e");
        return;
      }
    }

    final now = DateTime.now();
    int scheduledCount = 0;
    for (final prayer in prayerTimes) {
      if (prayer.dateTime.isAfter(now)) {
        try {
          final notificationId = prayer.name.hashCode + (dayOffset * 1000);
          
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: notificationId,
              channelKey: 'prayer_time_channel',
              title: 'Prayer Time',
              body: 'It\'s time for ${prayer.name} prayer',
              icon: 'resource://mipmap/launcher_icon',
              notificationLayout: NotificationLayout.Default,
              category: NotificationCategory.Reminder,
              wakeUpScreen: true,
              fullScreenIntent: true,
            ),
            schedule: NotificationCalendar(
              year: prayer.dateTime.year,
              month: prayer.dateTime.month,
              day: prayer.dateTime.day,
              hour: prayer.dateTime.hour,
              minute: prayer.dateTime.minute,
              second: 0,
              repeats: false,
              allowWhileIdle: true,
            ),
          );

          print("Successfully scheduled notification for ${prayer.name}");
          scheduledCount++;
        } catch (e) {
          print("Error scheduling notification for ${prayer.name}: $e");
        }
      }
    }
    print("Scheduled $scheduledCount notifications for day $dayOffset");
  }

  void _addPrayerTimeToList(List<PrayerTime> list, String name, String timeString, DateTime date) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final time = TimeOfDay(hour: hour, minute: minute);
    final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
    list.add(PrayerTime(name: name, time: time, dateTime: dateTime));
  }

  Future<void> _initializeTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final deviceTimeZone = DateTime.now().timeZoneName;
      print("Device timezone name: $deviceTimeZone");
      try {
        tz.setLocalLocation(tz.getLocation(deviceTimeZone));
        print("Set timezone to device timezone: $deviceTimeZone");
        return;
      } catch (e) {
        print("Could not use device timezone name: $e");
      }

      final nowUtc = DateTime.now().toUtc();
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      for (final locationName in tz.timeZoneDatabase.locations.keys) {
        final location = tz.getLocation(locationName);
        final testDateTime = tz.TZDateTime.from(nowUtc, location);
        if (testDateTime.timeZoneOffset == offset) {
          tz.setLocalLocation(location);
          print("Set timezone based on offset: $locationName");
          return;
        }
      }

      if (_latitude != null && _longitude != null) {
        final lat = _latitude!;
        final lng = _longitude!;
        String regionGuess;

        if (lat > 30 && lng > -10 && lng < 40) {
          regionGuess = 'Europe/London';
        } else if (lat > 20 && lng > -130 && lng < -50) {
          regionGuess = 'America/New_York';
        } else if (lat > -35 && lng > 100 && lng < 150) {
          regionGuess = 'Australia/Sydney';
        } else if (lat > 0 && lat < 40 && lng > 60 && lng < 140) {
          regionGuess = 'Asia/Shanghai';
        } else if (lat > -35 && lat < 35 && lng > 0 && lng < 50) {
          regionGuess = 'Africa/Lagos';
        } else {
          regionGuess = 'Etc/UTC';
        }
        try {
          tz.setLocalLocation(tz.getLocation(regionGuess));
          print("Set timezone based on coordinates: $regionGuess");
          return;
        } catch (e) {
          print("Could not set timezone from coordinates: $e");
        }
      }

      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      print("Falling back to UTC timezone");
    } catch (e) {
      print("Error in timezone initialization: $e");
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
  }

  static Future<void> _scheduleReadingReminder(Map<String, String> sessionData) async {
    final prefs = await SharedPreferences.getInstance();
    final lastReminder = prefs.getString(_lastReminderKey);
    final now = DateTime.now();

    if (lastReminder != null) {
      final lastReminderDate = DateTime.parse(lastReminder);
      if (now.difference(lastReminderDate).inHours < 24) {
        return;
      }
    }

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
          icon: 'resource://mipmap/launcher_icon',
          notificationLayout: NotificationLayout.BigText,
          largeIcon: 'resource://drawable/launcher_icon',
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

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      _latitude = position.latitude;
      _longitude = position.longitude;
      
      final latitude = position.latitude.toStringAsFixed(6);
      final longitude = position.longitude.toStringAsFixed(6);
      
      final prefs = await SharedPreferences.getInstance();
      final cachedCity = prefs.getString('city');
      final cachedCountry = prefs.getString('country');
      final cacheKey = '$latitude,$longitude';

      if (cachedCity != null && cachedCountry != null && _lastRequestTimes[cacheKey] != null) {
        final lastRequestTime = _lastRequestTimes[cacheKey]!;
        if (DateTime.now().difference(lastRequestTime).inMinutes < 10) {
          _city = cachedCity;
          _country = cachedCountry;
          print("Using cached location: $_city, $_country");
          return;
        }
      }
    }
  }

      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10';
      final response = await _makeRateLimitedRequest(url);

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

        String city = data['address']['city'] ?? 
                     data['address']['town'] ?? 
                     data['address']['village'] ?? 
                     data['address']['county'] ?? 
                     "Unknown";

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
  }

  Future<http.Response> _makeRateLimitedRequest(String url) async {
    final now = DateTime.now();
    final lastRequestTime = _lastRequestTimes['nominatim'] ?? DateTime(2000);
    final timeSinceLastRequest = now.difference(lastRequestTime).inMilliseconds;

    if (timeSinceLastRequest < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - timeSinceLastRequest));
    }

    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'TafseerApp/1.0'
    });

    _lastRequestTimes['nominatim'] = DateTime.now();
    return response;
  }

  Future<void> _loadSavedLocation() async {
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
    notifyListeners();
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

  Future<void> saveLocation(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', city);
    await prefs.setString('country', country);
    _city = city;
    _country = country;
    await getPrayerTimes();
  }

  Future<void> getPrayerTimes() async {
    return getPrayerTimesForDate(DateTime.now());
  }

  Future<void> getPrayerTimesForDate(DateTime date) async {
    try {
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('Fetching prayer times for date: $formattedDate');
      
      String apiUrl;
      if (_latitude != null && _longitude != null) {
        apiUrl = 'https://api.aladhan.com/v1/timings/$formattedDate?latitude=$_latitude&longitude=$_longitude&method=2';
      } else {
        if (_city == null || _country == null) {
          await _checkLocationPermission();
        }
        apiUrl = 'https://api.aladhan.com/v1/timingsByCity/$formattedDate?city=$_city&country=$_country&method=2';
      }
      
      print('API URL: $apiUrl');
      
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Debugging output to check API response
        print('API Response for $formattedDate:');
        if (data['data'] != null && data['data']['timings'] != null) {
          final timings = data['data']['timings'];
          print('  Fajr: ${timings['Fajr']}');
          print('  Dhuhr: ${timings['Dhuhr']}');
          print('  Asr: ${timings['Asr']}');
          print('  Maghrib: ${timings['Maghrib']}');
          print('  Isha: ${timings['Isha']}');
        } else {
          print('  No timings data found in response');
        }
        
        if (data['code'] == 200 && data['data'] != null) {
          final timings = data['data']['timings'];
          
          _prayerTimes = [];
          
          _addPrayerTime('Fajr', timings['Fajr'], date);
          _addPrayerTime('Sunrise', timings['Sunrise'], date);
          _addPrayerTime('Dhuhr', timings['Dhuhr'], date);
          _addPrayerTime('Asr', timings['Asr'], date);
          _addPrayerTime('Maghrib', timings['Maghrib'], date);
          _addPrayerTime('Isha', timings['Isha'], date);
          
          _prayerTimes.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          
          print('Successfully loaded ${_prayerTimes.length} prayer times for $formattedDate');
          
          if (_isToday(date)) {
            _findNextPrayer();
            await setupScheduledNotifications();
          }
        } else {
          throw Exception('Invalid API response for date $formattedDate');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch prayer times for $formattedDate');
      }
    } catch (e) {
      print('Error fetching prayer times for date $date: $e');
      rethrow;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  void _addPrayerTime(String name, String timeString, DateTime date) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final time = TimeOfDay(hour: hour, minute: minute);
    
    final dateTime = tz.TZDateTime(
      tz.local,
      date.year,
      date.month, 
      date.day,
      hour,
      minute,
    );
    
    _prayerTimes.add(PrayerTime(name: name, time: time, dateTime: dateTime));
  }

  void _findNextPrayer() {
    final now = DateTime.now();
    _nextPrayer = null;
    
    for (var prayer in _prayerTimes) {
      if (prayer.dateTime.isAfter(now)) {
        _nextPrayer = prayer;
        notifyListeners();
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
      notifyListeners();
    }
  }

  void startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      final previousNext = _nextPrayer;
      _findNextPrayer();
      
      if (previousNext?.name != _nextPrayer?.name) {
        print("Next prayer changed: ${_nextPrayer?.name}");
      }
    });
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
    await _scheduleMultipleDays();
    await _scheduleDailyFunFactNotifications();
    notifyListeners();
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
    await _scheduleMultipleDays();
    await _scheduleDailyFunFactNotifications();
    notifyListeners();
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
    await _scheduleMultipleDays();
    await _scheduleDailyFunFactNotifications();
    notifyListeners();
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

  Future<void> testRealNotification() async {
    final now = DateTime.now();
    final notificationTime = now.add(Duration(seconds: 30));

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 9999,
          channelKey: 'prayer_time_channel',
          title: 'Prayer Time Test',
          body: 'This is a critical test notification',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: notificationTime),
      );

      print("Forced test notification scheduled");
      return Future.value(true);
    } catch (e) {
      print("Error scheduling forced test: $e");
      return Future.error(e);
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

class PrayerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print('Prayer service started (background isolate)');
  }
  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    print('Prayer service heartbeat: ${DateTime.now()}');
  }
  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
  }
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('Prayer service destroyed');
  }
}