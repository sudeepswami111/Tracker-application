import 'dart:ui';

import 'package:flutter/material.dart';

import 'styles.dart';

/// A glassmorphism segmented control with an animated sliding pill indicator.
///
/// The active tab is highlighted by a soft blue-grey pill that slides
/// smoothly between positions.
class HybridSegmentedControl extends StatefulWidget {
  const HybridSegmentedControl({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabChanged,
    this.style = const HybridTabStyle(),
    this.showContainer = false,
  });

  /// Labels for each tab.
  final List<String> tabs;

  /// Currently active tab index.
  final int currentIndex;

  /// Called when a tab is tapped.
  final ValueChanged<int> onTabChanged;

  /// Visual style configuration.
  final HybridTabStyle style;

  /// Whether to wrap in its own glass container (standalone mode).
  final bool showContainer;

  @override
  State<HybridSegmentedControl> createState() => _HybridSegmentedControlState();
}

class _HybridSegmentedControlState extends State<HybridSegmentedControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.style.pillAnimationDuration,
    );
    _animation = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.style.animationCurve,
    ));
  }

  @override
  void didUpdateWidget(covariant HybridSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animation = Tween<double>(
        begin: oldWidget.currentIndex.toDouble(),
        end: widget.currentIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.style.animationCurve,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final activeColor = style.resolveActiveColor(context);
    final inactiveColor = style.resolveInactiveColor(context);
    final pillColor = style.resolveSegmentedPillColor(context);

    Widget content = Padding(
      padding: style.indicatorPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabCount = widget.tabs.length;
          final pillWidth = constraints.maxWidth / tabCount;

          return SizedBox(
            height: 44,
            child: Stack(
              children: [
                // ── Sliding Pill ──
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    return Positioned(
                      left: _animation.value * pillWidth,
                      top: 0,
                      bottom: 0,
                      width: pillWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(style.segmentedPillRadius),
                          color: pillColor,
                          boxShadow: [
                            // Inner neumorphic feel on the pill
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.60),
                              blurRadius: 3,
                              offset: const Offset(-1, -1),
                            ),
                            BoxShadow(
                              color: const Color(0xFFB0B8C8)
                                  .withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // ── Tab Labels ──
                Row(
                  children: List.generate(tabCount, (i) {
                    final isActive = i == widget.currentIndex;
                    return Expanded(
                      child: Semantics(
                        label: widget.tabs[i],
                        selected: isActive,
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onTabChanged(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeIn,
                              style: (isActive
                                      ? style.activeSegmentedLabelStyle
                                      : style.segmentedLabelStyle) ??
                                  TextStyle(
                                    fontSize: 14,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color:
                                        isActive ? activeColor : inactiveColor,
                                    decoration: TextDecoration.none,
                                  ),
                              child: AnimatedScale(
                                scale: isActive ? 1.03 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                child: Text(widget.tabs[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (!widget.showContainer) return RepaintBoundary(child: content);

    return RepaintBoundary(
      child: _GlassContainer(style: style, child: content),
    );
  }
}

/// Reusable glass container.
class _GlassContainer extends StatelessWidget {
  const _GlassContainer({required this.style, required this.child});

  final HybridTabStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glassTint = style.resolveGlassTint(context);

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
      child: child,
    );

    if (!style.enableBlur) return container;

    return ClipRRect(
      borderRadius: BorderRadius.circular(style.outerBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: style.blurAmount,
          sigmaY: style.blurAmount,
        ),
        child: container,
      ),
    );
  }
}
