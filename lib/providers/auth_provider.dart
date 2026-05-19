import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        _user = data.session?.user;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'lifepulse://login-callback',
      );
    } catch (e) {
      debugPrint("Error signing in with Google: \$e");
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Safety net: ensure profile row exists (handles users who signed up before DB trigger)
      final userId = response.user?.id;
      if (userId != null) {
        await _ensureProfileExists(userId, email);
      }
    } catch (e) {
      debugPrint("Error signing in with Email: \$e");
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Safety net: upsert profile row in case DB trigger didn't fire
      final userId = response.user?.id;
      if (userId != null) {
        await _ensureProfileExists(userId, email);
      }
    } catch (e) {
      debugPrint("Error signing up with Email: \$e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: \$e");
    }
  }

  // ─── Upserts a minimal profile row — safe to call on every login ──
  Future<void> _ensureProfileExists(String userId, String email) async {
    try {
      final name = email.split('@')[0];
      await _supabase.from('profiles').upsert(
        {
          'id': userId,
          'name': name,
        },
        onConflict: 'id',
        ignoreDuplicates: true,  // Don't overwrite existing name if profile already exists
      );
      debugPrint('✅ Profile ensured for $userId');
    } catch (e) {
      debugPrint('⚠️ _ensureProfileExists error (non-fatal): $e');
      // Non-fatal — don't rethrow, let login proceed
    }
  }
}
