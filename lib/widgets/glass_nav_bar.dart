import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _NavDestination {
  final IconData icon;
  final String label;
  final int index;

  const _NavDestination({
    required this.icon,
    required this.label,
    required this.index,
  });
}

const _destinations = [
  _NavDestination(icon: LucideIcons.layoutDashboard, label: 'Home', index: 0),
  _NavDestination(icon: LucideIcons.heartPulse, label: 'Health', index: 1),
  _NavDestination(icon: LucideIcons.messageSquare, label: 'Chat', index: 3),
  _NavDestination(icon: LucideIcons.graduationCap, label: 'Study', index: 4),
];

// ─── Main Widget ──────────────────────────────────────────────────────────────

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      // Floating offset
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomPadding + 16,
      ),
      child: SizedBox(
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // ── Glass Container ──────────────────────────────────────────────
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      // Dark: near-transparent white glass
                      // Light: opaque white card with subtle border
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.07),
                        width: 1,
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Nav Items Row ────────────────────────────────────────────────
            Row(
              children: [
                // Left half: Dashboard, Health
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavTab(
                          destination: _destinations[0],
                          isActive: currentIndex == 0,
                          onTap: onTap,
                        ),
                      ),
                      Expanded(
                        child: _NavTab(
                          destination: _destinations[1],
                          isActive: currentIndex == 1,
                          onTap: onTap,
                        ),
                      ),
                    ],
                  ),
                ),
                // Center gap for floating button
                const SizedBox(width: 72),
                // Right half: Chat, Study
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavTab(
                          destination: _destinations[2],
                          isActive: currentIndex == 3,
                          onTap: onTap,
                        ),
                      ),
                      Expanded(
                        child: _NavTab(
                          destination: _destinations[3],
                          isActive: currentIndex == 4,
                          onTap: onTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Floating Center Button ───────────────────────────────────────
            Positioned(
              top: -16,
              child: _FloatingCenterButton(
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Tab ──────────────────────────────────────────────────────────────────

class _NavTab extends StatefulWidget {
  final _NavDestination destination;
  final bool isActive;
  final ValueChanged<int> onTap;

  const _NavTab({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTapDown(_) async {
    HapticFeedback.lightImpact();
    await _controller.forward();
    await _controller.reverse();
    widget.onTap(widget.destination.index);
  }

  @override
  Widget build(BuildContext context) {
    // Specific module accent colors based on design spec
    Color getAccentColor() {
      switch (widget.destination.index) {
        case 1:
          return AppColors.pulseRed; // Health
        case 4:
          return AppColors.irisViolet; // Study
        default:
          return AppColors.voltCyan; // Home/Chat default
      }
    }

    final activeColor = getAccentColor();
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTapDown: _onTapDown,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: widget.destination.label,
        button: true,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            color: Colors.transparent, // Ensures full tap area
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon + Optional Label inside pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isActive ? 12 : 8, 
                    vertical: 8
                  ),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? activeColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.destination.icon,
                        size: 20,
                        color: widget.isActive ? activeColor : inactiveColor,
                      ),
                      if (widget.isActive) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: activeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Small filled circle beneath icon when active
                AnimatedOpacity(
                  opacity: widget.isActive ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Floating Center Button ───────────────────────────────────────────────────

class _FloatingCenterButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _FloatingCenterButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FloatingCenterButton> createState() => _FloatingCenterButtonState();
}

class _FloatingCenterButtonState extends State<_FloatingCenterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTapDown(_) async {
    HapticFeedback.lightImpact();
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // Center button represents "Running" so it gets Volt Cyan / Pulse Red combo
    final gradient = widget.isActive
        ? AppColors.gradientCyan
        : AppColors.gradientCoral;

    final glowColor = widget.isActive
        ? AppColors.voltCyan.withValues(alpha: 0.35)
        : AppColors.pulseRed.withValues(alpha: 0.35);

    return GestureDetector(
      onTapDown: _onTapDown,
      child: Semantics(
        label: 'Run',
        button: true,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
