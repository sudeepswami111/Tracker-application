import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/dashboard_interaction_storage_service.dart';
import '../theme/app_colors.dart';

class SmartCalendarSheet extends StatefulWidget {
  const SmartCalendarSheet({super.key});

  @override
  State<SmartCalendarSheet> createState() => _SmartCalendarSheetState();
}

class _SmartCalendarSheetState extends State<SmartCalendarSheet> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadNoteForDay(_selectedDay!);
  }

  Future<void> _loadNoteForDay(DateTime date) async {
    final noteStr = await DashboardInteractionStorageService.getCalendarNote(date);
    setState(() {
      _noteController.text = noteStr ?? '';
    });
  }

  Future<void> _saveNote() async {
    if (_selectedDay == null || _noteController.text.trim().isEmpty) return;
    
    setState(() => _isSaving = true);
    
    await DashboardInteractionStorageService.saveCalendarNote(
      _selectedDay!,
      _noteController.text.trim(),
    );
    
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved!')));
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.calendarCheck, color: AppColors.voltCyan, size: 24),
                  const SizedBox(width: 8),
                  Text('Smart Calendar', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2023, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _loadNoteForDay(selectedDay);
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(color: AppColors.voltCyan, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: AppColors.voltCyan.withValues(alpha: 0.3), shape: BoxShape.circle),
                        markerDecoration: const BoxDecoration(color: AppColors.solarAmber, shape: BoxShape.circle),
                        selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Daily Note', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write a note or reminder for this day...',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.voltCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
