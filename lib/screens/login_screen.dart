import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false, Duration duration = const Duration(seconds: 4)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[800] : null,
        duration: duration,
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password.', isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();

    try {
      if (_isLogin) {
        await authProvider.signInWithEmail(email, password);
      } else {
        await authProvider.signUpWithEmail(email, password);
        if (mounted) {
          // Auto-switch to login with email pre-filled
          setState(() {
            _isLogin = true;
          });
          _showSnackBar('Account created! You can now log in.', duration: const Duration(seconds: 5));
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      // Provide actionable messages for common Supabase errors
      if (e.message.toLowerCase().contains('email not confirmed')) {
        _showSnackBar(
          'Please confirm your email first — check your inbox, or disable email confirmation in Supabase.',
          isError: true,
          duration: const Duration(seconds: 6),
        );
      } else if (e.message.toLowerCase().contains('invalid login credentials')) {
        _showSnackBar('Wrong email or password. Please try again.', isError: true);
      } else if (e.message.toLowerCase().contains('user already registered')) {
        _showSnackBar('This email is already registered. Try logging in instead.', isError: true);
        setState(() => _isLogin = true);
      } else {
        _showSnackBar(e.message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
        _showSnackBar('No internet connection. Please check your network and try again.', isError: true);
      } else {
        _showSnackBar('An error occurred: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.read<AuthProvider>();

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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  LucideIcons.activity,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'LifePulse',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome back! Log in to continue.' : 'Create an account to get started.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(LucideIcons.mail),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(LucideIcons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(_isLogin ? 'Log In' : 'Sign Up'),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In",
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 32),

                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await authProvider.signInWithGoogle();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to sign in with Google: \$e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.chrome),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
}
