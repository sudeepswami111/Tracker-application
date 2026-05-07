import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Tailored for your Dark Mode theme
      appBar: AppBar(
        title: const Text("Lifepulse Inbox", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 1. Quick-Start Private Coach Banner
          _buildCoachBanner(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft, 
              child: Text("CHANNELS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
            ),
          ),
          // 2. Streamed Channels List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getChannelsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No channels available", style: TextStyle(color: Colors.white70)));
                }

                // Filter logic: Show if public, OR if private and user is a member
                final channels = snapshot.data!.where((ch) {
                  if (ch['is_private'] == false) return true;
                  final members = List<String>.from(ch['member_ids'] ?? []);
                  return members.contains(_chatService.currentUserId);
                }).toList();

                return ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final ch = channels[index];
                    final isPrivate = ch['is_private'] ?? false;

                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPrivate ? Colors.purple : Colors.cyan,
                          child: Icon(isPrivate ? Icons.support_agent : Icons.public, color: Colors.white),
                        ),
                        title: Text(ch['name'] ?? 'Unnamed Channel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(isPrivate ? "Private 1-on-1 Help" : "Public Community Chat", style: const TextStyle(color: Colors.grey)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(channelId: ch['id'], channelName: ch['name'], isPrivate: isPrivate),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Need Personalized Advice?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text("Talk 1-on-1 with a health coach.", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple),
            onPressed: () async {
              try {
                // Simulate launching a chat with a specific coach
                final channelId = await _chatService.createPrivateChannel(
                  "Coach Sarah (Nutrition)", 
                  "00000000-0000-0000-0000-111111111111" // Simulated coach user ID
                );
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(channelId: channelId, channelName: "Coach Sarah (Nutrition)", isPrivate: true),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create channel: \$e')),
                  );
                }
              }
            },
            child: const Text("Chat Now"),
          )
        ],
      ),
    );
  }
}
