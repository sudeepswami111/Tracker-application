import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart' as native_geo;
import '../models/geocoding_result.dart';
import '../models/location_suggestion.dart';
import 'exceptions.dart';

class GeocodingService {
  static const String _userAgent =
      'LifePulseRoutePlanner/1.0 (github.com/sudeepswami111/lifepulse; sudeepswami111@gmail.com)';

  // ── In-memory suggestion cache ─────────────────────────────────────────────
  // Key: normalised query string.  Value: parsed suggestions list.
  final Map<String, List<LocationSuggestion>> _suggestionCache = {};

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _isJsonResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    return contentType.contains('application/json') ||
        response.body.trim().startsWith('{') ||
        response.body.trim().startsWith('[');
  }

  String _normalizeLocationQuery(String input) {
    final lower = input.trim().toLowerCase();
    if (lower.isEmpty) return '';
    if (lower.contains('vadodara') ||
        lower.contains('surat') ||
        lower.contains('atladara') ||
        lower.contains('ahmedabad')) {
      if (!lower.contains('india')) {
        return '$input, Gujarat, India';
      }
    }
    return input;
  }

  Map<String, String> get _headers => {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
        'Accept-Language': 'en',
      };

  // ── searchSuggestions ──────────────────────────────────────────────────────

  /// Returns location suggestions for the given [query] string.
  ///
  /// - Query must be ≥ 2 characters.
  /// - Results are cached in memory by normalised query key.
  /// - Throws [GeocodingException] on rate-limit (403/429) or network error.
  /// - Returns an empty list if no suggestions found.
  Future<List<LocationSuggestion>> searchSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _log('Suggestion query too short (${trimmed.length} chars), skipping');
      return [];
    }

    final cacheKey = trimmed.toLowerCase();
    _log('Suggestion query: "$cacheKey"');

    // Cache hit
    if (_suggestionCache.containsKey(cacheKey)) {
      final cached = _suggestionCache[cacheKey]!;
      _log('Cache HIT for "$cacheKey" → ${cached.length} suggestions');
      return cached;
    }

    _log('Cache MISS for "$cacheKey" → calling Nominatim');

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(trimmed)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=7'
        '&dedupe=1',
      );

      final res = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw GeocodingException(
          technicalMessage: 'Nominatim suggestion request timed out',
          userMessage: 'Location search timed out. Please try again.',
          retryable: true,
        ),
      );

      _log('Nominatim suggestion status: ${res.statusCode}');

      if (res.statusCode == 403 || res.statusCode == 429) {
        throw GeocodingException(
          technicalMessage: 'Nominatim rate-limited (${res.statusCode})',
          userMessage:
              'Location suggestions are temporarily limited. Try again in a moment.',
          statusCode: res.statusCode,
          retryable: true,
        );
      }

      if (res.statusCode != 200) {
        // Non-critical – just return empty rather than crashing
        _log('Nominatim returned non-200: ${res.statusCode}');
        return [];
      }

      if (!_isJsonResponse(res)) {
        _log('Nominatim returned non-JSON response – likely HTML error page');
        return [];
      }

      final raw = jsonDecode(res.body);
      if (raw is! List) {
        _log('Unexpected Nominatim response type: ${raw.runtimeType}');
        return [];
      }

      final suggestions = raw
          .cast<Map<String, dynamic>>()
          .map((json) {
            try {
              return LocationSuggestion.fromNominatim(json);
            } catch (e) {
              _log('Failed to parse suggestion: $e');
              return null;
            }
          })
          .whereType<LocationSuggestion>()
          .toList();

      _log('Suggestions found: ${suggestions.length} for "$cacheKey"');

      // Store in cache
      _suggestionCache[cacheKey] = suggestions;

      return suggestions;
    } on GeocodingException {
      rethrow;
    } catch (e) {
      _log('Suggestion fetch error: $e');
      // Return empty – non-critical path; don't crash the app
      return [];
    }
  }

  // ── geocode (existing – unchanged) ────────────────────────────────────────

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
          return GeocodingResult(
              coordinates: LatLng(lat, lng), displayName: normalizedQuery);
        }
      } catch (_) {
        // ignore invalid cache
      }
    }

    try {
      final res = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(normalizedQuery)}&format=json&limit=1'),
        headers: _headers,
      );

      if (res.statusCode == 403 || res.statusCode == 429) {
        throw GeocodingException(
          technicalMessage:
              'Nominatim blocked or rate limited (Status ${res.statusCode})',
          userMessage:
              'Geocoding service is temporarily blocked or rate-limited. Please wait and try again.',
          statusCode: res.statusCode,
          retryable: true,
        );
      }

      if (!_isJsonResponse(res)) {
        throw GeocodingException(
          technicalMessage: 'Non-JSON response from Nominatim',
          userMessage:
              'Geocoding service returned an unexpected format. Please try again.',
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

      return GeocodingResult(
          coordinates: LatLng(lat, lon), displayName: normalizedQuery);
    } on GeocodingException {
      return await _fallbackGeocode(normalizedQuery);
    } catch (_) {
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
        userMessage:
            'Could not find the location. Please check the spelling or try a different place.',
        retryable: false,
      );
    }
  }

  void _log(String msg) {
    // ignore: avoid_print
    print('[LifePulse GeocodingService] $msg');
  }
}
