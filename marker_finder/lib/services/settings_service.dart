import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // Keys for shared preferences
  static const String _searchRadiusKey = 'search_radius';

  // Default values
  static const double defaultSearchRadius = 20.0; // 20km

  // Stream controller for radius changes
  static final StreamController<double> _radiusStreamController =
      StreamController<double>.broadcast();

  // Stream of radius changes
  static Stream<double> get radiusStream => _radiusStreamController.stream;

  // Get search radius from shared preferences
  static Future<double> getSearchRadius() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_searchRadiusKey) ?? defaultSearchRadius;
  }

  // Save search radius to shared preferences
  static Future<void> saveSearchRadius(double radius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_searchRadiusKey, radius);

    // Notify listeners
    _radiusStreamController.add(radius);
    debugPrint('SettingsService: Radius saved: $radius km');
  }
}
