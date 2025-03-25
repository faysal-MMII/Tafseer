import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io' show Platform;
import 'dart:math' show pi, sin, cos, sqrt, atan2;

class LocationService {
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final StreamController<LatLng> _locationController = StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;

  // Initialize location service
  Future<bool> initialize() async {
    if (Platform.isLinux) {
      return false;
    }

    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return false;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error initializing location service: $e');
      return false;
    }
  }

  // Get current location
  Future<LatLng?> getCurrentLocation() async {
    try {
      if (Platform.isLinux) {
        return null;
      }

      final LocationData locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final latLng = LatLng(locationData.latitude!, locationData.longitude!);
        _locationController.add(latLng);
        return latLng;
      }
      return null;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Start listening to location updates
  void startLocationUpdates() {
    if (Platform.isLinux) return;

    _locationSubscription = _location.onLocationChanged.listen((LocationData data) {
      if (data.latitude != null && data.longitude != null) {
        _locationController.add(LatLng(data.latitude!, data.longitude!));
      }
    });
  }

  // Stop listening to location updates
  void stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  // Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371.0; // km
    final lat1 = point1.latitude * pi / 180;
    final lon1 = point1.longitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final lon2 = point2.longitude * pi / 180;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = sin(dLat/2) * sin(dLat/2) +
             cos(lat1) * cos(lat2) *
             sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));

    return earthRadius * c;
  }

  // Calculate bounding box for a given center point and radius
  List<double> calculateBoundingBox(LatLng center, double radiusKm, {double radiusMultiplier = 1.0}) {
    // Convert km to degrees (approximate)
    final double kmInDegrees = 1 / 111.32;
    final double radiusInDegrees = radiusKm * kmInDegrees * radiusMultiplier;

    return [
      center.longitude - radiusInDegrees,  // min lon
      center.latitude - radiusInDegrees,   // min lat
      center.longitude + radiusInDegrees,  // max lon
      center.latitude + radiusInDegrees,   // max lat
    ];
  }

  // Show manual location input dialog
  Future<LatLng?> showLocationInputDialog(BuildContext context) async {
    final TextEditingController cityController = TextEditingController();

    return await showDialog<LatLng?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: 'City or Place Name',
                  hintText: 'e.g., Abuja, Lagos Mosque, Dubai Mall',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (cityController.text.isNotEmpty) {
                  Navigator.pop(context);
                  // The actual location will be determined by the API service
                }
              },
              child: Text('Search'),
            ),
          ],
        );
      },
    );
  }

  // Clean up resources
  void dispose() {
    stopLocationUpdates();
    _locationController.close();
  }
}
