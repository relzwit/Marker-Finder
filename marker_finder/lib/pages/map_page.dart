import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
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
import 'profile_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  void initState() {
    super.initState();
    // _loadCSV();
    _getCurrentLocation();
  }

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(MapPage());
  }

  final MapController mapController = MapController();
  final PopupController _popupLayerController = PopupController();
  String _selectedCSV = "assets/CSVs/hmdb_usa_tn.csv";

  // Raw CSV data
  List<List<dynamic>> _data = [];

  // List of locations within the specified radius
  final List<List<dynamic>> _closeLocations = [];

  // List of marker objects for the markers listed in _closeLocations
  final List<Marker> _markerObjList = [];

  Position? _position;

  // Flag to track if location is being fetched
  bool _isLoadingLocation = false;

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
    final rawData = await rootBundle.loadString(_selectedCSV);
    // final rawData = await rootBundle.loadString("assets/CSVs/hmdb_usa_tn.csv");
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
    setState(() {
      _data = listData;
      _data.removeAt(0); // remove top line of csv
      _fillCloseLocations();
    });
  }

  void _fillCloseLocations() async {
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
    double acceptableDist = 20000; // 20km radius

    for (var element in _data) {
      try {
        double lon = element[8];
        double lat = element[7];
        String markerName = element[2];
        int markerId = element[0];
        String markerLink = element[16];

        // Check if marker is within acceptable distance
        if (Geolocator.distanceBetween(myLat, myLon, lat, lon) <
            acceptableDist) {
          _closeLocations.add(element);

          // Create monument object
          Monument monument = Monument(
            name: markerName,
            lat: lat,
            long: lon,
            id: markerId,
            link: Uri.parse(markerLink),
          );

          // Fetch marker data from HMDB website
          _fetchMarkerData(monument);

          // Add marker to the list
          _markerObjList
              .add(MonumentMarker(monument: monument, context: context));
        }
      } catch (e) {
        // Skip invalid entries - silently handle errors
        // We don't want to interrupt the user experience with error messages for individual markers
        debugPrint('Error processing marker: $e');
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

  // Navigate to the selected page
  void _navigateBottomBar(int index) {
    if (index == 1) {
      // Navigate to profile page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
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
          DropdownMenu(
            enableFilter: true,
            label: const Text("Select a region"),
            onSelected: (region) {
              setState(() {
                _selectedCSV = "assets/CSVs/$region";
                _loadCSV();
              });
            },
            dropdownMenuEntries: <DropdownMenuEntry>[
              DropdownMenuEntry(value: "hmdb_usa_tn.csv", label: 'Tennessee'),
              DropdownMenuEntry(value: "hmdb_usa_ga.csv", label: 'Georgia'),
              DropdownMenuEntry(value: "hmdb_usa_ala.csv", label: 'Alabama'),
              DropdownMenuEntry(value: "hmdb_ger.csv", label: 'Germany'),
              DropdownMenuEntry(value: "hmdb_eng.csv", label: 'England'),
            ],
          )
        ],
      ),
      backgroundColor: Color.fromARGB(0, 53, 53, 205),
      // body: _pages[_selectedIndex]
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(35, -85), //good initial center
          initialZoom: 7.0,
          maxZoom: 30,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
          onTap: (_, __) => _popupLayerController.hideAllPopups(),
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          CurrentLocationLayer(),
          // Use MarkerClusterLayerWidget for better performance with many markers
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              markers: _markerObjList,
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.blue.withAlpha(179),
                  ),
                  child: Center(
                    child: Text(
                      markers.length.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        tooltip: 'Refresh location',
        child: _isLoadingLocation
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.my_location),
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
