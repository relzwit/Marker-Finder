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

// //TODO:       1. marker clustering
// //TODO:       4. USE ID TO LINK THE CORRECT IMAGE TO THE POPUP BUILDER
// //TODO:       5. look into error page for fluttermap
// //TODO:       6. swap to flutter_map_cancellable_tile_provider?
// //TODO:       7. add gamification (points, levels)
// //TODO:       8. make it more fun (animations and so on, confetti?)
// //TODO:       9. make links clickable in the popup box
// //TODO:      10. web scraping to get proper imgs and descriptions
