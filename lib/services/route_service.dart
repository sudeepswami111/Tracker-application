import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_result.dart';
import 'exceptions.dart';

class RouteService {
  bool _isJsonResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    return contentType.contains('application/json') ||
        response.body.trim().startsWith('{');
  }

  Future<RouteResult> getRoute(LatLng start, LatLng destination) async {
    // OSRM public API — alternatives=true requests up to 3 real alternative routes.
    final url =
        'https://router.project-osrm.org/route/v1/foot/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?geometries=geojson&overview=full&alternatives=true';

    debugLog('RouteService: Requesting routes from OSRM');
    debugLog('  Start: (${start.latitude}, ${start.longitude})');
    debugLog('  End:   (${destination.latitude}, ${destination.longitude})');

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
          userMessage:
              'Could not find a walkable route between these locations.',
          retryable: false,
        );
      }

      final routesData = data['routes'] as List?;

      if (routesData == null || routesData.isEmpty) {
        throw RouteException(
          technicalMessage: 'No routes found in OSRM response',
          userMessage:
              'Could not find a walkable route between these locations.',
          retryable: false,
        );
      }

      debugLog('RouteService: OSRM returned ${routesData.length} route(s)');

      // ── Parse all raw routes ──
      final List<List<LatLng>> alternatives = [];
      final List<double> distances = [];
      final List<double> durations = [];

      for (int i = 0; i < routesData.length; i++) {
        final route = routesData[i];
        final geometry = route['geometry']['coordinates'] as List;
        final polyline = geometry
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        alternatives.add(polyline);
        distances.add((route['distance'] as num) / 1000.0);
        durations.add((route['duration'] as num) / 60.0);

        debugLog(
          'RouteService: Route $i → '
          '${distances[i].toStringAsFixed(2)} km, '
          '${durations[i].toStringAsFixed(1)} min, '
          '${polyline.length} points',
        );
      }

      // ── Classify routes ──
      int fastestIdx = 0;
      int shortestIdx = 0;
      for (int i = 1; i < alternatives.length; i++) {
        if (durations[i] < durations[fastestIdx]) fastestIdx = i;
        if (distances[i] < distances[shortestIdx]) shortestIdx = i;
      }

      // ── Build rich RouteAlternative list ──
      final List<RouteAlternative> routeAlts = [];
      int altCounter = 1;

      for (int i = 0; i < alternatives.length; i++) {
        String label;
        if (i == fastestIdx && i == shortestIdx) {
          label = 'Fastest & Shortest';
        } else if (i == fastestIdx) {
          label = 'Fastest';
        } else if (i == shortestIdx) {
          label = 'Shortest';
        } else {
          label = 'Alternative $altCounter';
          altCounter++;
        }

        routeAlts.add(RouteAlternative(
          index: i,
          id: 'route_$i',
          label: label,
          distanceKm: distances[i],
          durationMinutes: durations[i],
          points: alternatives[i],
        ));
      }

      debugLog('RouteService: Fastest index=$fastestIdx, Shortest index=$shortestIdx');
      debugLog('RouteService: Route labels: ${routeAlts.map((r) => r.label).join(', ')}');

      return RouteResult(
        alternatives: alternatives,
        distances: distances,
        durations: durations,
        distanceKm: distances[0],
        durationMinutes: durations[0],
        routeAlternatives: routeAlts,
        fastestIndex: fastestIdx,
        shortestIndex: shortestIdx,
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

  void debugLog(String msg) {
    // ignore: avoid_print
    print('[LifePulse] $msg');
  }
}
