import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/map_page.dart';
import 'services/theme_provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode from the provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Historical Marker finder',
      theme: ThemeData(
        colorSchemeSeed: Colors.amber,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.amber,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: themeProvider.themeMode,
      home: const MapPage(),
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
