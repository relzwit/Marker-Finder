import 'package:longpress_popup_example/example_popup_with_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:longpress_popup/fluttermap_markerpopup.dart';
import 'package:latlong2/latlong.dart';

import 'example_popup.dart';

class SimpleMapWithPopups extends StatelessWidget {
  final List<LatLng> _markerPositions = [
    LatLng(44.421, 10.404),
    LatLng(45.683, 10.839),
    LatLng(45.246, 5.783),
  ];

  /// Used to trigger showing/hiding of popups.
  final PopupController _popupLayerController = PopupController();

  SimpleMapWithPopups({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        zoom: 5.0,
        center: LatLng(44.421, 10.404),
        onTap: (_, __) => _popupLayerController
            .hideAllPopups(), // Hide popup when the map is tapped.
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            popupController: _popupLayerController,
            markersData: _markers,
            markerRotateAlignment:
                PopupMarkerLayerOptions.rotationAlignmentFor(AnchorAlign.top),
            popupBuilder: (BuildContext context, MarkerData marker) =>
                ExamplePopup(marker),
          ),
        ),
      ],
    );
  }

  List<MarkerData> get _markers => _markerPositions
      .map((markerPosition) => DataMarker(
            Marker(
              point: markerPosition,
              width: 40,
              height: 40,
              builder: (_) => const Icon(Icons.location_on, size: 40),
              anchorPos: AnchorPos.align(AnchorAlign.top),
            ),
          ))
      .toList();
}
