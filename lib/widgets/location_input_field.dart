import 'dart:async';
import 'package:flutter/material.dart';
import '../models/location_suggestion.dart';
import '../services/geocoding_service.dart';
import '../services/recent_locations_service.dart';
import 'location_suggestions_dropdown.dart';

/// A text input field with live location autocomplete.
///
/// Behaviour:
/// - On focus with empty text → shows recent locations
/// - On text change (≥ 2 chars) → fires Nominatim search after [debounceDuration]
/// - On suggestion tap → calls [onSuggestionSelected], hides dropdown
/// - On clear button → calls [onCoordinatesCleared]
/// - On unfocus → hides dropdown after short delay (to allow tap events)
class LocationInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final Color prefixIconColor;
  final bool isDark;
  final bool isTop;

  /// Called when the user selects a suggestion from the dropdown.
  final void Function(LocationSuggestion suggestion) onSuggestionSelected;

  /// Called when the user manually clears or modifies the text
  /// (coordinates should be invalidated).
  final VoidCallback onCoordinatesCleared;

  /// Optional: trailing GPS / my-location button shown when field is empty
  final Widget? trailingAction;

  /// Extra right padding (e.g. for the swap button overlay)
  final double trailingSpace;

  const LocationInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.prefixIconColor,
    required this.isDark,
    required this.isTop,
    required this.onSuggestionSelected,
    required this.onCoordinatesCleared,
    this.trailingAction,
    this.trailingSpace = 38,
  });

  @override
  State<LocationInputField> createState() => _LocationInputFieldState();
}

class _LocationInputFieldState extends State<LocationInputField> {
  final GeocodingService _geocodingService = GeocodingService();
  final RecentLocationsService _recentsService = RecentLocationsService();
  final FocusNode _focusNode = FocusNode();

  static const Duration _debounceDuration = Duration(milliseconds: 500);

  Timer? _debounce;
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showDropdown = false;
  bool _isShowingRecents = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  // ── Focus handling ─────────────────────────────────────────────────────────

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _onFieldFocused();
    } else {
      // Delay so tap on a suggestion registers before dropdown hides
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showDropdown = false);
        }
      });
    }
  }

  void _onFieldFocused() {
    final text = widget.controller.text.trim();
    if (text.length < 2) {
      // Show recent locations
      _loadRecents();
    } else {
      // Re-show existing suggestions if any
      setState(() => _showDropdown = _suggestions.isNotEmpty || _isLoading);
    }
  }

  Future<void> _loadRecents() async {
    final recents = await _recentsService.getRecentLocations();
    if (!mounted) return;
    setState(() {
      _suggestions = recents;
      _isShowingRecents = true;
      _showDropdown = recents.isNotEmpty;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  // ── Text change → debounced search ────────────────────────────────────────

  void _onTextChanged(String value) {
    // Always signal that previously stored coordinates are now invalid
    widget.onCoordinatesCleared();

    _debounce?.cancel();

    if (value.trim().length < 2) {
      // Show recents or hide
      if (value.trim().isEmpty) {
        _loadRecents();
      } else {
        setState(() {
          _suggestions = [];
          _showDropdown = false;
          _isLoading = false;
          _errorMessage = null;
          _isShowingRecents = false;
        });
      }
      return;
    }

    // Start debounce
    setState(() {
      _isLoading = true;
      _showDropdown = true;
      _isShowingRecents = false;
      _errorMessage = null;
    });

    _debounce = Timer(_debounceDuration, () => _fetchSuggestions(value.trim()));
  }

  Future<void> _fetchSuggestions(String query) async {
    debugPrint('[LocationInputField] Debounce fired. Query: "$query"');
    if (!mounted) return;

    try {
      final results = await _geocodingService.searchSuggestions(query);
      if (!mounted) return;
      debugPrint('[LocationInputField] Suggestions count: ${results.length}');
      setState(() {
        _suggestions = results;
        _isLoading = false;
        _errorMessage = null;
        _showDropdown = true;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[LocationInputField] Suggestion error: $e');
      final msg = e.toString().contains('temporarily')
          ? 'Location suggestions are temporarily limited. Try again in a moment.'
          : null; // generic errors → just hide, don't show scary message
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _errorMessage = msg;
        _showDropdown = msg != null;
      });
    }
  }

  // ── Suggestion selected ────────────────────────────────────────────────────

  void _onSuggestionTapped(LocationSuggestion suggestion) {
    debugPrint(
      '[LocationInputField] Selected: "${suggestion.shortName}" '
      'lat=${suggestion.latitude} lng=${suggestion.longitude}',
    );

    // Fill the field with the short name
    widget.controller.text = suggestion.shortName;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.shortName.length),
    );

    // Hide dropdown
    setState(() {
      _showDropdown = false;
      _isLoading = false;
      _suggestions = [];
      _isShowingRecents = false;
    });

    // Unfocus keyboard
    _focusNode.unfocus();

    // Persist to recents
    _recentsService.saveLocation(suggestion);

    // Notify parent
    widget.onSuggestionSelected(suggestion);
  }

  // ── Clear button ───────────────────────────────────────────────────────────

  void _clearField() {
    widget.controller.clear();
    widget.onCoordinatesCleared();
    _debounce?.cancel();
    setState(() {
      _suggestions = [];
      _showDropdown = false;
      _isLoading = false;
      _errorMessage = null;
      _isShowingRecents = false;
    });
    _focusNode.requestFocus();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInputRow(),
        // Dropdown expands with AnimatedSize so the card below shifts smoothly
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: _showDropdown
              ? LocationSuggestionsDropdown(
                  suggestions: _suggestions,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  isShowingRecents: _isShowingRecents,
                  isDark: widget.isDark,
                  onSelected: _onSuggestionTapped,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildInputRow() {
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final hintColor = textColor.withValues(alpha: 0.45);
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.isTop ? 12 : 4),
          topRight: Radius.circular(widget.isTop ? 12 : 4),
          bottomLeft: Radius.circular(widget.isTop ? 4 : 12),
          bottomRight: Radius.circular(widget.isTop ? 4 : 12),
        ),
      ),
      child: Row(
        children: [
          Icon(widget.prefixIcon, color: widget.prefixIconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              maxLines: 1,
              style: TextStyle(color: textColor, fontSize: 14),
              onChanged: _onTextChanged,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(fontSize: 14, color: hintColor),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Clear button
          if (hasText)
            GestureDetector(
              onTap: _clearField,
              child: Icon(Icons.clear, size: 18, color: hintColor),
            )
          // Trailing action (e.g. GPS button) when empty
          else if (widget.trailingAction != null)
            widget.trailingAction!,
          SizedBox(width: widget.trailingSpace),
        ],
      ),
    );
  }
}
