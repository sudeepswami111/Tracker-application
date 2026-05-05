import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingResult {
  final String displayName;
  final LatLng location;
  GeocodingResult({required this.displayName, required this.location});
}

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;
  bool isSelected;
  RouteResult({required this.points, required this.distanceKm, required this.durationMin, this.isSelected = false});
}

class RoutingService {
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const _osrmBase = 'https://router.project-osrm.org';

  /// Geocode an address string to coordinates using Nominatim
  static Future<List<GeocodingResult>> geocode(String query) async {
    final uri = Uri.parse('$_nominatimBase/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1');
    final res = await http.get(uri, headers: {'User-Agent': 'LifePulseApp/1.0'});
    if (res.statusCode != 200) return [];
    final List data = json.decode(res.body);
    return data.map((e) => GeocodingResult(
      displayName: e['display_name'] ?? '',
      location: LatLng(double.parse(e['lat']), double.parse(e['lon'])),
    )).toList();
  }

  /// Get routes between two points using OSRM (with alternatives)
  static Future<List<RouteResult>> getRoutes(LatLng from, LatLng to) async {
    final uri = Uri.parse(
      '$_osrmBase/route/v1/foot/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?alternatives=true&geometries=geojson&overview=full'
    );
    final res = await http.get(uri, headers: {'User-Agent': 'LifePulseApp/1.0'});
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body);
    if (data['code'] != 'Ok') return [];

    final List routes = data['routes'];
    return routes.asMap().entries.map((entry) {
      final r = entry.value;
      final List coords = r['geometry']['coordinates'];
      final points = coords.map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      return RouteResult(
        points: points,
        distanceKm: (r['distance'] as num).toDouble() / 1000,
        durationMin: (r['duration'] as num).toDouble() / 60,
        isSelected: entry.key == 0,
      );
    }).toList();
  }
}
