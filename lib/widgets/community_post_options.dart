import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/community_service.dart';
import '../screens/profile_screen.dart';
import '../models/community_reply.dart';
import 'profile_avatar.dart';

// ====================================================
// 1. COMMUNITY POST OPTIONS SHEET
// ====================================================

class CommunityPostOptionsSheet extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onRefresh;
  final VoidCallback onHide;
  final String? pinnedPostId;
  final Function(String?) onPinToggle;

  const CommunityPostOptionsSheet({
    super.key,
    required this.post,
    required this.onRefresh,
    required this.onHide,
    required this.pinnedPostId,
    required this.onPinToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId == post['user_id'];
    final isPinned = pinnedPostId == post['id'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Post Options',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          if (isOwner) ...[
            // ── OWNER ACTIONS ──
            _buildOptionTile(
              context,
              icon: LucideIcons.pencil,
              label: 'Edit Post',
              onTap: () {
                Navigator.pop(context);
                _openEditSheet(context);
              },
              theme: theme,
              isDark: isDark,
            ),
            _buildOptionTile(
              context,
              icon: isPinned ? LucideIcons.pinOff : LucideIcons.pin,
              label: isPinned ? 'Unpin Post' : 'Pin Post',
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                if (isPinned) {
                  await prefs.remove('pinned_post_id');
                  onPinToggle(null);
                  if (context.mounted) {
                    _showToast(context, 'Post unpinned');
                  }
                } else {
                  await prefs.setString('pinned_post_id', post['id']);
                  onPinToggle(post['id']);
                  if (context.mounted) {
                    _showToast(context, 'Post pinned to top');
                  }
                }
              },
              theme: theme,
              isDark: isDark,
            ),
            _buildOptionTile(
              context,
              icon: LucideIcons.trash2,
              label: 'Delete Post',
              labelColor: AppColors.pulseRed,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
              theme: theme,
              isDark: isDark,
            ),
          ] else ...[
            // ── OTHER USER ACTIONS ──
            _buildOptionTile(
              context,
              icon: LucideIcons.user,
              label: 'View Profile',
              onTap: () {
                Navigator.pop(context);
                final authorId = post['user_id'] as String?;
                if (authorId != null && authorId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(targetUserId: authorId),
                    ),
                  );
                } else {
                  _showToast(context, 'Profile view coming soon');
                }
              },
              theme: theme,
              isDark: isDark,
            ),
            _buildOptionTile(
              context,
              icon: LucideIcons.eyeOff,
              label: 'Hide Post',
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                final hiddenList = prefs.getStringList('hidden_posts') ?? [];
                if (!hiddenList.contains(post['id'])) {
                  hiddenList.add(post['id']);
                  await prefs.setStringList('hidden_posts', hiddenList);
                }
                onHide();
                if (context.mounted) {
                  _showToast(context, 'Post hidden');
                }
              },
              theme: theme,
              isDark: isDark,
            ),
            _buildOptionTile(
              context,
              icon: LucideIcons.alertTriangle,
              label: 'Report Post',
              labelColor: AppColors.solarAmber,
              onTap: () {
                Navigator.pop(context);
                _openReportSheet(context);
              },
              theme: theme,
              isDark: isDark,
            ),
          ],

          // ── SHARED ACTIONS ──
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 24),
          _buildOptionTile(
            context,
            icon: LucideIcons.copy,
            label: 'Copy Text',
            onTap: () async {
              Navigator.pop(context);
              // Extract main text (without stats/feeling if possible)
              String cleanContent = post['content'] ?? '';
              if (cleanContent.contains('📊 Stats:')) {
                cleanContent = cleanContent.split('📊 Stats:')[0].trim();
              }
              await Clipboard.setData(ClipboardData(text: cleanContent));
              if (context.mounted) {
                _showToast(context, 'Post copied');
              }
            },
            theme: theme,
            isDark: isDark,
          ),
          _buildOptionTile(
            context,
            icon: LucideIcons.share2,
            label: 'Share Post',
            onTap: () async {
              Navigator.pop(context);
              String textToShare = post['content'] ?? '';
              final authorName = post['author']?['full_name'] ?? 'Someone';
              final type = post['activity_type'] ?? 'Workout';
              
              await Share.share(
                '$authorName shared a $type update:\n\n"$textToShare"\n\nShared via LifePulse',
                subject: 'LifePulse Social Fitness Update',
              );
            },
            theme: theme,
            isDark: isDark,
          ),
          _buildOptionTile(
            context,
            icon: LucideIcons.info,
            label: 'View Details',
            onTap: () {
              Navigator.pop(context);
              _openDetailsSheet(context);
            },
            theme: theme,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
    Color? labelColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: labelColor ?? (isDark ? Colors.white70 : Colors.black87), size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? (isDark ? Colors.white : Colors.black87),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.irisViolet),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPostBottomSheet(post: post, onRefresh: onRefresh),
    );
  }

  void _openReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportPostBottomSheet(postId: post['id']),
    );
  }

  void _openDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostDetailsBottomSheet(post: post),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceCard
            : Colors.white,
        title: const Text('Delete post?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await CommunityService().deletePost(post['id']);
                onRefresh();
                if (context.mounted) {
                  _showToast(context, 'Post deleted');
                }
              } catch (e) {
                if (context.mounted) {
                  _showToast(context, 'Could not delete post. Try again.');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pulseRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// 2. EDIT POST BOTTOM SHEET
// ====================================================

class EditPostBottomSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onRefresh;

  const EditPostBottomSheet({
    super.key,
    required this.post,
    required this.onRefresh,
  });

  @override
  State<EditPostBottomSheet> createState() => _EditPostBottomSheetState();
}

class _EditPostBottomSheetState extends State<EditPostBottomSheet> {
  late final TextEditingController _contentCtrl;
  late String _selectedActivity;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Strip stats and feeling metadata when editing, to avoid duplicate appends
    String rawContent = widget.post['content'] ?? '';
    if (rawContent.contains('📊 Stats:')) {
      rawContent = rawContent.split('📊 Stats:')[0].trim();
    }
    _contentCtrl = TextEditingController(text: rawContent);
    _selectedActivity = widget.post['activity_type'] ?? 'Running';
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // Re-append previous stats & mood if they existed in the old post
      String finalContent = _contentCtrl.text.trim();
      String oldContent = widget.post['content'] ?? '';
      
      if (oldContent.contains('📊 Stats:')) {
        final parts = oldContent.split('📊 Stats:');
        finalContent += '\n\n📊 Stats:${parts[1]}';
      } else if (oldContent.contains('Feeling:')) {
        final parts = oldContent.split('Feeling:');
        finalContent += '\n\nFeeling:${parts[1]}';
      }

      await CommunityService().updatePost(
        postId: widget.post['id'],
        content: finalContent,
        activityType: _selectedActivity,
      );

      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update post.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Post',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentCtrl,
                maxLines: 4,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Edit your message...",
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.irisViolet),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Activity Type',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _EditActivityTypeSelector(
                selectedActivity: _selectedActivity,
                onSelected: (act) => setState(() => _selectedActivity = act),
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.irisViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================
// 3. REPORT POST BOTTOM SHEET
// ====================================================

class ReportPostBottomSheet extends StatefulWidget {
  final String postId;

  const ReportPostBottomSheet({super.key, required this.postId});

  @override
  State<ReportPostBottomSheet> createState() => _ReportPostBottomSheetState();
}

class _ReportPostBottomSheetState extends State<ReportPostBottomSheet> {
  final _detailsCtrl = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _reasons = const [
    'Spam',
    'Harassment',
    'False information',
    'Inappropriate content',
    'Other'
  ];

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    try {
      await CommunityService().reportPost(
        postId: widget.postId,
        reason: _selectedReason!,
        details: _detailsCtrl.text.trim().isNotEmpty ? _detailsCtrl.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report failed. Try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report Post',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Select a reason for reporting:',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ..._reasons.map((reason) {
                return RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  value: reason,
                  groupValue: _selectedReason,
                  activeColor: AppColors.voltCyan,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      _selectedReason = val;
                    });
                  },
                );
              }),
              const SizedBox(height: 12),
              TextField(
                controller: _detailsCtrl,
                maxLines: 2,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Additional details (optional)...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedReason == null || _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pulseRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.white10 : Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================
// 4. POST DETAILS BOTTOM SHEET (WITH COMMENTS/REPLIES)
// ====================================================

class PostDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailsBottomSheet({super.key, required this.post});

  @override
  State<PostDetailsBottomSheet> createState() => _PostDetailsBottomSheetState();
}

