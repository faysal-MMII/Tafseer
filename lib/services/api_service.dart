import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import 'dart:async';

class ApiService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _userAgent = 'IslamicPlacesFinder/1.0';
  
  // Cache management
  final Map<String, CachedResponse> _cache = {};
  static const Duration _cacheDuration = Duration(days: 7);

  // Rate limiting
  DateTime _lastOverpassRequest = DateTime.now().subtract(Duration(seconds: 1));
  static const Duration _minOverpassRequestInterval = Duration(milliseconds: 1000);
  
  // Search via Overpass API
  Future<List<Place>> searchOverpass(String query, List<double> bbox) async {
    // Create a unique cache key
    final cacheKey = 'overpass_${query.hashCode}_${bbox.join('_')}';
    
    // Check cache
    if (_cache.containsKey(cacheKey) && 
        _cache[cacheKey]!.timestamp.isAfter(DateTime.now().subtract(_cacheDuration))) {
      print('Using cached Overpass results for $cacheKey');
      return _cache[cacheKey]!.places;
    }
    
    // Rate limiting
    final now = DateTime.now();
    if (now.difference(_lastOverpassRequest) < _minOverpassRequestInterval) {
      final waitTime = _minOverpassRequestInterval - now.difference(_lastOverpassRequest);
      await Future.delayed(waitTime);
    }
    
    _lastOverpassRequest = DateTime.now();
    
    // Apply bbox to query
    final formattedQuery = query
        .replaceAll('{{bbox}}', '${bbox[1]},${bbox[0]},${bbox[3]},${bbox[2]}')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    
    try {
      print('Sending Overpass query: $formattedQuery'); // Debug print
      
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: formattedQuery,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': _userAgent
        },
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Overpass response received. Elements: ${data['elements']?.length ?? 0}');
        
        final elements = data['elements'] as List? ?? [];
        final List<Place> places = [];
        
        // First, extract all nodes and their coordinates
        Map<String, LatLng> nodeMap = {};
        for (var element in elements) {
          try {
            if (element['type'] == 'node' && 
                element['id'] != null && 
                element['lat'] != null && 
                element['lon'] != null) {
              nodeMap[element['id'].toString()] = LatLng(
                element['lat'].toDouble(),
                element['lon'].toDouble()
              );
            }
          } catch (e) {
            print('Error extracting node coordinates: $e');
          }
        }
        
        // Process all elements with access to the node map
        for (var element in elements) {
          try {
            final Map<String, dynamic> elementMap = Map<String, dynamic>.from(element);
            final place = Place.fromOverpass(elementMap, nodeMap);
            places.add(place);
          } catch (e) {
            // Skip invalid elements
            print('Error processing Overpass element: $e');
          }
        }
        
        // Cache the result
        _cache[cacheKey] = CachedResponse(places, DateTime.now());
        
        return places;
      } else {
        print('Overpass API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error with Overpass API: $e');
      return [];
    }
  }

  // Add Retry Logic with Exponential Backoff
  Future<List<Place>> searchOverpassWithRetry(
      String query, List<double> bbox, {int maxRetries = 3}) async {
    for (int retry = 0; retry < maxRetries; retry++) {
      try {
        return await searchOverpass(query, bbox);
      } catch (e) {
        print('Overpass API error (attempt ${retry + 1}/$maxRetries): $e');
        if (retry < maxRetries - 1) {
          // Exponential backoff: wait longer after each failure
          final waitTime = Duration(seconds: 2 * (retry + 1));
          print('Retrying in ${waitTime.inSeconds} seconds...');
          await Future.delayed(waitTime);
        } else {
          // Last attempt failed
          rethrow;
        }
      }
    }
    return []; // This line shouldn't be reached, but Dart requires it
  }

  // Helper method to extract center from element
  LatLng? extractCenterFromElement(Map<String, dynamic> element) {
    // Direct coordinates
    if (element['lat'] != null && element['lon'] != null) {
      return LatLng(
        element['lat'].toDouble(),
        element['lon'].toDouble(),
      );
    }

    // Center node
    if (element['center'] != null && 
        element['center']['lat'] != null && 
        element['center']['lon'] != null) {
      return LatLng(
        element['center']['lat'].toDouble(),
        element['center']['lon'].toDouble(),
      );
    }

    // Calculate center from nodes (for ways)
    if (element['nodes'] is List && element['nodes'].isNotEmpty) {
      // This would require additional processing to get node coordinates
      // For now, return null
    }

    return null;
  }
  
  // Search via Nominatim
  Future<List<Place>> searchNominatim(String query, List<double> bbox, {int limit = 50}) async {
    // Create cache key
    final cacheKey = 'nominatim_${query.hashCode}_${bbox.join('_')}_$limit';
    
    // Check cache
    if (_cache.containsKey(cacheKey) && 
        _cache[cacheKey]!.timestamp.isAfter(DateTime.now().subtract(_cacheDuration))) {
      print('Using cached Nominatim results for $cacheKey');
      return _cache[cacheKey]!.places;
    }
    
    try {
      final searchUrl = Uri.parse(
        '$_nominatimUrl?'
        'format=json'
        '&q=${Uri.encodeComponent(query)}'
        '&viewbox=${bbox.join(",")}'
        '&bounded=1'
        '&limit=$limit'
        '&addressdetails=1'
        '&dedupe=1'
      );
      
      print('Nominatim search URL: $searchUrl');
      
      final response = await http.get(
        searchUrl,
        headers: {
          'User-Agent': _userAgent,
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        print('Found ${data.length} places with Nominatim');
        
        final List<Place> places = [];
        for (var element in data) {
          try {
            final place = Place.fromNominatim(element);
            places.add(place);
          } catch (e) {
            // Skip invalid elements
            print('Error processing Nominatim element: $e');
          }
        }
        
        // Cache the result
        _cache[cacheKey] = CachedResponse(places, DateTime.now());
        
        return places;
      } else {
        print('Nominatim API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error with Nominatim API: $e');
      return [];
    }
  }
  
  // Search for a location by city name
  Future<LatLng?> searchLocationByName(String placeName) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_nominatimUrl?'
          'format=json'
          '&q=${Uri.encodeComponent(placeName)}'
          '&limit=1'
        ),
        headers: {'User-Agent': _userAgent},
      );
      
      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final location = results.first;
          final lat = double.parse(location['lat']);
          final lon = double.parse(location['lon']);
          return LatLng(lat, lon);
        }
      }
      return null;
    } catch (e) {
      print('Error searching location by name: $e');
      return null;
    }
  }
  
  // Search for places by broader query
  Future<List<Place>> searchWithBroaderQuery(
      String query, List<double> bbox, {int limit = 50}) async {
    try {
      final overpassQuery = '''
        [out:json][timeout:60]; // Increase from 25 to 60 seconds
        (
          node[$query](${bbox[1]},${bbox[0]},${bbox[3]},${bbox[2]});
          way[$query](${bbox[1]},${bbox[0]},${bbox[3]},${bbox[2]});
        );
        out body;>;
        out skel qt;
      ''';
      
      print('Trying broader search with query: $query');
      
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: overpassQuery,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': _userAgent
        },
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List? ?? [];
        
        final List<Place> places = [];
        // First, extract all nodes and their coordinates for this query
        Map<String, LatLng> nodeMap = {};
        for (var element in elements) {
          try {
            if (element['type'] == 'node' && 
                element['id'] != null && 
                element['lat'] != null && 
                element['lon'] != null) {
              nodeMap[element['id'].toString()] = LatLng(
                element['lat'].toDouble(),
                element['lon'].toDouble()
              );
            }
          } catch (e) {
            print('Error extracting node coordinates: $e');
          }
        }
        
        // Process all elements with access to the node map
        for (var element in elements) {
          try {
            final Map<String, dynamic> elementMap = Map<String, dynamic>.from(element);
            final place = Place.fromOverpass(elementMap, nodeMap);
            places.add(place);
          } catch (e) {
            // Skip invalid elements
            print('Error processing Overpass element: $e');
          }
        }
        
        print('Found ${places.length} places with broader search query: $query');
        return places;
      }
      return [];
    } catch (e) {
      print('Error in broader search with query $query: $e');
      return [];
    }
  }
  
  // Clear cache
  void clearCache() {
    _cache.clear();
  }
}

// Helper class for caching
class CachedResponse {
  final List<Place> places;
  final DateTime timestamp;
  
  CachedResponse(this.places, this.timestamp);
}