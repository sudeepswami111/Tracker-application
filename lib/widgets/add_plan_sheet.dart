import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../constants/activity_types.dart';
import '../services/workout_suggestion_service.dart';

class AddPlanSheet extends StatefulWidget {
  const AddPlanSheet({super.key});

  @override
  State<AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<AddPlanSheet> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _kcalController = TextEditingController();

  static const Map<String, List<String>> _activitySampleImages = {
    'Outdoor Run': [
      'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1571008887538-b36bb32f4571?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=300&q=80',
    ],
    'Treadmill': [
      'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1576678927484-cc907957088c?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?auto=format&fit=crop&w=300&q=80',
    ],
    'Trail Run': [
      'https://images.unsplash.com/photo-1501555088652-021faa106b9b?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=300&q=80',
    ],
    'Cycling': [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1534787238916-9ba6764efd4f?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1502744688674-c619d1586c9e?auto=format&fit=crop&w=300&q=80',
    ],
    'Workout': [
      'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?auto=format&fit=crop&w=300&q=80',
    ],
    'HIIT': [
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1599058917212-d750089bc07e?auto=format&fit=crop&w=300&q=80',
    ],
    'Dance': [
      'https://images.unsplash.com/photo-1502519144081-acca18599776?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1547153760-18fc86324498?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1524594152303-9fd13543fe6e?auto=format&fit=crop&w=300&q=80',
    ],
    'Swim': [
      'https://images.unsplash.com/photo-1519315901367-f34f9273400a?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1530549387789-4c1017266635?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1560090995-01632a28895b?auto=format&fit=crop&w=300&q=80',
    ],
    'Surf': [
      'https://images.unsplash.com/photo-1502680390469-be75c86b636f?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1526367790939-014f33161c14?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1537519646099-335112f03225?auto=format&fit=crop&w=300&q=80',
    ],
    'Stand Up Paddle': [
      'https://images.unsplash.com/photo-1502086223501-7ea6ecd79368?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1558284560-1c09b8b7ed66?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1544498528-765f123f0340?auto=format&fit=crop&w=300&q=80',
    ],
    'Kayak': [
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1516571556942-03f39ee4b5a3?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1520638510864-cf36ea081971?auto=format&fit=crop&w=300&q=80',
    ],
    'Ice Skate': [
      'https://images.unsplash.com/photo-1518118014377-ce98b4618e7e?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1484080126989-1fc32ccdfa54?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1614271887221-50e588db62c8?auto=format&fit=crop&w=300&q=80',
    ],
    'Snowboard': [
      'https://images.unsplash.com/photo-1523783425027-3860bb40212f?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1498801931557-4b7b258673a3?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1551524559-8af4e6624178?auto=format&fit=crop&w=300&q=80',
    ],
    'Football': [
      'https://images.unsplash.com/photo-1518605368461-1ee1252328bb?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1551280336-b51f0f04c622?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1508344928928-7165b67de128?auto=format&fit=crop&w=300&q=80',
    ],
    'Basketball': [
      'https://images.unsplash.com/photo-1519861531473-9200262188bf?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1546519638-68e109498ffc?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1504450758481-7338eba7524a?auto=format&fit=crop&w=300&q=80',
    ],
    'Volleyball': [
      'https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1540932239986-30128078f3c5?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1595152772835-219674b2a8a6?auto=format&fit=crop&w=300&q=80',
    ],
    'Cricket': [
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1589801258579-18e091f4ca26?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1593341646782-e0b495cff86d?auto=format&fit=crop&w=300&q=80',
    ],
    'Skateboard': [
      'https://images.unsplash.com/photo-1520045892732-304bc3ac5d8e?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1564982752979-3f7bc974d29a?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1515860361099-31ff5b4e7ebc?auto=format&fit=crop&w=300&q=80',
    ],
    'Golf': [
      'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1535136104956-613d719a7ee1?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1593111774240-d529f12fc416?auto=format&fit=crop&w=300&q=80',
    ],
  };

