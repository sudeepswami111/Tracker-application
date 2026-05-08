import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  bool _isSearchVisible = false;
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Running', 'Fitness', 'Study', 'Nutrition', 'Sleep'];

  // Mock data for activities
  final List<Map<String, dynamic>> _activities = [
    {
      'date': 'Today, 8 May',
      'items': [
        {'type': 'Running', 'title': 'Morning 5K', 'detail': '5.2 km • 24:10', 'time': '07:30', 'icon': LucideIcons.footprints, 'color': AppColors.voltCyan},
        {'type': 'Study', 'title': 'Deep Work #3', 'detail': '1h 30m • Focus', 'time': '09:00', 'icon': LucideIcons.bookOpen, 'color': AppColors.irisViolet},
      ]
    },
    {
      'date': 'Yesterday, 7 May',
      'items': [
        {'type': 'Fitness', 'title': 'Upper Body Power', 'detail': '45 min • 320 kcal', 'time': '18:15', 'icon': LucideIcons.dumbbell, 'color': AppColors.pulseRed},
        {'type': 'Nutrition', 'title': 'Daily Summary', 'detail': '2,450 kcal • 120g P', 'time': '22:00', 'icon': LucideIcons.apple, 'color': AppColors.solarAmber},
      ]
    }
  ];

  void _showDetailSheet(Map<String, dynamic> item, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: (item['color'] as Color).withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('${item['time']} • ${item['detail']}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (item['type'] == 'Running') ...[
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Icon(LucideIcons.map, size: 48, color: item['color'] as Color)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _detailStat('Avg Pace', '4:38/km', isDark),
                    _detailStat('Elevation', '42m', isDark),
                    _detailStat('Avg HR', '152 bpm', isDark),
                  ],
                ),
              ],
              if (item['type'] == 'Study') ...[
                _detailStat('Focus Score', '92%', isDark),
                const SizedBox(height: 16),
                _detailStat('Tasks Completed', '3', isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('History', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.search, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          setState(() => _isSearchVisible = !_isSearchVisible);
                        },
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.filter, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. SEARCH BAR
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: _isSearchVisible ? 70 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _isSearchVisible
                  ? TextField(
                      decoration: InputDecoration(
                        hintText: "Search activities...",
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    )
                  : null,
            ),

            // 3. FILTER CHIPS ROW
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filters.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ActionChip(
                      label: const Row(
                        children: [
                          Text('This Week'),
                          SizedBox(width: 4),
                          Icon(LucideIcons.chevronDown, size: 14),
                        ],
                      ),
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      side: BorderSide.none,
                      onPressed: () {},
                    );
                  }
                  final filter = _filters[index - 1];
                  final isActive = filter == _activeFilter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isActive,
                    onSelected: (val) {
                      if (val) setState(() => _activeFilter = filter);
                    },
                    selectedColor: AppColors.voltCyan,
                    labelStyle: TextStyle(color: isActive ? Colors.black : theme.colorScheme.onSurfaceVariant, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                    backgroundColor: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
                    side: BorderSide.none,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // 4. MONTHLY SUMMARY CARD
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('May 2026 Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                            Icon(LucideIcons.chevronUp, size: 16),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _summaryPill('12', 'Workouts'),
                            _summaryPill('42 km', 'Distance'),
                            _summaryPill('28h', 'Focus'),
                            _summaryPill('2,450', 'Avg Kcal'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. CALENDAR HEATMAP
                  Text('Activity Heatmap', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _HeatmapPainter(isDark: isDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 6. ACTIVITY LIST
                  if (_activities.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(LucideIcons.calendarX, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('No activities yet.', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Start your first run, workout, or study session.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._activities.map((group) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 8),
                            child: Text(group['date'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          ...(group['items'] as List).map((item) {
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _showDetailSheet(item as Map<String, dynamic>, isDark);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: (item['color'] as Color).withValues(alpha: 0.2), shape: BoxShape.circle),
                                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text(item['detail'] as String, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(item['time'] as String, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                        const SizedBox(height: 4),
                                        Icon(LucideIcons.chevronRight, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  
                  const SizedBox(height: 24),
                  
                  // 9. EXPORT CTA
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(LucideIcons.download, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    label: Text('Export to CSV / PDF', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  
                  const SizedBox(height: 100), // Nav bar padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryPill(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final bool isDark;

  _HeatmapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 5 weeks (cols), 7 days (rows)
    final cols = 5;
    final rows = 7;
    final cellSize = 12.0;
    final spacing = 4.0;
    
    // Center the grid
    final totalWidth = cols * cellSize + (cols - 1) * spacing;
    final totalHeight = rows * cellSize + (rows - 1) * spacing;
    final startX = (size.width - totalWidth) / 2;
    final startY = (size.height - totalHeight) / 2;

    final bgPaint = Paint()..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    // Generate mock intensity
    final intensities = [
      [0, 1, 0, 2, 3, 0, 1],
      [1, 2, 3, 1, 0, 0, 2],
      [2, 3, 2, 1, 1, 0, 0],
      [3, 2, 1, 0, 0, 0, 1],
      [1, 0, 0, 1, 2, 3, 2],
    ];

    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        final intensity = intensities[col][row];
        
        Color fill;
        if (intensity == 0) {
          fill = bgPaint.color;
        } else if (intensity == 1) {
          fill = AppColors.voltCyan.withValues(alpha: 0.33);
        } else if (intensity == 2) {
          fill = AppColors.voltCyan.withValues(alpha: 0.66);
        } else {
          fill = AppColors.voltCyan;
        }

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + col * (cellSize + spacing), 
            startY + row * (cellSize + spacing), 
            cellSize, 
            cellSize
          ),
          const Radius.circular(3),
        );

        canvas.drawRRect(rect, Paint()..color = fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
