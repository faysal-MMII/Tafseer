import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'dart:async';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/responsive_layout.dart';

class UserInteractionTracker {
  static const String kFilterCountKey = 'filter_counts';
  static const String kSearchHistoryKey = 'search_history';
  static const String kPlaceClicksKey = 'place_clicks';

  // Track filter usage
  static Future<void> trackFilterUsage(String filter) async {
    final prefs = await SharedPreferences.getInstance();
    final counts = prefs.getStringList(kFilterCountKey) ?? [];

    // Store as "filter:count" pairs
    Map<String, int> filterCounts = {};
    for (String pair in counts) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        filterCounts[parts[0]] = int.parse(parts[1]);
      }
    }

    filterCounts[filter] = (filterCounts[filter] ?? 0) + 1;

    // Convert back to list for storage
    final updatedCounts = filterCounts.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();

    await prefs.setStringList(kFilterCountKey, updatedCounts);
  }

  // Track search history
  static Future<void> trackSearch(String searchTerm) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(kSearchHistoryKey) ?? [];

    // Keep only last 20 searches
    if (searches.length >= 20) {
      searches.removeLast();
    }
    searches.insert(0, searchTerm);

    await prefs.setStringList(kSearchHistoryKey, searches);
  }

  // Track place clicks
  static Future<void> trackPlaceClick(String placeType) async {
    final prefs = await SharedPreferences.getInstance();
    final clicks = prefs.getStringList(kPlaceClicksKey) ?? [];

    // Keep last 50 interactions
    if (clicks.length >= 50) {
      clicks.removeLast();
    }
    clicks.insert(0, placeType);

    await prefs.setStringList(kPlaceClicksKey, clicks);
  }

  // Get most used filter
  static Future<String?> getMostUsedFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final counts = prefs.getStringList(kFilterCountKey) ?? [];

    if (counts.isEmpty) return null;

    Map<String, int> filterCounts = {};
    for (String pair in counts) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        filterCounts[parts[0]] = int.parse(parts[1]);
      }
    }

    // Find highest count
    String? mostUsed;
    int maxCount = 0;
    filterCounts.forEach((filter, count) {
      if (count > maxCount) {
        maxCount = count;
        mostUsed = filter;
      }
    });

    return mostUsed;
  }

  // Get interaction summary
  static Future<Map<String, dynamic>> getInteractionSummary() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'mostUsedFilter': await getMostUsedFilter(),
      'recentSearches': prefs.getStringList(kSearchHistoryKey) ?? [],
      'recentClicks': prefs.getStringList(kPlaceClicksKey) ?? []
    };
  }
}

