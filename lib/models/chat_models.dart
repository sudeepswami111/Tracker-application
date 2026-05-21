// ── Chat & Message Models ─────────────────────────────────────────────────────

class ChatRoom {
  final String chatId;
  final String user1Id;
  final String user2Id;
  final ChatFriend friend; // the other person (not current user)
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const ChatRoom({
    required this.chatId,
    required this.user1Id,
    required this.user2Id,
    required this.friend,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json, String currentUserId) {
    final isUser1 = json['user1_id'] == currentUserId;
    final friendRaw = isUser1 ? json['user2'] : json['user1'];

    return ChatRoom(
      chatId: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      friend: ChatFriend.fromJson(friendRaw as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ChatFriend {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;

  const ChatFriend({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
  });

  String get displayName => fullName.isNotEmpty ? fullName : username;

  String get initials {
    final name = displayName.trim();
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  factory ChatFriend.fromJson(Map<String, dynamic> json) {
    return ChatFriend(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
