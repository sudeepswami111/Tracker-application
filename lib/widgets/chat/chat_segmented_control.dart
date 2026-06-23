import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ChatSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const ChatSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildSegmentButton(context, 'Chats', 0, isDark),
          _buildSegmentButton(context, 'Community', 1, isDark),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context,
    String title,
    int index,
    bool isDark,
  ) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.irisViolet : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
