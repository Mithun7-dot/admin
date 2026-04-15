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

  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
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

      // Step 2: Check if the logged-in user has an admin-level role
      // We query the public `users` table (NOT auth.users) which has a `role` column
      const validRoles = [
        'admin',
        'ceo',
        'stock_manager',
        'pricing_manager',
        'order_manager',
        'qa_manager'
      ];
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', res.user!.id)
          .maybeSingle(); // Returns null if no row found (safe, no exception)

      // Step 3: Reject non-admin users
      if (userData == null || !validRoles.contains(userData['role'])) {
        // Sign them out of Supabase Auth immediately
        await Supabase.instance.client.auth.signOut();
        setState(() => _error = 'Access denied. Admin accounts only.');
        return;
      }

      // Step 4: All checks passed — navigate to dashboard
      if (mounted) context.go('/dashboard');
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
