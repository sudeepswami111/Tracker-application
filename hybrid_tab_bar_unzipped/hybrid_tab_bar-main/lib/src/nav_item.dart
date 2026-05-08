import 'package:flutter/widgets.dart';

/// Represents a single item in the [HybridBottomBar].
///
/// Each item has an [icon] and a [label], displayed stacked vertically.
/// Optionally, an item can have [segmentedTabs] — a list of sub-tab labels
/// that appear in the segmented control when this bottom item is active.
///
/// Example:
/// ```dart
/// HybridNavItem(
///   icon: Icons.explore,
///   label: "Explore",
///   segmentedTabs: ["Rooms", "Inspiration", "Profiles"],
/// )
/// ```
class HybridNavItem {
  /// Creates a [HybridNavItem].
  const HybridNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.semanticLabel,
    this.segmentedTabs,
  });

  /// The icon displayed when the item is inactive.
  final IconData icon;

  /// The icon displayed when the item is active. Defaults to [icon].
  final IconData? activeIcon;

  /// The label displayed below the icon.
  final String label;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  /// Optional list of sub-tab labels shown in the segmented control
  /// when this bottom item is selected. If `null` or empty, no
  /// segmented control is shown.
  final List<String>? segmentedTabs;

  /// Whether this item has segmented sub-tabs.
  bool get hasSegmentedTabs =>
      segmentedTabs != null && segmentedTabs!.isNotEmpty;
}
