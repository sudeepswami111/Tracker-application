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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 72 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Glass Container ──────────────────────────────────────────────
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF111B33).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.90),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 24,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Nav Items Row ────────────────────────────────────────────────
          Positioned.fill(
            bottom: bottomPadding,
            child: Row(
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
                const SizedBox(width: 68),
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
  late final Animation<double> _pillWidth;

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
    _pillWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryLight;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.45);

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
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with subtle background pill when active
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? activeColor.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.destination.icon,
                    size: 22,
                    color: widget.isActive ? activeColor : inactiveColor,
                  ),
                ),
                const SizedBox(height: 3),
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isActive ? activeColor : inactiveColor,
                    letterSpacing: 0.2,
                  ),
                  child: Text(
                    widget.destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                // Active dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 3,
                  width: widget.isActive ? 18 : 0,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 0,
                            )
                          ]
                        : [],
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
    final gradient = widget.isActive
        ? const LinearGradient(
            colors: [Color(0xFF8B7CF6), Color(0xFF6C5CE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFF7B7B), Color(0xFFE84393)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final glowColor = widget.isActive
        ? AppColors.primary.withValues(alpha: 0.35)
        : AppColors.coral.withValues(alpha: 0.35);

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
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
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
