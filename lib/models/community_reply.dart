class CommunityReply {
  final String id;
  final String postId;
  final String userId;
  final String replyText;
  final DateTime createdAt;
  final String? userName;
  final String? avatarUrl;

  CommunityReply({
    required this.id,
    required this.postId,
    required this.userId,
    required this.replyText,
    required this.createdAt,
    this.userName,
    this.avatarUrl,
  });

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    // If we joined with the profiles table in Supabase
    String? parsedName;
    String? parsedAvatar;
    if (json['author'] != null) {
      parsedName = json['author']['full_name'] as String?;
      parsedAvatar = json['author']['avatar_url'] as String?;
    } else if (json['profiles'] != null) {
       parsedName = json['profiles']['full_name'] as String?;
       parsedAvatar = json['profiles']['avatar_url'] as String?;
    }

    return CommunityReply(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      replyText: json['reply_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      userName: parsedName,
      avatarUrl: parsedAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'reply_text': replyText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
