import 'package:flutter/cupertino.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:longpress_popup/src/marker_tap_behavior.dart';
import 'package:longpress_popup/src/markerdata.dart';
import 'package:longpress_popup/src/popup_animation.dart';
import 'package:longpress_popup/src/popup_builder.dart';
import 'package:longpress_popup/src/popup_controller.dart';
import 'package:longpress_popup/src/popup_snap.dart';

import 'marker_center_animation.dart';
import 'popup_event.dart';

class PopupMarkerLayerOptions extends MarkerLayer {
  /// Used to construct the popup.
  final PopupBuilder popupBuilder;
  final Function(MarkerData)? onTap;

  /// If a PopupController is provided it can be used to programmatically show
  /// and hide the popup.
  final PopupController? popupController;

  /// Controls the position of the popup relative to the marker or popup.
  final PopupSnap popupSnap;

  /// Allows the use of an animation for showing/hiding popups. Defaults to no
  /// animation.
  final PopupAnimation? popupAnimation;

  /// Setting a [MarkerCenterAnimation] will cause the map to be centered on
  /// a marker when it is tapped. Defaults to not centering on the marker.
  final MarkerCenterAnimation? markerCenterAnimation;

  final MarkerLongPressBehavior markerLongPressBehavior;

  final Function(PopupEvent event, List<MarkerData> selectedMarkers)?
      onPopupEvent;

  final List<MarkerData> markersData;
  PopupMarkerLayerOptions({
    required this.popupBuilder,
    AlignmentGeometry? markerRotateAlignment,
    MarkerLongPressBehavior? markerLongPressBehavior,
    Offset? markerRotateOrigin,
    bool? markerRotate = true,
    Stream<void>? rebuild,
    this.popupSnap = PopupSnap.markerTop,
    this.markerCenterAnimation,
    this.popupController,
    this.popupAnimation,
    required this.markersData,
    this.onPopupEvent,
    this.onTap,
  })  : markerLongPressBehavior = markerLongPressBehavior ??
            MarkerLongPressBehavior.togglePopupAndHideRest(),
        super(
          markers: markersData.map((e) => e.marker).toList(),
          rotate: markerRotate ?? false,
          rotateAlignment: markerRotateAlignment,
          rotateOrigin: markerRotateOrigin,
        );

  static AlignmentGeometry rotationAlignmentFor(AnchorAlign anchorAlign) {
    switch (anchorAlign) {
      case AnchorAlign.left:
        return Alignment.centerRight;
      case AnchorAlign.top:
        return Alignment.bottomCenter;
      case AnchorAlign.right:
        return Alignment.centerLeft;
      case AnchorAlign.bottom:
        return Alignment.topCenter;
      case AnchorAlign.topLeft:
        return Alignment.bottomRight;
      case AnchorAlign.topRight:
        return Alignment.bottomLeft;
      case AnchorAlign.bottomLeft:
        return Alignment.topRight;
      case AnchorAlign.bottomRight:
        return Alignment.topLeft;
      case AnchorAlign.center:
      default:
        return Alignment.center;
    }
  }
}
