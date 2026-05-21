import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart' as native_geo;
import '../models/geocoding_result.dart';
import 'exceptions.dart';

class GeocodingService {
  static const String _userAgent = 'LifePulseRoutePlanner/1.0 (github.com/sudeepswami111/lifepulse; sudeepswami111@gmail.com)';

  bool _isJsonResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    return contentType.contains('application/json') || response.body.trim().startsWith('{') || response.body.trim().startsWith('[');
  }

  String _normalizeLocationQuery(String input) {
    final lower = input.trim().toLowerCase();
    if (lower.isEmpty) return '';
    if (lower.contains('vadodara') || lower.contains('surat') || lower.contains('atladara') || lower.contains('ahmedabad')) {
      if (!lower.contains('india')) {
        return '$input, Gujarat, India';
      }
    }
    return input;
  }

  Future<GeocodingResult> geocode(String query) async {
    final normalizedQuery = _normalizeLocationQuery(query);
    if (normalizedQuery.isEmpty) {
      throw GeocodingException(
        technicalMessage: 'Empty query provided',
        userMessage: 'Please enter a valid location.',
        retryable: false,
      );
    }

    final cacheKey = 'geocode_${normalizedQuery.toLowerCase()}';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);

    if (cached != null) {
      try {
        final parts = cached.split(',');
        if (parts.length == 2) {
          final lat = double.parse(parts[0]);
          final lng = double.parse(parts[1]);
          return GeocodingResult(coordinates: LatLng(lat, lng), displayName: normalizedQuery);
        }
      } catch (e) {
        // ignore invalid cache
      }
    }

    try {
      final headers = {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
        'Accept-Language': 'en',
      };
      
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(normalizedQuery)}&format=json&limit=1'),
        headers: headers,
      );

      if (res.statusCode == 403 || res.statusCode == 429) {
        throw GeocodingException(
          technicalMessage: 'Nominatim blocked or rate limited (Status ${res.statusCode})',
          userMessage: 'Geocoding service is temporarily blocked or rate-limited. Please wait and try again.',
          statusCode: res.statusCode,
          retryable: true,
        );
      }

      if (!_isJsonResponse(res)) {
        throw GeocodingException(
          technicalMessage: 'Non-JSON response from Nominatim',
          userMessage: 'Geocoding service returned an unexpected format. Please try again.',
          statusCode: res.statusCode,
          retryable: true,
        );
      }

      final data = jsonDecode(res.body) as List;
      if (data.isEmpty) {
        return await _fallbackGeocode(normalizedQuery);
      }

      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);
      
      await prefs.setString(cacheKey, '$lat,$lon');

      return GeocodingResult(coordinates: LatLng(lat, lon), displayName: normalizedQuery);

    } on GeocodingException {
      return await _fallbackGeocode(normalizedQuery);
    } catch (e) {
      return await _fallbackGeocode(normalizedQuery);
    }
  }

  Future<GeocodingResult> _fallbackGeocode(String query) async {
    try {
      final locations = await native_geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return GeocodingResult(
          coordinates: LatLng(loc.latitude, loc.longitude),
          displayName: query,
        );
      }
      throw Exception('No results');
    } catch (e) {
      throw GeocodingException(
        technicalMessage: 'Native geocoding failed: $e',
        userMessage: 'Could not find the location. Please check the spelling or try a different place.',
        retryable: false,
      );
    }
  }
}
