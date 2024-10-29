import 'package:flutter/widgets.dart';
import 'package:longpress_popup/fluttermap_markerpopup.dart';

/// This allows a popup instance to maintain state until it is closed, even when
/// it goes off screen.
class MarkerWithKey {
  final Key key;
  final MarkerData marker;

  MarkerWithKey(this.marker) : key = GlobalKey();

  static MarkerWithKey wrap(MarkerData marker) => MarkerWithKey(marker);

  static MarkerData unwrap(MarkerWithKey markerWithKey) => markerWithKey.marker;

  @override
  bool operator ==(Object other) =>
      other is MarkerWithKey && marker == other.marker;

  @override
  int get hashCode => marker.hashCode;
}
