import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../models/filter_option.dart';
import 'api_service.dart';
import 'location_service.dart';
import 'tracking_service.dart';
import 'dart:math' show pi, cos;
import 'package:cloud_firestore/cloud_firestore.dart';

class PlacesService {
  final ApiService _apiService;
  final LocationService _locationService;
  final UserInteractionTracker _tracker;
  
  // Keep track of places to avoid duplicates
  final Set<String> _processedPlaceIds = <String>{};
  
  PlacesService(this._apiService, this._locationService, this._tracker);
  
  // Search for places near a location with a specific filter
  Future<List<Place>> searchNearbyPlaces(
    LatLng location,
    String filterKey,
    double radiusKm,
    {bool useBroaderSearch = true}
  ) async {
    final filterOptions = FilterOption.getFilterOptions();
    final filterOption = filterOptions[filterKey];
    
    if (filterOption == null) {
      print('Invalid filter key: $filterKey');
      return [];
    }
    
    // Track filter usage
    await _tracker.trackFilterUsage(filterKey);
    
    // Clear processed IDs for a fresh search
    _processedPlaceIds.clear();
    
    final List<Place> foundPlaces = [];
    
    // Calculate bounding box
    final bbox = _locationService.calculateBoundingBox(location, radiusKm);
    
    try {
      // First try Overpass API
      final overpassPlaces = await _apiService.searchOverpass(
        filterOption.overpassQuery, 
        bbox
      );
      
      if (overpassPlaces.isNotEmpty) {
        print('Found ${overpassPlaces.length} places with Overpass API');
        _addUniquePlaces(foundPlaces, overpassPlaces, location, radiusKm, filterKey);
      }
      
      // If few results, try Nominatim
      if (foundPlaces.length < 3) {
        print('Few Overpass results, trying Nominatim');
        final nominatimPlaces = await _apiService.searchNominatim(
          filterOption.nominatimQuery, 
          _locationService.calculateBoundingBox(location, radiusKm, radiusMultiplier: 2.0)
        );
        
        if (nominatimPlaces.isNotEmpty) {
          print('Found ${nominatimPlaces.length} places with Nominatim');
          _addUniquePlaces(foundPlaces, nominatimPlaces, location, radiusKm, filterKey);
        }
      }
      
      // If still few results and broader search is enabled, try broader queries
      if (foundPlaces.length < 5 && useBroaderSearch) {
        print('Few results, trying broader search queries');
        await _searchWithBroaderQueries(
          filterOption, 
          location, 
          radiusKm, 
          foundPlaces,
          filterKey
        );
      }

      // Check for user-reported places
      final reportedPlaces = await getReportedPlaces(location, radiusKm, filterKey);
      if (reportedPlaces.isNotEmpty) {
        print('Found ${reportedPlaces.length} user-reported places');
        for (final place in reportedPlaces) {
          if (!_processedPlaceIds.contains(place.id)) {
            foundPlaces.add(place);
            _processedPlaceIds.add(place.id);
          }
        }
      }
      
      // Sort places by distance
      foundPlaces.sort((a, b) {
        final distA = _locationService.calculateDistance(location, a.location);
        final distB = _locationService.calculateDistance(location, b.location);
        return distA.compareTo(distB);
      });
      
      return foundPlaces;
    } catch (e) {
      print('Error searching nearby places: $e');
      return [];
    }
  }
  
