import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_models.dart';
import '../services/friend_service.dart';

enum FriendProviderState { idle, loading, loaded, error }

class FriendProvider extends ChangeNotifier {
  final FriendService _service = FriendService();

  List<FriendSuggestion> _suggestions = [];
  List<FriendRequest> _incomingRequests = [];
  final Set<String> _sentRequestIds = {};
  final Set<String> _dismissedIds = {};

  FriendProviderState _state = FriendProviderState.idle;
  String _error = '';
  RealtimeChannel? _realtimeChannel;

  List<FriendSuggestion> get suggestions => _suggestions;
  List<FriendRequest> get incomingRequests => _incomingRequests;
  Set<String> get sentRequestIds => _sentRequestIds;
  FriendProviderState get state => _state;
  String get error => _error;
  bool get isLoading => _state == FriendProviderState.loading;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  // ─── Load everything ──────────────────────────────────────────────
  Future<void> init() async {
    final uid = _userId;
    if (uid == null) return;

    _state = FriendProviderState.loading;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getFriendSuggestions(uid),
        _service.getIncomingRequests(uid),
      ]);
      _suggestions = results[0] as List<FriendSuggestion>;
      _incomingRequests = results[1] as List<FriendRequest>;
      _state = FriendProviderState.loaded;

      _subscribeRealtime(uid);
    } catch (e) {
      _error = e.toString();
      _state = FriendProviderState.error;
      if (kDebugMode) print('FriendProvider.init error: $e');
    }

    notifyListeners();
  }

  // ─── Send friend request (optimistic) ────────────────────────────
  Future<void> sendRequest(String toUserId) async {
    final uid = _userId;
    if (uid == null) return;

    // Optimistic: immediately mark as sent so button changes
    _sentRequestIds.add(toUserId);
    notifyListeners();

    final success = await _service.sendFriendRequest(uid, toUserId);
    if (!success) {
      _sentRequestIds.remove(toUserId);
      notifyListeners();
    }
  }

  // ─── Dismiss a suggestion ────────────────────────────────────────
  Future<void> dismiss(String profileId) async {
    final uid = _userId;
    if (uid == null) return;

    _dismissedIds.add(profileId);
    _suggestions.removeWhere((s) => s.profile.id == profileId);
    notifyListeners();

    await _service.dismissSuggestion(uid, profileId);
  }

  // ─── Accept incoming request ─────────────────────────────────────
  Future<void> acceptRequest(String requestId) async {
    final success = await _service.acceptFriendRequest(requestId);
    if (success) {
      _incomingRequests.removeWhere((r) => r.id == requestId);
      notifyListeners();
    }
  }

  // ─── Reject incoming request ─────────────────────────────────────
  Future<void> rejectRequest(String requestId) async {
    final success = await _service.rejectFriendRequest(requestId);
    if (success) {
      _incomingRequests.removeWhere((r) => r.id == requestId);
      notifyListeners();
    }
  }

  // ─── Refresh suggestions ─────────────────────────────────────────
  Future<void> refreshSuggestions() async {
    final uid = _userId;
    if (uid == null) return;
    _suggestions = await _service.getFriendSuggestions(uid);
    notifyListeners();
  }

  // ─── Realtime subscription ───────────────────────────────────────
  void _subscribeRealtime(String uid) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _service.subscribeToFriendRequests(
      uid,
      onNew: (request) {
        _incomingRequests.insert(0, request);
        notifyListeners();
      },
      onUpdate: (request) {
        final idx = _incomingRequests.indexWhere((r) => r.id == request.id);
        if (idx >= 0) {
          _incomingRequests[idx] = request;
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
