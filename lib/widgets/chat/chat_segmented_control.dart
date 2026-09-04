import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(22),
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

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.secondaryBlue : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.textPrimary)
                  : (isDark ? Colors.white54 : AppColors.neutralGray),
            ),
          ),
        ),
      ),
    );
  }
}