  // Fetch reported places
  Future<List<Place>> getReportedPlaces(LatLng location, double radiusKm, String filterKey) async {
    try {
      // Calculate approximate bounding box
      double lat = location.latitude;
      double lon = location.longitude;
      double latDelta = radiusKm / 111.0; // Rough approximation: 1 degree is about 111km
      double lonDelta = radiusKm / (111.0 * cos(lat * pi / 180.0));

      // Query Firebase for approved or pending reports within range
      final snapshot = await FirebaseFirestore.instance
          .collection('missing_places')
          .where('type', isEqualTo: filterKey)
          .where('latitude', isGreaterThan: lat - latDelta)
          .where('latitude', isLessThan: lat + latDelta)
          .where('longitude', isGreaterThan: lon - lonDelta)
          .where('longitude', isLessThan: lon + lonDelta)
          .get();

      List<Place> reportedPlaces = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Skip if missing coordinates
        if (data['latitude'] == null || data['longitude'] == null) continue;

        // Create a place from the report
        final place = Place(
          id: 'reported-${doc.id}',
          lat: data['latitude'],
          lon: data['longitude'],
          name: data['name'],
          type: data['type'],
          tags: {
            'reported': 'true',
            'address': data['address'],
            if (data['notes'] != null) 'notes': data['notes'],
          },
        );

        reportedPlaces.add(place);
      }

      return reportedPlaces;
    } catch (e) {
      print('Error fetching reported places: $e');
      return [];
    }
  }
  
  // Search for a place by name/city
  Future<PlaceSearchResult?> searchByPlaceName(String placeName) async {
    await _tracker.trackSearch(placeName);
    
    try {
      // First, find the location of the place
      final location = await _apiService.searchLocationByName(placeName);
      
      if (location == null) {
        print('Location not found for: $placeName');
        return null;
      }
      
      // Return the location and let the caller decide what to search for
      return PlaceSearchResult(
        location: location,
        placeName: placeName,
      );
    } catch (e) {
      print('Error searching by place name: $e');
      return null;
    }
  }
  
  // Helper method to add places to the result list, avoiding duplicates
  void _addUniquePlaces(
    List<Place> targetList, 
    List<Place> newPlaces, 
    LatLng centerLocation,
    double radiusKm,
    String filterKey
  ) {
    for (final place in newPlaces) {
      // Skip if already processed
      if (_processedPlaceIds.contains(place.id)) {
        continue;
      }
      
      // Skip if no proper name (e.g., just "Node")
      if (place.name == "Node" || place.name.isEmpty) {
        continue;
      }
      
      // Check if the place matches the filter
      if (!_doesPlaceMatchFilter(place, filterKey)) {
        continue;
      }
      
      // Check if within radius
      final distance = _locationService.calculateDistance(
        centerLocation, 
        place.location
      );
      
      if (distance <= radiusKm * 1.5) {
        _processedPlaceIds.add(place.id);
        targetList.add(place);
      }
    }
  }
  
  // Helper method to verify a place matches the current filter
  bool _doesPlaceMatchFilter(Place place, String filterKey) {
    switch (filterKey) {
      case 'mosque':
        if (place.tags['religion'] == 'christian' || 
            place.tags['religion'] == 'hindu' || 
            place.tags['religion'] == 'buddhist' || 
            place.name.toLowerCase().contains('church') || 
            place.name.toLowerCase().contains('chapel') || 
            place.name.toLowerCase().contains('cathedral') || 
            place.name.toLowerCase().contains('synagogue') || 
            place.name.toLowerCase().contains('temple') && !place.name.toLowerCase().contains('islamic')) {
          return false;
        }
        return (place.tags['religion'] == 'muslim') ||
               (place.type == 'mosque') ||
               (place.name.toLowerCase().contains('mosque')) ||
               (place.name.toLowerCase().contains('masjid')) ||
               (place.name.toLowerCase().contains('islamic')) ||
               (place.name.toLowerCase().contains('muslim'));
      case 'restaurant':
        if (place.tags['diet:halal'] == 'no' || 
            place.tags['cuisine'] == 'pork' || 
            place.name.toLowerCase().contains('pork') ||
            place.name.toLowerCase().contains('bacon')) {
          return false;
        }
        return (place.tags['diet:halal'] == 'yes') ||
               (place.tags['cuisine'] == 'halal') || 
               (place.tags['halal'] == 'yes') ||
               (place.name.toLowerCase().contains('halal')) ||
               (place.name.toLowerCase().contains('muslim')) ||
               (place.name.toLowerCase().contains('arabic')) ||
               (place.name.toLowerCase().contains('turkish')) ||
               (place.name.toLowerCase().contains('middle eastern'));
      case 'shop':
        if (place.tags['diet:halal'] == 'no' || 
            place.tags['products'] == 'pork' ||
            place.name.toLowerCase().contains('pork')) {
          return false;
        }
        return (place.tags['diet:halal'] == 'yes') ||
               (place.tags['halal'] == 'yes') ||
               (place.name.toLowerCase().contains('halal')) ||
               (place.name.toLowerCase().contains('muslim')) ||
               (place.name.toLowerCase().contains('islamic'));
      case 'community':
        if (place.tags['religion'] == 'christian' || 
            place.tags['religion'] == 'hindu' || 
            place.tags['religion'] == 'buddhist') {
          return false;
        }
        return (place.tags['religion'] == 'muslim') ||
               (place.name.toLowerCase().contains('islamic')) ||
               (place.name.toLowerCase().contains('muslim'));
      default:
        return true;
    }
  }
  
  // Search with broader queries when specific search fails
  Future<void> _searchWithBroaderQueries(
    FilterOption filterOption,
    LatLng location,
    double radiusKm,
    List<Place> targetList,
    String filterKey
  ) async {
    final bbox = _locationService.calculateBoundingBox(
      location, 
      radiusKm, 
      radiusMultiplier: 3.0
    );
    
    // Only try 3 broader queries at most to avoid rate limiting
    final queriesToTry = filterOption.broaderQueries.take(3).toList();
    
    for (final query in queriesToTry) {
      // Add delay between queries to avoid rate limiting
      await Future.delayed(Duration(seconds: 1));
      
      try {
        print('Trying broader query: $query'); // Debugging statement
        final places = await _apiService.searchWithBroaderQuery(query, bbox);
        
        if (places.isNotEmpty) {
          print('Found ${places.length} places with broader query: $query');
          _addUniquePlaces(targetList, places, location, radiusKm, filterKey);
        } else {
          print('No places found with query: $query'); // Debugging statement
        }
      } catch (e) {
        print('Error with broader query $query: $e');
      }
    }
  }
  
  // Track when a user clicks on a place
  Future<void> trackPlaceClick(Place place) async {
    await _tracker.trackPlaceClick(place.type);
  }
  
  // Clear caches and processed IDs
  void clearCache() {
    _processedPlaceIds.clear();
    _apiService.clearCache();
  }
}

// Helper class for search by place name
class PlaceSearchResult {
  final LatLng location;
  final String placeName;
  
  PlaceSearchResult({
    required this.location,
    required this.placeName,
  });
}