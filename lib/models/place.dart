import 'package:latlong2/latlong.dart';

class Place {
  final String id;
  final double lat;
  final double lon;
  final String name;
  final String type;
  final Map<String, dynamic> tags;

  Place({
    required this.id,
    required this.lat,
    required this.lon,
    required this.name,
    required this.type,
    this.tags = const {},
  });

  LatLng get location => LatLng(lat, lon);

  factory Place.fromOverpass(Map<String, dynamic> element, Map<String, LatLng> nodeMap) {
    try {
      // Extract tags and basic info
      final Map<String, dynamic> tags = 
          Map<String, dynamic>.from(element['tags'] ?? {});

      String name = tags['name'] ?? 
          tags['name:en'] ?? 
          tags['alt_name'] ?? 
          '${element['type']?.toString().capitalize() ?? 'Place'}';

      // Try different ways to get coordinates
      double? lat;
      double? lon;

      // Direct coordinates (for nodes)
      if (element['lat'] != null && element['lon'] != null) {
        lat = element['lat'].toDouble();
        lon = element['lon'].toDouble();
      } 
      // Center point (for ways/relations)
      else if (element['center'] != null && 
               element['center']['lat'] != null && 
               element['center']['lon'] != null) {
        lat = element['center']['lat'].toDouble();
        lon = element['center']['lon'].toDouble();
      }
      // For ways, calculate center from nodes
      else if (element['type'] == 'way' && element['nodes'] is List && element['nodes'].isNotEmpty) {
        double sumLat = 0;
        double sumLon = 0;
        int count = 0;

        // Print debug info
        print('Processing way with ${element['nodes'].length} nodes, nodeMap has ${nodeMap.length} entries');

        for (var nodeId in element['nodes']) {
          String id = nodeId.toString();
          if (nodeMap.containsKey(id)) {
            sumLat += nodeMap[id]!.latitude;
            sumLon += nodeMap[id]!.longitude;
            count++;
          }
        }

        if (count > 0) {
          lat = sumLat / count;
          lon = sumLon / count;
          print('Calculated center for way ${element['id']}: $lat, $lon from $count nodes');
        } else {
          print('No node coordinates found for way ${element['id']}');
        }
      }

      // Skip if we can't determine location
      if (lat == null || lon == null) {
        throw Exception('Location coordinates missing in element');
      }

      return Place(
        id: element['id'].toString(),
        lat: lat,
        lon: lon,
        name: name,
        type: element['type'] ?? 'unknown',
        tags: tags,
      );
    } catch (e) {
      print('Error processing Overpass element: $e');
      rethrow;
    }
  }

  factory Place.fromNominatim(Map<String, dynamic> element) {
    final lat = double.tryParse(element['lat']?.toString() ?? '');
    final lon = double.tryParse(element['lon']?.toString() ?? '');

    if (lat == null || lon == null) {
      throw Exception('Location coordinates missing in Nominatim result');
    }

    // Extract name with fallbacks
    final name = element['name'] ?? 
        element['display_name']?.toString().split(',').first ?? 
        'Unnamed Place';

    return Place(
      id: element['place_id']?.toString() ?? "${lat}_${lon}",
      lat: lat,
      lon: lon,
      name: name,
      type: element['type'] ?? 'unknown',
      tags: element['address'] ?? {},
    );
  }

  // Factory method to create from generic map data, trying both formats
  static Place? fromAny(Map<String, dynamic> data, Map<String, LatLng> nodeMap) {
    try {
      if (data.containsKey('place_id') || data.containsKey('display_name')) {
        return Place.fromNominatim(data);
      } else {
        return Place.fromOverpass(data, nodeMap);
      }
    } catch (e) {
      print('Error creating Place from data: $e');
      return null;
    }
  }
}

// Define the capitalize extension here since it's used in the Place class
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}