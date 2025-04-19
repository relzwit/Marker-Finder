import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class RegionService {
  // Define region boundaries (approximate center points and names)
  static final List<Map<String, dynamic>> _regions = [
    {
      'name': 'Tennessee',
      'file': 'hmdb_usa_tn.csv',
      'center': LatLng(35.8, -86.0),
      'country': 'USA',
    },
    {
      'name': 'Georgia',
      'file': 'hmdb_usa_ga.csv',
      'center': LatLng(32.9, -83.4),
      'country': 'USA',
    },
    {
      'name': 'Alabama',
      'file': 'hmdb_usa_ala.csv',
      'center': LatLng(32.8, -86.8),
      'country': 'USA',
    },
    {
      'name': 'Germany',
      'file': 'hmdb_ger.csv',
      'center': LatLng(51.1, 10.4),
      'country': 'Germany',
    },
    {
      'name': 'England',
      'file': 'hmdb_eng.csv',
      'center': LatLng(52.3, -1.9),
      'country': 'England',
    },
  ];

  // Get all available regions
  static List<Map<String, dynamic>> getAllRegions() {
    return _regions;
  }

  // Get region file by name
  static String? getRegionFileByName(String regionName) {
    final region = _regions.firstWhere(
      (r) => r['name'] == regionName,
      orElse: () => {'file': null},
    );
    return region['file'];
  }

  // Determine the closest region based on coordinates
  static String determineClosestRegion(double latitude, double longitude) {
    final userLocation = LatLng(latitude, longitude);

    // Calculate distances to each region center
    final distances = _regions.map((region) {
      final regionCenter = region['center'] as LatLng;
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        regionCenter.latitude,
        regionCenter.longitude,
      );
      return {
        'region': region,
        'distance': distance,
      };
    }).toList();

    // Sort by distance (closest first)
    distances.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    // Return the file name of the closest region
    final closestRegion = distances.first['region'] as Map<String, dynamic>;
    return closestRegion['file'] as String;
  }

  // Get region name from file name
  static String getRegionNameFromFile(String fileName) {
    final region = _regions.firstWhere(
      (r) => r['file'] == fileName,
      orElse: () => {'name': 'Unknown Region'},
    );
    return region['name'] as String;
  }
}
