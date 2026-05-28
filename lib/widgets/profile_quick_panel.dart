import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../screens/profile_screen.dart';
import '../screens/challenge_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import 'profile_avatar.dart';
import 'add_plan_sheet.dart';
import 'smart_calendar_sheet.dart';

void showProfileQuickPanel(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Profile Panel',
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 60.0, right: 16.0),
            child: Material(
              color: Colors.transparent,
              child: _ProfileQuickPanel(animation: animation),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      final slideAnimation = Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        ),
      );
    },
  );
}

class _ProfileQuickPanel extends StatelessWidget {
  final Animation<double> animation;

  const _ProfileQuickPanel({required this.animation});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final double panelWidth = min(MediaQuery.of(context).size.width * 0.85, 290);

    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161821).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header Section
              _buildHeader(context, app, theme),

              // 2. Today Snapshot
              _buildTodaySnapshot(context, app, theme),

              // 3. Quick Actions
              _buildQuickActions(context, app, theme),

              Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),

              // 4. Navigation Menu Items
              _ProfileQuickPanelItem(
                icon: LucideIcons.user,
                title: 'Profile',
                subtitle: 'View and edit your profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                },
              ),
              _ProfileQuickPanelItem(
                icon: LucideIcons.trophy,
                title: 'Challenges',
                subtitle: 'Join fitness challenges',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeScreen()));
                },
              ),
              _ProfileQuickPanelItem(
                icon: LucideIcons.activity,
                title: 'History',
                subtitle: 'View your activity records',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                },
              ),
              _ProfileQuickPanelItem(
                icon: LucideIcons.settings,
                title: 'Settings',
                subtitle: 'Goals, privacy, preferences',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),

              Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),

              // 5. Logout
              _ProfileQuickPanelItem(
                icon: LucideIcons.logOut,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                isDestructive: true,
                onTap: () => _handleLogout(context),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider app, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          ProfileAvatar(
            imageUrl: app.avatarUrl,
            name: app.userName,
            radius: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.userName.isNotEmpty ? app.userName : 'Fitness Member',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  app.email.isNotEmpty ? app.email : 'user@example.com',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.flame, size: 12, color: AppColors.solarAmber),
                    const SizedBox(width: 4),
                    Text(
                      '${app.currentStreak} day streak',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.solarAmber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySnapshot(BuildContext context, AppProvider app, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SnapshotItem(
              icon: LucideIcons.footprints,
              value: _formatNumber(app.steps),
              label: 'Steps',
              color: AppColors.voltCyan,
            ),
            Container(height: 30, width: 1, color: isDark ? Colors.white24 : Colors.black12),
            _SnapshotItem(
              icon: LucideIcons.timer,
              value: '${app.todayDuration}',
              label: 'Active Mins',
              color: AppColors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppProvider app, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QuickActionChip(
            icon: LucideIcons.plusCircle,
            label: 'Quick Log',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddPlanSheet(),
              );
            },
          ),
          _QuickActionChip(
            icon: LucideIcons.fileText,
            label: 'Add Note',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const SmartCalendarSheet(),
              );
            },
          ),
          _QuickActionChip(
            icon: LucideIcons.playCircle,
            label: 'Start Run',
            isPrimary: true,
            onTap: () {
              Navigator.pop(context);
              // Since Run screen is usually a tab, we'll issue a snackbar if we can't easily push it,
              // but ideally it pushes to the run setup or switches tab.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use the central Run button to start!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pulseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close profile panel
              await context.read<AuthProvider>().signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

class _SnapshotItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SnapshotItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary 
                ? AppColors.voltCyan.withValues(alpha: 0.15) 
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary 
                  ? AppColors.voltCyan.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isPrimary ? AppColors.voltCyan : (isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.voltCyan : (isDark ? Colors.white70 : Colors.black87),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileQuickPanelItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileQuickPanelItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? AppColors.pulseRed : (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: color)),
                    Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (!isDestructive)
                const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
