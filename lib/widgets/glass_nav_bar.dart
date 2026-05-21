import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        // Floating offset above the bottom edge
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 16,
        ),
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ── Glass Container ──────────────────────────────────────────────
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        // Semi-transparent dark premium background in dark mode
                        color: isDark
                            ? const Color(0xFF151515).withValues(alpha: 0.75)
                            : Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
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
                top: -24, // Moved slightly higher than nav bar to be prominent
                child: _FloatingCenterButton(
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;

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
            height: 72,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? activeColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.destination.icon,
                    size: 24, // Consistent icon size 24px
                    color: widget.isActive ? activeColor : inactiveColor,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: widget.isActive ? activeColor : inactiveColor,
                      fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
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
