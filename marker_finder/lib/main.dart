import 'package:flutter/material.dart';
import 'pages/map_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //was const type
      title: 'Historical Marker finder',
      theme: ThemeData(
        colorSchemeSeed: Colors.amber,
        useMaterial3: true,
      ),
      home: MapPage(),
    );
  }
}

// initial attempts at proper routing
// class MapPage extends StatelessWidget {
//   const MapPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Marker Finder'),
//       ),
//       body: const Center(
//         child: Text('Map Page'),
//       ),
//     );
//   }
// }
