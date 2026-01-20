import '../services/nominatim_service.dart';
import 'package:flutter/foundation.dart';

/// University coordinates in Malawi
/// Uses Nominatim API to fetch coordinates dynamically, with caching for performance
class UniversityCoordinates {
  // Cache for university coordinates to avoid repeated API calls
  static final Map<String, Map<String, double>> _coordinatesCache = {};
  
  // Fallback hardcoded coordinates for major universities (used if API fails)
  static const Map<String, Map<String, double>> _fallbackCoordinates = {
    // Major Universities
    // University of Malawi (UNIMA) - Zomba campus (main)
    'University of Malawi (UNIMA)': {
      'latitude': -15.3861,
      'longitude': 35.3181,
    },
    // Malawi University of Science and Technology (MUST) - Thyolo
    'Malawi University of Science and Technology (MUST)': {
      'latitude': -16.0644,
      'longitude': 35.0381,
    },
    // Lilongwe University of Agriculture and Natural Resources (LUANAR) - Bunda campus
    'Lilongwe University of Agriculture and Natural Resources (LUANAR)': {
      'latitude': -13.9626,
      'longitude': 33.7741,
    },
    // Mzuzu University (MZUNI)
    'Mzuzu University (MZUNI)': {
      'latitude': -11.4528,
      'longitude': 34.0214,
    },
    // Malawi University of Business and Applied Sciences (MUBAS) - Blantyre
    'Malawi University of Business and Applied Sciences (MUBAS)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Kamuzu University of Health Sciences (KUHeS)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Malawi College of Accountancy (MCA)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Malawi School of Government (MSG)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Domasi College of Education (DCE)': {
      'latitude': -15.3847,
      'longitude': 35.3331,
    },
    'Nalikule College of Education (NCE)': {
      'latitude': -13.9626,
      'longitude': 33.7741,
    },
    'Malawi College of Health Sciences (MCHS)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Mikolongwe College of Veterinary Sciences (MCVS)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Malawi College of Forestry and Wildlife (MCFW)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Malawi Institute of Tourism (MIT)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Marine College (MC)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Civil Aviation Training Centre (CATC)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Montfort Special Needs Education Centre (MSNEC)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'National College of Information Technology (NACIT)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Guidance, Counselling and Youth Development Centre for Africa (GCYDCA)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Catholic University of Malawi (CUNIMA)': {
      'latitude': -15.3847,
      'longitude': 35.3331,
    },
    'DMI St John the Baptist University (DMI)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Nkhoma University (NKHUNI)': {
      'latitude': -13.9626,
      'longitude': 33.7741,
    },
    'Malawi Assemblies of God University (MAGU)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Daeyang University (DU)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Malawi Adventist University (MAU)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'Pentecostal Life University (PLU)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'African Bible College (ABC)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'University of Livingstonia (UNILIA)': {
      'latitude': -11.4528,
      'longitude': 34.0214,
    },
    'Exploits University (EU)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
    'University of Lilongwe (UNILIL)': {
      'latitude': -13.9626,
      'longitude': 33.7741,
    },
    'Millennium University (MU)': {
      'latitude': -15.7861,
      'longitude': 35.0058,
    },
  };

  /// Get coordinates for a university by name
  /// Uses Nominatim API to search for the university, with caching and fallback
  /// Returns null if university not found
  static Future<Map<String, double>?> getCoordinates(String? universityName) async {
    if (universityName == null || universityName.isEmpty) {
      return null;
    }
    
    // Normalize university name for cache lookup
    final normalizedName = _normalizeUniversityName(universityName);
    
    // Check cache first
    if (_coordinatesCache.containsKey(normalizedName)) {
      return _coordinatesCache[normalizedName];
    }
    
    // Try to find in fallback coordinates first (faster)
    final fallbackCoords = _getFallbackCoordinates(universityName);
    if (fallbackCoords != null) {
      _coordinatesCache[normalizedName] = fallbackCoords;
      return fallbackCoords;
    }
    
    // Search using Nominatim API
    try {
      // Build search query - add "Malawi" to improve accuracy
      String searchQuery = universityName;
      if (!searchQuery.toLowerCase().contains('malawi')) {
        searchQuery = '$universityName, Malawi';
      }
      
      // Search for the university
      final results = await NominatimService.searchPlaces(
        searchQuery,
        limit: 5,
        countryCodes: 'mw', // Limit to Malawi
      );
      
      // Find the best match (prefer results with "university" in the name)
      Place? bestMatch;
      for (final place in results) {
        final placeName = place.displayName.toLowerCase();
        final searchName = universityName.toLowerCase();
        
        // Check if it's a university and matches our search
        if ((placeName.contains('university') || 
             placeName.contains('college') ||
             placeName.contains('institute')) &&
            (placeName.contains(searchName) || 
             searchName.contains(place.simpleName.toLowerCase()))) {
          bestMatch = place;
          break;
        }
      }
      
      // If no exact match, use the first result if available
      if (bestMatch == null && results.isNotEmpty) {
        bestMatch = results.first;
      }
      
      if (bestMatch != null) {
        final coords = {
          'latitude': bestMatch.location.latitude,
          'longitude': bestMatch.location.longitude,
        };
        
        // Cache the result
        _coordinatesCache[normalizedName] = coords;
        
        if (kDebugMode) {
          print('Found coordinates for $universityName: ${coords['latitude']}, ${coords['longitude']}');
        }
        
        return coords;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching coordinates for $universityName: $e');
      }
    }
    
    // If API search fails, try fallback one more time with normalized name
    final finalFallback = _getFallbackCoordinates(normalizedName);
    if (finalFallback != null) {
      _coordinatesCache[normalizedName] = finalFallback;
      return finalFallback;
    }
    
    return null;
  }
  
  /// Get coordinates from fallback hardcoded list
  static Map<String, double>? _getFallbackCoordinates(String universityName) {
    if (universityName.isEmpty) return null;
    
    final lowerName = universityName.toLowerCase();
    
    // Try exact match first
    for (final entry in _fallbackCoordinates.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }
    
    // Try partial match
    for (final entry in _fallbackCoordinates.entries) {
      final entryLower = entry.key.toLowerCase();
      if (entryLower.contains(lowerName) || lowerName.contains(entryLower)) {
        return entry.value;
      }
    }
    
    // Try matching by abbreviation
    final abbreviations = {
      'unima': 'University of Malawi (UNIMA)',
      'must': 'Malawi University of Science and Technology (MUST)',
      'luanar': 'Lilongwe University of Agriculture and Natural Resources (LUANAR)',
      'mzuni': 'Mzuzu University (MZUNI)',
      'mubas': 'Malawi University of Business and Applied Sciences (MUBAS)',
      'kuhes': 'Kamuzu University of Health Sciences (KUHeS)',
      'cunima': 'Catholic University of Malawi (CUNIMA)',
      'unilia': 'University of Livingstonia (UNILIA)',
      'unilil': 'University of Lilongwe (UNILIL)',
    };
    
    for (final entry in abbreviations.entries) {
      if (lowerName.contains(entry.key) || lowerName.contains(entry.value.toLowerCase())) {
        return _fallbackCoordinates[entry.value];
      }
    }
    
    return null;
  }
  
  /// Normalize university name for consistent caching
  static String _normalizeUniversityName(String name) {
    return name.trim().toLowerCase();
  }
  
  /// Clear the coordinates cache (useful for testing or if coordinates need to be refreshed)
  static void clearCache() {
    _coordinatesCache.clear();
  }
}
