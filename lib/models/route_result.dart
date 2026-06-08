import 'package:latlong2/latlong.dart';

/// A single real route alternative returned by the routing API.
class RouteAlternative {
  final int index;
  final String id;

  /// Human-readable label: "Fastest", "Shortest", or "Alternative N"
  final String label;

  /// Distance in kilometres.
  final double distanceKm;

  /// Estimated travel time in minutes.
  final double durationMinutes;

  /// Decoded polyline points for this route.
  final List<LatLng> points;

  const RouteAlternative({
    required this.index,
    required this.id,
    required this.label,
    required this.distanceKm,
    required this.durationMinutes,
    required this.points,
  });

  /// Helper: formatted distance string e.g. "5.2 km"
  String get distanceText => '${distanceKm.toStringAsFixed(1)} km';

  /// Helper: formatted duration string e.g. "28 min"
  String get durationText => '${durationMinutes.round()} min';

  /// Full summary line e.g. "28 min · 5.2 km"
  String get summaryText => '$durationText · $distanceText';
}

/// Result returned by [RouteService.getRoute].
///
/// Contains all real route alternatives from the API (1–N routes).
class RouteResult {
  /// Raw list of polylines for each alternative (legacy, kept for compatibility).
  final List<List<LatLng>> alternatives;

  /// Distances in km for each alternative.
  final List<double> distances;

  /// Durations in minutes for each alternative.
  final List<double> durations;

  /// Distance (km) of the primary/first route.
  final double distanceKm;

  /// Duration (min) of the primary/first route.
  final double durationMinutes;

  /// Rich labelled alternatives — use these for the UI.
  final List<RouteAlternative> routeAlternatives;

  /// Index into [alternatives] for the route with the lowest duration.
  final int fastestIndex;

  /// Index into [alternatives] for the route with the lowest distance.
  final int shortestIndex;

  RouteResult({
    required this.alternatives,
    required this.distances,
    required this.durations,
    required this.distanceKm,
    required this.durationMinutes,
    required this.routeAlternatives,
    required this.fastestIndex,
    required this.shortestIndex,
  });
}
