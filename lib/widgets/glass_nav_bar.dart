import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../screens/running/running_screen.dart';
import '../screens/hydration_hub_screen.dart';
import '../screens/workout/fitness_screen.dart';
import '../screens/study_screen.dart';

class _NavDestination {
  final IconData icon;
  final String label;
  final int index;

  const _NavDestination({
    required this.icon,
    required this.label,
    required this.index,
  });
}

const _destinations = [
  _NavDestination(icon: LucideIcons.home, label: 'Home', index: 0),
  _NavDestination(icon: LucideIcons.compass, label: 'Explore', index: 1),
  _NavDestination(icon: LucideIcons.users, label: 'Community', index: 3),
  _NavDestination(icon: LucideIcons.user, label: 'Profile', index: 4),
];

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  void _showQuickActionSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Quick Actions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickSheetAction(
                  context,
                  icon: LucideIcons.footprints,
                  iconColor: AppColors.sageGreen,
                  bgColor: AppColors.mintLight,
                  label: 'Start Run',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
                  },
                ),
                _buildQuickSheetAction(
                  context,
                  icon: LucideIcons.droplets,
                  iconColor: AppColors.skyBlue,
                  bgColor: AppColors.skyLight,
                  label: 'Add Water',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HydrationHubScreen()));
                  },
                ),
                _buildQuickSheetAction(
                  context,
                  icon: LucideIcons.dumbbell,
                  iconColor: AppColors.accentOrange,
                  bgColor: const Color(0xFFFEF3E8),
                  label: 'Workout',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessScreen()));
                  },
                ),
                _buildQuickSheetAction(
                  context,
                  icon: LucideIcons.bookOpen,
                  iconColor: AppColors.lavender,
                  bgColor: AppColors.lavenderLight,
                  label: 'Start Study',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyScreen()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSheetAction(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: 12,
        ),
        child: SizedBox(
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ── Background Surface ──
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16382B).withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Navigation Tabs Row ──
              Row(
                children: [
                  // Left: Home, Explore
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavTab(
                            destination: _destinations[0],
                            isActive: currentIndex == 0,
                            onTap: onTap,
                          ),
                        ),
                        Expanded(
                          child: _NavTab(
                            destination: _destinations[1],
                            isActive: currentIndex == 1,
                            onTap: onTap,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center Gap for (+) Action Button
                  const SizedBox(width: 60),

                  // Right: Community, Profile
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavTab(
                            destination: _destinations[2],
                            isActive: currentIndex == 3,
                            onTap: onTap,
                          ),
                        ),
                        Expanded(
                          child: _NavTab(
                            destination: _destinations[3],
                            isActive: currentIndex == 4,
                            onTap: onTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Center (+) Floating Button in Dark Forest Green ──
              Positioned(
                top: -14,
                child: GestureDetector(
                  onTap: () => _showQuickActionSheet(context),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forestGreen.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final _NavDestination destination;
  final bool isActive;
  final ValueChanged<int> onTap;

  const _NavTab({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.forestGreen;
    const inactiveColor = AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(destination.index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            destination.icon,
            size: 20,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 3),
          Text(
            destination.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
