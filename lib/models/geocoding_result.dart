import 'package:latlong2/latlong.dart';

class GeocodingResult {
  final LatLng coordinates;
  final String displayName;

  GeocodingResult({required this.coordinates, required this.displayName});
}
