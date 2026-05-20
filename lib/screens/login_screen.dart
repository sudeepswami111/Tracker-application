import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────
// LOGIN / SIGN-UP SCREEN
// Sign-up collects: full name, username (unique), email, password,
// confirm password, mobile number (optional).
// Username is checked live against Supabase for availability.
// ─────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────
  final _fullNameCtrl    = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmPwdCtrl  = TextEditingController();
  final _mobileCtrl      = TextEditingController();

  // ── State ─────────────────────────────────────────────────────
  bool _isLogin          = true;
  bool _isLoading        = false;
  bool _obscurePwd       = true;
  bool _obscureConfirm   = true;

  // Username availability
  bool?   _usernameAvailable;       // null = unchecked, true/false = result
  bool    _checkingUsername = false;
  String  _lastCheckedUsername = '';
  Timer?  _usernameDebounce;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _mobileCtrl.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  // ── Username live-check (debounced 600 ms) ────────────────────
  void _onUsernameChanged(String value) {
    final trimmed = value.trim().toLowerCase();
    _usernameDebounce?.cancel();

    if (trimmed.isEmpty) {
      setState(() { _usernameAvailable = null; _checkingUsername = false; });
      return;
    }

    if (trimmed == _lastCheckedUsername) return;

    setState(() { _checkingUsername = true; _usernameAvailable = null; });

    _usernameDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        // Calls the SQL function: check_username_available(p_username TEXT)
        final result = await _supabase.rpc(
          'check_username_available',
          params: {'p_username': trimmed},
        );
        _lastCheckedUsername = trimmed;
        if (mounted) {
          setState(() {
            _checkingUsername   = false;
            _usernameAvailable  = result as bool;
          });
        }
      } catch (_) {
        if (mounted) setState(() { _checkingUsername = false; });
      }
    });
  }

  // ── Validation ────────────────────────────────────────────────
  String? _validateSignUp() {
    if (_fullNameCtrl.text.trim().isEmpty) return 'Please enter your full name.';
    if (_usernameCtrl.text.trim().isEmpty) return 'Please choose a username.';
    if (_usernameAvailable == false) return 'That username is already taken.';
    if (_emailCtrl.text.trim().isEmpty)    return 'Please enter your email.';
    if (!_emailCtrl.text.contains('@'))    return 'Please enter a valid email.';
    if (_passwordCtrl.text.length < 6)     return 'Password must be at least 6 characters.';
    if (_passwordCtrl.text != _confirmPwdCtrl.text) return 'Passwords do not match.';
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_isLogin) {
      final error = _validateSignUp();
      if (error != null) { _showSnack(error, isError: true); return; }
    } else {
      if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
        _showSnack('Please enter your email and password.', isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _supabase.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        // Pass extra metadata so handle_new_user() trigger picks it up
        await _supabase.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          data: {
            'full_name':     _fullNameCtrl.text.trim(),
            'username':      _usernameCtrl.text.trim().toLowerCase(),
            'mobile_number': _mobileCtrl.text.trim().isEmpty
                ? null
                : _mobileCtrl.text.trim(),
          },
        );
        if (mounted) {
          setState(() => _isLogin = true);
          _showSnack('Account created! You can now log in.', isError: false);
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed')) {
        _showSnack('Check your inbox to confirm your email before logging in.',
            isError: true);
      } else if (msg.contains('invalid login credentials')) {
        _showSnack('Wrong email or password. Please try again.', isError: true);
      } else if (msg.contains('user already registered')) {
        _showSnack('This email is already registered. Try logging in.',
            isError: true);
        setState(() => _isLogin = true);
      } else {
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
        _showSnack('No internet connection.', isError: true);
      } else {
        _showSnack('An error occurred: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message,
      {bool isError = false,
      Duration duration = const Duration(seconds: 4)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red[800] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }

  // ── Username feedback widget ──────────────────────────────────
  Widget _usernameSuffix() {
    if (_usernameCtrl.text.trim().isEmpty) return const SizedBox.shrink();
    if (_checkingUsername) {
      return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_usernameAvailable == true) {
      return const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 20);
    }
    if (_usernameAvailable == false) {
      return const Icon(LucideIcons.xCircle, color: Colors.red, size: 20);
    }
    return const SizedBox.shrink();
  }

  String? _usernameHelperText() {
    if (_usernameCtrl.text.trim().isEmpty) return null;
    if (_checkingUsername) return 'Checking availability…';
    if (_usernameAvailable == true)  return '✓ Username is available';
    if (_usernameAvailable == false) return '✗ Username is already taken';
    return null;
  }

  Color? _usernameHelperColor() {
    if (_usernameAvailable == true)  return Colors.green;
    if (_usernameAvailable == false) return Colors.red;
    return null;
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBg]
                : [AppColors.lightSurface, AppColors.lightBg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Icon(LucideIcons.activity,
                    size: 72, color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  'LifePulse',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLogin
                      ? 'Welcome back! Log in to continue.'
                      : 'Create your account.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 36),

                // ── SIGN-UP ONLY FIELDS ──────────────────────────
                if (!_isLogin) ...[
                  // Full Name
                  _buildField(
                    controller: _fullNameCtrl,
                    label: 'Full Name',
                    icon: LucideIcons.user,
                    isDark: isDark,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),

                  // Username (unique)
                  TextField(
                    controller: _usernameCtrl,
                    onChanged: _onUsernameChanged,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black),
                    inputFormatters: [
                      // Only allow a-z 0-9 _ no spaces
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9_]')),
                      LengthLimitingTextInputFormatter(30),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'e.g. john_doe',
                      prefixIcon: const Icon(LucideIcons.atSign),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _usernameSuffix(),
                      ),
                      helperText: _usernameHelperText(),
                      helperStyle: TextStyle(
                          color: _usernameHelperColor(), fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Email
                _buildField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: LucideIcons.mail,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // Password
                _buildField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  icon: LucideIcons.lock,
                  isDark: isDark,
                  obscure: _obscurePwd,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePwd
                        ? LucideIcons.eyeOff
                        : LucideIcons.eye),
                    onPressed: () =>
                        setState(() => _obscurePwd = !_obscurePwd),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm Password (sign-up only)
                if (!_isLogin) ...[
                  _buildField(
                    controller: _confirmPwdCtrl,
                    label: 'Confirm Password',
                    icon: LucideIcons.lock,
                    isDark: isDark,
                    obscure: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? LucideIcons.eyeOff
                          : LucideIcons.eye),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mobile number (optional)
                  _buildField(
                    controller: _mobileCtrl,
                    label: 'Mobile Number (optional)',
                    icon: LucideIcons.smartphone,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 10),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_isLogin ? 'Log In' : 'Create Account'),
                ),
                const SizedBox(height: 16),

                // Toggle login / sign-up
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _usernameAvailable = null;
                    _lastCheckedUsername = '';
                  }),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : 'Already have an account? Log In',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),

                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: Divider(
                          color: theme.colorScheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  Expanded(
                      child: Divider(
                          color: theme.colorScheme.outlineVariant)),
                ]),
                const SizedBox(height: 24),

                // Google sign-in
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await _supabase.auth.signInWithOAuth(
                        OAuthProvider.google,
                        redirectTo: 'lifepulse://login-callback',
                      );
                    } catch (e) {
                      if (mounted) {
                        _showSnack('Failed to sign in with Google: $e',
                            isError: true);
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.chrome),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.outline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper to build a standard text field ────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
