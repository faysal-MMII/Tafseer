import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/system.dart';
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
  
  double? _latitude;
  double? _longitude;
  bool _useCoordinates = false;

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
      print("Location permission checked and coordinates obtained");
      
      if (_latitude != null && _longitude != null) {
        await getPrayerTimesGlobally(_latitude!, _longitude!, DateTime.now());
        await setupScheduledNotifications();
        print("Global prayer times loaded successfully");
        await _initializeTimezone();
        return;
      }
    } catch (e) {
      print("GPS location failed: $e");
    }
    
    try {
      await _loadCachedCoordinates();
      if (_latitude != null && _longitude != null) {
        await getPrayerTimesGlobally(_latitude!, _longitude!, DateTime.now());
        await setupScheduledNotifications();
        print("Cached coordinates used successfully");
        await _initializeTimezone();
        return;
      }
    } catch (e) {
      print("Cached coordinates failed: $e");
    }
    
    try {
      await _loadSavedLocation();
      if (_city != null && _country != null) {
        await _getPrayerTimesByCity(DateTime.now());
        await setupScheduledNotifications();
        print("City-based prayer times loaded");
      }
    } catch (e) {
      print("City-based approach failed: $e");
      _city = "London";
      _country = "United Kingdom";
      await _getPrayerTimesByCity(DateTime.now());
    }
    
    await _initializeTimezone();
    print("Prayer time service initialized");
  }

  Future<void> getPrayerTimesGlobally(double lat, double lng, DateTime date) async {
    try {
      if (await _tryStandardCalculation(lat, lng, date)) {
        print('Standard prayer calculation successful for $lat, $lng');
        return;
      }
      
      if (_isExtremePolarRegion(lat)) {
        await _handleExtremePolarRegion(lat, lng, date);
      } else if (_isHighLatitudeRegion(lat)) {
        await _handleHighLatitudeRegion(lat, lng, date);
      } else {
        await _fallbackToNearestCity(lat, lng, date);
      }
      
    } catch (e) {
      print('All prayer time calculations failed: $e');
      await _useMeccaTimes(date);
    }
  }

  Future<bool> _tryStandardCalculation(double lat, double lng, DateTime date) async {
    try {
      final formattedDate = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      final url = 'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lng&method=2&date=$formattedDate';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];
        
        final requiredPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
        for (String prayer in requiredPrayers) {
          if (timings[prayer] == null || timings[prayer] == "--:--" || timings[prayer].isEmpty) {
            print('Invalid $prayer time: ${timings[prayer]}');
            return false;
          }
        }
        
        _prayerTimes = [];
        _addPrayerTime('Fajr', timings['Fajr'], date);
        _addPrayerTime('Dhuhr', timings['Dhuhr'], date);
        _addPrayerTime('Asr', timings['Asr'], date);
        _addPrayerTime('Maghrib', timings['Maghrib'], date);
        _addPrayerTime('Isha', timings['Isha'], date);
        _prayerTimes.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        
        _findNextPrayer();
        _useCoordinates = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('prayer_method', 'coordinates');
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Standard calculation error: $e');
      return false;
    }
  }

  bool _isExtremePolarRegion(double latitude) {
    return latitude.abs() > 66.5;
  }
  
  bool _isHighLatitudeRegion(double latitude) {
    return latitude.abs() > 48.0 && latitude.abs() <= 66.5;
  }

  Future<void> _handleExtremePolarRegion(double lat, double lng, DateTime date) async {
    print('Handling extreme polar region: $lat, $lng');
    
    try {
      final nearestCity = _findNearestNormalCity(lat, lng);
      await _getPrayerTimesForCity(nearestCity['city']!, nearestCity['country']!, date);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_method', 'nearest_city');
      await prefs.setString('reference_city', '${nearestCity['city']}, ${nearestCity['country']}');
      
      print('Using prayer times from ${nearestCity['city']}, ${nearestCity['country']}');
      return;
    } catch (e) {
      print('Nearest city method failed: $e');
    }
    
    await _useMeccaTimes(date);
  }

  Future<void> _handleHighLatitudeRegion(double lat, double lng, DateTime date) async {
    print('Handling high latitude region: $lat, $lng');
    await _handleExtremePolarRegion(lat, lng, date);
  }

  Map<String, String> _findNearestNormalCity(double lat, double lng) {
    final normalCities = [
      {'city': 'Riyadh', 'country': 'Saudi Arabia', 'lat': 24.7136, 'lng': 46.6753},
      {'city': 'Istanbul', 'country': 'Turkey', 'lat': 41.0082, 'lng': 28.9784},
      {'city': 'London', 'country': 'United Kingdom', 'lat': 51.5074, 'lng': -0.1278},
      {'city': 'Paris', 'country': 'France', 'lat': 48.8566, 'lng': 2.3522},
      {'city': 'New York', 'country': 'United States', 'lat': 40.7128, 'lng': -74.0060},
      {'city': 'Toronto', 'country': 'Canada', 'lat': 43.6532, 'lng': -79.3832},
      {'city': 'Moscow', 'country': 'Russia', 'lat': 55.7558, 'lng': 37.6176},
      {'city': 'Cairo', 'country': 'Egypt', 'lat': 30.0444, 'lng': 31.2357},
    ];
    
    double minDistance = double.infinity;
    Map<String, String> nearestCity = {'city': 'Mecca', 'country': 'Saudi Arabia'};
    
    for (var city in normalCities) {
      final distance = _calculateDistance(lat, lng, city['lat'] as double, city['lng'] as double);
      if (distance < minDistance) {
        minDistance = distance;
        nearestCity = {'city': city['city'] as String, 'country': city['country'] as String};
      }
    }
    
    return nearestCity;
  }

  Future<void> _useMeccaTimes(DateTime date) async {
    print('Using Mecca times as universal reference');
    await _getPrayerTimesForCity('Mecca', 'Saudi Arabia', date);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_method', 'mecca_reference');
    await prefs.setString('reference_city', 'Mecca, Saudi Arabia');
  }

  Future<void> _fallbackToNearestCity(double lat, double lng, DateTime date) async {
    final nearestCity = _findNearestNormalCity(lat, lng);
    await _getPrayerTimesForCity(nearestCity['city']!, nearestCity['country']!, date);
  }

  Future<void> _checkLocationPermission() async {
    try {
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
      
      _position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      
      _latitude = _position!.latitude;
      _longitude = _position!.longitude;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cached_latitude', _latitude!);
      await prefs.setDouble('cached_longitude', _longitude!);
      await prefs.setString('coordinates_updated', DateTime.now().toIso8601String());
      
      try {
        await _getAddressFromLatLng(_position!);
      } catch (e) {
        print('City name detection failed (not critical): $e');
      }
      
    } catch (e) {
      print('GPS location failed: $e');
      rethrow;
    }
  }

  Future<void> _loadCachedCoordinates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble('cached_latitude');
      final cachedLng = prefs.getDouble('cached_longitude');
      final lastUpdate = prefs.getString('coordinates_updated');
      
      if (cachedLat != null && cachedLng != null) {
        if (lastUpdate != null) {
          final lastUpdateTime = DateTime.parse(lastUpdate);
          final daysSinceUpdate = DateTime.now().difference(lastUpdateTime).inDays;
          
          if (daysSinceUpdate <= 7) {
            _latitude = cachedLat;
            _longitude = cachedLng;
            print('Loaded cached coordinates: $cachedLat, $cachedLng');
            return;
          }
        }
      }
      throw Exception('No valid cached coordinates');
    } catch (e) {
      print('Failed to load cached coordinates: $e');
      rethrow;
    }
  }

  Future<String> getLocationDisplayName() async {
    if (_latitude != null && _longitude != null) {
      return await _getLocationDisplayNameFromCoords(_latitude!, _longitude!);
    }
    
    if (_city != null && _country != null) {
      return '$_city, $_country';
    }
    
    return 'Current Location';
  }

  Future<String> _getLocationDisplayNameFromCoords(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('location_display_name');
    if (cachedName != null) return cachedName;
    
    try {
      final bigDataResult = await _tryBigDataCloudGeocoding(lat, lng);
      if (bigDataResult != null) {
        await prefs.setString('location_display_name', bigDataResult);
        return bigDataResult;
      }
    } catch (e) {
      print('BigDataCloud geocoding failed: $e');
    }

    try {
      final geoNamesResult = await _tryGeoNamesGeocoding(lat, lng);
      if (geoNamesResult != null) {
        await prefs.setString('location_display_name', geoNamesResult);
        return geoNamesResult;
      }
    } catch (e) {
      print('GeoNames geocoding failed: $e');
    }

    final coordsName = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    await prefs.setString('location_display_name', coordsName);
    return coordsName;
  }

  Future<String?> _tryBigDataCloudGeocoding(double lat, double lng) async {
    final url = 'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TafseerApp/1.0'}
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        String? city = data['city'] ?? 
                      data['locality'] ?? 
                      data['principalSubdivision'];
                      
        String? country = data['countryName'];
        
        if (city != null && country != null) {
          return '$city, $country';
        } else if (country != null) {
          return country;
        }
      }
    } catch (e) {
      print('BigDataCloud error: $e');
    }
    return null;
  }

  Future<String?> _tryGeoNamesGeocoding(double lat, double lng) async {
    final url = 'http://api.geonames.org/findNearbyPlaceNameJSON?lat=$lat&lng=$lng&username=demo';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geonames = data['geonames'] as List?;
        
        if (geonames != null && geonames.isNotEmpty) {
          final place = geonames[0];
          final city = place['name'];
          final country = place['countryName'];
          
          if (city != null && country != null) {
            return '$city, $country';
          }
        }
      }
    } catch (e) {
      print('GeoNames error: $e');
    }
    return null;
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

  Future<void> setLocationByCoordinates(double lat, double lng, String displayName) async {
    try {
      _latitude = lat;
      _longitude = lng;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cached_latitude', lat);
      await prefs.setDouble('cached_longitude', lng);
      await prefs.setString('coordinates_updated', DateTime.now().toIso8601String());
      await prefs.setString('location_display_name', displayName);
      await prefs.setBool('location_set_manually', true);
      
      await getPrayerTimesGlobally(lat, lng, DateTime.now());
      
      print('Location set manually: $displayName ($lat, $lng)');
    } catch (e) {
      print('Error setting manual location: $e');
      rethrow;
    }
  }

  Future<String> getPrayerCalculationMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final method = prefs.getString('prayer_method') ?? 'standard';
    final referenceCity = prefs.getString('reference_city');
    
    switch (method) {
      case 'coordinates':
        return 'GPS Coordinates (Most Accurate)';
      case 'nearest_city':
        return 'Reference: $referenceCity';
      case 'mecca_reference':
        return 'Mecca Times (Universal)';
      case 'city_based':
        return 'City-Based';
      default:
        return 'Standard';
    }
  }

  Future<void> getPrayerTimes() async {
    return getPrayerTimesForDate(DateTime.now());
  }

  Future<void> getPrayerTimesForDate(DateTime date) async {
    if (_latitude != null && _longitude != null) {
      try {
        await getPrayerTimesGlobally(_latitude!, _longitude!, date);
        return;
      } catch (e) {
        print('Coordinate-based prayer times failed: $e');
      }
    }

    await _getPrayerTimesByCity(date);
  }

  Future<void> _getPrayerTimesByCity(DateTime date) async {
    if (_city == null || _country == null) {
      await _loadSavedLocation();
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
        
        _findNextPrayer();
        _useCoordinates = false;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('prayer_method', 'city_based');
        
        if (_isToday(date)) {
          await setupScheduledNotifications();
        }
      }
    } catch (e) {
      print('Error fetching prayer times: $e');
    }
  }

  Future<void> _getPrayerTimesForCity(String city, String country, DateTime date) async {
    final formattedDate = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final url = '$dateApiUrl?city=$city&country=$country&method=2&date=$formattedDate';
    
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
      
      if (_isToday(date)) {
        await setupScheduledNotifications();
      }
    } else {
      throw Exception('Failed to get prayer times for $city, $country');
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
    });
  }

  Future<void> setupScheduledNotifications() async {
    await AwesomeNotifications().cancelAll();
    print("Previous notifications canceled");

    final now = DateTime.now();
    print("Current time when scheduling: ${now.toString()}");

    await _schedulePrayersForDate(DateTime.now(), 0);
  }

  Future<void> _schedulePrayersForDate(DateTime date, int dayOffset) async {
    print("Scheduling prayers for ${date.toString().split(' ')[0]}");

    List<PrayerTime> prayerTimes = [];

    if (dayOffset == 0) {
      prayerTimes = _prayerTimes;
    } else {
      final savedPrayerTimes = List<PrayerTime>.from(_prayerTimes);
      
      try {
        if (_latitude != null && _longitude != null) {
          await getPrayerTimesGlobally(_latitude!, _longitude!, date);
          prayerTimes = _prayerTimes;
          
          _prayerTimes = savedPrayerTimes;
          _findNextPrayer();
        } else {
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
        }
      } catch (e) {
        print("Error fetching prayer times for ${date.toString().split(' ')[0]}: $e");
        _prayerTimes = savedPrayerTimes;
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
      try {
        tz.setLocalLocation(tz.getLocation(deviceTimeZone));
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

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
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

      final locationName = await _getLocationDisplayNameFromCoords(position.latitude, position.longitude);
      if (locationName.contains(',')) {
        final parts = locationName.split(',');
        _city = parts[0].trim();
        _country = parts[1].trim();
        
        await prefs.setString('city', _city!);
        await prefs.setString('country', _country!);
        _lastRequestTimes[cacheKey] = DateTime.now();
        
        print("Geocoded location: $_city, $_country");
      }
    } catch (e) {
      print('Error handling location: $e');
    }
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _city = prefs.getString('city');
    _country = prefs.getString('country');
    if (_city == null || _country == null) {
      try {
        await _checkLocationPermission();
      } catch (e) {
        _city = "London";
        _country = "United Kingdom";
      }
    }
  }

  Future<void> saveLocation(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', city);
    await prefs.setString('country', country);
    _city = city;
    _country = country;
    
    _latitude = null;
    _longitude = null;
    await prefs.remove('cached_latitude');
    await prefs.remove('cached_longitude');
    
    await getPrayerTimes();
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

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    final dx = lat1 - lat2;
    final dy = lng1 - lng2;
    return sqrt(dx * dx + dy * dy);
  }

  void dispose() {
    _prayerCheckTimer?.cancel();
  }
}