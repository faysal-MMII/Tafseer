import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart'; // Import FirebaseFirestore

import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/places_service.dart';
import '../services/tracking_service.dart';
import '../models/place.dart';
import '../models/filter_option.dart';
import '../widgets/place_marker.dart';
import '../widgets/filter_chips.dart';
import '../widgets/search_radius_slider.dart';

class PlacesScreen extends StatefulWidget {
  final String selectedFilter;

  PlacesScreen({
    this.selectedFilter = 'mosque',
    Key? key,
  }) : super(key: key);

  @override
  _PlacesScreenState createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  // Services
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  final UserInteractionTracker _tracker = UserInteractionTracker();
  late PlacesService _placesService;

  // Map controller
  final MapController _mapController = MapController();

  // State
  LatLng? _currentLocation;
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _activeFilter = 'mosque';
  double _searchRadiusKm = 2.0;
  List<Place> _foundPlaces = [];
  bool _searchInProgress = false;
  StreamSubscription<LatLng>? _locationSubscription;

  // Filter options
  late final Map<String, FilterOption> _filterOptions;

  @override
  void initState() {
    super.initState();
    _filterOptions = FilterOption.getFilterOptions();
    _placesService = PlacesService(_apiService, _locationService, _tracker);
    _activeFilter = widget.selectedFilter;

    // Initialize without delay
    _initializeLocation();
  }

