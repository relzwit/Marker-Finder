import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'firebase_options.dart';
// import 'marker_finder/lib/firebase_options.dart';

import '../services/hmdb_scraper.dart';
import '../services/settings_service.dart';
import '../services/region_service.dart';
import '../widgets/custom_location_layer.dart';
import '../widgets/draggable_explorer.dart';
import 'profile_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Store the last map center to detect significant movement
  LatLng? _lastMapCenter;
  // Minimum distance in meters to trigger marker refresh
  static const double _minMapMoveDistance = 5000; // 5km

  // Debounce timer for map movements
  Timer? _mapMovementDebounceTimer;
  // Debounce duration in milliseconds
  static const int _debounceTimeMs = 500; // Wait 500ms after movement stops

  @override
  void initState() {
    super.initState();

    // Initialize the map controller
    mapController = MapController();

    // _loadCSV();
    _getCurrentLocation();

    // Listen to radius changes
    _radiusSubscription = SettingsService.radiusStream.listen((radius) {
      debugPrint('MapPage: Radius changed to $radius km, refreshing markers');
      _loadCSV(); // Reload markers with the new radius
    });
  }

  @override
  void dispose() {
    _radiusSubscription?.cancel();
    _mapMovementDebounceTimer?.cancel();
    super.dispose();
  }

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(MapPage());
  }

  // Map controller - will be initialized when the map is created
  late final MapController mapController;
  final PopupController _popupLayerController = PopupController();
  String _selectedCSV = "assets/CSVs/hmdb_usa_tennessee.csv";

  // Raw CSV data
  List<List<dynamic>> _data = [];

  // List of locations within the specified radius
  final List<List<dynamic>> _closeLocations = [];

  // List of marker objects for the markers listed in _closeLocations
  final List<Marker> _markerObjList = [];

  Position? _position;

  // Flag to track if location is being fetched
  bool _isLoadingLocation = false;

  // Subscription to radius changes
  StreamSubscription<double>? _radiusSubscription;

  void _getCurrentLocation() async {
    // Prevent multiple simultaneous location requests
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await _determinePosition();

      if (mounted) {
        setState(() {
          _position = position;
          _isLoadingLocation = false;
          // Update the last map center to the new position
          _lastMapCenter = LatLng(position.latitude, position.longitude);
          _loadCSV(); // Load CSV after getting location
        });
      }
    } catch (e) {
      // Only show error if the widget is still mounted
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Error'),
            content: Text(
                'Could not get your location: $e\n\nPlease check your location permissions and try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _getCurrentLocation(); // Try again
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  void _loadCSV() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading markers...')),
        );
      }

      // Automatically determine the best region based on current position
      if (_position != null) {
        String closestRegionFile = RegionService.determineClosestRegion(
            _position!.latitude, _position!.longitude);

        // Only update if different from current selection
        if (_selectedCSV != "assets/CSVs/$closestRegionFile") {
          setState(() {
            _selectedCSV = "assets/CSVs/$closestRegionFile";
          });

          // Show which region was selected
          String regionName =
              RegionService.getRegionNameFromFile(closestRegionFile);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Automatically selected region: $regionName')),
            );
          }
          debugPrint('Automatically selected region: $regionName');
        }
      }

      final rawData = await rootBundle.loadString(_selectedCSV);
      List<List<dynamic>> listData =
          const CsvToListConverter().convert(rawData);

      if (mounted) {
        setState(() {
          _data = listData;
          if (_data.isNotEmpty) {
            _data.removeAt(0); // remove top line of csv
            debugPrint('CSV loaded successfully with ${_data.length} entries');
          } else {
            debugPrint('CSV loaded but contains no data');
          }
          _fillCloseLocations();
        });
      }
    } catch (e) {
      debugPrint('Error loading CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading markers: $e')),
        );
      }
    }
  }

  // Maximum number of markers to display at once for performance
  static const int _maxMarkersToDisplay = 500;
  bool _isLoadingMarkers = false;

  void _fillCloseLocations() async {
    // Prevent multiple simultaneous loading operations
    if (_isLoadingMarkers) return;

    setState(() {
      _isLoadingMarkers = true;
    });

    try {
      // Clear existing markers and locations
      _closeLocations.clear();
      _markerObjList.clear();

      // Check if position is available
      if (_position == null) {
        // Use default location since current location is not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Using default location (Tennessee). Enable location for better results.')),
          );
        }
        // Use a default location (Tennessee)
        _position = Position(
          latitude: 35.5175,
          longitude: -86.5804,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      double myLat = _position!.latitude;
      double myLon = _position!.longitude;

      // Get the search radius from settings (in km, convert to meters)
      double acceptableDist = await SettingsService.getSearchRadius() * 1000;
      debugPrint('Using search radius: ${acceptableDist / 1000} km');

      // Create a list to store markers with their distances
      List<Map<String, dynamic>> markersWithDistance = [];

      // First pass: calculate distances and store markers that are in range
      for (var element in _data) {
        try {
          // Make sure we have valid numeric values for lat/lon
          double? lon = _parseDouble(element[8]);
          double? lat = _parseDouble(element[7]);

          // Skip if lat/lon are not valid numbers
          if (lat == null || lon == null) {
            continue;
          }

          // Get other marker data
          String markerName = element[2].toString();
          int markerId = int.tryParse(element[0].toString()) ?? 0;
          String markerLink = element[16].toString();

          // Check if marker is within acceptable distance
          double distance = Geolocator.distanceBetween(myLat, myLon, lat, lon);

          // Only add markers that are within the radius
          if (distance < acceptableDist) {
            markersWithDistance.add({
              'element': element,
              'distance': distance,
              'lat': lat,
              'lon': lon,
              'name': markerName,
              'id': markerId,
              'link': markerLink,
            });
          }
        } catch (e) {
          // Skip invalid entries - silently handle errors
          debugPrint('Error processing marker: $e');
        }
      }

      // Sort markers by distance (closest first)
      markersWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Limit the number of markers to display
      int markersToShow = markersWithDistance.length > _maxMarkersToDisplay
          ? _maxMarkersToDisplay
          : markersWithDistance.length;

      // Second pass: create and add the markers
      for (int i = 0; i < markersToShow; i++) {
        var markerData = markersWithDistance[i];
        _closeLocations.add(markerData['element']);

        // Create monument object
        Monument monument = Monument(
          name: markerData['name'],
          lat: markerData['lat'],
          long: markerData['lon'],
          id: markerData['id'],
          link: Uri.parse(markerData['link']),
        );

        // Fetch marker data from HMDB website
        _fetchMarkerData(monument);

        // Add marker to the list
        if (mounted) {
          _markerObjList
              .add(MonumentMarker(monument: monument, context: context));
        }

        // Debug info for first few markers
        if (i < 3) {
          debugPrint(
              'Added marker: ${markerData['name']} at distance: ${(markerData['distance'] / 1000).toStringAsFixed(2)} km');
        }
      }

      // Double-check that all markers are within the radius
      debugPrint('Before filtering: ${markersWithDistance.length} markers');
      markersWithDistance = markersWithDistance
          .where((marker) => (marker['distance'] as double) <= acceptableDist)
          .toList();
      debugPrint(
          'After strict filtering: ${markersWithDistance.length} markers');

      // Show summary message
      int totalMarkersInRange = markersWithDistance.length;
      debugPrint(
          'Found $totalMarkersInRange markers within ${acceptableDist / 1000} km radius');
      debugPrint('Displaying $markersToShow markers for better performance');

      if (mounted) {
        setState(() {
          _isLoadingMarkers = false;
        });

        if (totalMarkersInRange > 0) {
          String message =
              'Found $totalMarkersInRange markers within ${(acceptableDist / 1000).toStringAsFixed(1)} km';
          if (totalMarkersInRange > _maxMarkersToDisplay) {
            message += ' (showing $markersToShow for performance)';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'No markers found within ${(acceptableDist / 1000).toStringAsFixed(1)} km. Try increasing the radius in Profile settings.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _fillCloseLocations: $e');
      if (mounted) {
        setState(() {
          _isLoadingMarkers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading markers: $e')),
        );
      }
    }
  }

  // Fetch marker data (image and inscription) from HMDB website
  void _fetchMarkerData(Monument monument) async {
    try {
      final markerData =
          await HmdbScraper.getMarkerData(monument.link.toString());
      setState(() {
        monument.imageUrl = markerData['imageUrl'];
        monument.inscription = markerData['inscription'];
      });
    } catch (e) {
      debugPrint('Error fetching marker data: $e');
    }
  }

  // Current index for bottom navigation bar
  int _selectedIndex = 0;

  // Helper method to get cluster color based on number of markers
  Color _getClusterColor(int markerCount) {
    if (markerCount < 10) {
      return Colors.blue; // Small cluster
    } else if (markerCount < 50) {
      return Colors.orange; // Medium cluster
    } else {
      return Colors.red; // Large cluster
    }
  }

  // Helper method to safely parse a double from various data types
  double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is String) {
      // Try to parse the string as a double
      try {
        return double.parse(value);
      } catch (e) {
        // If it fails, return null
        return null;
      }
    }

    // For any other type, return null
    return null;
  }

  // Flag to control automatic marker loading on map movement
  bool _autoLoadMarkersOnMove = false;

  // Handle map movement to load new markers when moved significantly
  void _onMapMoved(LatLng newCenter) {
    // Skip if we're already loading markers or auto-loading is disabled
    if (_isLoadingMarkers || !_autoLoadMarkersOnMove) return;

    // If this is the first movement, store the center and return
    if (_lastMapCenter == null) {
      _lastMapCenter = newCenter;
      return;
    }

    // Calculate distance between last center and new center
    double distanceInMeters = Geolocator.distanceBetween(
        _lastMapCenter!.latitude,
        _lastMapCenter!.longitude,
        newCenter.latitude,
        newCenter.longitude);

    // If moved significantly, update the position and reload markers after debounce
    if (distanceInMeters > _minMapMoveDistance) {
      debugPrint(
          'Map moved significantly: ${(distanceInMeters / 1000).toStringAsFixed(2)} km');

      // Cancel any existing timer
      _mapMovementDebounceTimer?.cancel();

      // Set a new timer to load markers after movement stops
      _mapMovementDebounceTimer =
          Timer(Duration(milliseconds: _debounceTimeMs), () {
        if (mounted) {
          // Update the position to the new map center
          _position = Position(
            latitude: newCenter.latitude,
            longitude: newCenter.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );

          // Update the last map center
          _lastMapCenter = newCenter;

          // Show a message that markers are being updated
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Updating markers for new location...'),
              duration: Duration(seconds: 1),
            ),
          );

          // Reload markers with the new position
          _loadCSV();
        }
      });
    }
  }

  // Navigate to the selected page
  void _navigateBottomBar(int index) {
    if (index == 1) {
      // Navigate to profile page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marker Finder'),
        actions: [
          // Show marker count
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${_markerObjList.length} markers',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Show current region
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _selectedCSV.isEmpty
                    ? ''
                    : 'Region: ${RegionService.getRegionNameFromFile(_selectedCSV.split('/').last)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          // Region selector in a menu button
          PopupMenuButton<String>(
            tooltip: 'Manually select region',
            icon: const Icon(Icons.map),
            onSelected: (String region) {
              setState(() {
                _selectedCSV = "assets/CSVs/$region";
                _loadCSV();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: '',
                enabled: false,
                child: Text('Select Region',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'hmdb_ger.csv',
                child: Text('Germany'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_eng.csv',
                child: Text('England'),
              ),
              //USA states below -->
              const PopupMenuItem<String>(
                value: 'hmdb_usa_arizona.csv',
                child: Text('Arizona'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_california.csv',
                child: Text('California'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_connecticut.csv',
                child: Text('Connecticut'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_delaware.csv',
                child: Text('Delaware'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_florida.csv',
                child: Text('Florida'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_hawaii.csv',
                child: Text('Hawaii'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_idaho.csv',
                child: Text('Idaho'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_maine.csv',
                child: Text('Maine'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_massachusetts.csv',
                child: Text('Massachusetts'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_minnesota.csv',
                child: Text('Minnesota'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_montana.csv',
                child: Text('Montana'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_nevada.csv',
                child: Text('Nevada'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_new-hampshire.csv',
                child: Text('New Hampshire'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_new-jersey.csv',
                child: Text('New Jersey'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_new-york.csv',
                child: Text('New York'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_north-carolina.csv',
                child: Text('North Carolina'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_oklahoma.csv',
                child: Text('Oklahoma'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_oregon.csv',
                child: Text('Oregon'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_pennsylvania.csv',
                child: Text('Pennsylvania'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_rhode-island.csv',
                child: Text('Rhode Island'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_south-carolina.csv',
                child: Text('South Carolina'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_utah.csv',
                child: Text('Utah'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_vermont.csv',
                child: Text('Vermont'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_washington.csv',
                child: Text('Washington'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_west-virginia.csv',
                child: Text('West Virginia'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_alaska.csv',
                child: Text('Alaska'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_arkansas.csv',
                child: Text('Arkansas'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_colorado.csv',
                child: Text('Colorado'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_illinois.csv',
                child: Text('Illinois'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_indiana.csv',
                child: Text('Indiana'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_iowa.csv',
                child: Text('Iowa'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_kansas.csv',
                child: Text('Kansas'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_kentucky.csv',
                child: Text('Kentucky'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_louisiana.csv',
                child: Text('Louisiana'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_maryland.csv',
                child: Text('Maryland'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_michigan.csv',
                child: Text('Michigan'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_mississippi.csv',
                child: Text('Mississippi'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_missouri.csv',
                child: Text('Missouri'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_nebraska.csv',
                child: Text('Nebraska'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_new-mexico.csv',
                child: Text('New Mexico'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_north-dakota.csv',
                child: Text('North Dakota'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_south-dakota.csv',
                child: Text('South Dakota'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_texas.csv',
                child: Text('Texas'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_virginia.csv',
                child: Text('Virginia'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_wisconsin.csv',
                child: Text('Wisconsin'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_wyoming.csv',
                child: Text('Wyoming'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_alabama.csv',
                child: Text('Alabama'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_georgia.csv',
                child: Text('Georgia'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_tennessee.csv',
                child: Text('Tennessee'),
              ),

              //speshul little pookie
              const PopupMenuItem<String>(
                value: 'hmdb_usa_district-of-colombia.csv',
                child: Text('District of Colombia'),
              ),
              // territories
              const PopupMenuItem<String>(
                value: 'hmdb_usa_puerto-rico.csv',
                child: Text('Puerto Rico'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_virgin-islands.csv',
                child: Text('Virgin Islands'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_guam.csv',
                child: Text('Guam'),
              ),
              const PopupMenuItem<String>(
                value: 'hmdb_usa_amer-samoa.csv',
                child: Text('American Samoa'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Color.fromARGB(0, 53, 53, 205),
      // body: _pages[_selectedIndex]
      body: Stack(
        children: [
          // The map
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(35, -85), //good initial center
              initialZoom: 7.0,
              maxZoom: 30,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (_, __) => _popupLayerController.hideAllPopups(),
              // Add map event listener to update markers when map interaction stops
              onMapEvent: (event) {
                // Only process events when map interaction ends
                if (event is MapEventMoveEnd ||
                    event is MapEventFlingAnimationEnd ||
                    event is MapEventDoubleTapZoomEnd) {
                  _onMapMoved(event.camera.center);
                }
              },
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              CustomLocationLayer(mapController: mapController),
              // Use MarkerClusterLayerWidget for better performance with many markers
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  // Increase cluster radius for better performance with many markers
                  maxClusterRadius: 80,
                  size: const Size(50, 50),
                  markers: _markerObjList,
                  // Fit bounds when cluster is tapped
                  onClusterTap: (cluster) {
                    mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: cluster.bounds,
                        padding: const EdgeInsets.all(50.0),
                      ),
                    );
                  },
                  // Custom cluster marker builder
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: _getClusterColor(markers.length),
                        border: Border.all(width: 2, color: Colors.white),
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                  // Animate cluster splitting/merging
                  animationsOptions: const AnimationsOptions(
                    zoom: Duration(milliseconds: 500),
                    spiderfy: Duration(milliseconds: 500),
                  ),
                ),
              ),

              // Popup layer for marker popups
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  markers: _markerObjList,
                  popupController: _popupLayerController,
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (_, Marker marker) {
                      if (marker is MonumentMarker) {
                        return MonumentMarkerPopup(monument: marker.monument);
                      }
                      return const Card(child: Text('Not a monument'));
                    },
                  ),
                ),
              ),
            ],
          ),

          // Map explorer target - covers the entire map area
          Positioned.fill(
            child: MapExplorerTarget(
              onDrop: (LatLng screenPosition) {
                // Convert screen position to map coordinates
                final mapPosition = mapController.camera.pointToLatLng(
                    Point(screenPosition.longitude, screenPosition.latitude));

                // Always proceed since pointToLatLng always returns a non-null value
                // Update position to the dropped location
                _position = Position(
                  latitude: mapPosition.latitude,
                  longitude: mapPosition.longitude,
                  timestamp: DateTime.now(),
                  accuracy: 0,
                  altitude: 0,
                  heading: 0,
                  speed: 0,
                  speedAccuracy: 0,
                  altitudeAccuracy: 0,
                  headingAccuracy: 0,
                );

                // Show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Exploring area at ${mapPosition.latitude.toStringAsFixed(4)}, ${mapPosition.longitude.toStringAsFixed(4)}')),
                );

                // Zoom in to the dropped location for a better view of the city
                mapController.move(
                    mapPosition, 12.0); // Zoom level 12 is good for cities

                // Load markers for the new location
                _loadCSV();
              },
            ),
          ),

          // Draggable explorer icon
          DraggableExplorer(
            onDrop: (LatLng location) {
              // This is handled by the MapExplorerTarget
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Loading indicator overlay when markers are being loaded
          if (_isLoadingMarkers)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'Loading markers...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          FloatingActionButton.small(
            onPressed: _isLoadingMarkers
                ? null
                : () {
                    // Update position to current map center before reloading
                    final currentCenter = mapController.camera.center;
                    _position = Position(
                      latitude: currentCenter.latitude,
                      longitude: currentCenter.longitude,
                      timestamp: DateTime.now(),
                      accuracy: 0,
                      altitude: 0,
                      heading: 0,
                      speed: 0,
                      speedAccuracy: 0,
                      altitudeAccuracy: 0,
                      headingAccuracy: 0,
                    );

                    // Reload markers with the updated position
                    _loadCSV();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Refreshing markers for ${currentCenter.latitude.toStringAsFixed(4)}, ${currentCenter.longitude.toStringAsFixed(4)}')),
                    );
                  },
            tooltip: 'Refresh markers',
            heroTag: 'refreshMarkers',
            child: _isLoadingMarkers
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _isLoadingLocation || _isLoadingMarkers
                ? null
                : _getCurrentLocation,
            tooltip: 'Get current location',
            heroTag: 'getCurrentLocation',
            child: _isLoadingLocation
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class Monument {
  static const double size = 25;

  Monument({
    required this.name,
    required this.lat,
    required this.long,
    required this.id,
    required this.link,
    this.imageUrl,
    this.inscription,
  });

  final String name;
  final Uri link;
  final double lat;
  final double long;
  final int id; //already parsed url
  String? imageUrl; // URL to the marker image
  String? inscription; // Inscription text from the marker
}

class MonumentMarker extends Marker {
  MonumentMarker({required this.monument, required BuildContext context})
      : super(
          alignment: Alignment.topCenter,
          height: Monument.size,
          width: Monument.size,
          point: LatLng(monument.lat, monument.long),
          child: Icon(
            Icons.pin_drop,
            color: Theme.of(context).brightness == Brightness.dark
                //marker color based on mode
                ? const Color.fromARGB(255, 0, 0, 0) // Use amber in dark mode
                : const Color.fromARGB(255, 0, 0, 0), // Use red in light mode
            size: 25,
          ),
        );

  final Monument monument;
}

class MonumentMarkerPopup extends StatelessWidget {
  const MonumentMarkerPopup({super.key, required this.monument});
  final Monument monument;

  void _mapLauncher() {
    String location = '${monument.lat}, ${monument.long}';
    debugPrint('Launching maps with location: $location');
    MapsLauncher.launchQuery(location);
  }

  Future<void> _launchLink() async {
    if (!await launchUrl(monument.link)) {
      throw Exception('Could not launch your link');
    }
  }

/*
* renders the popups for each marker
* the children are displayed on the window/card
*/
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 3.0),
        elevation: 8.0,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            width: 1.0,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color.fromARGB(255, 77, 7, 255).withAlpha(179)
                : const Color.fromARGB(255, 173, 157, 10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Display marker name with larger font
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                monument.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

            // Display marker image if available
            if (monument.imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CachedNetworkImage(
                  imageUrl: monument.imageUrl!,
                  width: 250,
                  height: 150,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),

            // Display inscription if available
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inscription:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monument.inscription ?? 'Loading inscription...',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _mapLauncher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber
                            : Theme.of(context).primaryColor,
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                    side: BorderSide(
                      width: 1.2,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber.shade800
                          : Colors.black,
                    ),
                  ),
                  child: const Icon(Icons.directions),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _launchLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber
                            : Theme.of(context).primaryColor,
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                    side: BorderSide(
                      width: 1.2,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber.shade800
                          : Colors.black,
                    ),
                  ),
                  child: const Icon(Icons.info),
                ),
              ],
            ),
            Text("      "),
          ],
        ),
      ),
    );
  }
}
