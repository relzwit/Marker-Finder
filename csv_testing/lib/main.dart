import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

//coordinates for SAU: 35.04842984003839, -85.05191851568703

void main() {
  runApp(const MyApp());
}

// //uses the haversine formula to check distance between two coords
// //-------------------------------------------------------------
// class Haversine {
//   static final R = 6372.8; // In kilometers

//   static double haversine(double lat1, lon1, lat2, lon2) {
//     double dLat = _toRadians(lat2 - lat1);
//     double dLon = _toRadians(lon2 - lon1);
//     lat1 = _toRadians(lat1);
//     lat2 = _toRadians(lat2);
//     double a =
//         pow(sin(dLat / 2), 2) + pow(sin(dLon / 2), 2) * cos(lat1) * cos(lat2);
//     double c = 2 * asin(sqrt(a));
//     return R * c;
//   }

//   static double _toRadians(double degree) {
//     return degree * pi / 180;
//   }

//   static void main() {
//     print(haversine(36.12, -86.67, 33.94, -118.40));
//   }
// }
// //-------------------------------------------------------------

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

  void _loadCSV() async {
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
    _loadCSV();

    // LOCATION COMPARISON BELOW

    // TODO: write a function to take lat/lon from
    // csv and send it to the haversine calculation

    // also write a function that take two coords and compares

    // these are the coords for SAU
    // in the app they would be the current coords of the user
    double my_lat = 35.04842984003839;
    double my_lon = -85.05191851568703;

    for (var element in _data) {
      double lon_2 = element[8];
      double lat_2 = element[7];
      double acceptable_dist = 30.1; // distance in Kilometers
      // need to catch the error if there is nothing within the selected distance
      if (haversine(my_lat, my_lon, lat_2, lon_2) < acceptable_dist) {
        _closeLocations.add(element); // cause of error here?
        // int temp = _closeLocations.length;
        // print("$temp items in _closeLocations");
      }

      dynamic temp1 = [];

      if (_closeLocations.length > 0) {
        temp1 = _closeLocations.last;
      }
      //print("$temp items in _closeLocations \n $temp1 is last elem");
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _closeLocations.length,
        itemBuilder: (_, index) {
          return Card(
            margin: const EdgeInsets.all(3),
            color: index == 0 ? Colors.amber : Colors.white,
            child: ListTile(
              //leading: Text(_data[index][1].toString()),
              // title: Text(_data[index][2]),
              // subtitle: Text(_data[index][4]),
              // trailing: Text(_data[index][18].toString()),
              title: Text(_closeLocations[index][2]),
              subtitle: Text(_closeLocations[index][4]),
              trailing: Text(_closeLocations[index][18].toString()),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadCSV,
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
