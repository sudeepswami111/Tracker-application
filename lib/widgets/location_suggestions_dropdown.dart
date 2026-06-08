import 'package:flutter/material.dart';
import '../models/location_suggestion.dart';
import '../theme/app_colors.dart';

/// Pure UI widget that renders a dropdown list of [LocationSuggestion] items.
/// The parent [LocationInputField] drives the state and calls [onSelected].
class LocationSuggestionsDropdown extends StatelessWidget {
  final List<LocationSuggestion> suggestions;
  final bool isLoading;
  final String? errorMessage;
  final bool isShowingRecents;
  final void Function(LocationSuggestion) onSelected;
  final bool isDark;

  const LocationSuggestionsDropdown({
    super.key,
    required this.suggestions,
    required this.isLoading,
    required this.onSelected,
    required this.isDark,
    this.errorMessage,
    this.isShowingRecents = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final border = isDark
        ? AppColors.voltCyan.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.12);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      constraints: const BoxConstraints(maxHeight: 248),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: _buildContent(textColor),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    // Loading state
    if (isLoading) {
      return _loadingRow();
    }

    // Error / rate-limit state
    if (errorMessage != null) {
      return _messageRow(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.solarAmber,
        text: errorMessage!,
        textColor: textColor,
      );
    }

    // Empty state (query was long enough but nothing found)
    if (suggestions.isEmpty && !isShowingRecents) {
      return _messageRow(
        icon: Icons.search_off,
        iconColor: textColor.withValues(alpha: 0.4),
        text: 'No suggestions found',
        textColor: textColor.withValues(alpha: 0.6),
      );
    }

    // Recents or API results
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: suggestions.length,
      itemBuilder: (context, i) {
        final s = suggestions[i];
        return _SuggestionTile(
          suggestion: s,
          isDark: isDark,
          showDivider: i < suggestions.length - 1,
          isRecent: isShowingRecents,
          onTap: () => onSelected(s),
        );
      },
    );
  }

  Widget _loadingRow() {
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.voltCyan,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Searching locations…',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual tile in the suggestions list.
class _SuggestionTile extends StatefulWidget {
  final LocationSuggestion suggestion;
  final bool isDark;
  final bool showDivider;
  final bool isRecent;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.isDark,
    required this.onTap,
    this.showDivider = true,
    this.isRecent = false,
  });

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final bg = _pressed ? AppColors.voltCyan.withValues(alpha: 0.12) : Colors.transparent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.voltCyan.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isRecent ? Icons.history : Icons.location_on,
                      size: 15,
                      color: AppColors.voltCyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.suggestion.shortName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.suggestion.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.suggestion.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_pressed)
                    const Icon(Icons.check, size: 14, color: AppColors.voltCyan),
                ],
              ),
            ),
            if (widget.showDivider)
              Divider(
                height: 1,
                indent: 58,
                endIndent: 0,
                color: (widget.isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
              ),
          ],
        ),
      ),
    );
  }
}
