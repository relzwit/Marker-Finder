import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

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

  final MapController mapController = MapController();
  final PopupController _popupLayerController = PopupController();

  // ? raw csv lines i think
  List<List<dynamic>> _data = [];

  // list of locations within the specified radius
  List<List<dynamic>> _closeLocations = [];

  // this will be filled with the marker objects for the markers listed in _closeLocations
  final List<Marker> _marker_obj_list = [
    MonumentMarker(
        // adds the marker to the marker obj list
        monument: Monument(
      name: "De Soto's Route",
      imagePath: 'assets/imgs/de_soto.jpg', // default image
      lat: 35.11303,
      long: -84.98160,
      id: 1,
      link: Uri.parse("https://www.google.com"),
      // erectedBy: element[8],
      // location: element[16],
    )),
    MonumentMarker(
        // adds the marker to the marker obj list
        monument: Monument(
      name: "Joseph Vann's town",
      imagePath: 'assets/imgs/an_elephant.jpg', // default image
      lat: 35.14543,
      long: -85.11205,
      id: 1,
      link: Uri.parse("https://www.google.com"),
      // erectedBy: element[8],
      // location: element[16],
    )),
    MonumentMarker(
        // adds the marker to the marker obj list
        monument: Monument(
      name: "Old Harrison",
      imagePath: 'assets/imgs/an_elephant.jpg', // default image
      lat: 35.13835,
      long: -85.12158,
      id: 1,
      link: Uri.parse("https://www.google.com"),
      // erectedBy: element[8],
      // location: element[16],
    )),
    MonumentMarker(
        // adds the marker to the marker obj list
        monument: Monument(
      name: "Harrison Academy",
      imagePath: 'assets/imgs/an_elephant.jpg', // default image
      lat: 35.10985,
      long: -85.14068,
      id: 1,
      link: Uri.parse("https://www.google.com"),
      // erectedBy: element[8],
      // location: element[16],
    )),
    MonumentMarker(
        // adds the marker to the marker obj list
        monument: Monument(
      name: "Order of the Southern Cross",
      imagePath: 'assets/imgs/an_elephant.jpg', // default image
      lat: 36.11528,
      long: -86.80757,
      id: 1,
      link: Uri.parse("https://www.google.com"),
      // erectedBy: element[8],
      // location: element[16],
    )),
    MonumentMarker(
        // adds the marker to the marker obj list
        monument: Monument(
      name: "County of James",
      imagePath: 'assets/imgs/an_elephant.jpg', // default image
      lat: 35.07168,
      long: -85.06032,
      id: 1,
      link: Uri.parse("https://www.google.com"),
      // erectedBy: element[8],
      // location: element[16],
    )),
    MonumentMarker(
        // adds the marker to the marker obj list
        monument: Monument(
      name: "Kenneth A. Wright Hall",
      imagePath: 'assets/imgs/an_elephant.jpg', // default image
      lat: 35.04817,
      long: -85.05184,
      id: 1,
      link: Uri.parse("https://www.google.com"),
      // erectedBy: element[8],
      // location: element[16],
    ))
  ];

  Position? _position;

  void _getCurrentLocation() async {
    Position position = await _determinePosition();

    setState(() {
      _position = position;
      // _fillCloseLocations();
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

//TODO:       1. marker clustering
//TODO:       2. fix bug where button needs to be doubleclicked
//TODO:       4. USE ID TO LINK THE CORRECT IMAGE TO THE POPUP BUILDER
//TODO:       5. look into error page for fluttermap
//TODO:       6. swap to flutter_map_cancellable_tile_provider?
//TODO:       7. add gamification (points, levels)
//TODO:       8. make it more fun (animations and so on, confetti?)
//TODO:       9. make links clickable in the popup box
//TODO:      10. web scraping to get proper imgs and descriptions

  void _buttonClickedFunction() {
    // _fillCloseLocations();
    int len_of_list = _closeLocations.length;
    print("_closeLocations list size is:  $len_of_list");
    setState(() {
      // _fillCloseLocations();
      // int len_of_list = _closeLocations.length;
      // print("_closeLocations list size is:  $len_of_list");
    }); // tells flutter to schedule a rebuild after the button click stuff finishes
  }

  void _testMapLaunch() {
    // MapsLauncher.launchQuery('1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA');
    MapsLauncher.launchQuery('16, 35');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(0, 53, 53, 205),
      // body: _pages[_selectedIndex]
      body: FlutterMap(
        options: MapOptions(
          initialCenter:
              const LatLng(35.045967, -85.052979), //good initial center
          initialZoom: 11.0,
          maxZoom: 40,
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
          Text(
            "Marker Mapper",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          PopupMarkerLayer(
            options: PopupMarkerLayerOptions(
              markers: _marker_obj_list,
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
  final Uri link;
  final double lat;
  final double long;
  final int id; //already parsed url
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

  void _mapLauncher() {
    String location = monument.lat.toString() + ', ' + monument.long.toString();
    print(location);
    // MapsLauncher.launchQuery('1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA');
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
        margin: EdgeInsets.symmetric(vertical: 3.0, horizontal: 3.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            width: 1.0,
            color: const Color.fromARGB(255, 64, 58, 2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.network(monument.imagePath),
            // , width: 200
            Text(monument.name),
            Text("      "),
            Row(children: <Widget>[
              Text(" "),
              Flexible(
                child: Text(
                    "Inscription: From Canasoga, near Wetmore, to Chiaha, near South Pittsburg. De Soto's expedition of 1540 followed the Great War and Trading Path, which ran from northeast to southwest, passing near this spot."),
              ),
              // Text(" "),
              // Text("Inscription: Lorem ipsum dolor sit Lorem ipsum dolor sit "),
              // Text(" "),
            ]),
            Text("      "),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _mapLauncher,
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(
                      width: 1.2,
                      color: Colors.black,
                    ),
                  ),
                  child: const Icon(Icons.directions),
                ),
                Text(" "),
                ElevatedButton(
                  onPressed: _launchLink,
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(
                      width: 1.2,
                      color: Colors.black,
                    ),
                  ),
                  child: Icon(Icons.info),
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
