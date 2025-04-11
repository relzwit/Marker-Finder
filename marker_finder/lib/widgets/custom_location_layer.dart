import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/settings_service.dart';

class CustomLocationLayer extends StatefulWidget {
  final MapController? mapController;

  const CustomLocationLayer({super.key, this.mapController});

  @override
  State<CustomLocationLayer> createState() => _CustomLocationLayerState();
}

class _CustomLocationLayerState extends State<CustomLocationLayer> {
  double _currentRadius = 20.0; // Default radius in km
  StreamSubscription<double>? _radiusSubscription;
  // We'll use the map controller from the widget

  // Calculate opacity based on zoom level
  int _calculateOpacityForZoom(double zoom) {
    // At low zoom levels (zoomed out), show full opacity
    if (zoom < 8) return 77; // ~30% opacity

    // At medium zoom levels, reduce opacity
    if (zoom < 12) return 51; // ~20% opacity

    // At high zoom levels (zoomed in), make very transparent
    if (zoom < 15) return 26; // ~10% opacity

    // At very high zoom levels, almost invisible
    return 13; // ~5% opacity
  }

  @override
  void initState() {
    super.initState();
    _loadRadius();

    // Listen to the radius stream from SettingsService
    _radiusSubscription = SettingsService.radiusStream.listen((radius) {
      if (mounted && radius != _currentRadius) {
        setState(() {
          _currentRadius = radius;
        });
        debugPrint('CustomLocationLayer: Radius updated from stream to $radius km');
      }
    });
  }

  @override
  void dispose() {
    _radiusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRadius() async {
    final radius = await SettingsService.getSearchRadius();
    if (radius != _currentRadius) {
      setState(() {
        _currentRadius = radius;
      });
      debugPrint('CustomLocationLayer: Initial radius loaded: $radius km');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a custom layer stack to show both the location marker and a custom accuracy circle
    return Stack(
      children: [
        // Custom accuracy circle layer with zoom-dependent opacity
        StreamBuilder<Position?>(
          stream: Geolocator.getPositionStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }

            final position = snapshot.data!;
            final latLng = LatLng(position.latitude, position.longitude);

            // Get current zoom level from the map controller if available
            double zoom = 7.0; // Default zoom level
            if (widget.mapController != null) {
              try {
                zoom = widget.mapController!.camera.zoom;
              } catch (e) {
                // If there's an error accessing the zoom level, use the default
                debugPrint('Error accessing map zoom: $e');
              }
            }

            // Calculate opacity based on zoom level
            final opacity = _calculateOpacityForZoom(zoom);

            return CircleLayer(
              circles: [
                CircleMarker(
                  point: latLng,
                  radius: _currentRadius * 1000, // Convert km to meters
                  color: Colors.blue.withAlpha(opacity),
                  useRadiusInMeter: true,
                ),
              ],
            );
          },
        ),

        // Standard location marker layer
        CurrentLocationLayer(
          style: LocationMarkerStyle(
            marker: DefaultLocationMarker(
              color: Colors.blue,
              child: const Icon(
                Icons.navigation,
                color: Colors.white,
                size: 20,
              ),
            ),
            markerSize: const Size(25, 25),
            markerDirection: MarkerDirection.heading,
            // Don't show the built-in accuracy circle since we're using our own
            showAccuracyCircle: false,
          ),
        ),
      ],
    );
  }
}
