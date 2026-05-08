import 'dart:ui';

import 'package:flutter/material.dart';

import 'bottom_bar.dart';
import 'controller.dart';
import 'nav_item.dart';
import 'segmented_control.dart';
import 'styles.dart';

/// A unified hybrid scaffold that renders a **single glass container** at the
/// bottom of the screen containing a [HybridBottomBar] and, when the active
/// bottom item has sub-tabs, a [HybridSegmentedControl] that animates in
/// above it.
///
/// This matches the Dribbble reference where tapping "Explore" shows
/// segmented tabs while tapping "Assistant" hides them.
///
/// ```dart
/// HybridTabBarScaffold(
///   bottomItems: [
///     HybridNavItem(
///       icon: Icons.explore,
///       label: "Explore",
///       segmentedTabs: ["Rooms", "Inspiration", "Profiles"],
///     ),
///     HybridNavItem(icon: Icons.auto_awesome, label: "Assistant"),
///     HybridNavItem(icon: Icons.settings, label: "Configs"),
///   ],
///   bodyBuilder: (bottomIndex, segmentedIndex) => ...,
/// )
/// ```
class HybridTabBarScaffold extends StatefulWidget {
  const HybridTabBarScaffold({
    super.key,
    required this.bottomItems,
    this.bodyBuilder,
    this.controller,
    this.style = const HybridTabStyle(),
    this.backgroundColor,
    this.barPadding =
        const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 4),
    this.floatingActionButton,
    this.appBar,
  });

  /// Bottom navigation items. Each can optionally carry [segmentedTabs].
  final List<HybridNavItem> bottomItems;

  /// Builds the body from the current indices.
  /// Receives [bottomIndex] and [segmentedIndex].
  final Widget Function(int bottomIndex, int segmentedIndex)? bodyBuilder;

  /// Optional external controller.
  final HybridTabController? controller;

  /// Visual style configuration.
  final HybridTabStyle style;

  /// Scaffold background colour.
  final Color? backgroundColor;

  /// Padding around the unified glass bar.
  final EdgeInsets barPadding;

  /// Optional FAB.
  final Widget? floatingActionButton;

  /// Optional app bar.
  final PreferredSizeWidget? appBar;

  @override
  State<HybridTabBarScaffold> createState() => _HybridTabBarScaffoldState();
}

class _HybridTabBarScaffoldState extends State<HybridTabBarScaffold> {
  late HybridTabController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = HybridTabController(
        bottomLength: widget.bottomItems.length,
      );
      _ownsController = true;
    }
    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant HybridTabBarScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_rebuild);
      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
      } else {
        _controller = HybridTabController(
          bottomLength: widget.bottomItems.length,
        );
        _ownsController = true;
      }
      _controller.addListener(_rebuild);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onBottomTapped(int index) => _controller.setBottomIndex(index);

  void _onSegmentedTapped(int index) => _controller.setSegmentedIndex(index);

  /// Whether the currently active bottom item has segmented sub-tabs.
  bool get _showSegmented =>
      widget.bottomItems[_controller.bottomIndex].hasSegmentedTabs;

  List<String> get _currentSegmentedTabs =>
      widget.bottomItems[_controller.bottomIndex].segmentedTabs ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: widget.appBar,
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        child: Column(
          children: [
            // ── Body ──
            Expanded(
              child: widget.bodyBuilder?.call(
                    _controller.bottomIndex,
                    _controller.segmentedIndex,
                  ) ??
                  const SizedBox.shrink(),
            ),
            // ── Unified Glass Nav Bar ──
            Padding(
              padding: widget.barPadding,
              child: _UnifiedNavBar(
                bottomItems: widget.bottomItems,
                bottomIndex: _controller.bottomIndex,
                segmentedTabs: _currentSegmentedTabs,
                segmentedIndex: _controller.segmentedIndex,
                showSegmented: _showSegmented,
                onBottomTapped: _onBottomTapped,
                onSegmentedTapped: _onSegmentedTapped,
                style: widget.style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Single unified glass container with both rows
// ═══════════════════════════════════════════════════════════════════

class _UnifiedNavBar extends StatelessWidget {
  const _UnifiedNavBar({
    required this.bottomItems,
    required this.bottomIndex,
    required this.segmentedTabs,
    required this.segmentedIndex,
    required this.showSegmented,
    required this.onBottomTapped,
    required this.onSegmentedTapped,
    required this.style,
  });

  final List<HybridNavItem> bottomItems;
  final int bottomIndex;
  final List<String> segmentedTabs;
  final int segmentedIndex;
  final bool showSegmented;
  final ValueChanged<int> onBottomTapped;
  final ValueChanged<int> onSegmentedTapped;
  final HybridTabStyle style;

  @override
  Widget build(BuildContext context) {
    final glassTint = style.resolveGlassTint(context);

    Widget innerContent = Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Segmented Control (animated show / hide) ──
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedOpacity(
              opacity: showSegmented ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
              child: showSegmented
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: HybridSegmentedControl(
                        tabs: segmentedTabs,
                        currentIndex: segmentedIndex,
                        onTabChanged: onSegmentedTapped,
                        style: style,
                        showContainer: false,
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),
          // ── Bottom Nav (inner card) ──
          HybridBottomBar(
            items: bottomItems,
            currentIndex: bottomIndex,
            onItemTapped: onBottomTapped,
            style: style,
            showContainer: false,
          ),
        ],
      ),
    );

    // ── Glass container ──
    final container = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(style.outerBorderRadius),
        color: glassTint.withValues(alpha: style.glassTintOpacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: style.glassBorderOpacity),
          width: 1,
        ),
        boxShadow: style.resolveContainerShadows(),
      ),
      child: innerContent,
    );

    if (!style.enableBlur) return RepaintBoundary(child: container);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(style.outerBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: style.blurAmount,
            sigmaY: style.blurAmount,
          ),
          child: container,
        ),
      ),
    );
  }
}
