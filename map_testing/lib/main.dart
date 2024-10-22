import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
//import 'package:interactive_maps_marker/interactive_maps_marker.dart';

// find a flutter component for a map display

// TODO: add default coords so no red screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Read from CSV test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<List<dynamic>> _data = [];
  List<List<dynamic>> _closeLocations = [];

  Position? _position;

  void _getCurrentLocation() async {
    Position position = await _determinePosition();
    setState(() {
      _position = position;
    });
  }

  // there is some platform specific stuff to pay attention to
  // if i ever deploy to mobile devices: https://pub.dev/packages/geolocator
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

  //  haversine stuff to compare two sets of coords
  static final R = 6372.8; // In kilometers

  static double haversine(double lat1, lon1, lat2, lon2) {
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    lat1 = _toRadians(lat1);
    lat2 = _toRadians(lat2);
    double a =
        pow(sin(dLat / 2), 2) + pow(sin(dLon / 2), 2) * cos(lat1) * cos(lat2);
    double c = 2 * asin(sqrt(a));
    return R * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  //  code to load the info from the CSV file into a list
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

  @override
  Widget build(BuildContext context) {
    for (var i = 0; i < 10; i++) {
      Text('Item $i');
    }

  
    double? my_lat = 30;
    double? my_lon = 40;

    List<Marker> markers = [];

    // asks for location access when the app launches
    if (_closeLocations.isEmpty) {
      _getCurrentLocation();
    }

    // LOCATION COMPARISON BELOW

    // TODO: write a function to take lat/lon from
    // csv and send it to the haversine calculation

    // also write a function that take two coords and compares

    // these are the coords for SAU
    // in the app they would be the current coords of the user

    // double my_lat = 35.04842984003839;
    // double my_lon = -85.05191851568703;

    if (_position != null) {
      my_lat = _position?.latitude;
      my_lon = _position?.longitude;

      for (var element in _data) {
        double lon_2 = element[8];
        double lat_2 = element[7];
        double acceptable_dist = 30.1;
        // distance in Kilometers
        // need to catch the error if there is
        // nothing within the selected distance
        if (haversine(my_lat!, my_lon!, lat_2, lon_2) < acceptable_dist) {
          _closeLocations.add(element);
        }
      }
    }
    int temp = _closeLocations.length;
    print("$temp items in _closeLocations");

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        // title: Text(widget.title),
        title: _position != null
            ? Text('Current location: ' + _position.toString())
            : Text('no location data'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(my_lat!, my_lon!),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              CurrentLocationLayer(),
              MarkerLayer(
                markers: [
                  Marker(
                      // hickman coords
                      // 35.04614904475529, -85.05275917473938
                    point: LatLng(35.04614904475529, -85.05275917473938),
                    width: 80,
                    height: 80,
                    child: FlutterLogo(),
                  )
                ],
              )
            ],
          ),
        ],
      ),
      // body: ListView.builder(
      //   itemCount: _closeLocations.length,
      //   itemBuilder: (_, index) {
      //     return Card(
      //       margin: const EdgeInsets.all(3),
      //       color: index == 0 ? Colors.amber : Colors.white,
      //       child: ListTile(
      //         //leading: Text(_data[index][1].toString()),
      //         // title: Text(_data[index][2]),
      //         // subtitle: Text(_data[index][4]),
      //         // trailing: Text(_data[index][18].toString()),
      //         title: Text(_closeLocations[index][2]),
      //         subtitle: Text(_closeLocations[index][4]),
      //         trailing: Text(_closeLocations[index][18].toString()),
      //       ),
      //     );
      //   },
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadCSV,
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// class LocationPage extends StatefulWidget {
//   const LocationPage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<LocationPage> createState() => _LocationPageState();
// }

// class _LocationPageState extends State<LocationPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Location Page")),
//       body: SafeArea(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text('LAT: '),
//               const Text('LNG: '),
//               const Text('ADDRESS: '),
//               const SizedBox(height: 32),
//               ElevatedButton(
//                 onPressed: () {},
//                 child: const Text("Get Current Location"),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
