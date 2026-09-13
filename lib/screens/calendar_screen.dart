import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../widgets/botanical_decorations.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(2025, 9, 1);
  int _selectedDay = 16;

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calendar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Month Selector: < September 2025 > ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.textPrimary),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                    });
                  },
                ),
                Text(
                  monthName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textPrimary),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── 2. Calendar Grid Card ──
            _buildCalendarGrid(),
            const SizedBox(height: 14),

            // ── 3. Legend Dots: Workout, Study, Hydration, Run ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppColors.sageGreen, 'Workout'),
                const SizedBox(width: 14),
                _buildLegendItem(AppColors.lavender, 'Study'),
                const SizedBox(width: 14),
                _buildLegendItem(AppColors.skyBlue, 'Hydration'),
                const SizedBox(width: 14),
                _buildLegendItem(AppColors.accentOrange, 'Run'),
              ],
            ),
            const SizedBox(height: 24),

            // ── 4. Today's Schedule List (Today, 16 Sep) ──
            Text(
              'Today, $_selectedDay Sep',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _buildScheduleItem(
              icon: LucideIcons.footprints,
              iconColor: AppColors.sageGreen,
              iconBgColor: AppColors.mintLight,
              title: 'Morning Walk',
              time: '20 min',
            ),
            const SizedBox(height: 10),

            _buildScheduleItem(
              icon: LucideIcons.dumbbell,
              iconColor: AppColors.lavender,
              iconBgColor: AppColors.lavenderLight,
              title: 'Workout',
              time: '30 min',
            ),
            const SizedBox(height: 10),

            _buildScheduleItem(
              icon: LucideIcons.droplets,
              iconColor: AppColors.skyBlue,
              iconBgColor: AppColors.skyLight,
              title: 'Hydration',
              time: '1.8 / 2.5 L',
            ),
            const SizedBox(height: 10),

            _buildScheduleItem(
              icon: LucideIcons.bookOpen,
              iconColor: AppColors.accentOrange,
              iconBgColor: const Color(0xFFFEF3E8),
              title: 'Study',
              time: '45 min',
            ),
            const SizedBox(height: 20),

            // ── 5. Botanical Quote Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFE6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Consistency\ncreates results.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CustomPaint(
                      painter: BotanicalBranchPainter(
                        color: AppColors.sageGreen,
                        leafScale: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    const daysHeader = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // September 2025 grid simulation
    final days = [
      {'d': 25, 'cur': false}, {'d': 26, 'cur': false}, {'d': 27, 'cur': false}, {'d': 28, 'cur': false}, {'d': 29, 'cur': false}, {'d': 30, 'cur': false}, {'d': 1, 'cur': true},
      {'d': 2, 'cur': true}, {'d': 3, 'cur': true}, {'d': 4, 'cur': true}, {'d': 5, 'cur': true}, {'d': 6, 'cur': true}, {'d': 7, 'cur': true}, {'d': 8, 'cur': true},
      {'d': 9, 'cur': true}, {'d': 10, 'cur': true}, {'d': 11, 'cur': true}, {'d': 12, 'cur': true, 'done': true}, {'d': 13, 'cur': true}, {'d': 14, 'cur': true}, {'d': 15, 'cur': true},
      {'d': 16, 'cur': true, 'active': true}, {'d': 17, 'cur': true}, {'d': 18, 'cur': true}, {'d': 19, 'cur': true}, {'d': 20, 'cur': true}, {'d': 21, 'cur': true}, {'d': 22, 'cur': true},
      {'d': 23, 'cur': true}, {'d': 24, 'cur': true}, {'d': 25, 'cur': true}, {'d': 26, 'cur': true}, {'d': 27, 'cur': true}, {'d': 28, 'cur': true}, {'d': 29, 'cur': true},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysHeader
                .map((d) => SizedBox(
                      width: 36,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final dayItem = days[index];
              final d = dayItem['d'] as int;
              final isCurrentMonth = dayItem['cur'] as bool;
              final isSelected = dayItem['active'] == true || (_selectedDay == d && isCurrentMonth);
              final isDone = dayItem['done'] == true;

              return GestureDetector(
                onTap: isCurrentMonth
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDay = d);
                      }
                    : null,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.forestGreen
                          : (isDone ? const Color(0xFFE5F3E8) : Colors.transparent),
                    ),
                    child: Center(
                      child: Text(
                        '$d',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDone
                                  ? AppColors.sageGreen
                                  : (isCurrentMonth
                                      ? AppColors.textPrimary
                                      : const Color(0xFFC4CEC7))),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
