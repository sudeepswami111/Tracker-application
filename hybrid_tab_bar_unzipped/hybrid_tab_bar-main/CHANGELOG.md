# Changelog

All notable changes to the `hybrid_tab_bar` package will be documented in this file.

## [1.0.0] — 2026-04-15

### Added

- **`HybridTabBarScaffold`** — Main scaffold widget combining segmented control and bottom navigation inside a unified glassmorphism container.
- **`HybridSegmentedControl`** — Standalone segmented control with animated sliding pill indicator and neumorphic shadows.
- **`HybridBottomBar`** — Floating bottom navigation bar with its own distinct inner card (card-within-card design) and sliding pill indicator.
- **`HybridTabController`** — Dual-index `ChangeNotifier` controller managing `bottomIndex` and `segmentedIndex` with optional `PageController` sync.
- **`HybridNavItem`** — Navigation item data class with optional `segmentedTabs` — allowing per-item segmented sub-tabs.
- **`HybridTabStyle`** — Comprehensive styling configuration with 25+ properties including:
  - Separate pill colors for segmented control and bottom nav
  - Neumorphic dual-shadow system (light highlight + dark shadow)
  - Configurable blur, border radius, animation curves/durations
  - `copyWith` support
  - `light` and `dark` static presets
- **Animation constants** — Centralized durations and curves in `animations.dart`.
- **Animated show/hide** — Segmented control slides in with `AnimatedSize` + `AnimatedOpacity` when the active bottom item has sub-tabs.
- **Glassmorphism effects** — `BackdropFilter` blur, semi-transparent tint, 1px inner stroke.
- **Accessibility** — Full `Semantics` labels on all interactive elements.
- **Haptic feedback** — Optional `HapticFeedback.lightImpact()` on bottom nav taps.
- **Example app** — Fully working demo with 3 bottom items (one with segmented sub-tabs, two without).
- **Unit tests** — 9 tests covering controller, nav item, and style classes.
- **README** — Complete documentation with usage, customization, and architecture.
