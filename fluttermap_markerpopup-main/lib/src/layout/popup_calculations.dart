import 'package:flutter_map/plugin_api.dart';
import 'package:longpress_popup/src/markerdata.dart';

import 'oval_bounds.dart';

abstract class PopupCalculations {
  /// The X offset to the center of the marker from the marker's point.
  static double centerOffsetX(MarkerData marker) {
    return -(marker.marker.width / 2 - marker.marker.width);
  }

  /// The X offset to the left edge of the marker from the marker's point.
  static double leftOffsetX(MarkerData marker) {
    return -(marker.marker.width - marker.marker.width);
  }

  /// The X offset to the right edge of the marker from the marker's point.
  static double rightOffsetX(MarkerData marker) {
    return marker.marker.width;
  }

  /// The Y offset to the center of the marker from the marker's point.
  static double centerOffsetY(MarkerData marker) {
    return -(marker.marker.height / 2 - marker.marker.height);
  }

  /// The Y offset to the top edge of the marker from the marker's point.
  static double topOffsetY(MarkerData marker) {
    return -(marker.marker.height - marker.marker.height);
  }

  /// The Y offset to the bottom edge of the marker from the marker's point.
  static double bottomOffsetY(MarkerData marker) {
    return marker.marker.height;
  }

  /// The distance from the [marker] center to the horizontal bounds at a given
  /// rotation.
  static double boundXAtRotation(MarkerData marker, double radians) {
    return OvalBounds.boundX(
        marker.marker.width, marker.marker.height, radians);
  }

  /// The distance from the [marker] center to the vertical bounds at a given
  /// rotation.
  static double boundYAtRotation(MarkerData marker, double radians) {
    return OvalBounds.boundY(
        marker.marker.width, marker.marker.height, radians);
  }

  static double mapLeftToPointX(
      FlutterMapState mapState, CustomPoint<num> point) {
    return point.x.toDouble();
  }

  static double mapRightToPointX(
      FlutterMapState mapState, CustomPoint<num> point) {
    return -(mapState.size.x - point.x).toDouble();
  }

  static double mapCenterToPointX(
      FlutterMapState mapState, CustomPoint<num> point) {
    return -(mapState.size.x / 2 - point.x).toDouble();
  }

  static double mapTopToPointY(
      FlutterMapState mapState, CustomPoint<num> point) {
    return point.y.toDouble();
  }

  static double mapBottomToPointY(
      FlutterMapState mapState, CustomPoint<num> point) {
    return -(mapState.size.y - point.y).toDouble();
  }

  static double mapCenterToPointY(
      FlutterMapState mapState, CustomPoint<num> point) {
    return -(mapState.size.y / 2 - point.y).toDouble();
  }
}
