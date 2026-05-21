import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _shimmerController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(AppProvider app) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      app.updateProfileImagePath(image.path);
    }
  }

  void _showEditProfile(BuildContext context, AppProvider app) {
    final nameCtrl = TextEditingController(text: app.userName);
    final bioCtrl = TextEditingController(text: 'Chasing the next personal best.');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.backgroundDeep : AppColors.lightBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.voltCyan)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioCtrl,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.voltCyan)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    app.updateUserName(nameCtrl.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.voltCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final app = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ΓöÇΓöÇ 1. HERO SECTION ΓöÇΓöÇ
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.pencil, color: Colors.white, size: 20),
                ),
                onPressed: () => _showEditProfile(context, app),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Gradient Banner
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.voltCyan.withValues(alpha: 0.4),
                          isDark ? AppColors.backgroundDeep : AppColors.lightBg,
                        ],
                      ),
                    ),
                  ),
                  // Avatar & Info
                  Positioned(
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(app),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(color: AppColors.voltCyan.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.surfaceElevated,
                              backgroundImage: app.profileImagePath.isNotEmpty ? FileImage(File(app.profileImagePath)) : null,
                              child: app.profileImagePath.isEmpty
                                  ? Text(app.userName.isNotEmpty ? app.userName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          app.userName,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chasing the next personal best.',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.voltCyan, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('248 Followers', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(width: 12),
                            Text('112 Following', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ΓöÇΓöÇ 2. STAT PILLS ROW ΓöÇΓöÇ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statPill(LucideIcons.footprints, '34', 'Runs', theme, isDark),
                      _statPill(LucideIcons.bookOpen, '142h', 'Study', theme, isDark),
                      _statPill(LucideIcons.messageSquare, '89', 'Posts', theme, isDark),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 3. STREAK OVERVIEW ΓöÇΓöÇ
                  Text('Active Streaks', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _streakBadgeCard('Fitness', app.longestStreak, 42, AppColors.pulseRed, isDark), // Mock values
                        const SizedBox(width: 12),
                        _streakBadgeCard('Study', app.studyStreak, app.longestStreak, AppColors.irisViolet, isDark),
                        const SizedBox(width: 12),
                        _streakBadgeCard('Nutrition', 7, 14, AppColors.solarAmber, isDark), // Mock values
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 4. ACHIEVEMENTS SECTION ΓöÇΓöÇ
                  Row(
                    children: [
                      Text('Trophies', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.voltCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text('${app.achievements.where((a) => a['unlocked'] == true).length}', style: const TextStyle(color: AppColors.voltCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: app.achievements.length,
                    itemBuilder: (context, index) {
                      final badge = app.achievements[index];
                      return _achievementBadge(badge, theme, isDark);
                    },
                  ),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 5. MODULE STATS (ACCORDION) ΓöÇΓöÇ
                  Text('Detailed Stats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildAccordionStat(
                    'Fitness', 
                    LucideIcons.activity, 
                    AppColors.pulseRed, 
                    {'Total Distance': '${app.distance} km', 'Workouts': '112', 'PR Badges': '4'}, 
                    isDark
                  ),
                  const SizedBox(height: 8),
                  _buildAccordionStat(
                    'Study', 
                    LucideIcons.bookOpen, 
                    AppColors.irisViolet, 
                    {'Focus Hours': '${(app.totalStudyMinutes / 60).toStringAsFixed(1)} h', 'Tasks Completed': '342', 'Best Streak': '${app.longestStreak} days'}, 
                    isDark
                  ),
                  const SizedBox(height: 8),
                  _buildAccordionStat(
                    'Nutrition', 
                    LucideIcons.apple, 
                    AppColors.solarAmber, 
                    {'Avg Calories': '2,450', 'Macro Adherence': '88%'}, 
                    isDark
                  ),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 6. CONNECTED DEVICES ΓöÇΓöÇ
                  Text('Connected Devices', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDeviceRow('Mi Band 5', LucideIcons.watch, 84, true, isDark),
                  const SizedBox(height: 8),
                  _buildDeviceRow('Smart Scale X', LucideIcons.scale, 0, false, isDark),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 7. SOCIAL LINKS ΓöÇΓöÇ
                  Row(
                    children: [
                      _socialPill('Strava', AppColors.solarAmber),
                      const SizedBox(width: 8),
                      _socialPill('Instagram', AppColors.pulseRed),
                      const SizedBox(width: 8),
                      _socialPill('Share Profile', AppColors.voltCyan),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String value, String label, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.voltCyan),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _streakBadgeCard(String label, int streak, int best, Color accent, bool isDark) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        // Trigger share intent logic here
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.flame, color: accent, size: 18),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text('$streak', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: accent, height: 1.1)),
              const Spacer(),
              Text('Best: $best days', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _achievementBadge(Map<String, dynamic> badge, ThemeData theme, bool isDark) {
    final unlocked = badge['unlocked'] as bool;
    final icon = badge['icon'] as IconData;
    final title = badge['title'] as String;

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: unlocked ? AppColors.voltCyan.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: unlocked ? AppColors.voltCyan : Colors.grey),
              ),
              if (!unlocked)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: isDark ? AppColors.surfaceElevated : Colors.white, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.lock, size: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, maxLines: 2, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (unlocked) ...[
            const SizedBox(height: 4),
            Text('Earned', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.voltCyan, fontSize: 9)),
          ],
        ],
      ),
    );

    if (unlocked) {
      // Add metallic sheen to unlocked badges
      return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              final val = _shimmerController.value;
              return LinearGradient(
                begin: Alignment(-2.0 + (val * 4), -2.0 + (val * 4)),
                end: Alignment(-1.0 + (val * 4), -1.0 + (val * 4)),
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.plus,
            child: child,
          );
        },
        child: card,
      );
    } else {
      // Greyscale for locked
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: card,
      );
    }
  }

  Widget _buildAccordionStat(String title, IconData icon, Color accent, Map<String, String> stats, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: accent, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: stats.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
              Text(e.value, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDeviceRow(String name, IconData icon, int battery, bool connected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: connected ? AppColors.voltCyan : Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (connected)
                  Text('Battery: $battery%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: connected ? AppColors.voltCyan.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              connected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: connected ? AppColors.voltCyan : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialPill(String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
