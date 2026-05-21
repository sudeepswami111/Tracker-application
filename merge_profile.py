import re
import traceback

try:
    with open('lib/screens/profile_screen.dart', 'r', encoding='utf-8') as f:
        current = f.read()

    with open('old_profile2.dart', 'r', encoding='utf-8') as f:
        old = f.read()

    # Extract the new UI helpers from old
    helpers_match = re.search(r'(  Widget _statPill\(.*?)^\}', old, re.MULTILINE | re.DOTALL)
    helpers = helpers_match.group(1)

    # Extract build from old
    build_old_match = re.search(r'(  @override\n  Widget build\(BuildContext context\) \{.*?)  Widget _statPill', old, re.MULTILINE | re.DOTALL)
    build_old = build_old_match.group(1)

    # Replace `app.profileImagePath.isNotEmpty ? FileImage(File(app.profileImagePath)) : null`
    build_old = build_old.replace(
        'app.profileImagePath.isNotEmpty ? FileImage(File(app.profileImagePath)) : null',
        'avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null'
    )
    # Replace `app.profileImagePath.isEmpty`
    build_old = build_old.replace(
        'app.profileImagePath.isEmpty',
        'avatarUrl == null || avatarUrl.isEmpty'
    )
    # Replace `app.userName.isNotEmpty ? app.userName[0].toUpperCase() : \'U\'`
    build_old = build_old.replace(
        "app.userName.isNotEmpty ? app.userName[0].toUpperCase() : 'U'",
        "fullName.isNotEmpty ? fullName[0].toUpperCase() : '?'"
    )
    # Replace `app.userName` with `fullName`
    build_old = build_old.replace(
        'app.userName',
        'fullName'
    )
    # Replace hardcoded followers/following counts
    build_old = build_old.replace(
        "Text('248 Followers'",
        "Text('${followersCount} Followers'"
    )
    build_old = build_old.replace(
        "Text('112 Following'",
        "Text('${followingCount} Following'"
    )
    # Replace bio
    build_old = build_old.replace(
        "'Chasing the next personal best.'",
        "bio.isNotEmpty ? bio : 'Chasing the next personal best.'"
    )

    supabase_vars = """
    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final fullName       = _profile?.get('full_name') as String? ?? 'User';
    final username       = _profile?.get('username')  as String? ?? '';
    final bio            = _profile?.get('bio')        as String? ?? '';
    final avatarUrl      = _profile?.get('avatar_url') as String?;
    final followersCount = (_profile?.get('followers_count') as num?)?.toInt() ?? 0;
    final followingCount = (_profile?.get('following_count') as num?)?.toInt() ?? 0;
"""
    # Fix the .get map access since _profile is a Map<String, dynamic>
    supabase_vars = supabase_vars.replace(".get('", "['").replace("')", "']")

    build_old = build_old.replace(
        "final app = context.watch<AppProvider>();",
        "final app = context.watch<AppProvider>();\n" + supabase_vars
    )

    build_old = build_old.replace(
        "Text('${followersCount} Followers', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))",
        "GestureDetector(onTap: _showFollowersList, child: Text('${followersCount} Followers', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)))"
    )
    build_old = build_old.replace(
        "Text('${followingCount} Following', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))",
        "GestureDetector(onTap: _showFollowingList, child: Text('${followingCount} Following', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)))"
    )

    follow_button = """
                        const SizedBox(height: 12),
                        if (!_isOwnProfile)
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed:
                                  _followActionLoading ? null : _handleFollowAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _followStatus == FollowStatus.accepted
                                        ? Colors.grey.shade700
                                        : _followStatus == FollowStatus.pending
                                            ? AppColors.solarAmber
                                            : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _followActionLoading
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      _followStatus == FollowStatus.accepted
                                          ? 'Unfollow'
                                          : _followStatus == FollowStatus.pending
                                              ? 'Requested'
                                              : 'Follow',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                            ),
                          ),
"""
    build_old = build_old.replace(
        "                          ],\n                        ),\n                      ],\n                    ),\n                  ),",
        "                          ],\n                        ),\n" + follow_button + "                      ],\n                    ),\n                  ),"
    )

    # In old UI, edit profile action was: _showEditProfile(context, app)
    # But current UI uses _showEditProfile(app) since it's a state method.
    # We should update old UI's action to:
    build_old = build_old.replace(
        "onPressed: () => _showEditProfile(context, app),",
        "onPressed: () => _showEditProfile(app),"
    )

    # Note: old UI uses LucideIcons which is now lucide_icons_flutter
    # But current file already imports it.
    
    current_build_match = re.search(r'(  @override\n  Widget build\(BuildContext context\) \{.*?)^\}', current, re.MULTILINE | re.DOTALL)
    current_build = current_build_match.group(1)

    new_current = current.replace(current_build, build_old + helpers)

    with open('lib/screens/profile_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_current)
    print("Success")
except Exception as e:
    print("Error:")
    traceback.print_exc()
