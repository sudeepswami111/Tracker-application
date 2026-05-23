import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class CreateChallengeSheet extends StatefulWidget {
  final Function(Map<String, dynamic>)? onChallengeCreated;

  const CreateChallengeSheet({super.key, this.onChallengeCreated});

  @override
  State<CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<CreateChallengeSheet> {
  final _titleController = TextEditingController();
  final _stakesController = TextEditingController();
  
  String _selectedGoal = 'Distance';
  String _selectedDifficulty = 'Medium';
  double _goalValue = 100.0;
  
  final List<String> _goals = ['Distance', 'Steps', 'Workouts'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard', 'Extreme'];
  
  final List<String> _ideas = [
    "Mount Everest Base Camp",
    "7-Day Zen Mode",
    "100K Step Challenge",
    "Couch to 5K Sprint",
    "Iron Man Prep Month",
    "No-Sugar Week"
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _stakesController.dispose();
    super.dispose();
  }
  
  void _generateIdea() {
    HapticFeedback.lightImpact();
    setState(() {
      _titleController.text = _ideas[Random().nextInt(_ideas.length)];
    });
  }

  Color _getDifficultyColor(String diff) {
    switch (diff) {
      case 'Easy': return AppColors.green;
      case 'Medium': return AppColors.solarAmber;
      case 'Hard': return AppColors.pulseRed;
      case 'Extreme': return AppColors.irisViolet;
      default: return AppColors.primary;
    }
  }

  void _createChallenge() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a challenge name!')));
      return;
    }
    
    String tier = 'Bronze';
    if (_selectedDifficulty == 'Medium') tier = 'Silver';
    if (_selectedDifficulty == 'Hard') tier = 'Gold';
    if (_selectedDifficulty == 'Extreme') tier = 'Diamond';

    final challenge = {
      'title': _titleController.text.trim(),
      'tier': tier,
      'current': 0.0,
      'total': _goalValue,
      'rank': 1,
      'goalType': _selectedGoal,
      'stakes': _stakesController.text.trim(),
    };
    
    widget.onChallengeCreated?.call(challenge);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final diffColor = _getDifficultyColor(_selectedDifficulty);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: diffColor.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 10),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Challenge', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black12),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Name & AI Generator
              Text('Challenge Name', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: "e.g. 30 Days of Running",
                        filled: true,
                        fillColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _generateIdea,
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.irisViolet, AppColors.voltCyan]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.sparkles, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Goal Type
              Text('Goal Type', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: _goals.map((g) {
                  final active = _selectedGoal == g;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGoal = g),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: active ? AppColors.voltCyan.withValues(alpha: 0.15) : (isDark ? AppColors.backgroundDeep : AppColors.lightBg),
                          border: Border.all(color: active ? AppColors.voltCyan : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(g, style: TextStyle(
                            color: active ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black),
                            fontWeight: active ? FontWeight.bold : FontWeight.w600,
                          )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Stakes (Wager)
              Row(
                children: [
                  const Icon(LucideIcons.dice5, color: AppColors.solarAmber, size: 20),
                  const SizedBox(width: 8),
                  Text('Set the Stakes (Optional)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.solarAmber)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _stakesController,
                decoration: InputDecoration(
                  hintText: "e.g. If I fail, I donate \$10",
                  filled: true,
                  fillColor: AppColors.solarAmber.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.solarAmber.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.solarAmber, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Difficulty
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Difficulty', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(_selectedDifficulty, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: diffColor)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: _difficulties.map((d) {
                  final active = _selectedDifficulty == d;
                  final c = _getDifficultyColor(d);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedDifficulty = d;
                        if (d == 'Easy') _goalValue = 10.0;
                        if (d == 'Medium') _goalValue = 30.0;
                        if (d == 'Hard') _goalValue = 100.0;
                        if (d == 'Extreme') _goalValue = 500.0;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 4),
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? c : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: active ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)] : [],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: diffColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: diffColor.withValues(alpha: 0.5),
                  ),
                  onPressed: _createChallenge,
                  child: const Text('Create Challenge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
