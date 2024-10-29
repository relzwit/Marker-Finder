import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:longpress_popup/fluttermap_markerpopup.dart';
import 'package:longpress_popup/src/layout/popup_layout.dart';
import 'package:longpress_popup/src/popup_container/marker_with_key.dart';

import '../popup_controller_impl.dart';
import '../popup_event.dart';

mixin PopupContainerMixin {
  FlutterMapState get mapState;

  PopupControllerImpl get popupController;

  PopupSnap get snap;

  bool get markerRotate;

  Function(PopupEvent event, List<MarkerData> selectedMarkers)?
      get onPopupEvent;

  @nonVirtual
  Widget inPosition(MarkerData marker, Widget popup) {
    final layout = popupLayout(marker);

    return Positioned.fill(
      child: Transform(
        alignment: layout.rotationAlignment,
        transform: layout.transformationMatrix,
        child: Align(
          alignment: layout.contentAlignment,
          child: popup,
        ),
      ),
    );
  }

  @nonVirtual
  PopupLayout popupLayout(MarkerData marker) {
    return PopupLayout.calculate(
      mapState: mapState,
      marker: marker,
      snap: snap,
      markerRotate: markerRotate,
    );
  }

  /// This makes sure that the state of the popup stays with the popup even if
  /// it goes off screen or changes position in the widget tree.
  @nonVirtual
  Widget popupWithStateKeepAlive(MarkerWithKey markerWithKey,
      Widget Function(BuildContext, MarkerData) popupBuilder) {
    return Builder(
      key: markerWithKey.key,
      builder: (context) => popupBuilder(
        context,
        markerWithKey.marker,
      ),
    );
  }

  @nonVirtual
  void handleAction(PopupEvent event) {
    onPopupEvent?.call(event, popupController.selectedMarkers);

    return event.handle(
      showAlsoFor: wrapShowPopupsAlsoFor,
      showOnlyFor: wrapShowPopupsOnlyFor,
      hideAll: wrapHideAllPopups,
      hideOnlyFor: wrapHidePopupsOnlyFor,
      toggle: toggle,
    );
  }

  @nonVirtual
  void wrapShowPopupsAlsoFor(
    List<MarkerData> markers, {
    required bool disableAnimation,
  }) {
    final markersWithKeys =
        markers.map((marker) => MarkerWithKey(marker)).toList();
    popupController.selectedMarkersWithKeys.addAll(markersWithKeys);

    showPopupsAlsoFor(markersWithKeys, disableAnimation: disableAnimation);
  }

  @nonVirtual
  void wrapShowPopupsOnlyFor(
    List<MarkerData> markers, {
    required bool disableAnimation,
  }) {
    final markersWithKeys =
        markers.map((marker) => MarkerWithKey(marker)).toList();
    popupController.selectedMarkersWithKeys.clear();
    popupController.selectedMarkersWithKeys.addAll(markersWithKeys);

    showPopupsOnlyFor(markersWithKeys, disableAnimation: disableAnimation);
  }

  @nonVirtual
  void wrapHideAllPopups({required bool disableAnimation}) {
    popupController.selectedMarkersWithKeys.clear();
    hideAllPopups(disableAnimation: disableAnimation);
  }

  @nonVirtual
  void wrapHidePopupsOnlyFor(
    List<MarkerData> markers, {
    required bool disableAnimation,
  }) {
    popupController.selectedMarkersWithKeys
        .removeWhere((markerWithKey) => markers.contains(markerWithKey.marker));
    hidePopupsOnlyFor(markers, disableAnimation: disableAnimation);
  }

  @nonVirtual
  void toggle(MarkerData marker, {bool disableAnimation = false}) {
    if (popupController.selectedMarkersWithKeys
        .contains(MarkerWithKey.wrap(marker))) {
      wrapHidePopupsOnlyFor([marker], disableAnimation: disableAnimation);
    } else {
      wrapShowPopupsAlsoFor([marker], disableAnimation: disableAnimation);
    }
  }

  void showPopupsAlsoFor(
    List<MarkerWithKey> markersWithKeys, {
    required bool disableAnimation,
  });

  void showPopupsOnlyFor(
    List<MarkerWithKey> markersWithKeys, {
    required bool disableAnimation,
  });

  void hideAllPopups({required bool disableAnimation});

  void hidePopupsOnlyFor(List<MarkerData> markers,
      {required bool disableAnimation});
}