  @override
  void dispose() {
    // Cancel location updates to avoid setState after dispose
    _locationService.stopLocationUpdates();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (Platform.isLinux) {
        _showLocationDialog();
        return;
      }

      final locationInitialized = await _locationService.initialize();

      if (!locationInitialized) {
        if (mounted) {
          _showLocationDialog();
        }
        return;
      }

      // Get initial location
      final initialLocation = await _locationService.getCurrentLocation();

      if (initialLocation != null && mounted) {
        setState(() {
          _currentLocation = initialLocation;
          _isLoading = false;
        });

        // Start listening for location updates
        _locationService.startLocationUpdates();

        // Explicitly move map to current location
        _mapController.move(initialLocation, 13.0);

        // Run search immediately, but with a tiny delay to ensure UI updates first
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            _searchNearbyPlaces();
          }
        });

        // Subscribe to location updates
        _locationSubscription = _locationService.locationStream.listen((newLocation) {
          // Only update if significant movement (more than 100m)
          if (_currentLocation != null) {
            final distance = _locationService.calculateDistance(_currentLocation!, newLocation);
            if (distance > 0.1) {
              if (mounted) {
                setState(() {
                  _currentLocation = newLocation;
                });
                _searchNearbyPlaces();
              }
            }
          } else if (mounted) {
            setState(() {
              _currentLocation = newLocation;
            });
            _searchNearbyPlaces();
          }
        });
      } else {
        if (mounted) {
          _showLocationDialog();
        }
      }
    } catch (e) {
      print('Error initializing location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to get location: $e';
        });
        _showLocationDialog();
      }
    }
  }

  void _showLocationDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Your Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your city name or place:'),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Enter Location'),
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
                onSubmitted: (text) {
                  if (text.isNotEmpty) {
                    Navigator.pop(context);
                    _searchByCity(text);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
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
    if (searchQuery.isEmpty || !mounted) return;

    setState(() {
      _isLoading = true;
      _markers = [];
    });

    try {
      final searchResult = await _placesService.searchByPlaceName(searchQuery);

      if (searchResult != null && mounted) {
        setState(() {
          _currentLocation = searchResult.location;
        });

        // Add a marker for the city/place
        _markers.add(Marker(
          point: searchResult.location,
          child: Icon(
            Icons.location_city,
            color: Colors.blue,
            size: 40,
          ),
        ));

        // Move map to the location
        _mapController.move(searchResult.location, 13.0);

        // Search for places near this location
        _searchNearbyPlaces();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location not found. Please try another search.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location not found. Please try another search.'))
          );
        }
      }
    } catch (e) {
      print('Error searching by city: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error searching location: $e';
        });
      }
    }
  }

  Future<void> _searchNearbyPlaces() async {
    if (_currentLocation == null || !mounted || _searchInProgress) return;

    setState(() {
      _isLoading = true;
      _searchInProgress = true;
    });

    try {
      _markers = [];

      _markers.add(Marker(
        point: _currentLocation!,
        child: CurrentLocationMarker(),
      ));

      print('Searching near location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');

      final places = await _placesService.searchNearbyPlaces(
        _currentLocation!,
        _activeFilter,
        _searchRadiusKm,
      );

      if (mounted) {
        setState(() {
          _foundPlaces = places;

          for (final place in places) {
            final filterOption = _filterOptions[_activeFilter]!;
            final distance = _locationService.calculateDistance(_currentLocation!, place.location);

            // Additional verification at UI level
            bool isAppropriate = true;

            if (_activeFilter == 'mosque' &&
                (place.name.toLowerCase().contains('church') ||
                    place.name.toLowerCase().contains('temple') && !place.name.toLowerCase().contains('islamic'))) {
              isAppropriate = false;
            } else if (_activeFilter == 'restaurant' &&
                (place.name.toLowerCase().contains('pork') ||
                    place.name.toLowerCase().contains('bacon'))) {
              isAppropriate = false;
            }

            if (isAppropriate) {
              _markers.add(Marker(
                point: place.location,
                width: 42,
                height: 42,
                child: PlaceMarker(
                  place: place,
                  distance: distance,
                  filterOption: filterOption,
                  onTap: () => _onPlaceMarkerTap(place),
                ),
              ));
            }
          }
        });
      }
    } catch (e) {
      print('Error searching nearby places: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error searching nearby places: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchInProgress = false;
        });
      }
    }
  }

  void _onPlaceMarkerTap(Place place) {
    _placesService.trackPlaceClick(place);

    // Prepare a list of detail items to display
    List<Widget> detailWidgets = [];

    // Add address section if available
    if (place.tags.containsKey('addr:street') ||
        place.tags.containsKey('addr:housenumber') ||
        place.tags.containsKey('address')) {
      detailWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Address:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                place.tags['address'] ??
                    [
                      place.tags['addr:housenumber'],
                      place.tags['addr:street'],
                      place.tags['addr:city'],
                    ].where((e) => e != null).join(' ') ??
                    'Address not available',
              ),
            ],
          ),
        ),
      );
    }

    // Add phone section if available
    if (place.tags.containsKey('phone')) {
      detailWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(place.tags['phone']),
            ],
          ),
        ),
      );
    }

    // Add website if available
    if (place.tags.containsKey('website')) {
      detailWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Website:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(place.tags['website']),
            ],
          ),
        ),
      );
    }

    // Add hours if available
    if (place.tags.containsKey('opening_hours')) {
      detailWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hours:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(place.tags['opening_hours']),
            ],
          ),
        ),
      );
    }

    // Always add type information
    detailWidgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_capitalizeString(place.type)),
          ],
        ),
      ),
    );

    // Add OSM ID (can be useful for mapping enthusiasts or debugging)
    detailWidgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OSM ID:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${place.type} ${place.id}', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    // Add coordinates at the bottom
    detailWidgets.add(
      Text(
        'Coordinates: ${place.lat.toStringAsFixed(6)}, ${place.lon.toStringAsFixed(6)}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );

    // Check if we have any mosque-specific tags
    if (place.tags.containsKey('denomination') ||
        place.tags.containsKey('religion') ||
        place.tags.containsKey('name:ar')) {
      detailWidgets.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Additional Info:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (place.tags.containsKey('denomination'))
                Text('Denomination: ${place.tags['denomination']}'),
              if (place.tags.containsKey('religion'))
                Text('Religion: ${place.tags['religion']}'),
              if (place.tags.containsKey('name:ar'))
                Text('Arabic Name: ${place.tags['name:ar']}'),
            ],
          ),
        ),
      );
    }

    // If we have very little information, add a note explaining why
    if (detailWidgets.length < 3) {
      detailWidgets.add(
        Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            'This location has limited information in OpenStreetMap. You can help improve the data by updating it on openstreetmap.org.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ),
      );
    }

    // Show the dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detailWidgets,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Center the map on this place
              _mapController.move(place.location, 16.0);
              Navigator.pop(context);
            },
            child: Text('Show on Map'),
          ),
          // Add report button to allow users to suggest corrections
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showReportIssueDialog(place);
            },
            child: Text('Report Issue'),
          ),
        ],
      ),
    );
  }

  // New method to allow users to report issues with a place
  void _showReportIssueDialog(Place place) {
    final issueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Issue with ${place.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please describe the issue:'),
            SizedBox(height: 16),
            TextField(
              controller: issueController,
              decoration: InputDecoration(
                hintText: 'e.g., Wrong location, incorrect name, closed down',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (issueController.text.isNotEmpty) {
                // Submit the report
                FirebaseFirestore.instance.collection('place_issues').add({
                  'place_id': place.id,
                  'place_name': place.name,
                  'place_type': place.type,
                  'latitude': place.lat,
                  'longitude': place.lon,
                  'issue': issueController.text,
                  'reported_at': FieldValue.serverTimestamp(),
                  'status': 'pending',
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Thank you for your report!'))
                );
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }


  void _onFilterChanged(String filterKey) {
    if (_activeFilter == filterKey) return;

    setState(() {
      _activeFilter = filterKey;
    });

    _searchNearbyPlaces();
  }

  // --- Added methods from prompt ---
  void _showReportMissingPlaceDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = _activeFilter; // Default to current filter

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Missing Place'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Please provide details about the missing place:'),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Place Name*',
                    hintText: 'e.g., Al-Noor Mosque',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address*',
                    hintText: 'e.g., 123 Main Street',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                Text('Type:'),
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedType = newValue;
                      });
                    }
                  },
                  items: _filterOptions.keys.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(_filterOptions[value]!.displayName),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes',
                    hintText: 'Any other details about this place',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter both name and address'))
                );
                return;
              }

              _submitMissingPlaceReport(
                name: nameController.text,
                address: addressController.text,
                type: selectedType,
                notes: notesController.text,
              );
              Navigator.pop(context);
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitMissingPlaceReport({
    required String name,
    required String address,
    required String type,
    String? notes,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Store in Firebase
      await FirebaseFirestore.instance.collection('missing_places').add({
        'name': name,
        'address': address,
        'type': type,
        'notes': notes,
        'latitude': _currentLocation?.latitude,
        'longitude': _currentLocation?.longitude,
        'status': 'pending', // could be 'pending', 'approved', 'rejected'
        'reported_at': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for reporting $name! Your submission will help improve our data.'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report. Please try again.'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  // --- End of added methods ---

  // Helper function to capitalize strings
  String _capitalizeString(String text) {
    if (text.isEmpty) return text;
    return "${text[0].toUpperCase()}${text.substring(1)}";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Muslim Places Finder'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showCityInputDialog(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _searchNearbyPlaces,
          ),
          IconButton( // Added report button here
            icon: Icon(Icons.report_problem),
            onPressed: _showReportMissingPlaceDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips container
          FilterChipsRow(
            activeFilter: _activeFilter,
            onFilterSelected: _onFilterChanged,
            filterOptions: _filterOptions,
          ),

          // Radius slider
          SearchRadiusSlider(
            radius: _searchRadiusKm,
            onChanged: (value) {
              setState(() {
                _searchRadiusKm = value;
              });
            },
            onChangeEnd: (value) {
              _searchNearbyPlaces();
            },
          ),

          // Map section
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(0, 0),
                    initialZoom: 13.0,
                    interactiveFlags: InteractiveFlag.all,
                    onMapReady: () {
                      if (_currentLocation != null) {
                        _mapController.move(_currentLocation!, 13.0);
                      }
                    },
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
                      markers: _markers,
                      rotate: true,
                      alignment: Alignment.center,
                    ),
                  ],
                ),

                // Loading indicator
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                if (_errorMessage != null && !_isLoading)
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Places count display
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Found: ${_foundPlaces.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
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
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 13.0);
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}