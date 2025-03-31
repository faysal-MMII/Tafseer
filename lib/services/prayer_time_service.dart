import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

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

typedef PrayerNotificationCallback = void Function(PrayerTime prayer);

class PrayerTimeService {
  final String apiUrl = 'https://api.aladhan.com/v1/timingsByCity';
  final String dateApiUrl = 'https://api.aladhan.com/v1/timingsByCity';

  List<PrayerTime> _prayerTimes = [];
  List<PrayerTime> get prayerTimes => _prayerTimes;

  PrayerTime? _nextPrayer;
  PrayerTime? get nextPrayer => _nextPrayer;

  String? _city;
  String? _country;
  Position? _position;

  Timer? _prayerCheckTimer;

  final PrayerNotificationCallback? onPrayerTime;

  final Map<String, DateTime> _lastRequestTimes = {};

  PrayerTimeService({this.onPrayerTime});

  Future<void> initialize() async {
    try {
      await _initializeNotifications();
      print("Notifications initialized");
    } catch (e) {
      print("Failed to initialize notifications: $e");
    }
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
      _city = "Default";
      _country = "Default";
    }
    try {
      await getPrayerTimes();
      print("Prayer times retrieved");
      await setupScheduledNotifications();
      print("All notifications scheduled");
    } catch (e) {
      print("Failed to get prayer times: $e");
    }
    await _initializeTimezone();
    print("Timezone initialized");
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

    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> setupScheduledNotifications() async {
    await AwesomeNotifications().cancelAll();
    print("Previous notifications canceled");

    final now = DateTime.now();
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
        final url = '$dateApiUrl?city=$_city&country=$_country&method=2&date=$formattedDate';
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
          // Create unique ID for each prayer
          final notificationId = prayer.name.hashCode + (dayOffset * 1000);
          
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: notificationId,
              channelKey: 'prayer_time_channel',
              title: 'Prayer Time',
              body: 'It\'s time for ${prayer.name} prayer',
              notificationLayout: NotificationLayout.Default,
            ),
            schedule: NotificationCalendar.fromDate(date: prayer.dateTime),
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

      if (_position != null) {
        final lat = _position!.latitude;
        final lng = _position!.longitude;
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
      _position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      await _getAddressFromLatLng(_position!);
    } catch (e) {
      print('Error getting location: $e');
      await _loadSavedLocation();
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      final latitude = position.latitude.toStringAsFixed(6);
      final longitude = position.longitude.toStringAsFixed(6);
      
      // Check if we have a cached address
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

      // Use Nominatim for geocoding
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10';
      final response = await _makeRateLimitedRequest(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract city and country from Nominatim response
        String city = data['address']['city'] ?? 
                     data['address']['town'] ?? 
                     data['address']['village'] ?? 
                     data['address']['county'] ?? 
                     "Unknown";

        String country = data['address']['country'] ?? "Unknown";

        _city = city;
        _country = country;

        await prefs.setString('city', _city!);
        await prefs.setString('country', _country!);
        _lastRequestTimes[cacheKey] = DateTime.now();

        print("Geocoded location: $_city, $_country");
      } else {
        throw Exception('Failed to geocode location');
      }
    } catch (e) {
      print('Error handling location: $e');
      await _loadSavedLocation();
    }
  }

  Future<http.Response> _makeRateLimitedRequest(String url) async {
    // Check if we need to wait to respect rate limits
    final now = DateTime.now();
    final lastRequestTime = _lastRequestTimes['nominatim'] ?? DateTime(2000);
    final timeSinceLastRequest = now.difference(lastRequestTime).inMilliseconds;

    // If last request was less than 1 second ago, wait
    if (timeSinceLastRequest < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - timeSinceLastRequest));
    }

    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'TafseerApp/1.0'
    });

    // Update last request time
    _lastRequestTimes['nominatim'] = DateTime.now();

    return response;
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _city = prefs.getString('city');
    _country = prefs.getString('country');
    if (_city == null || _country == null) {
      try {
        await _checkLocationPermission();
      } catch (e) {
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

  Future<void> getPrayerTimes() async {
    return getPrayerTimesForDate(DateTime.now());
  }

  Future<void> getPrayerTimesForDate(DateTime date) async {
    if (_city == null || _country == null) {
      try {
        await _checkLocationPermission();
      } catch (e) {
        _city = "Unknown";
        _country = "Unknown";
      }
    }
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
        if (_isToday(date)) {
          _findNextPrayer();
          await setupScheduledNotifications();
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
    final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
    _prayerTimes.add(PrayerTime(name: name, time: time, dateTime: dateTime));
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
        dateTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, firstPrayer.time.hour, firstPrayer.time.minute),
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

  Future<void> testRealNotification() async {
    // Schedule notification for 30 seconds from now
    final now = DateTime.now();
    final notificationTime = now.add(Duration(seconds: 30));

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 9999, // Unique ID for test
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

  void dispose() {
    _prayerCheckTimer?.cancel();
  }
}