// Keep your existing StringExtension
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class PlacesScreen extends StatefulWidget {
  // Keep your existing constructor and createState
  final String selectedFilter;

  PlacesScreen({this.selectedFilter = 'mosque', Key? key}) : super(key: key);

  @override
  _PlacesScreenState createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  // Keep your existing variable declarations
  final MapController mapController = MapController();
  late Location location;
  StreamSubscription<LocationData>? locationSubscription;
  LatLng? currentLocation;
  List<Marker> markers = [];
  bool isLoading = true;
  String? _errorMessage;
  String activeFilter = 'mosque';
  String get selectedFilter => widget.selectedFilter;
  double _searchRadiusKm = 2.0;

  // Add new variables for caching
  static const String CACHE_KEY_PREFIX = 'places_cache_';
  static const Duration CACHE_DURATION = Duration(days: 7);

  // Updated filterOptions with comprehensive Overpass queries
  final Map<String, Map<String, dynamic>> filterOptions = {
    'mosque': {
      'icon': Icons.mosque,
      'overpassQuery': '''
        [out:json][timeout:25];
        (
          node["amenity"="place_of_worship"]["religion"="muslim"]({{bbox}});
          way["amenity"="place_of_worship"]["religion"="muslim"]({{bbox}});
          relation["amenity"="place_of_worship"]["religion"="muslim"]({{bbox}});
          node["building"="mosque"]({{bbox}});
          way["building"="mosque"]({{bbox}});
          node["amenity"="place_of_worship"]["name"~"masjid|mosque",i]({{bbox}});
        );
        out body;>;out skel qt;
      ''',
      'nominatimQuery': 'mosque OR masjid OR "islamic center" OR "place of worship" AND "muslim"',
      'displayName': 'Mosques',
      'markerColor': Colors.green,
    },
    'restaurant': {
      'icon': Icons.restaurant,
      'overpassQuery': '''
        [out:json][timeout:25];
        (
          node["cuisine"="halal"]({{bbox}});
          way["cuisine"="halal"]({{bbox}});
          node["diet:halal"="yes"]({{bbox}});
          way["diet:halal"="yes"]({{bbox}});
          node["food"="halal"]({{bbox}});
          way["food"="halal"]({{bbox}});
          node["amenity"="restaurant"]["name"~"halal|muslim|arabic|turkish|persian|middle eastern",i]({{bbox}});
          way["amenity"="restaurant"]["name"~"halal|muslim|arabic|turkish|persian|middle eastern",i]({{bbox}});
        );
        out body;>;out skel qt;
      ''',
      'nominatimQuery': 'halal restaurant OR muslim restaurant OR arabic restaurant',
      'displayName': 'Halal Restaurants',
      'markerColor': Colors.red,
    },
    'shop': {
      'icon': Icons.shopping_cart,
      'overpassQuery': '''
        [out:json][timeout:25];
        (
          node["shop"]["diet:halal"="yes"]({{bbox}});
          way["shop"]["diet:halal"="yes"]({{bbox}});
          node["shop"="convenience"]["halal"="yes"]({{bbox}});
          way["shop"="convenience"]["halal"="yes"]({{bbox}});
          node["shop"="supermarket"]["halal"="yes"]({{bbox}});
          way["shop"="supermarket"]["halal"="yes"]({{bbox}});
          node["shop"]["name"~"halal|muslim|islamic",i]({{bbox}});
          way["shop"]["name"~"halal|muslim|islamic",i]({{bbox}});
          node["shop"="butcher"]["halal"="yes"]({{bbox}});
          way["shop"="butcher"]["halal"="yes"]({{bbox}});
        );
        out body;>;out skel qt;
      ''',
      'nominatimQuery': 'halal shop OR islamic shop OR muslim shop OR halal butcher OR halal market',
      'displayName': 'Halal Shops',
      'markerColor': Colors.blue,
    },
    'community': {
      'icon': Icons.people,
      'overpassQuery': '''
        [out:json][timeout:25];
        (
          node["amenity"="community_centre"]["religion"="muslim"]({{bbox}});
          way["amenity"="community_centre"]["religion"="muslim"]({{bbox}});
          node["amenity"="social_centre"]["religion"="muslim"]({{bbox}});
          way["amenity"="social_centre"]["religion"="muslim"]({{bbox}});
          node["leisure"="social_club"]["religion"="muslim"]({{bbox}});
          way["leisure"="social_club"]["religion"="muslim"]({{bbox}});
          node["amenity"="social_facility"]["religion"="muslim"]({{bbox}});
          way["amenity"="social_facility"]["religion"="muslim"]({{bbox}});
          node["name"~"islamic center|muslim community|islamic society",i]({{bbox}});
          way["name"~"islamic center|muslim community|islamic society",i]({{bbox}});
        );
        out body;>;out skel qt;
      ''',
      'nominatimQuery': 'islamic center OR muslim community center OR islamic society',
      'displayName': 'Community Centers',
      'markerColor': Colors.orange,
    }
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    try {
      if (Platform.isLinux) {
        _showLocationDialog();
        return;
      }

      location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print('Location services are required.');
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Location permission required.');
          return;
        }
      }

      final LocationData initialLocation = await location.getLocation();
      setState(() {
        currentLocation =
            LatLng(initialLocation.latitude!, initialLocation.longitude!);
        isLoading = false;
      });

      if (!Platform.isLinux) {
        locationSubscription =
            location.onLocationChanged.listen((LocationData newLocation) {
          final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);
          setState(() {
            currentLocation = newLatLng;
          });
          _searchNearbyPlaces();
        });
      }
      _searchNearbyPlaces();
    } catch (e) {
      print('Error initializing location: $e');
      _showLocationDialog();
    }
  }

  void _handleError(String message) {
    setState(() {
      _errorMessage = null;
      isLoading = false;
    });
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Your Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your city name:'),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Enter City Name'),
                onPressed: () {
                  Navigator.pop(context);
                  _showCityInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCityInputDialog() async {
    final TextEditingController cityController = TextEditingController();

    await showDialog(
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
              onPressed: () async {
                if (cityController.text.isNotEmpty) {
                  Navigator.pop(context);
                  await _searchByCity(cityController.text);
                }
              },
              child: Text('Search'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _searchByCity(String searchQuery) async {
    if (searchQuery.isEmpty) return;

    await UserInteractionTracker.trackSearch(searchQuery); // Track search here

    setState(() {
      isLoading = true;
      markers.clear();
    });

    try {
      final cityResponse = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?'
          'format=json'
          '&q=${Uri.encodeComponent(searchQuery)}'
          '&limit=1'
        ),
        headers: {'User-Agent': 'IslamicPlacesFinder/1.0'},
      );

      // First decode the response into cityPlaces
      final List cityPlaces = json.decode(cityResponse.body);

      if (cityResponse.statusCode == 200 && cityPlaces.isNotEmpty) {
        final cityLocation = cityPlaces.first;
        final lat = double.parse(cityLocation['lat']);
        final lon = double.parse(cityLocation['lon']);

        setState(() {
          currentLocation = LatLng(lat, lon);
        });

        markers.add(Marker(
          point: LatLng(lat, lon),
          child: Icon(
            Icons.location_city,
            color: Colors.blue,
            size: 40,
          ),
        ));

        final filterData = filterOptions[activeFilter];
        if (filterData != null) {
          // Calculate a larger bounding box (approximately 10km radius)
          final double boxSize = 0.1; // roughly 10km at equator

          // Construct a more comprehensive search URL
          final placeSearchUrl = Uri.parse(
            'https://nominatim.openstreetmap.org/search?'
            'format=json'
            '&q=${Uri.encodeComponent(filterData['nominatimQuery'])}'
            '&viewbox=${lon - boxSize},${lat - boxSize},${lon + boxSize},${lat + boxSize}'
            '&bounded=1'
            '&limit=50'
            '&amenity=place_of_worship'
            '&religion=muslim'
            '&dedupe=1'
            '&addressdetails=1'
          );

          final placesResponse = await http.get(
            placeSearchUrl,
            headers: {
              'User-Agent': 'IslamicPlacesFinder/1.0',
              'Accept-Language': 'en-US,en;q=0.9',
            },
          );

          if (placesResponse.statusCode == 200) {
            final List places = json.decode(placesResponse.body);

            if (places.isEmpty) {
              // If no results, try a broader search without amenity filters
              final broaderSearchUrl = Uri.parse(
                'https://nominatim.openstreetmap.org/search?'
                'format=json'
                '&q=${Uri.encodeComponent(filterData['nominatimQuery'])}'
                '&viewbox=${lon - boxSize * 2},${lat - boxSize * 2},${lon + boxSize * 2},${lat + boxSize * 2}'
                '&bounded=1'
                '&limit=50'
                '&dedupe=1'
                '&addressdetails=1'
              );

              final broaderResponse = await http.get(
                broaderSearchUrl,
                headers: {
                  'User-Agent': 'IslamicPlacesFinder/1.0',
                  'Accept-Language': 'en-US,en;q=0.9',
                },
              );

              if (broaderResponse.statusCode == 200) {
                final List broaderPlaces = json.decode(broaderResponse.body);
                _addPlacesToMarkers(broaderPlaces);
              }
            } else {
              _addPlacesToMarkers(places);
            }

            mapController.move(LatLng(lat, lon), 13.0);
            setState(() {});
          }
        }
      } else {
        print('City not found. Please try another search term.');
      }
    } catch (e) {
      print('Error searching places: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to convert Overpass API response to List of Places
  List<dynamic> _convertOverpassToPlaces(Map<String, dynamic> data) {
    final elements = data['elements'] as List;
    return elements.map((element) {
      // Extract tags and basic info
      final tags = element['tags'] ?? {};
      final name = tags['name'] ??
                  tags['name:en'] ??
                  tags['alt_name'] ??
                  '${element['type']?.toString().capitalize() ?? 'Place'}';

      // Handle different element types (node, way, relation)
      double? lat = element['lat']?.toDouble();
      double? lon = element['lon']?.toDouble();

      // For ways and relations, use center point if available
      if (lat == null || lon == null) {
        if (element['center'] != null) {
          lat = element['center']['lat']?.toDouble();
          lon = element['center']['lon']?.toDouble();
        }
      }

      // Skip if we can't determine location
      if (lat == null || lon == null) return null;

      return {
        'id': element['id'].toString(),
        'lat': lat,
        'lon': lon,
        'name': name,
        'type': element['type'],
        'tags': tags,
      };
    }).where((element) => element != null).toList();
  }

  // Build current location marker
  Widget _buildCurrentLocationMarker() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.my_location,
        color: Colors.white,
        size: 12,
      ),
    );
  }

  // Search with broader terms when specific search fails
  Future<void> _searchWithBroaderTerms(List<double> bbox) async {
    // Define broader queries based on active filter
    final Map<String, List<String>> broaderQueriesByFilter = {
      'mosque': [
        'amenity=place_of_worship',
        'building=mosque',
        'name~"masjid|mosque|islamic|muslim"',
        'religion=muslim'
      ],
      'restaurant': [
        'amenity=restaurant',
        'cuisine=halal',
        'diet:halal=yes',
        'food=halal',
        'name~"halal|muslim|arabic|turkish|persian|middle eastern"'
      ],
      'shop': [
        'shop=convenience',
        'shop=supermarket',
        'shop=butcher',
        'diet:halal=yes',
        'halal=yes',
        'name~"halal|muslim|islamic"'
      ],
      'community': [
        'amenity=community_centre',
        'amenity=social_centre',
        'leisure=social_club',
        'name~"islamic|muslim|community"',
        'religion=muslim'
      ]
    };

    final queries = broaderQueriesByFilter[activeFilter] ?? [];
    if (queries.isEmpty) return;

    for (final query in queries) {
      final overpassQuery = '''
        [out:json][timeout:25];
        (
          node[$query](${bbox[1]},${bbox[0]},${bbox[3]},${bbox[2]});
          way[$query](${bbox[1]},${bbox[0]},${bbox[3]},${bbox[2]});
          relation[$query](${bbox[1]},${bbox[0]},${bbox[3]},${bbox[2]});
        );
        out body;>;
        out skel qt;
      ''';

      try {
        print('Trying broader search with query: $query'); // Debug print

        final response = await http.post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          body: overpassQuery,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'IslamicPlacesFinder/1.0'
          },
        ).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final places = _convertOverpassToPlaces(data);
          if (places.isNotEmpty) {
            print('Found ${places.length} places with broader search query: $query'); // Debug print
            _addPlacesToMarkers(places);
            // Don't break here - collect all results from different queries
          }
        }
      } catch (e) {
        print('Error in broader search with query $query: $e');
      }
    }
  }

  // Calculate distance between current location and place
  double _calculateDistance(LatLng placeLocation) {
    if (currentLocation == null) return double.infinity;

    const double earthRadius = 6371.0; // km
    final lat1 = currentLocation!.latitude * pi / 180;
    final lon1 = currentLocation!.longitude * pi / 180;
    final lat2 = placeLocation.latitude * pi / 180;
    final lon2 = placeLocation.longitude * pi / 180;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = sin(dLat/2) * sin(dLat/2) +
             cos(lat1) * cos(lat2) *
             sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));

    return earthRadius * c;
  }

  // Get place name with fallbacks
  String _getPlaceName(dynamic place) {
    if (place is Map) {
      return place['name'] ??
             place['tags']?['name'] ??
             place['tags']?['name:en'] ??
             place['display_name']?.toString().split(',').first ??
             'Unnamed ${place['type']?.toString().capitalize() ?? 'Place'}';
    }
    return 'Unnamed Place';
  }

  // Build marker for a place with specific styling based on filter type
  Widget _buildMarker(dynamic place) {
    final placeLocation = LatLng(
      double.parse(place['lat'].toString()),
      double.parse(place['lon'].toString()),
    );

    final distance = _calculateDistance(placeLocation);
    final filterData = filterOptions[activeFilter];
    final Color markerColor = filterData?['markerColor'] ?? Colors.blue;
    final IconData markerIcon = filterData?['icon'] ?? Icons.place;

    return Container(
      width: 32,
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            markerIcon,
            size: 16,
            color: markerColor,
          ),
          if (distance != double.infinity)
            Text(
              '${distance.toStringAsFixed(1)}km',
              style: TextStyle(
                fontSize: 8,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // Update the _searchWithOverpass method:
  Future<List<dynamic>> _searchWithOverpass() async {
    final bbox = _calculateBoundingBox();
    final query = filterOptions[activeFilter]!['overpassQuery']
        .replaceAll('{{bbox}}', '${bbox[1]},${bbox[0]},${bbox[3]},${bbox[2]}')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    try {
      print('Sending Overpass query: $query'); // Debug print

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'IslamicPlacesFinder/1.0'
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(json.decode(response.body));
        print('Overpass response received. Elements: ${data['elements']?.length ?? 0}'); // Debug print
        return _convertOverpassToPlaces(data);
      }
      print('Overpass API error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Error with Overpass API: $e');
      return [];
    }
  }

  // Update the _searchNearbyPlaces method:
  Future<void> _searchNearbyPlaces() async {
    if (currentLocation == null) return;

    setState(() {
      isLoading = true;
      markers.clear();
    });

    try {
      // Add current location marker
      markers.add(Marker(
        point: currentLocation!,
        child: _buildCurrentLocationMarker(),
      ));

      print('Searching near location: ${currentLocation!.latitude}, ${currentLocation!.longitude}'); // Debug print

      // First try Overpass API
      List<dynamic> overpassPlaces = await _searchWithOverpass();
      if (overpassPlaces.isNotEmpty) {
        print('Found ${overpassPlaces.length} places with Overpass'); // Debug print
        _addPlacesToMarkers(overpassPlaces);
      }

      // If no results from Overpass, try Nominatim
      if (markers.length <= 1) {
        print('No Overpass results, trying Nominatim'); // Debug print
        final bbox = _calculateBoundingBox(radiusMultiplier: 2.0);
        final filterData = filterOptions[activeFilter];
        if (filterData != null) {
          await _searchWithNominatim(filterData['nominatimQuery'], bbox);
        }
      }

      // If still no results, try broader search
      if (markers.length <= 1) {
        print('No results from initial searches, trying broader search'); // Debug print
        final bbox = _calculateBoundingBox(radiusMultiplier: 3.0);
        await _searchWithBroaderTerms(bbox);
      }

    } catch (e) {
      print('Error searching nearby places: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update the _calculateBoundingBox method:
  List<double> _calculateBoundingBox({double radiusMultiplier = 1.0}) {
    if (currentLocation == null) return [0, 0, 0, 0];

    // Convert km to degrees (approximate)
    final double kmInDegrees = 1 / 111.32;
    final double radiusInDegrees = _searchRadiusKm * kmInDegrees * radiusMultiplier;

    return [
      currentLocation!.longitude - radiusInDegrees,  // min lon
      currentLocation!.latitude - radiusInDegrees,   // min lat
      currentLocation!.longitude + radiusInDegrees,  // max lon
      currentLocation!.latitude + radiusInDegrees,   // max lat
    ];
  }

  // Update the _searchWithNominatim method:
  Future<void> _searchWithNominatim(String query, List<double> bbox) async {
    try {
      final searchUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'format=json'
        '&q=${Uri.encodeComponent(query)}'
        '&viewbox=${bbox.join(",")}'
        '&bounded=1'
        '&limit=50'
        '&addressdetails=1'
        '&dedupe=1'
      );

      print('Nominatim search URL: $searchUrl'); // Debug print

      final response = await http.get(
        searchUrl,
        headers: {
          'User-Agent': 'IslamicPlacesFinder/1.0',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final List places = json.decode(response.body);
        print('Found ${places.length} places with Nominatim'); // Debug print
        _addPlacesToMarkers(places);
      }
    } catch (e) {
      print('Error in Nominatim search: $e');
    }
  }

  // Update the _addPlacesToMarkers method:
  void _addPlacesToMarkers(List places) {
    for (var place in places) {
      try {
        final lat = double.tryParse(place['lat']?.toString() ?? '') ??
                   place['center']?['lat'] ??
                   place['geometry']?['coordinates']?[1];
        final lon = double.tryParse(place['lon']?.toString() ?? '') ??
                   place['center']?['lon'] ??
                   place['geometry']?['coordinates']?[0];

        if (lat != null && lon != null) {
          final placeLocation = LatLng(lat, lon);
          final distance = _calculateDistance(placeLocation);

          if (distance <= _searchRadiusKm * 1.5) {
            print('Adding marker for place: ${_getPlaceName(place)} at $lat, $lon'); // Debug print
            markers.add(Marker(
              point: placeLocation,
              child: _buildMarker(place),
            ));
          }
        }
      } catch (e) {
        print('Error adding marker for place: $e');
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Muslim Places Finder'),
      ),
      body: Column(
        children: [
          // Filter chips container
          Container(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 5 : 10,
                vertical: 5
              ),
              children: filterOptions.entries.map((filter) {
                bool isActive = activeFilter == filter.key;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(filter.value['icon'],
                            size: 20,
                            color: isActive ? Colors.white : Colors.black),
                        SizedBox(width: 5),
                        Text(filter.value['displayName'].toString().capitalize(),
                            style: TextStyle(
                                color: isActive ? Colors.white : Colors.black)),
                      ],
                    ),
                    selected: isActive,
                    onSelected: (bool selected) {
                      if (selected) {
                        UserInteractionTracker.trackFilterUsage(filter.key);
                        setState(() {
                          activeFilter = filter.key;
                          mapController.move(currentLocation!, mapController.camera.zoom);
                          _searchNearbyPlaces();
                        });
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),

          // Radius slider
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8.0 : 16.0
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Search Radius: ${_searchRadiusKm.toStringAsFixed(1)} km'),
                Slider(
                  value: _searchRadiusKm,
                  min: 0.5,
                  max: 5.0,
                  divisions: 9,
                  label: '${_searchRadiusKm.toStringAsFixed(1)} km',
                  onChanged: (double value) {
                    setState(() {
                      _searchRadiusKm = value;
                    });
                  },
                  onChangeEnd: (double value) {
                    _searchNearbyPlaces();
                  },
                ),
              ],
            ),
          ),

          // Map section
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: currentLocation ?? const LatLng(0, 0),
                    initialZoom: 13.0,
                    interactiveFlags: InteractiveFlag.all,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                      maxZoom: 19,
                      minZoom: 1,
                      tileProvider: NetworkTileProvider(),
                      errorImage: NetworkImage('https://tile.openstreetmap.org/0/0/0.png'),
                      retinaMode: MediaQuery.of(context).devicePixelRatio > 1,
                      keepBuffer: 5,
                      tileBuilder: (context, child, tile) {
                        return Opacity(
                          opacity: 1.0,
                          child: child,
                        );
                      },
                    ),
                    MarkerLayer(
                      markers: markers,
                      rotate: true,
                    ),
                  ],
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (currentLocation != null) {
            mapController.move(currentLocation!, 13.0);
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}

class LocationService { // Moved LocationService outside PlacesScreen and _PlacesScreenState
  static Future<LocationData?> getCurrentLocation(BuildContext context) async {
    if (Platform.isAndroid) {
      try {
        final location = Location();
        bool serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) return null;
        }
        PermissionStatus permissionStatus = await location.hasPermission();
        if (permissionStatus == PermissionStatus.denied) {
          permissionStatus = await location.requestPermission();
          if (permissionStatus != PermissionStatus.granted) return null;
        }
        return await location.getLocation();
      } catch (e) {
        _showManualInputDialog(context);
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _showManualInputDialog(
      BuildContext context) async {
    final TextEditingController latController = TextEditingController();
    final TextEditingController lngController = TextEditingController();

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lngController,
              decoration: InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'latitude': double.parse(latController.text),
                'longitude': double.parse(lngController.text),
              });
            },
            child: Text('Submit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}