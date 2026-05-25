import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

class CreateChallengeSheet extends StatefulWidget {
  const CreateChallengeSheet({super.key});

  @override
  State<CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<CreateChallengeSheet> {
  int _step = 0; // 0: Type, 1: Details, 2: Unique Features (Wager/Team)
  String _selectedType = 'Distance';
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  
  bool _enableWager = false;
  double _wagerAmount = 100;
  bool _teamMode = false;
  bool _aiGenerated = false;
  
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _types = [
    {'name': 'Distance', 'icon': LucideIcons.footprints, 'unit': 'km', 'color': AppColors.solarAmber},
    {'name': 'Workouts', 'icon': Icons.fitness_center, 'unit': 'sessions', 'color': AppColors.pulseRed},
    {'name': 'Study', 'icon': LucideIcons.bookOpen, 'unit': 'hours', 'color': AppColors.voltCyan},
    {'name': 'Nutrition', 'icon': LucideIcons.apple, 'unit': 'days logged', 'color': AppColors.irisViolet},
  ];

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _targetCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('Not logged in');
      
      final typeData = _types.firstWhere((t) => t['name'] == _selectedType);
      
      // 1. Insert challenge
      final challengeRes = await Supabase.instance.client.from('challenges').insert({
        'title': _titleCtrl.text.trim(),
        'description': _aiGenerated 
            ? 'AI Generated Challenge tailored for you!' 
            : (_teamMode ? 'Team vs Team Challenge!' : 'Personal Challenge'),
        'goal_type': _selectedType,
        'target_value': double.tryParse(_targetCtrl.text.trim()) ?? 10.0,
        'target_unit': typeData['unit'],
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        // Assuming we might add these to DB later, for now we just pass standard fields
        // 'wager_amount': _enableWager ? _wagerAmount : 0,
        // 'is_team_mode': _teamMode,
        'created_by': uid,
      }).select().single();
      
      // 2. Join the challenge automatically
      await Supabase.instance.client.from('challenge_participants').insert({
        'challenge_id': challengeRes['id'],
        'user_id': uid,
        'current_value': 0.0,
      });
      
      if (mounted) {
        Navigator.pop(context, true); // return true to refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge Created! 🚀'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _generateAIChallenge() {
    HapticFeedback.mediumImpact();
    setState(() {
      _aiGenerated = true;
      _selectedType = 'Distance';
      _titleCtrl.text = 'AI: Push Your Limits (50km)';
      _targetCtrl.text = '50';
      _step = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _step == 0 ? 'Choose Type' : _step == 1 ? 'Challenge Details' : 'Unique Rules',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_step == 0)
                TextButton.icon(
                  onPressed: _generateAIChallenge,
                  icon: const Icon(LucideIcons.sparkles, color: AppColors.voltCyan, size: 16),
                  label: const Text('AI Auto-Create', style: TextStyle(color: AppColors.voltCyan)),
                )
            ],
          ),
          const SizedBox(height: 24),
          
          // Steps Content
          if (_step == 0) _buildStep0(theme, isDark)
          else if (_step == 1) _buildStep1(theme, isDark)
          else _buildStep2(theme, isDark),
          
          const SizedBox(height: 32),
          
          // Bottom Nav
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () {
                    if (_step < 2) {
                      setState(() => _step++);
                    } else {
                      _submit();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _step < 2 ? 'Next' : 'Launch Challenge 🚀',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep0(ThemeData theme, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _types.length,
      itemBuilder: (context, index) {
        final type = _types[index];
        final isSelected = _selectedType == type['name'];
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedType = type['name'] as String);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? (type['color'] as Color).withValues(alpha: 0.15) : (isDark ? const Color(0xFF1E1E2E) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? (type['color'] as Color) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type['icon'] as IconData, size: 32, color: isSelected ? type['color'] as Color : Colors.grey),
                const SizedBox(height: 12),
                Text(
                  type['name'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isSelected ? type['color'] as Color : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep1(ThemeData theme, bool isDark) {
    final typeData = _types.firstWhere((t) => t['name'] == _selectedType);
    return Column(
      children: [
        TextField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: 'Challenge Title',
            hintText: 'e.g. 100km Summer Run',
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _targetCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Target Goal',
            suffixText: typeData['unit'],
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Wager Feature
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _enableWager ? AppColors.solarAmber.withValues(alpha: 0.1) : (isDark ? const Color(0xFF1E1E2E) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _enableWager ? AppColors.solarAmber.withValues(alpha: 0.3) : Colors.transparent),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: _enableWager,
                onChanged: (v) => setState(() => _enableWager = v),
                title: const Text('Wager Pulse Points', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Bet points on yourself. Win double if you succeed!'),
                activeColor: AppColors.solarAmber,
                secondary: const Icon(LucideIcons.coins, color: AppColors.solarAmber),
                contentPadding: EdgeInsets.zero,
              ),
              if (_enableWager) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('${_wagerAmount.toInt()} pts', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.solarAmber, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: _wagerAmount,
                        min: 50, max: 1000, divisions: 19,
                        activeColor: AppColors.solarAmber,
                        onChanged: (v) => setState(() => _wagerAmount = v),
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Team Feature
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _teamMode ? AppColors.irisViolet.withValues(alpha: 0.1) : (isDark ? const Color(0xFF1E1E2E) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _teamMode ? AppColors.irisViolet.withValues(alpha: 0.3) : Colors.transparent),
          ),
          child: SwitchListTile(
            value: _teamMode,
            onChanged: (v) => setState(() => _teamMode = v),
            title: const Text('Team vs Team Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Co-op challenge. Red Team vs Blue Team.'),
            activeColor: AppColors.irisViolet,
            secondary: const Icon(LucideIcons.users, color: AppColors.irisViolet),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
