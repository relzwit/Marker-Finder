import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

class HmdbScraper {
  /// Fetches the image URL and inscription text from an HMDB marker page
  /// Returns a map with 'imageUrl' and 'inscription' keys
  static Future<Map<String, String?>> scrapeMarkerData(String url) async {
    try {
      // Make HTTP request to the HMDB page
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        print('Failed to load page: ${response.statusCode}');
        return {'imageUrl': null, 'inscription': null};
      }
      
      // Parse the HTML document
      Document document = parser.parse(response.body);
      
      // Extract the image URL
      String? imageUrl;
      try {
        // Look for the main marker image
        Element? imgElement = document.querySelector('.photoright img');
        if (imgElement != null) {
          String? src = imgElement.attributes['src'];
          if (src != null) {
            // Convert relative URL to absolute if needed
            if (src.startsWith('/')) {
              imageUrl = 'https://www.hmdb.org$src';
            } else {
              imageUrl = src;
            }
          }
        }
      } catch (e) {
        print('Error extracting image: $e');
      }
      
      // Extract the inscription text
      String? inscription;
      try {
        // Look for the inscription section
        Element? inscriptionElement = document.querySelector('.inscription');
        if (inscriptionElement != null) {
          inscription = inscriptionElement.text.trim();
        } else {
          // Try alternative selectors if the main one doesn't work
          List<Element> paragraphs = document.querySelectorAll('p');
          for (var p in paragraphs) {
            if (p.text.contains('Inscription.') || p.text.contains('Text.')) {
              inscription = p.text.trim();
              break;
            }
          }
        }
      } catch (e) {
        print('Error extracting inscription: $e');
      }
      
      return {
        'imageUrl': imageUrl,
        'inscription': inscription ?? 'No inscription available'
      };
    } catch (e) {
      print('Error scraping marker data: $e');
      return {'imageUrl': null, 'inscription': 'Error loading data'};
    }
  }
  
  /// Caches the results to avoid repeated network requests
  static final Map<String, Map<String, String?>> _cache = {};
  
  /// Gets marker data with caching
  static Future<Map<String, String?>> getMarkerData(String url) async {
    // Check if data is already in cache
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }
    
    // Fetch data and store in cache
    final data = await scrapeMarkerData(url);
    _cache[url] = data;
    return data;
  }
}
