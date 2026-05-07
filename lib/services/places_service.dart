import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ── Nominatim Autocomplete Result ────────────────────────────────────────────
class PlaceSuggestion {
  final String displayName;
  final String shortName;
  final LatLng location;

  const PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    required this.location,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      displayName: json['display_name'] as String,
      shortName: (json['display_name'] as String).split(',').take(2).join(', '),
      location: LatLng(
        double.parse(json['lat'] as String),
        double.parse(json['lon'] as String),
      ),
    );
  }
}

// ── Nearby Landmark ───────────────────────────────────────────────────────────
class NearbyLandmark {
  final String name;
  final String category;
  final LatLng location;
  final IconData icon;
  final Color color;

  const NearbyLandmark({
    required this.name,
    required this.category,
    required this.location,
    required this.icon,
    required this.color,
  });
}

// ── Places Service ────────────────────────────────────────────────────────────
class PlacesService {
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const _overpassBase = 'https://overpass-api.de/api/interpreter';

  static const _headers = {
    'User-Agent': 'LifePulse/1.0 (Flutter App)',
    'Accept-Language': 'en',
  };

  // ── Autocomplete ─────────────────────────────────────────────────────────
  static Future<List<PlaceSuggestion>> autocomplete(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final uri = Uri.parse('$_nominatimBase/search').replace(queryParameters: {
        'q': query,
        'format': 'json',
        'limit': '5',
        'addressdetails': '0',
      });
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as List;
      return data.map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Nearby Landmarks via Overpass ─────────────────────────────────────────
  static Future<List<NearbyLandmark>> fetchNearbyLandmarks(LatLng center, {double radiusM = 500}) async {
    final lat = center.latitude;
    final lon = center.longitude;
    final r = radiusM.toInt();

    final query = '''
[out:json][timeout:10];
(
  node["amenity"~"cafe|restaurant|gym|park|hospital|pharmacy|fuel|bank|atm|library"](around:$r,$lat,$lon);
  node["leisure"~"park|playground|sports_centre"](around:$r,$lat,$lon);
  node["tourism"~"attraction|viewpoint|museum"](around:$r,$lat,$lon);
);
out body 20;
''';

    try {
      final res = await http.post(
        Uri.parse(_overpassBase),
        body: {'data': query},
        headers: {'User-Agent': 'LifePulse/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final elements = data['elements'] as List;

      return elements.map((e) {
        final tags = e['tags'] as Map<String, dynamic>? ?? {};
        final name = (tags['name'] as String?) ?? (tags['amenity'] as String?) ?? (tags['leisure'] as String?) ?? 'Place';
        final amenity = (tags['amenity'] ?? tags['leisure'] ?? tags['tourism'] ?? '') as String;
        return NearbyLandmark(
          name: name,
          category: amenity,
          location: LatLng(e['lat'] as double, e['lon'] as double),
          icon: _iconFor(amenity),
          color: _colorFor(amenity),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static IconData _iconFor(String amenity) {
    switch (amenity) {
      case 'cafe': return Icons.local_cafe;
      case 'restaurant': return Icons.restaurant;
      case 'gym': return Icons.fitness_center;
      case 'park': case 'playground': return Icons.park;
      case 'hospital': return Icons.local_hospital;
      case 'pharmacy': return Icons.local_pharmacy;
      case 'fuel': return Icons.local_gas_station;
      case 'bank': case 'atm': return Icons.account_balance;
      case 'library': return Icons.local_library;
      case 'sports_centre': return Icons.sports;
      case 'attraction': return Icons.star;
      case 'museum': return Icons.museum;
      default: return Icons.place;
    }
  }

  static Color _colorFor(String amenity) {
    switch (amenity) {
      case 'cafe': case 'restaurant': return const Color(0xFFFF9F43);
      case 'gym': case 'sports_centre': return const Color(0xFF6C5CE7);
      case 'park': case 'playground': return const Color(0xFF00B894);
      case 'hospital': case 'pharmacy': return const Color(0xFFFF6B6B);
      case 'fuel': return const Color(0xFFE17055);
      case 'bank': case 'atm': return const Color(0xFF74B9FF);
      case 'attraction': case 'museum': return const Color(0xFFFD79A8);
      default: return const Color(0xFF00E5FF);
    }
  }
}

// ── Autocomplete TextField Widget ─────────────────────────────────────────────
class PlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<PlaceSuggestion> onSelected;

  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.onSelected,
  });

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  final _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _removeOverlay();
    });
  }

  void _onChanged() {
    _debounce?.cancel();
    final text = widget.controller.text;
    if (text.length < 3) { _removeOverlay(); return; }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(text));
  }

  Future<void> _fetchSuggestions(String q) async {
    setState(() => _loading = true);
    final results = await PlacesService.autocomplete(q);
    if (!mounted) return;
    setState(() { _suggestions = results; _loading = false; });
    if (results.isNotEmpty && _focusNode.hasFocus) _showOverlay();
    else _removeOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _select(PlaceSuggestion s) {
    widget.controller.text = s.shortName;
    _removeOverlay();
    _focusNode.unfocus();
    widget.onSelected(s);
  }

  Widget _buildOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      width: 320,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 52),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.map((s) => InkWell(
                onTap: () => _select(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Icon(Icons.location_on, size: 16, color: widget.iconColor),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.shortName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(s.displayName, style: TextStyle(fontSize: 10, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                ),
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(widget.icon, size: 18, color: widget.iconColor),
            suffixIcon: _loading
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }
}
