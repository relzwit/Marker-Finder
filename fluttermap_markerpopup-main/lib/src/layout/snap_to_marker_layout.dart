import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:longpress_popup/src/layout/popup_container_translate.dart';
import 'package:longpress_popup/src/markerdata.dart';

import 'popup_layout.dart';

abstract class SnapToMarkerLayout {
  static PopupLayout left(
      FlutterMapState mapState, MarkerData markerData, bool markerRotate) {
    return PopupLayout(
      contentAlignment: Alignment.centerRight,
      rotationAlignment: Alignment.centerRight,
      transformationMatrix: markerData.marker.rotate ?? markerRotate
          ? PopupContainerTransform.toLeftOfRotatedMarker(mapState, markerData)
          : PopupContainerTransform.toLeftOfMarker(mapState, markerData),
    );
  }

  static PopupLayout top(
      FlutterMapState mapState, MarkerData markerData, bool markerRotate) {
    return PopupLayout(
      contentAlignment: Alignment.bottomCenter,
      rotationAlignment: Alignment.bottomCenter,
      transformationMatrix: markerData.marker.rotate ?? markerRotate
          ? PopupContainerTransform.toTopOfRotatedMarker(mapState, markerData)
          : PopupContainerTransform.toTopOfMarker(mapState, markerData),
    );
  }

  static PopupLayout right(
      FlutterMapState mapState, MarkerData markerData, bool markerRotate) {
    return PopupLayout(
      contentAlignment: Alignment.centerLeft,
      rotationAlignment: Alignment.centerLeft,
      transformationMatrix: markerData.marker.rotate ?? markerRotate
          ? PopupContainerTransform.toRightOfRotatedMarker(mapState, markerData)
          : PopupContainerTransform.toRightOfMarker(mapState, markerData),
    );
  }

  static PopupLayout bottom(
      FlutterMapState mapState, MarkerData markerData, bool markerRotate) {
    return PopupLayout(
      contentAlignment: Alignment.topCenter,
      rotationAlignment: Alignment.topCenter,
      transformationMatrix: markerData.marker.rotate ?? markerRotate
          ? PopupContainerTransform.toBottomOfRotatedMarker(
              mapState, markerData)
          : PopupContainerTransform.toBottomOfMarker(mapState, markerData),
    );
  }

  static PopupLayout center(
      FlutterMapState mapState, MarkerData markerData, bool markerRotate) {
    return PopupLayout(
      contentAlignment: Alignment.center,
      rotationAlignment: Alignment.center,
      transformationMatrix: markerData.marker.rotate ?? markerRotate
          ? PopupContainerTransform.toCenterOfRotatedMarker(
              mapState, markerData)
          : PopupContainerTransform.toCenterOfMarker(mapState, markerData),
    );
  }
}
