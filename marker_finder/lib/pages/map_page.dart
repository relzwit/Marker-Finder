import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:csv/csv.dart';
// import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:flutter/src/material/theme_data.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

// class ProfilePage extends StatefulWidget{
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() =>
// }

class _MapPageState extends State<MapPage> {
  @override
  void initState() {
    super.initState();
    _loadCSV();
    _getCurrentLocation();
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
      _fillCloseLocations();
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
    final _rawData = await rootBundle.loadString("assets/hmdb.csv");
    List<List<dynamic>> _listData =
        const CsvToListConverter().convert(_rawData);
    int lengthss = _listData.length;
    print("csv data list is len $lengthss");

    setState(() {
      _data = _listData;
      _data.removeAt(0); // remove top line of csv
    });
  }

  void _fillCloseLocations() async {
    print("---close loces fill entered---");

    double my_lat = _position!.latitude;
    double my_lon = _position!.longitude;

    for (var element in _data) {
      double lon_2 = element[8];
      double lat_2 = element[7];
      double acceptable_dist = 13000.1;

      // String erect = element[8];
      // String local = element[16];
      //wrong indeces

      // print("ererct: $erect");
      // print("location is: $local");
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
          //imagePath: 'assets/imgs/an_elephant.jpg', // default image
          imagePath: Image.network(
              'https://www.hmdb.org/Photos7/703/Photo703003o.jpg?129202350700PM'),
          lat: element[7],
          long: element[8],
          id: element[0],
          link: Uri.parse(element[16]),
          // erectedBy: element[8],
          // location: element[16],
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
    _fillCloseLocations();
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

  // void _navigateBottomBar(int index){
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  // final List<Widget> _pages = [
  //   SecondPage(),
  // ];

  // int _selectedIndex = 0;
  // final screens = [
  //   MapPage(),
  //   // SecondPage(),
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _getCurrentLocation,
      //   child: const Text("update location"),
      //   // child: const Icon(Icons.location_disabled),
      // ),
      //
      // this method can include multiple floating action buttons:
      // floatingActionButton:
      //     Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      //   FloatingActionButton(
      //     child: Icon(Icons.location_city),
      //     onPressed: _buttonClickedFunction,
      //     heroTag: null,
      //   ),
      //   SizedBox(
      //     height: 10,
      //   ),
      //   FloatingActionButton(
      //     child: Icon(Icons.map),
      //     onPressed: _testMapLaunch,
      //     heroTag: null,
      //   )
      // ]),
      bottomNavigationBar: BottomNavigationBar(
        // currentIndex: _selectedIndex,
        // onTap: _navigateBottomBar,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Map',
            // selectedIndex: index,
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
    required this.imagePath,
    required this.lat,
    required this.long,
    required this.id,
    required this.link,
  });

  final String name;
  final Widget imagePath;
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
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Image.network(monument.imagePath, width: 200),
            Text(monument.name),
            Text(
                "Inscription: Lorem ipsum dolor sit ametLorem ipsum dolor sit ametLorem ipsum dolor sit ametLorem ipsum dolor sit amet"),
            ElevatedButton(
              onPressed: _mapLauncher,
              child: const Icon(Icons.directions),
            ),
            SizedBox(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _launchLink,
                  child: Icon(Icons.help),
            ),
              ],
            ),
            
          ],
        ),
      ),
    );
  }
}
