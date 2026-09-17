import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'botanical_decorations.dart';
import 'profile_avatar.dart';

/// Scenic Mountain Sunrise Hero Banner on the Home / Dashboard Screen
class ScenicHeroBanner extends StatelessWidget {
  final double height;
  final VoidCallback? onTap;

  const ScenicHeroBanner({
    super.key,
    this.height = 165,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Scenic Mountain Lake Artwork
              Image.asset(
                'assets/dashboard_scenic_hero.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFDAB9),
                          Color(0xFFE88B58),
                          Color(0xFF436B56),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  );
                },
              ),
              // Soft warm light overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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

/// Full Scenic Header that seamlessly integrates the greeting, bell, and avatar over the artwork
class DashboardScenicHeader extends StatelessWidget {
  final String userName;
  final bool hasUnreadNotifications;
  final VoidCallback onNotificationTap;
  final VoidCallback onAvatarTap;
  final VoidCallback? onBannerTap;

  const DashboardScenicHeader({
    super.key,
    required this.userName,
    required this.hasUnreadNotifications,
    required this.onNotificationTap,
    required this.onAvatarTap,
    this.onBannerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Greeting + Action Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning,',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      userName.isNotEmpty ? userName : 'Sudeep',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestGreen,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('☀️', style: TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Small steps. Big dreams.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Bell Notification button
                GestureDetector(
                  onTap: onNotificationTap,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.forestGreen),
                        if (hasUnreadNotifications)
                          Positioned(
                            right: 11,
                            top: 11,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.accentPeach,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Avatar button
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder, width: 1.5),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: const ProfileAvatar(radius: 19),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Aesthetic Scenic Mountain Lake Banner
        ScenicHeroBanner(
          height: 170,
          onTap: onBannerTap,
        ),
      ],
    );
  }
}

/// Scenic Trail Runner Banner used in Steps Screen & Bottom Carousel
class ScenicRunnerBanner extends StatelessWidget {
  final String title;
  final double height;

  const ScenicRunnerBanner({
    super.key,
    this.title = 'Every step brings you closer to your goals.',
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Scenic Runner Artwork
            Image.asset(
              'assets/runner_scenic_hero.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF39C6B),
                        Color(0xFFE88B58),
                        Color(0xFF355442),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                );
              },
            ),
            // Gradient scrim for quote readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Motivational Quote on left
            Positioned(
              left: 20,
              top: 24,
              right: 140,
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Motivational Daily Thought Banner ("Progress, not perfection. 🍃" or "Discipline today builds the freedom tomorrow.")
class MotivationalCard extends StatelessWidget {
  final String quote;
  final Color backgroundColor;
  final Color textColor;
  final bool hasLeaf;

  const MotivationalCard({
    super.key,
    required this.quote,
    this.backgroundColor = const Color(0xFFF3EFE6),
    this.textColor = AppColors.forestGreen,
    this.hasLeaf = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          if (hasLeaf) ...[
            const BotanicalLeafIcon(size: 26, color: AppColors.sageGreen),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Text(
              quote,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
