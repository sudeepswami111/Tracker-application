import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/dashboard_interaction_storage_service.dart';
import '../theme/app_colors.dart';

class DailyThoughtSheet extends StatefulWidget {
  final String quote;
  final String author;

  const DailyThoughtSheet({super.key, required this.quote, required this.author});

  @override
  State<DailyThoughtSheet> createState() => _DailyThoughtSheetState();
}

class _DailyThoughtSheetState extends State<DailyThoughtSheet> {
  final TextEditingController _reflectionController = TextEditingController();
  String? _selectedMood;
  bool _isSaved = false;

  final List<String> moods = ['Happy', 'Tired', 'Focused', 'Stressed', 'Motivated'];

  @override
  void initState() {
    super.initState();
    _loadReflection();
  }

  Future<void> _loadReflection() async {
    final now = DateTime.now();
    final mood = await DashboardInteractionStorageService.getDailyMood(now);
    final reflection = await DashboardInteractionStorageService.getDailyReflection(now);
    setState(() {
      _selectedMood = mood;
      _reflectionController.text = reflection ?? '';
      _isSaved = (reflection != null && reflection.isNotEmpty);
    });
  }

  Future<void> _saveMood(String mood) async {
    setState(() {
      _selectedMood = mood;
      _isSaved = false;
    });
    await DashboardInteractionStorageService.saveDailyMood(DateTime.now(), mood);
  }

  Future<void> _saveReflection() async {
    if (_reflectionController.text.isEmpty) return;

    await DashboardInteractionStorageService.saveDailyReflection(DateTime.now(), _reflectionController.text);
    
    setState(() {
      _isSaved = true;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reflection saved!')));
    }
  }

  @override
  void dispose() {
    _reflectionController.dispose();
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.sparkles, color: AppColors.solarAmber, size: 24),
                    const SizedBox(width: 8),
                    Text('Daily Thought', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '"${widget.quote}"',
              style: theme.textTheme.titleLarge?.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '— ${widget.author}',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 32),
            Text('How are you feeling today?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moods.map((mood) {
                final isSelected = _selectedMood == mood;
                return ChoiceChip(
                  label: Text(mood),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _saveMood(mood);
                    } else {
                      _saveMood('');
                    }
                  },
                  selectedColor: AppColors.irisViolet.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: isSelected ? AppColors.irisViolet : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reflectionController,
              maxLines: 3,
              onChanged: (_) => setState(() => _isSaved = false),
              decoration: InputDecoration(
                hintText: 'Write a short reflection...',
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveReflection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.irisViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_isSaved ? 'Saved' : 'Save Reflection', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
