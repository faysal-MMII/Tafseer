import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QiblaService {
  // The Kaaba coordinates in Mecca
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;
  
  // Current device bearing (compass)
  Stream<double>? _compassStream;
  Stream<double>? get compassStream => _compassStream;
  
  // Current qibla direction in degrees from north
  double _qiblaDirection = 0.0;
  double get qiblaDirection => _qiblaDirection;
  
  // Current device position
  Position? _currentPosition;
  
  // Current location name
  String _locationName = "Unknown";
  
  // Qibla position relative to device
  StreamController<double> _qiblaStreamController = StreamController<double>.broadcast();
  Stream<double> get qiblaStream => _qiblaStreamController.stream;
  
  QiblaService() {
    _initCompass();
  }
  
  // Initialize compass
  void _initCompass() {
    if (FlutterCompass.events != null) {
      _compassStream = FlutterCompass.events!.map((event) {
        // Get the heading from compass (in degrees)
        final heading = event.heading ?? 0;
        
        // If qibla direction is calculated, adjust the heading
        if (_qiblaDirection != 0) {
          // Calculate the relative angle to qibla
          final qiblaAngle = (_qiblaDirection - heading) % 360;
          
          // Send the angle to the stream
          _qiblaStreamController.add(qiblaAngle);
        }
        
        return heading;
      });
    }
  }
  
  // Calculate qibla direction from current position
  Future<void> calculateQiblaDirection() async {
    try {
      // Request location permission
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
      
      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Try to get location name
      await _determineLocationName();
      
      // Calculate qibla direction using the latlong2 package
      final Distance distance = Distance();
      final LatLng currentLatLng = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude
      );
      final LatLng kaabaLatLng = LatLng(kaabaLatitude, kaabaLongitude);
      
      // Calculate bearing to Kaaba
      _qiblaDirection = distance.bearing(currentLatLng, kaabaLatLng);
      
      // Ensure the direction is between 0 and 360 degrees
      if (_qiblaDirection < 0) {
        _qiblaDirection += 360;
      }
      
    } catch (e) {
      print('Error calculating qibla direction: $e');
      // Try to load saved location name
      await _loadSavedLocationName();
      rethrow;
    }
  }
  
  // Determine location name from coordinates
  Future<void> _determineLocationName() async {
    if (_currentPosition == null) return;
    
    try {
      // This would ideally use a geocoding service
      // Since we're keeping it simple, we'll use coordinates
      // In a real app, you would use the Geocoding package to get the actual city name
      
      // For now, we'll try to retrieve a saved location name or use coordinates
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('locationName');
      
      if (savedName != null && savedName.isNotEmpty) {
        _locationName = savedName;
      } else {
        // Format coordinates nicely
        final lat = _currentPosition!.latitude.toStringAsFixed(4);
        final lng = _currentPosition!.longitude.toStringAsFixed(4);
        _locationName = '${lat}, ${lng}';
        
        // Save for future use
        await prefs.setString('locationName', _locationName);
      }
    } catch (e) {
      print('Error determining location name: $e');
      _locationName = 'Unknown Location';
    }
  }
  
  // Load saved location name
  Future<void> _loadSavedLocationName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('locationName');
      _locationName = savedName ?? 'Unknown Location';
    } catch (e) {
      _locationName = 'Unknown Location';
    }
  }
  
  // Get current location name
  Future<String> getLocationName() async {
    if (_locationName == 'Unknown Location') {
      await _loadSavedLocationName();
    }
    return _locationName;
  }
  
  // Get distance to Kaaba in kilometers
  double getDistanceToKaaba() {
    if (_currentPosition == null) return 0;
    
    final Distance distance = Distance();
    final LatLng currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude
    );
    final LatLng kaabaLatLng = LatLng(kaabaLatitude, kaabaLongitude);
    
    // Calculate distance in kilometers
    return distance.as(LengthUnit.Kilometer, currentLatLng, kaabaLatLng);
  }
  
  // Save a custom location name
  Future<void> saveLocationName(String name) async {
    if (name.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locationName', name);
    _locationName = name;
  }
  
  // Dispose streams
  void dispose() {
    _qiblaStreamController.close();
  }
}