class _PostDetailsBottomSheetState extends State<PostDetailsBottomSheet> {
  final _replyCtrl = TextEditingController();
  List<CommunityReply> _replies = [];
  bool _isLoadingReplies = true;
  bool _isSendingReply = false;
  RealtimeChannel? _replyChannel;

  @override
  void initState() {
    super.initState();
    _fetchReplies();
    _subscribeReplies();
  }

  Future<void> _fetchReplies() async {
    try {
      final list = await CommunityService().fetchRepliesForPost(widget.post['id']);
      if (mounted) {
        setState(() {
          _replies = list;
          _isLoadingReplies = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReplies = false);
      }
    }
  }

  void _subscribeReplies() {
    final postId = widget.post['id'];
    _replyChannel = Supabase.instance.client
        .channel('post_details_replies_$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_replies',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'post_id', value: postId),
          callback: (payload) => _fetchReplies(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _replyChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingReply = true);

    try {
      final authorId = widget.post['user_id'];
      final added = await CommunityService().addReply(widget.post['id'], text, postAuthorId: authorId);
      if (added != null && mounted) {
        _replyCtrl.clear();
        setState(() {
          _replies.add(added);
        });
      }
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) {
        setState(() => _isSendingReply = false);
      }
    }
  }

  void _deleteReply(CommunityReply reply) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != reply.userId) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.pulseRed),
              title: const Text('Delete Reply', style: TextStyle(color: AppColors.pulseRed, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  setState(() => _replies.removeWhere((r) => r.id == reply.id));
                  await CommunityService().deleteReply(reply.id);
                } catch (_) {}
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Parse stats & mood for visual display
    String cleanContent = widget.post['content'] ?? '';
    List<String> statsChips = [];
    String? moodText;

    if (cleanContent.contains('📊 Stats:')) {
      final parts = cleanContent.split('📊 Stats:');
      cleanContent = parts[0].trim();
      final statsPart = parts[1].split('Feeling:')[0].trim();
      statsChips = statsPart.split(' · ');
    }
    if (cleanContent.contains('Feeling:')) {
      final parts = cleanContent.split('Feeling:');
      if (widget.post['content']?.contains('📊 Stats:') == true) {
        // cleanContent already stripped above
      } else {
        cleanContent = parts[0].trim();
      }
      moodText = parts[1].trim();
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 8,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Post Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // Scrollable area
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info
                  Row(
                    children: [
                      ProfileAvatar(
                        imageUrl: widget.post['author']?['avatar_url'] as String?,
                        name: (widget.post['author']?['full_name'] as String?) ?? 'Anonymous',
                        radius: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (widget.post['author']?['full_name'] as String?) ?? 'Anonymous',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_formatTime(widget.post['created_at'])} • ${widget.post['activity_type'] ?? 'Update'}',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Post content text
                  Text(
                    cleanContent,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontSize: 15),
                  ),

                  // Image (if exists)
                  if (widget.post['image_url'] != null) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.post['image_url'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],

                  // Stats chips Wrap
                  if (statsChips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text("Today's Stats", style: theme.textTheme.labelMedium?.copyWith(color: AppColors.voltCyan, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: statsChips.map((chip) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black12),
                          ),
                          child: Text(
                            chip,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Mood chip
                  if (moodText != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Feeling: ', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.irisViolet.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.irisViolet.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            moodText,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.irisViolet, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Colors.white10),
                  const SizedBox(height: 16),

                  // Replies Title
                  Text(
                    'Replies (${_replies.length})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  // Replies List
                  if (_isLoadingReplies)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                  else if (_replies.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No replies yet.', style: TextStyle(color: AppColors.textSecondary))))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _replies.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reply = _replies[index];
                        final isMe = reply.userId == Supabase.instance.client.auth.currentUser?.id;
                        final displayName = isMe ? 'You' : (reply.userName ?? 'User');
                        
                        return GestureDetector(
                          onLongPress: () => _deleteReply(reply),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isMe ? AppColors.voltCyan : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(reply.createdAt.toIso8601String()),
                                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  reply.replyText,
                                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Inline reply textfield at the very bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceCard : Colors.grey[100],
              border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    style: theme.textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Add a reply...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSendingReply
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.voltCyan))
                      : const Icon(LucideIcons.send, color: AppColors.voltCyan, size: 20),
                  onPressed: _isSendingReply ? null : _sendReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit specific Choice Chip Selector ──

class _EditActivityTypeSelector extends StatelessWidget {
  final String selectedActivity;
  final ValueChanged<String> onSelected;
  final List<String> activities = const [
    'Running',
    'Workout',
    'Study',
    'Nutrition',
    'Recovery',
    'Cycling',
    'Swimming',
    'Yoga',
    'Meditation'
  ];
  final bool isDark;
  final ThemeData theme;

  const _EditActivityTypeSelector({
    required this.selectedActivity,
    required this.onSelected,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final act = activities[index];
          final isSelected = selectedActivity == act;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: isSelected
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
              label: Text(act),
              selected: isSelected,
              onSelected: (val) {
                if (val) onSelected(act);
              },
              backgroundColor: isDark ? AppColors.surfaceCard : Colors.grey[200],
              selectedColor: AppColors.irisViolet,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
