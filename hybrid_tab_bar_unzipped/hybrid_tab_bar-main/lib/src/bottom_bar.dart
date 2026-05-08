import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nav_item.dart';
import 'styles.dart';

/// A bottom navigation bar with an animated sliding pill indicator,
/// wrapped in its own distinct inner container.
///
/// In the Dribbble reference, the bottom nav sits inside its own
/// rounded, more opaque card — creating a card-within-card look
/// when placed inside the outer glass container.
class HybridBottomBar extends StatefulWidget {
  const HybridBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemTapped,
    this.style = const HybridTabStyle(),
    this.showContainer = false,
  });

  /// Navigation items.
  final List<HybridNavItem> items;

  /// Currently active item index.
  final int currentIndex;

  /// Called when an item is tapped.
  final ValueChanged<int> onItemTapped;

  /// Visual style configuration.
  final HybridTabStyle style;

  /// Whether to wrap in an external glass container (standalone mode).
  final bool showContainer;

  @override
  State<HybridBottomBar> createState() => _HybridBottomBarState();
}

class _HybridBottomBarState extends State<HybridBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillController;
  late Animation<double> _pillAnimation;

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: widget.style.iconAnimationDuration,
    );
    _pillAnimation = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _pillController,
      curve: widget.style.animationCurve,
    ));
  }

  @override
  void didUpdateWidget(covariant HybridBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _pillAnimation = Tween<double>(
        begin: oldWidget.currentIndex.toDouble(),
        end: widget.currentIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _pillController,
        curve: widget.style.animationCurve,
      ));
      _pillController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final activeColor = style.resolveActiveColor(context);
    final inactiveColor = style.resolveInactiveColor(context);
    final pillColor = style.resolveBottomPillColor(context);

    // ── Inner container (the distinct nav bar card) ──
    Widget innerCard = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(style.bottomPillRadius + 4),
        color: Colors.white.withValues(alpha: 0.85),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.60),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.50),
            blurRadius: 3,
            offset: const Offset(-1, -1),
          ),
          BoxShadow(
            color: const Color(0xFFB0B8C8).withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemCount = widget.items.length;
            final pillWidth = constraints.maxWidth / itemCount;

            return SizedBox(
              height: 68,
              child: Stack(
                children: [
                  // ── Sliding active pill ──
                  AnimatedBuilder(
                    animation: _pillAnimation,
                    builder: (context, _) {
                      return Positioned(
                        left: _pillAnimation.value * pillWidth,
                        top: 0,
                        bottom: 0,
                        width: pillWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(style.bottomPillRadius),
                            color: pillColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.45),
                                blurRadius: 2,
                                offset: const Offset(-1, -1),
                              ),
                              BoxShadow(
                                color: const Color(0xFFB0B8C8)
                                    .withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // ── Nav items ──
                  Row(
                    children: List.generate(itemCount, (i) {
                      final isActive = i == widget.currentIndex;
                      final item = widget.items[i];
                      final iconData =
                          isActive ? (item.activeIcon ?? item.icon) : item.icon;

                      return Expanded(
                        child: Semantics(
                          label: item.semanticLabel ?? item.label,
                          selected: isActive,
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (style.enableHaptics) {
                                HapticFeedback.lightImpact();
                              }
                              widget.onItemTapped(i);
                            },
                            child: AnimatedOpacity(
                              opacity: isActive ? 1.0 : style.inactiveOpacity,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeIn,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    iconData,
                                    size: 24,
                                    color:
                                        isActive ? activeColor : inactiveColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: (isActive
                                            ? style.activeBottomLabelStyle
                                            : style.bottomLabelStyle) ??
                                        TextStyle(
                                          fontSize: 12,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isActive
                                              ? activeColor
                                              : inactiveColor,
                                          decoration: TextDecoration.none,
                                        ),
                                  ),
                                ],
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
      ),
    );

    if (!widget.showContainer) return RepaintBoundary(child: innerCard);

    // Standalone mode: wrap in external glass container too
    return RepaintBoundary(
      child: _StandaloneGlassContainer(style: style, child: innerCard),
    );
  }
}

/// External glass container for standalone mode.
class _StandaloneGlassContainer extends StatelessWidget {
  const _StandaloneGlassContainer({required this.style, required this.child});

  final HybridTabStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glassTint = style.resolveGlassTint(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(style.outerBorderRadius),
        color: glassTint.withValues(alpha: style.glassTintOpacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: style.glassBorderOpacity),
          width: 1,
        ),
        boxShadow: style.resolveContainerShadows(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    );
  }
}
