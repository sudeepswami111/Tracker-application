import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_result.dart';
import 'exceptions.dart';

class RouteService {
  bool _isJsonResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    return contentType.contains('application/json') || response.body.trim().startsWith('{');
  }

  Future<RouteResult> getRoute(LatLng start, LatLng destination) async {
    // Use HTTPS for OSRM to avoid Android cleartext HTTP blocking
    final url = 'https://router.project-osrm.org/route/v1/foot/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?geometries=geojson&overview=full&alternatives=true';
    
    try {
      final res = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw RouteException(
          technicalMessage: 'OSRM request timed out after 15s',
          userMessage: 'Route calculation timed out. Check your connection.',
          retryable: true,
        ),
      );

      if (res.statusCode != 200) {
        throw RouteException(
          technicalMessage: 'OSRM returned status ${res.statusCode}',
          userMessage: 'Routing service is temporarily unavailable.',
          statusCode: res.statusCode,
          retryable: true,
        );
      }

      if (!_isJsonResponse(res)) {
        throw RouteException(
          technicalMessage: 'Non-JSON response from OSRM',
          userMessage: 'Routing service returned an unexpected format.',
          statusCode: res.statusCode,
          retryable: true,
        );
      }

      final data = jsonDecode(res.body);
      
      if (data['code'] != 'Ok') {
        throw RouteException(
          technicalMessage: 'OSRM code: ${data['code']}',
          userMessage: 'Could not find a walkable route between these locations.',
          retryable: false,
        );
      }

      final routesData = data['routes'] as List?;
      
      if (routesData == null || routesData.isEmpty) {
        throw RouteException(
          technicalMessage: 'No routes found in OSRM response',
          userMessage: 'Could not find a walkable route between these locations.',
          retryable: false,
        );
      }

      List<List<LatLng>> alternatives = [];
      List<double> distances = [];
      List<double> durations = [];

      for (int i = 0; i < routesData.length; i++) {
        final route = routesData[i];
        final geometry = route['geometry']['coordinates'] as List;
        List<LatLng> polyline = geometry.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        alternatives.add(polyline);
        distances.add((route['distance'] as num) / 1000.0);
        durations.add((route['duration'] as num) / 60.0);
      }

      return RouteResult(
        alternatives: alternatives,
        distances: distances,
        durations: durations,
        distanceKm: distances[0],
        durationMinutes: durations[0],
      );

    } catch (e) {
      if (e is RouteException) rethrow;
      throw RouteException(
        technicalMessage: e.toString(),
        userMessage: 'Failed to calculate route. Please check your connection.',
        retryable: true,
      );
    }
  }
}
