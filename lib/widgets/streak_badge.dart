import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StreakBadge extends StatefulWidget {
  final int count;
  final bool isActive;
  final IconData icon;
  final Color activeColor;
  
  const StreakBadge({
    super.key,
    required this.count,
    required this.isActive,
    required this.icon,
    this.activeColor = AppColors.solarAmber,
  });

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _countAnimation = IntTween(begin: 0, end: widget.count).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _controller.duration = const Duration(milliseconds: 800);
      _countAnimation = IntTween(begin: oldWidget.count, end: widget.count).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = widget.isActive
        ? widget.activeColor.withValues(alpha: 0.15)
        : Colors.transparent;

    final borderColor = widget.isActive
        ? widget.activeColor.withValues(alpha: 0.3)
        : theme.colorScheme.outline;

    final contentColor = widget.isActive
        ? widget.activeColor
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 16, color: contentColor),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              return Text(
                '${_countAnimation.value}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
