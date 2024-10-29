# `longpress_popup`

[![pub.dev](https://img.shields.io/pub/v/longpress_popup.svg)](https://pub.dev/packages/longpress_popup)
[![GitHub stars](https://img.shields.io/github/stars/ymrabti/fluttermap_markerpopup?style=social)](https://github.com/ymrabti/fluttermap_markerpopup/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ymrabti/fluttermap_markerpopup?style=social)](https://github.com/ymrabti/fluttermap_markerpopup/network)

Flutter Map Custom Marker Popups is an extension for the popular Flutter Map package. It allows you to create custom markers that, when long-pressed, open customizable popups containing additional data associated with the marker. This package enhances the interactivity and visual appeal of maps in your Flutter applications.

## Features

- **Customizable Markers**: Create custom markers with images, icons, or other widgets.
- **Interactive Popups**: Popups open on long-press and can contain rich data.
- **Data Integration**: Associate custom data with each marker and display it in the popup.
- **Styling Options**: Customize marker and popup appearance to match your app's design.
- **Easy Integration**: Seamlessly integrate with Flutter Map for powerful map displays.

## Installation

To use this package, add `longpress_popup` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  longpress_popup: ^1.0.0
```

If you have any suggestions/problems please don't hesitate to open an issue.

## Getting Started

For a minimal code example have a look at [SimpleMapWithPopups](https://github.com/ymrabti/fluttermap_markerpopup/blob/master/example/lib/simple_map_with_popups.dart).
## Usage

Import the package:
```dart
import 'package:flutter_map_custom_marker_popups/flutter_map_custom_marker_popups.dart';

```
Create a `FlutterMap` widget and add a `MarkerLayer`:


```dart
FlutterMap(
  options: MapOptions(
    // set your map options here
  ),
  layers: [
    TileLayerOptions(
      // set your tile layer options here
    ),
    MarkerLayer(
      markers: [
        CustomMarker(
          // Customize your marker here
          point: LatLng(51.5, -0.09), // Marker position
          builder: (BuildContext context) {
            return MarkerWidget(); // Your custom marker widget
          },
          popupBuilder: (BuildContext context, CustomMarker marker) {
            return MyCustomPopup(marker.data); // Your custom popup widget
          },
          data: MyMarkerData(/* Your data here */),
        ),
        // Add more markers as needed
      ],
    ),
  ],
)

```

For a complete example which demonstrates all of the various options available try running the demo app in the `example/` directory which results in the following:

![Example](https://raw.githubusercontent.com/ymrabti/fluttermap_markerpopup/main/demo.gif)

## FAQ

* Why is the popup not showing when I long press the marker?

  Make sure you don't have a GestureDetector in your Marker's builder which is preventing this plugin from detecting the Marker long press.

"# longpress_popup"

## Contributing
Contributions to this package are welcome! Feel free to open issues or pull requests to suggest improvements or report bugs.

## License
This project is licensed under the MIT License - see the [LICENSE.md](/LICENSE) file for details.
## Author
- **YOUNES MRABTI**
- GitHub: [ymrabti](https://github.com/ymrabti)
- E-Mail [mr.younes@youmrabti.com](mailto:mr.younes@youmrabti.com)

## Acknowledgments
- Mention any contributors or libraries used in this package.
- Provide links to relevant resources or tutorials.


Please make sure to customize this Markdown text with your specific package details and replace placeholders accordingly.
