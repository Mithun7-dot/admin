// ─────────────────────────────────────────────────────────────────────────────
// login_screen.dart — Admin login page
// Route: /login
//
// How it works:
//   1. Renders a centered login card (email + password fields).
//   2. On submit, calls Supabase signInWithPassword.
//   3. After successful auth, queries the `users` table to check role == 'admin'.
//   4. If not admin: signs out immediately and shows "Access denied" error.
//   5. If admin: navigates to /dashboard using GoRouter.
//
// Error handling:
//   - AuthException (wrong password, user not found) → inline error banner
//   - Non-admin user → inline error banner
//   - Any other error → inline error banner
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../widgets/admin_brand_logo.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController(text: '');
  final _passCtrl = TextEditingController();
  bool _loading = false; // Controls the loading spinner on the button
  String? _error; // Non-null when there is an auth error to display
  bool _obscure = true; // Controls password visibility toggle
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    // Check if user is already signed in (e.g., after OAuth redirect)
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSignedIn();
      });
      return;
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (event) {
        if (event.event == AuthChangeEvent.signedIn && mounted) {
          _handleSignedIn();
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignedIn() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();

      if (userData == null ||
          ![
            'admin',
            'ceo',
            'stock_manager',
            'pricing_manager',
            'order_manager',
            'qa_manager'
          ].contains(userData['role'])) {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          setState(() => _error = 'Access denied. Admin accounts only.');
        }
        return;
      }

      if (mounted) context.go('/dashboard');
    } catch (e) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        setState(() =>
            _error = 'Unable to verify admin permissions. Please try again.');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // For web OAuth, don't specify redirectTo — let Supabase handle it automatically
      // This prevents localhost redirect issues by using the current app URL
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
      );

      if (!launched && mounted) {
        setState(() =>
            _error = 'Unable to launch Google sign-in. Please try again.');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Called when the user taps "SIGN IN TO ADMIN" or presses Enter.
  Future<void> _signIn() async {
    // Guard: do nothing if fields are empty
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Step 1: Authenticate with Supabase Auth
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (res.user == null) throw Exception('Authentication failed');
      await _handleSignedIn();
    } on AuthException catch (e) {
      // Supabase-specific auth errors (e.g. invalid credentials)
      setState(() => _error = e.message);
    } catch (e) {
      // Any other errors
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Brand logo row ──────────────────────────────────────────────
              const AdminBrandLogo(),
              const SizedBox(height: 40),

              // Page title
              const Text('SIGN IN',
                  style: TextStyle(
                      fontFamily: 'Epilogue',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Administrator access only',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: AdminColors.textMuted)),
              const SizedBox(height: 32),

              // ── Email field ─────────────────────────────────────────────────
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style:
                    const TextStyle(fontFamily: 'Manrope', color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined,
                      size: 18, color: AdminColors.textMuted),
                ),
                onSubmitted: (_) => _signIn(), // Allow pressing Enter to submit
              ),
              const SizedBox(height: 16),

              // ── Password field (with show/hide toggle) ──────────────────────
              TextField(
                controller: _passCtrl,
                obscureText: _obscure, // Hides chars when true
                style:
                    const TextStyle(fontFamily: 'Manrope', color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline,
                      size: 18, color: AdminColors.textMuted),
                  suffixIcon: IconButton(
                    // Toggle between eye-off and eye icons
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AdminColors.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _signIn(),
              ),

              // ── Error banner (shown only when _error is not null) ───────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AdminColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: AdminColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontFamily: 'Manrope',
                                color: AdminColors.error,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('SIGN IN WITH GOOGLE'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Submit button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  // Disabled (grayed out) while loading to prevent double-submit
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('SIGN IN TO ADMIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
