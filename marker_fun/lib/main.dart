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
// //TODO:       7. add gamification (points, levels)
// //TODO:       8. make it more fun (animations and so on, confetti?)
// //TODO:      10. web scraping to get proper descriptions
