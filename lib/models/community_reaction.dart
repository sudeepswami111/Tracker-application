class ReactionSummary {
  final int cheerCount;
  final int fireCount;
  final bool hasCurrentUserCheered;
  final bool hasCurrentUserFired;

  const ReactionSummary({
    this.cheerCount = 0,
    this.fireCount = 0,
    this.hasCurrentUserCheered = false,
    this.hasCurrentUserFired = false,
  });

  ReactionSummary copyWith({
    int? cheerCount,
    int? fireCount,
    bool? hasCurrentUserCheered,
    bool? hasCurrentUserFired,
  }) {
    return ReactionSummary(
      cheerCount: cheerCount ?? this.cheerCount,
      fireCount: fireCount ?? this.fireCount,
      hasCurrentUserCheered: hasCurrentUserCheered ?? this.hasCurrentUserCheered,
      hasCurrentUserFired: hasCurrentUserFired ?? this.hasCurrentUserFired,
    );
  }

  /// Parses a list of raw reaction rows for a specific post and determines the current user's status
  factory ReactionSummary.fromReactions(List<dynamic> reactions, String? currentUserId) {
    int cheer = 0;
    int fire = 0;
    bool currentCheer = false;
    bool currentFire = false;

    for (var r in reactions) {
      final type = r['reaction_type'] as String?;
      final uid = r['user_id'] as String?;
      
      if (type == 'cheer') {
        cheer++;
        if (uid == currentUserId) currentCheer = true;
      } else if (type == 'fire') {
        fire++;
        if (uid == currentUserId) currentFire = true;
      }
    }

    return ReactionSummary(
      cheerCount: cheer,
      fireCount: fire,
      hasCurrentUserCheered: currentCheer,
      hasCurrentUserFired: currentFire,
    );
  }
}
