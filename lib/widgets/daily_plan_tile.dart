import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class DailyPlanTile extends StatelessWidget {
  final String activityName;
  final String durationOrReps;
  final String kcal;
  final String imageUrl;
  final bool isCompleted;
  final VoidCallback? onStart;
  final VoidCallback? onDelete;

  // Accent color drives the gradient + shadow — default to coral (Run)
  final Color accentColor;

  const DailyPlanTile({
    super.key,
    required this.activityName,
    required this.durationOrReps,
    required this.kcal,
    required this.imageUrl,
    this.isCompleted = false,
    this.onStart,
    this.onDelete,
    this.accentColor = const Color(0xFFFF3B5C),
  });

  // Choose gradient from accentColor
  LinearGradient get _accentGradient {
    if (accentColor == AppColors.voltCyan || accentColor == AppColors.irisViolet) {
      return AppColors.gradientCyan;
    }
    if (accentColor == AppColors.solarAmber) return AppColors.gradientAmber;
    return AppColors.gradientCoral;
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove this plan?',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('This will delete the plan from your list.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.pulseRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Activity image 80×80 ──
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceElevated,
                          child: const Icon(LucideIcons.dumbbell, color: AppColors.textSecondary, size: 28),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceElevated,
                          child: const Icon(LucideIcons.dumbbell, color: AppColors.textSecondary, size: 28),
                        ),
                      )
                    : Image.file(
                        File(imageUrl),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Right: Info + buttons ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with trash icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          activityName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: () => _confirmDelete(context),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6, top: 2),
                            child: Icon(LucideIcons.trash2, size: 16, color: AppColors.textSecondary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stats chips
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _StatChip(icon: LucideIcons.timer, label: durationOrReps),
                      _StatChip(icon: LucideIcons.zap, label: kcal),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // CTA button / Completed state
                  isCompleted
                      ? Row(
                          children: [
                            Icon(LucideIcons.checkCircle2, size: 18, color: AppColors.green),
                            const SizedBox(width: 6),
                            Text(
                              'Completed!',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: _accentGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: onStart,
                                child: const Center(
                                  child: Text(
                                    'Start Workout →',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return isCompleted ? Opacity(opacity: 0.65, child: card) : card;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}
