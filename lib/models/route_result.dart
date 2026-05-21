import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<List<LatLng>> alternatives;
  final double distanceKm;
  final double durationMinutes;

  RouteResult({
    required this.alternatives,
    required this.distanceKm,
    required this.durationMinutes,
  });
}
