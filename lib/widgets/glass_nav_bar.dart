import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/app_provider.dart';

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
              // ── Navigation Bar Surface ──
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF131F2E).withValues(alpha: 0.92)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.cardBorder,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
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
                  // Left half: Home, Health
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
                  // Center gap for floating RUN button
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

              // ── Floating Center RUN Button ──
              Positioned(
                top: -20,
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
    Color getAccentColor() {
      switch (widget.destination.index) {
        case 0:
          return AppColors.primaryTeal;
        case 1:
          return AppColors.primaryTeal;
        case 3:
          return AppColors.primaryTeal;
        case 4:
          return AppColors.secondaryBlue;
        default:
          return AppColors.primaryTeal;
      }
    }

    final activeColor = getAccentColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final app = context.watch<AppProvider>();
    final showChatBadge = widget.destination.index == 3 && app.unreadChatCount > 0;

    Widget iconWidget = Icon(
      widget.destination.icon,
      size: 22,
      color: widget.isActive ? activeColor : inactiveColor,
    );

    if (showChatBadge) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              decoration: const BoxDecoration(
                color: AppColors.accentCoral,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  app.unreadChatCount > 99 ? '99+' : '${app.unreadChatCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: widget.destination.label,
        button: true,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            color: Colors.transparent,
            height: 72,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(height: 3),
                  Text(
                    widget.destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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
    return GestureDetector(
      onTapDown: _onTapDown,
      child: Semantics(
        label: 'Run',
        button: true,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryTeal, Color(0xFF00D8C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white,
                width: 2.5,
              ),
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