  // Helper — fallback to first generic image if activity not in map yet
  List<String> _sampleImagesFor(String activityLabel) {
    return _activitySampleImages[activityLabel] ??
        _activitySampleImages['Outdoor Run']!;
  }

  late String _selectedCategory;
  late String _selectedActivity;
  late String _selectedImage;
  bool _isCustomImage = false;
  String? _customImagePath;

  @override
  void initState() {
    super.initState();
    _selectedCategory = kSportsCategories.keys.first;
    _selectedActivity = kSportsCategories[_selectedCategory]!.first.label;
    _selectedImage = _sampleImagesFor(_selectedActivity).first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _customImagePath = picked.path;
        _selectedImage = picked.path;  // will be a local path, not a URL
        _isCustomImage = true;
      });
    }
  }

  void _savePlan() {
    if (_titleController.text.isEmpty ||
        _durationController.text.isEmpty ||
        _kcalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    final newPlan = DailyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      duration: _durationController.text,
      kcal: _kcalController.text,
      imageUrl: _selectedImage,
      type: _selectedActivity,
    );

    context.read<AppProvider>().addDailyPlan(newPlan);
    Navigator.pop(context);
  }

  Widget _buildCustomImageTile() {
    return GestureDetector(
      onTap: _pickCustomImage,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isCustomImage ? AppColors.voltCyan : AppColors.borderSubtle,
            width: _isCustomImage ? 3 : 1,
          ),
          color: AppColors.surfaceCard,
          image: _isCustomImage && _customImagePath != null
              ? DecorationImage(
                  image: FileImage(File(_customImagePath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _isCustomImage && _customImagePath != null
            ? null  // show the image, no icon overlay needed
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.imagePlus, color: AppColors.textSecondary, size: 22),
                  const SizedBox(height: 4),
                  Text('Custom', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            
            // Type Selection
            Text('Activity Type', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            
            // Categories Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kSportsCategories.keys.map((cat) {
                  final isActive = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedCategory = cat;
                        _selectedActivity = kSportsCategories[cat]!.first.label;
                        _selectedImage = _sampleImagesFor(_selectedActivity).first;
                        _isCustomImage = false;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.voltCyan.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? AppColors.voltCyan : AppColors.borderSubtle),
                      ),
                      child: Text(cat, style: TextStyle(color: isActive ? AppColors.voltCyan : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Activity Chips for selected category
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kSportsCategories[_selectedCategory]!.map((activity) {
                  final isSelected = _selectedActivity == activity.label;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedActivity = activity.label;
                      _selectedImage = _sampleImagesFor(activity.label).first;
                      _isCustomImage = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.voltCyan : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.voltCyan : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(activity.icon, size: 16,
                              color: isSelected ? Colors.black : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(activity.label,
                              style: TextStyle(
                                color: isSelected ? Colors.black : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // ── AI Coach Best Time Suggestion Banner ──
            Builder(
              builder: (context) {
                final timeRec = WorkoutPlanSuggestionService.getOptimalTimeRecommendation(_selectedActivity);
                final isDark = theme.brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131D2D) : const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.voltCyan.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.voltCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(timeRec.icon, color: AppColors.voltCyan, size: 15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'BEST TIME WINDOW: ',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.voltCyan,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    timeRec.optimalWindow,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeRec.quickTip,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Plan Title (e.g., Morning Run 5K)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      hintText: '30',
                      suffixText: 'min',
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Calories',
                      hintText: '320',
                      suffixText: 'kcal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            Text('Preview Image', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Sample images for selected activity
                  ..._sampleImagesFor(_selectedActivity).map((imgUrl) {
                    final isSelected = !_isCustomImage && _selectedImage == imgUrl;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedImage = imgUrl;
                        _isCustomImage = false;
                      }),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
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
                  }),

                  // Custom image picker tile
                  _buildCustomImageTile(),
                ],
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
