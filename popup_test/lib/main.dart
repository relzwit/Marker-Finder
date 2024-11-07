import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:csv/csv.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

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
  final MapController mapController = MapController();
  final PopupController _popupLayerController = PopupController();

  // ? raw csv lines i think
  List<List<dynamic>> _data = [];

  // list of locations within the specified radius
  List<List<dynamic>> _closeLocations = [];

  // this will be filled with the marker objects for the markers listed in _closeLocations
  List<Marker> _marker_obj_list = [];

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

  // int _haversine() {}

  void _loadCSV() async {
    final _rawData = await rootBundle.loadString("assets/hmdb.csv");
    List<List<dynamic>> _listData =
        const CsvToListConverter().convert(_rawData);
    setState(() {
      _data = _listData;
      _data.removeAt(0); // remove top line of csv
    });
  }

  void _fillCloseLocations() async {
    //TODO: convert to geolocator coord comparisons
    final rando_coords = LatLng(45, 67);
    // mapController.move(rando_coords, 7); // hopefully updating map after render

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

    if (_closeLocations.isEmpty) {
      //  testing for null ensures that the map launches with a valid initial center
      if (_position != null) {
        double my_lat = _position!.latitude;
        double my_lon = _position!.longitude;
        //TODO: there is a bracket missing somewhere
        //TODO: need to set default location then change on_click maybe

        for (var element in _data) {
          double lon_2 = element[8];
          double lat_2 = element[7];
          double acceptable_dist = 30.1;
          // distance in Kilometers
          // need to catch the error if there is
          // nothing within the selected distance
          if (haversine(my_lat, my_lon, lat_2, lon_2) < acceptable_dist) {
            _closeLocations.add(element);

            // adds each marker to a list as a monument obj
            _marker_obj_list.add(MonumentMarker(
                monument: Monument(
              name: element[2],
              imagePath: 'assets/imgs/an_elephant.jpg', // default image
              lat: element[7],
              long: element[8],
              id: element[0],
              link: element[16],
            )));
          }
        }
      }
    } else {
      print("_closeLocations is already filled");
    }

    int len_of_list = _closeLocations.length;
    print("_closeLocations list size is:  $len_of_list");
  }

//TODO:       1. populate _closeLocations list
//TODO:       2. loop through _closeLocations and add data as a Monument object to _marker_obj_list
//TODO:       3. streamline Haversine
//TODO:       4. USE ID TO LINK THE CORRECT IMAGE TO THE POPUP BUILDER
//TODO:       5. look into error page for fluttermap
//TODO:       6. swap to flutter_map_cancellable_tile_provider?

  void _buttonClickedFunction() {
    if (_data.isEmpty) {
      _loadCSV();
    }
    if (_closeLocations.isEmpty) {
      _fillCloseLocations();
    }

    setState(
        () {}); // tells flutter to schedule a rebuild after the button click stuff finishes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(30, -85),
          initialZoom: 3.0,
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
          PopupMarkerLayer(
            options: PopupMarkerLayerOptions(
              markers: _marker_obj_list,
              // markers: <Marker>[
              //   MonumentMarker(
              //     monument: Monument(
              //       name: 'Graceland Marker',
              //       imagePath: 'assets/imgs/graceland.jpg',
              //       lat: 35.04679,
              //       long: -90.02463,
              //       id: 6,
              //       link: "",
              //     ),
              //   ),
              //   MonumentMarker(
              //     monument: Monument(
              //       name: 'Casper Mansker',
              //       imagePath: 'assets/imgs/casper.jpg',
              //       lat: 36.32083,
              //       long: -86.71333,
              //       id: 5,
              //       link: "",
              //     ),
              //   ),
              //   const Marker(
              //     alignment: Alignment.topCenter,
              //     point: LatLng(48.859661, 2.305135),
              //     height: Monument.size,
              //     width: Monument.size,
              //     child: Icon(Icons.ad_units),
              //   ),
              // ],
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
        onPressed: _buttonClickedFunction,
        child: const Icon(Icons.location_disabled),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

// class mapController {
//   _marker_obj_list.add(MonumentMarker(
//               monument: Monument(
//             name: element[2],
//             imagePath: 'assets/imgs/an_elephant.jpg', // default image
//             lat: element[7],
//             long: element[8],
//             id: element[0],
//             link: element[16],
//           )));
// }

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

/*
* renders the popups for each marker
* the children are displayed on the window/card
*/
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
