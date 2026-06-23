import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class QuickReplyChips extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const QuickReplyChips({
    super.key,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final replies = [
      'Hey 👋',
      'Great job 🔥',
      'How was your run?',
      'Keep going 💪',
      'Want to run together?',
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.only(top: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final reply = replies[i];
          return ActionChip(
            label: Text(reply),
            onPressed: () => onSelect(reply),
            backgroundColor: AppColors.irisViolet.withValues(alpha: 0.1),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
}
