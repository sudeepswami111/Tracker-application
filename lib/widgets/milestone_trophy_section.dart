import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../providers/watch_metrics_provider.dart';
import '../screens/challenge_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MilestoneTrophySection extends StatefulWidget {
  const MilestoneTrophySection({super.key});

  @override
  State<MilestoneTrophySection> createState() => _MilestoneTrophySectionState();
}

class _MilestoneTrophySectionState extends State<MilestoneTrophySection>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final stepTracker = context.watch<StepTrackerProvider>();
    final watchProvider = context.watch<WatchMetricsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate dynamic athlete level and XP
    final int totalSteps = stepTracker.steps;
    final int streak = app.currentStreak;
    final double distance = app.distance;
    final int xp = (totalSteps ~/ 10) + (streak * 150) + (distance * 50).toInt();
    final int level = (xp ~/ 1000) + 1;
    final int currentLevelXp = xp % 1000;
    final double levelProgress = (currentLevelXp / 1000.0).clamp(0.0, 1.0);

    // Badges computation
    final badges = _getBadges(app, stepTracker, watchProvider);
    final unlockedCount = badges.where((b) => b.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Responsive Header ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Milestones & Trophies",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Personal Bests & Badges",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChallengeScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.trophy, size: 12, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      'Trophy Room',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.chevronRight, size: 11, color: Color(0xFFF59E0B)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Main Holographic Trophy Vault Capsule ──
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF131F2E), Color(0xFF0C1520)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: AppColors.zenAmber.withValues(alpha: isDark ? 0.25 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.zenAmber.withValues(alpha: isDark ? 0.08 : 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Top velocity gradient line
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.zenAmber.withValues(alpha: 0.1),
                          AppColors.zenAmber,
                          AppColors.zenMint,
                          AppColors.zenAmber.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. Top Athlete Tier & XP Progress ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Level emblem
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.crown, size: 13, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(
                                  'LVL $level',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _getRankTitle(level),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$currentLevelXp / 1000 XP',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: levelProgress,
                                    minHeight: 5,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.08),
                                    valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                        height: 1,
                      ),
                      const SizedBox(height: 14),

                      // ── 2. Personal Records Matrix (4 PRs) ──
                      Text(
                        'ALL-TIME PERSONAL RECORDS',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _buildPrCard(
                              title: 'BEST STREAK',
                              value: '${app.longestStreak}',
                              unit: 'Days',
                              icon: LucideIcons.flame,
                              color: AppColors.zenAmber,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPrCard(
                              title: 'DISTANCE PR',
                              value: app.distance.toStringAsFixed(1),
                              unit: 'KM',
                              icon: LucideIcons.footprints,
                              color: AppColors.zenMint,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPrCard(
                              title: 'DAILY STEPS',
                              value: '${app.dailyStepsGoal.toInt()}',
                              unit: 'Goal',
                              icon: LucideIcons.zap,
                              color: AppColors.zenSky,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPrCard(
                              title: 'FOCUS TIME',
                              value: (app.totalStudyMinutes / 60).toStringAsFixed(1),
                              unit: 'Hours',
                              icon: LucideIcons.brain,
                              color: AppColors.zenLavender,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                        height: 1,
                      ),
                      const SizedBox(height: 14),

                      // ── 3. Active Weekly Quest / Sprint ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ACTIVE SPRINT QUEST',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.zenMint.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'WEEKLY',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: AppColors.zenMint,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.zenMint.withValues(alpha: isDark ? 0.2 : 0.25),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.zenMint.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.target,
                                    size: 15,
                                    color: AppColors.zenMint,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '50,000 Steps Weekly Sprint',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Reward: +500 XP • 🥇 Gold Century Badge',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          color: AppColors.zenAmber,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Progress bar with indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(totalSteps).clamp(0, 50000)} / 50,000 steps',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${((totalSteps / 50000) * 100).clamp(0, 100).toInt()}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.zenMint,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (totalSteps / 50000).clamp(0.0, 1.0),
                                minHeight: 5,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.08),
                                valueColor: const AlwaysStoppedAnimation(AppColors.zenMint),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Divider(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                        height: 1,
                      ),
                      const SizedBox(height: 14),

                      // ── 4. Holographic Badge Vault (Horizontal Carousel) ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'BADGE VAULT',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                  color: isDark ? Colors.white38 : Colors.black45,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unlockedCount/${badges.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Tap to inspect',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: badges.map((badge) {
                            return _buildHolographicBadgeTile(
                              badge: badge,
                              isDark: isDark,
                              onTap: () => _showBadgeInspection(context, badge, isDark),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.06)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolographicBadgeTile({
    required _TrophyBadge badge,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: badge.isUnlocked
              ? LinearGradient(
                  colors: isDark
                      ? [badge.color.withValues(alpha: 0.18), const Color(0xFF0D111A)]
                      : [badge.color.withValues(alpha: 0.15), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: isDark
                      ? [Colors.white.withValues(alpha: 0.03), const Color(0xFF0A0D14)]
                      : [Colors.black.withValues(alpha: 0.03), const Color(0xFFF1F5F9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          border: Border.all(
            color: badge.isUnlocked
                ? badge.color.withValues(alpha: isDark ? 0.45 : 0.6)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
            width: badge.isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: badge.isUnlocked
              ? [
                  BoxShadow(
                    color: badge.color.withValues(alpha: isDark ? 0.2 : 0.15),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge icon with glowing circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badge.isUnlocked
                    ? badge.color.withValues(alpha: 0.2)
                    : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                border: Border.all(
                  color: badge.isUnlocked
                      ? badge.color.withValues(alpha: 0.6)
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: 20,
                    color: badge.isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: badge.isUnlocked
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? badge.color.withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge.isUnlocked ? 'UNLOCKED' : 'LOCKED',
                style: GoogleFonts.inter(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: badge.isUnlocked ? badge.color : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeInspection(BuildContext context, _TrophyBadge badge, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F1729) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large glowing badge
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.isUnlocked
                      ? badge.color.withValues(alpha: 0.2)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                  border: Border.all(
                    color: badge.isUnlocked ? badge.color : Colors.grey,
                    width: 2,
                  ),
                  boxShadow: badge.isUnlocked
                      ? [
                          BoxShadow(
                            color: badge.color.withValues(alpha: 0.4),
                            blurRadius: 20,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    badge.emoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                badge.title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.isUnlocked
                      ? badge.color.withValues(alpha: 0.15)
                      : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge.isUnlocked ? '✦ TROPHY CLAIMED' : '🔒 LOCKED OBJECTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: badge.isUnlocked ? badge.color : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Text(
                      'XP REWARD: +${badge.xpReward} XP',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (badge.isUnlocked)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Share.share('I unlocked the "${badge.title}" badge on LifePulse! 🏆✨');
                        },
                        icon: const Icon(LucideIcons.share2, size: 16),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: badge.color,
                          side: BorderSide(color: badge.color),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ),
                  if (badge.isUnlocked) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: badge.isUnlocked ? badge.color : AppColors.voltCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'GOT IT',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRankTitle(int level) {
    if (level <= 1) return 'Novice Athlete';
    if (level == 2) return 'Kinetic Runner';
    if (level == 3) return 'Cyber Vanguard';
    if (level == 4) return 'Titanium Crusher';
    if (level == 5) return 'Apex Legend';
    return 'Immortal Grandmaster';
  }

  List<_TrophyBadge> _getBadges(
    AppProvider app,
    StepTrackerProvider stepTracker,
    WatchMetricsProvider watch,
  ) {
    return [
      _TrophyBadge(
        title: 'Century Walker',
        emoji: '🥇',
        description: 'Logged over 3,000 steps in a single day.',
        isUnlocked: stepTracker.steps >= 3000,
        xpReward: 300,
        color: AppColors.zenAmber,
      ),
      _TrophyBadge(
        title: 'Iron Streak',
        emoji: '🔥',
        description: 'Maintained active daily physical consistency.',
        isUnlocked: app.currentStreak >= 1 || app.longestStreak >= 1,
        xpReward: 500,
        color: AppColors.zenCoral,
      ),
      _TrophyBadge(
        title: 'Hydration Hero',
        emoji: '💧',
        description: 'Completed 100% of daily hydration targets.',
        isUnlocked: app.waterIntake >= 2.0 || app.waterGlasses >= 8,
        xpReward: 250,
        color: AppColors.zenSky,
      ),
      _TrophyBadge(
        title: 'Zen Master',
        emoji: '🧠',
        description: 'Completed deep work focus sessions.',
        isUnlocked: app.totalStudyMinutes >= 25,
        xpReward: 400,
        color: AppColors.zenLavender,
      ),
      _TrophyBadge(
        title: 'Titan Runner',
        emoji: '⚡',
        description: 'Crossed over 5 km total cardio distance.',
        isUnlocked: app.distance >= 5.0,
        xpReward: 750,
        color: AppColors.zenMint,
      ),
      _TrophyBadge(
        title: 'Recovery Pro',
        emoji: '🌙',
        description: 'Logged 7.5+ hours of restorative sleep.',
        isUnlocked: (watch.sleepHours ?? 0) >= 7.5 || app.sleepHours >= 7.5,
        xpReward: 350,
        color: AppColors.zenLavenderLight,
      ),
    ];
  }
}

class _TrophyBadge {
  final String title;
  final String emoji;
  final String description;
  final bool isUnlocked;
  final int xpReward;
  final Color color;

  _TrophyBadge({
    required this.title,
    required this.emoji,
    required this.description,
    required this.isUnlocked,
    required this.xpReward,
    required this.color,
  });
}
