import 'package:csv_testing/variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:csv/csv.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  @override
  void initState() {
    super.initState();
    _loadCSV();
  }

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
      // my_current_latitude = _position!.latitude;
      // my_current_longitude = _position!.longitude;
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
    // final _rawData = await rootBundle.loadString("assets/hmdb.csv");
    final _rawData = await rootBundle.loadString("assets/mycsv.csv");
    List<List<dynamic>> _listData =
        const CsvToListConverter().convert(_rawData);
    print("csv list len $_data.length");

    setState(() {
      _data = _listData;
      _data.removeAt(0); // remove top line of csv
    });
  }

  void _fillCloseLocations() async {
    //  testing for null ensures that the map launches with a valid initial center
    // double my_lat = _position!.latitude;
    // double my_lon = _position!.longitude;

    double my_lat = 35.048816306111476;
    double my_lon = -85.0503950213476;

    for (var element in _data) {
      double lon_2 = element[8];
      double lat_2 = element[7];
      double acceptable_dist = 30000.1;
      // distance in Kilometers
      // need to catch the error if there is
      // nothing within the selected distance
      if (Geolocator.distanceBetween(my_lat, my_lon, lat_2, lon_2) <
          acceptable_dist) {
        _closeLocations.add(element);
        _marker_obj_list.add(MonumentMarker(
            // adds the marker to the marker obj list
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
    setState(() {
      // if (_data.length < 1) {
      //   print("data empty; csv loading");
      //   _loadCSV();
      //   print("data empty; csv loaded");
      // }

      if (_closeLocations.length < 1) {
        print("locations empty; filtering");
        _fillCloseLocations();
        print("locations empty; filtered");
      }
      int len_of_list = _closeLocations.length;
      print("_closeLocations list size is:  $len_of_list");
    }); // tells flutter to schedule a rebuild after the button click stuff finishes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
