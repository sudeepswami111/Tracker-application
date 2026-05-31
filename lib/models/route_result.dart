import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<List<LatLng>> alternatives;
  final List<double> distances;
  final List<double> durations;
  final double distanceKm;
  final double durationMinutes;

  RouteResult({
    required this.alternatives,
    required this.distances,
    required this.durations,
    required this.distanceKm,
    required this.durationMinutes,
  });
}
