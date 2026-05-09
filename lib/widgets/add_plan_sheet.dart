import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AddPlanSheet extends StatefulWidget {
  const AddPlanSheet({super.key});

  @override
  State<AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<AddPlanSheet> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _kcalController = TextEditingController();

  final List<String> _galleryImages = [
    'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=150&q=80', // Run
    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=150&q=80', // Yoga
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=150&q=80', // Weights
    'https://images.unsplash.com/photo-1519315901367-f34f9273400a?auto=format&fit=crop&w=150&q=80', // Swim
    'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=150&q=80', // Cycle
  ];

  String? _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = _galleryImages.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  void _savePlan() {
    if (_titleController.text.isEmpty ||
        _durationController.text.isEmpty ||
        _kcalController.text.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select an image.')),
      );
      return;
    }

    final newPlan = DailyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      duration: _durationController.text,
      kcal: _kcalController.text,
      imageUrl: _selectedImage!,
    );

    context.read<AppProvider>().addDailyPlan(newPlan);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add New Plan', style: theme.textTheme.headlineMedium),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Plan Title (e.g., Morning Run 5K)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: 'Timer / Duration',
                      hintText: '30 min',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _kcalController,
                    decoration: InputDecoration(
                      labelText: 'Kcal Burn',
                      hintText: '320 kcal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Select Logo / Image', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _galleryImages.length,
                itemBuilder: (context, index) {
                  final imgUrl = _galleryImages[index];
                  final isSelected = _selectedImage == imgUrl;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedImage = imgUrl),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.voltCyan : Colors.transparent,
                          width: 3,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(imgUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.voltCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Save Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
