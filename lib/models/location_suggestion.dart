import 'package:latlong2/latlong.dart';

/// A single location suggestion returned by the geocoding autocomplete API.
class LocationSuggestion {
  /// Full display name from Nominatim e.g. "Vadodara, Vadodara District, Gujarat, India"
  final String displayName;

  /// Short name shown in the input field after selection e.g. "Vadodara, Gujarat"
  final String shortName;

  final double latitude;
  final double longitude;

  /// OSM type: "city", "town", "suburb", "station", "aerodrome", etc.
  final String? type;

  final String? city;
  final String? state;
  final String? country;

  const LocationSuggestion({
    required this.displayName,
    required this.shortName,
    required this.latitude,
    required this.longitude,
    this.type,
    this.city,
    this.state,
    this.country,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  /// Single subtitle line e.g. "Gujarat, India"
  String get subtitle {
    final parts = <String>[
      if (state != null && state!.isNotEmpty) state!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(', ');
  }

  /// Build from a Nominatim JSON result map.
  factory LocationSuggestion.fromNominatim(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};

    final city = address['city'] as String? ??
        address['town'] as String? ??
        address['village'] as String? ??
        address['municipality'] as String? ??
        address['county'] as String?;
    final state = address['state'] as String?;
    final country = address['country'] as String?;
    final displayName = json['display_name'] as String? ?? '';

    // Build a compact short name: "City, State" or just "display_name" trimmed
    final shortParts = <String>[
      if (city != null && city.isNotEmpty) city,
      if (state != null && state.isNotEmpty) state,
    ];
    final shortName = shortParts.isNotEmpty ? shortParts.join(', ') : _trimDisplayName(displayName);

    // Derive type label
    final osmType = json['type'] as String? ?? json['class'] as String? ?? '';

    return LocationSuggestion(
      displayName: displayName,
      shortName: shortName,
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      type: osmType,
      city: city,
      state: state,
      country: country,
    );
  }

  /// Trim Nominatim display_name to first 2 parts for a compact view.
  static String _trimDisplayName(String displayName) {
    final parts = displayName.split(', ');
    if (parts.length > 2) return '${parts[0]}, ${parts[1]}';
    return displayName;
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'shortName': shortName,
        'latitude': latitude,
        'longitude': longitude,
        'type': type,
        'city': city,
        'state': state,
        'country': country,
      };

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) =>
      LocationSuggestion(
        displayName: json['displayName'] as String,
        shortName: json['shortName'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        type: json['type'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        country: json['country'] as String?,
      );
}
