import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Activity History'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: app.history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.calendarX,
                      size: 64,
                      color: isDark
                          ? Colors.white24
                          : Colors.black12),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your daily stats will appear here\nafter the first midnight reset.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: app.history.length,
              itemBuilder: (context, index) {
                return _DayHistoryCard(
                    snapshot: app.history[index]);
              },
            ),
    );
  }
}

// ──── Expandable Day Card ────
class _DayHistoryCard extends StatefulWidget {
  final DailySnapshot snapshot;
  const _DayHistoryCard({required this.snapshot});

  @override
  State<_DayHistoryCard> createState() => _DayHistoryCardState();
}

class _DayHistoryCardState extends State<_DayHistoryCard> {
  bool _expanded = false;

  /// Parses 'yyyy-MM-dd' into a human-readable 'Mon, 5 May'
  String _formatDate(String raw) {
    try {
      final parts = raw.split('-');
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      const days = [
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
      ];
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month]}';
    } catch (_) {
      return raw;
    }
  }

  Color _pulseColor(int score) {
    if (score >= 80) return AppColors.green;
    if (score >= 50) return AppColors.yellow;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer.withValues(alpha: 0.7)
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                // Date
                Expanded(
                  child: Text(
                    _formatDate(s.date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Pulse Score badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _pulseColor(s.pulseScore)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _pulseColor(s.pulseScore)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.zap,
                          size: 12,
                          color: _pulseColor(s.pulseScore)),
                      const SizedBox(width: 4),
                      Text(
                        '${s.pulseScore}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _pulseColor(s.pulseScore),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Expand chevron
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Summary row: 4 quick metrics ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricChip(
                    icon: LucideIcons.footprints,
                    value: '${s.steps}',
                    label: 'steps',
                    color: AppColors.primary),
                _MetricChip(
                    icon: LucideIcons.flame,
                    value: '${s.calories}',
                    label: 'kcal',
                    color: AppColors.coral),
                _MetricChip(
                    icon: LucideIcons.mapPin,
                    value: s.distanceKm.toStringAsFixed(1),
                    label: 'km',
                    color: AppColors.blue),
                _MetricChip(
                    icon: LucideIcons.moon,
                    value: s.sleepHours.toStringAsFixed(1),
                    label: 'hrs',
                    color: AppColors.green),
              ],
            ),

            // ── Expanded detail grid ──
            if (_expanded) ...[
              const SizedBox(height: 16),
              Divider(
                  color:
                      isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DetailTile(
                      label: 'Steps',
                      value: '${s.steps}',
                      icon: LucideIcons.footprints,
                      color: AppColors.primary),
                  _DetailTile(
                      label: 'Calories',
                      value: '${s.calories} kcal',
                      icon: LucideIcons.flame,
                      color: AppColors.coral),
                  _DetailTile(
                      label: 'Distance',
                      value:
                          '${s.distanceKm.toStringAsFixed(2)} km',
                      icon: LucideIcons.mapPin,
                      color: AppColors.blue),
                  _DetailTile(
                      label: 'Sleep',
                      value:
                          '${s.sleepHours.toStringAsFixed(1)} hrs',
                      icon: LucideIcons.moon,
                      color: AppColors.green),
                  _DetailTile(
                      label: 'Water',
                      value:
                          '${s.waterGlasses} glasses\n(${s.waterIntake.toStringAsFixed(2)} L)',
                      icon: LucideIcons.droplets,
                      color: AppColors.secondary),
                  _DetailTile(
                      label: 'Study',
                      value:
                          '${s.studyHrs.toStringAsFixed(1)} hrs',
                      icon: LucideIcons.bookOpen,
                      color: AppColors.pink),
                  _DetailTile(
                      label: 'Pulse Score',
                      value: '${s.pulseScore} / 100',
                      icon: LucideIcons.heartPulse,
                      color: _pulseColor(s.pulseScore)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontSize: 9, letterSpacing: 0.5)),
                Text(value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white
                          : Colors.black87,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
