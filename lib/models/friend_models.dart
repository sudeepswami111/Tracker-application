// ─── Friend System Models ────────────────────────────────────────────────────

enum FriendRequestStatus { pending, accepted, rejected }

enum FriendshipActivityLevel { sedentary, light, moderate, active, veryActive }

class FitnessProfile {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final String? country;
  final String? fitnessGoal;
  final String? activityLevel;
  final int dailyStepGoal;
  final int averageDailySteps;
  final List<String> interests;
  final DateTime createdAt;

  const FitnessProfile({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.country,
    this.fitnessGoal,
    this.activityLevel,
    this.dailyStepGoal = 10000,
    this.averageDailySteps = 0,
    this.interests = const [],
    required this.createdAt,
  });

  factory FitnessProfile.fromJson(Map<String, dynamic> json) {
    return FitnessProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? json['name'] as String? ?? 'user',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      fitnessGoal: json['fitness_goal'] as String?,
      activityLevel: json['activity_level'] as String?,
      dailyStepGoal: (json['daily_step_goal'] as num?)?.toInt() ?? 10000,
      averageDailySteps: (json['average_daily_steps'] as num?)?.toInt() ?? 0,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'bio': bio,
        'city': city,
        'country': country,
        'fitness_goal': fitnessGoal,
        'activity_level': activityLevel,
        'daily_step_goal': dailyStepGoal,
        'average_daily_steps': averageDailySteps,
        'interests': interests,
        'created_at': createdAt.toIso8601String(),
      };
}


class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final FitnessProfile? senderProfile;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.senderProfile,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      senderProfile: json['sender'] != null
          ? FitnessProfile.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Friendship {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final FitnessProfile? friendProfile;

  const Friendship({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.friendProfile,
  });

  factory Friendship.fromJson(Map<String, dynamic> json, String currentUserId) {
    final isUser1 = json['user1_id'] == currentUserId;
    return Friendship(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      friendProfile: isUser1 && json['user2'] != null
          ? FitnessProfile.fromJson(json['user2'] as Map<String, dynamic>)
          : !isUser1 && json['user1'] != null
              ? FitnessProfile.fromJson(json['user1'] as Map<String, dynamic>)
              : null,
    );
  }
}
