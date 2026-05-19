import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../models/friend_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PeopleSuggestionSection extends StatelessWidget {
  const PeopleSuggestionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friends, _) {
        final contactSuggestions = friends.contactSuggestions;
        final otherSuggestions = friends.suggestions;

        if (friends.suggestionsLoading) {
          return const SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.voltCyan,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (contactSuggestions.isEmpty && otherSuggestions.isEmpty) {
          return const SizedBox.shrink(); // hide section if no suggestions
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── From Contacts ──
            if (contactSuggestions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionHeader(
                    title: 'From Your Contacts',
                    icon: Icons.contacts_rounded,
                  ),
                  GestureDetector(
                    onTap: () => context.read<FriendProvider>().loadSuggestions(),
                    child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _HorizontalSuggestionList(profiles: contactSuggestions),
              const SizedBox(height: 20),
            ],

            // ── People You May Know ──
            if (otherSuggestions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionHeader(
                    title: 'People You May Know',
                    icon: Icons.people_rounded,
                  ),
                  if (contactSuggestions.isEmpty) // Only show refresh here if no contacts section above
                    GestureDetector(
                      onTap: () => context.read<FriendProvider>().loadSuggestions(),
                      child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _HorizontalSuggestionList(profiles: otherSuggestions),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.voltCyan),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _HorizontalSuggestionList extends StatelessWidget {
  final List<FitnessProfile> profiles;
  const _HorizontalSuggestionList({required this.profiles});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: profiles.length,
        itemBuilder: (context, i) => _SuggestionCard(profile: profiles[i]),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final FitnessProfile profile;
  const _SuggestionCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendProvider>();
    final isSent = friends.sentRequestIds.contains(profile.id);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Avatar ──
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.irisViolet.withValues(alpha: 0.3),
            backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                ? Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),

          // ── Name ──
          Text(
            profile.fullName.isNotEmpty ? profile.fullName : profile.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),

          // ── City / fitness goal ──
          if (profile.city != null || profile.fitnessGoal != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                profile.city ?? profile.fitnessGoal ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── Follow / Requested + Dismiss row ──
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isSent
                      ? null
                      : () {
                          context.read<FriendProvider>().sendRequest(profile.id);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSent ? Colors.transparent : AppColors.voltCyan,
                      borderRadius: BorderRadius.circular(10),
                      border: isSent
                          ? Border.all(color: AppColors.borderSubtle)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        isSent ? 'Requested' : 'Follow',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSent ? AppColors.textSecondary : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Dismiss (X) button
              GestureDetector(
                onTap: () =>
                    context.read<FriendProvider>().dismissSuggestion(profile.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
