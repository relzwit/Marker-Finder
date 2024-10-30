import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Marker with additional data example',
      home: MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final PopupController _popupLayerController = PopupController();
  List<List<dynamic>> _data = [];
  List<List<dynamic>> _closeLocations = [];

  Position? _position;

  void _getCurrentLocation() async {
    Position position = await _determinePosition();
    setState(() {
      _position = position;
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void _loadCSV() async {
    // if (_closeLocations.isEmpty) {
    //   _getCurrentLocation();
    // }
    final _rawData = await rootBundle.loadString("assets/hmdb.csv");
    List<List<dynamic>> _listData =
        const CsvToListConverter().convert(_rawData);
    setState(() {
      _data = _listData;
      _data.removeAt(0); // remove top line of csv
      //_close_locations = _data; // a list for the locations to display
    });
  }

  void _fillCloseLocations() async {
    final R = 6372.8; // In kilometers
    double _toRadians(double degree) {
      return degree * pi / 180;
    }

    double haversine(double lat1, lon1, lat2, lon2) {
      double dLat = _toRadians(lat2 - lat1);
      double dLon = _toRadians(lon2 - lon1);
      lat1 = _toRadians(lat1);
      lat2 = _toRadians(lat2);
      double a =
          pow(sin(dLat / 2), 2) + pow(sin(dLon / 2), 2) * cos(lat1) * cos(lat2);
      double c = 2 * asin(sqrt(a));
      return R * c;
    }

    //  testing for null ensures that the map launches with a valid initial center
    if (_position != null) {
      double my_lat = _position!.latitude;
      double my_lon = _position!.longitude;

      for (var element in _data) {
        double lon_2 = element[8];
        double lat_2 = element[7];
        double acceptable_dist = 30.1;
        // distance in Kilometers
        // need to catch the error if there is
        // nothing within the selected distance
        if (haversine(my_lat!, my_lon!, lat_2, lon_2) < acceptable_dist) {
          _closeLocations.add(element);
          // here i need to add the coordinate of current element to the marker list
        }
      }
    }
  }

// TODO: 1. CREATE A LIST OF MARKER OBJECTS
//       2. INSIDE THE SCAFFOLD, ITERATE THROUGH THE LIST AND DISPLAY THE COORDS AS MARKERS
//       3. MODIFY THE MARKER CONSTRUCTOR TO INCLUDE AN ID
//       4. USE ID TO LINK THE CORRECT IMAGE TO THE POPUP BUILDER

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(30, -85),
          initialZoom: 3.0,
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
          PopupMarkerLayer(
            options: PopupMarkerLayerOptions(
              markers: <Marker>[
                MonumentMarker(
                  monument: Monument(
                    name: 'Graceland Marker',
                    imagePath: 'assets/graceland.jpg',
                    lat: 35.04679,
                    long: -90.02463,
                    id: 6,
                    link: "",
                  ),
                ),
                MonumentMarker(
                  monument: Monument(
                    name: 'Casper Mansker',
                    imagePath: 'assets/casper.jpg',
                    lat: 36.32083,
                    long: -86.71333,
                    id: 5,
                    link: "",
                  ),
                ),
                const Marker(
                  alignment: Alignment.topCenter,
                  point: LatLng(48.859661, 2.305135),
                  height: Monument.size,
                  width: Monument.size,
                  child: Icon(Icons.ad_units),
                ),
              ],
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
    );
  }
}

class Monument {
  static const double size = 25;

  Monument({
    required this.name,
    required this.imagePath,
    required this.lat,
    required this.long,
    required this.id,
    required this.link,
  });

  final String name;
  final String imagePath;
  final String link;
  final double lat;
  final double long;
  final int id;
}

class MonumentMarker extends Marker {
  MonumentMarker({required this.monument})
      : super(
          alignment: Alignment.topCenter,
          height: Monument.size,
          width: Monument.size,
          point: LatLng(monument.lat, monument.long),
          // child: const Icon(Icons.add_circle_sharp),
          child: const Icon(Icons.pin_drop_outlined),
        );

  final Monument monument;
}

class MonumentMarkerPopup extends StatelessWidget {
  const MonumentMarkerPopup({super.key, required this.monument});
  final Monument monument;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.network(monument.imagePath, width: 200),
            Text(monument.name),
            Text('${monument.lat}, ${monument.long}'),
            Text(monument.link),
          ],
        ),
      ),
    );
  }
}
