import 'package:longpress_popup/fluttermap_markerpopup.dart';
import 'package:longpress_popup/src/popup_controller_impl.dart';

/// Used to programmatically show/hide popups and find out which markers
/// have visible popups.

abstract class PopupController {
  /// The [MarkerData]s for which a popup is currently showing if there is one.
  List<MarkerData> get selectedMarkers;

  factory PopupController({List<MarkerData> initiallySelectedMarkers}) =
      PopupControllerImpl;

  /// Show the popups for the given [markers]. If a popup is already showing for
  /// a given marker it remains visible.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing the popups.
  void showPopupsAlsoFor(List<MarkerData> markers,
      {bool disableAnimation = false});

  /// Show the popups only for the given [markers]. All other popups will be
  /// hidden. If a popup is already showing for a given marker it remains
  /// visible.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing/hiding the popups.
  void showPopupsOnlyFor(List<MarkerData> markers,
      {bool disableAnimation = false});

  /// Hide all popups that are showing.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  void hideAllPopups({bool disableAnimation = false});

  /// Hide popups showing for any of the given markers.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  void hidePopupsOnlyFor(List<MarkerData> markers,
      {bool disableAnimation = false});

  /// Hide the popup if it is showing for the given [marker], otherwise show it
  /// for that [marker].
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing/hiding the popup.
  void togglePopup(MarkerData marker, {bool disableAnimation = false});
}
