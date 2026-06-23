import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onSend;
  final VoidCallback onPlusTap;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.sending,
    required this.isDark,
    required this.theme,
    required this.onSend,
    required this.onPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDeep : Colors.white,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.irisViolet),
            onPressed: onPlusTap,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message…',
                filled: true,
                fillColor: isDark
                    ? AppColors.surfaceElevated
                    : AppColors.lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final hasText = value.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: (hasText && !sending) ? onSend : null,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hasText
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceElevated : Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          hasText ? LucideIcons.send : LucideIcons.mic,
                          color: hasText ? Colors.white : Colors.grey,
                          size: 18,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
