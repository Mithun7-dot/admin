// ─────────────────────────────────────────────────────────────────────────────
// users_screen.dart — User + Admin management
//
// Features:
//   • Lists all registered users in a responsive table/card view
//   • Primary admin: identified by is_primary_admin = true
//     - Cannot be demoted, displayed with a shield badge
//     - ONLY the primary admin can manage other admins
//   • Secondary admin management: promote / demote (only by primary admin)
//   • Password reset: sends a reset email via Supabase Auth
//   • Fully responsive: table on desktop, cards on mobile
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../layouts/admin_layout.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const String _allowedManagerEmail = 'mithunsrinivas86@gmail.com';

  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _currentIsPrimary = false;
  bool _canManageUsers = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final email = currentUser?.email?.trim().toLowerCase();
    if (mounted) {
      setState(() {
        _canManageUsers = email == _allowedManagerEmail;
      });
    }
    _currentUserId = currentUser?.id;
    await _checkCurrentPrimary();
    await _load();
  }

  Future<void> _checkCurrentPrimary() async {
    if (_currentUserId == null) return;
    final data = await Supabase.instance.client
        .from('users')
        .select('is_primary_admin')
        .eq('id', _currentUserId!)
        .maybeSingle();
    if (mounted) {
      setState(() => _currentIsPrimary = data?['is_primary_admin'] == true);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    if (mounted) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  Future<void> _setRole(String userId, String role) async {
    if (!_currentIsPrimary) {
      _showError('Only the primary admin can change roles.');
      return;
    }
    await Supabase.instance.client
        .from('users')
        .update({'role': role}).eq('id', userId);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to $role')),
      );
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    if (!_currentIsPrimary) {
      _showError('Only the primary admin can reset passwords.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email')),
        );
      }
    } catch (e) {
      if (mounted) _showError('Failed to send reset email: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AdminColors.error.withOpacity(0.9),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget? _buildHeaderAction() {
    final children = <Widget>[];
    if (_currentIsPrimary) children.add(_primaryBadge());
    if (_canManageUsers) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 12));
      children.add(ElevatedButton.icon(
        onPressed: _showAddUserDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.person_add_outlined, size: 16),
        label: const Text('Add User',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ));
    }
    if (children.isEmpty) return null;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _primaryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AdminColors.accent.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: AdminColors.accent, size: 14),
          SizedBox(width: 6),
          Text(
            'PRIMARY ADMIN',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AdminColors.accent),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUserDialog() async {
    if (!_canManageUsers) {
      _showError('Only mithunsrinivas86@gmail.com can add users.');
      return;
    }

    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AdminColors.card,
          title: const Text('Register new user',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'user@gmail.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'John Doe',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter a password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                final fullName = nameCtrl.text.trim();
                final password = passwordCtrl.text.trim();
                if (email.isEmpty || fullName.isEmpty || password.isEmpty) {
                  _showError('Please enter email, full name, and password.');
                  return;
                }
                final success = await _signUpUser(email, password, fullName);
                if (success) {
                  if (mounted) Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Register'),
            ),
          ],
        );
      },
    );

    emailCtrl.dispose();
    nameCtrl.dispose();
    passwordCtrl.dispose();
  }

  Future<bool> _signUpUser(
      String email, String password, String fullName) async {
    if (!_canManageUsers) {
      _showError('Only mithunsrinivas86@gmail.com can add users.');
      return false;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      final newUser = response.user;
      if (newUser == null) {
        throw Exception('User creation failed.');
      }

      await Supabase.instance.client.from('users').insert([
        {
          'id': newUser.id,
          'email': email,
          'full_name': fullName,
          'role': 'customer',
        }
      ]);
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User registered successfully.'),
          backgroundColor: AdminColors.success,
        ));
      }
      return true;
    } catch (e) {
      if (mounted) _showError('Failed to register user: $e');
      return false;
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    if (!_canManageUsers) {
      _showError('Only mithunsrinivas86@gmail.com can remove users.');
      return;
    }

    if (userId == _currentUserId) {
      _showError('You cannot remove your own account.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AdminColors.card,
          title: const Text('Remove user',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Text('Are you sure you want to remove $email?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await Supabase.instance.client.from('users').delete().eq('id', userId);
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User removed successfully.'),
          backgroundColor: AdminColors.error,
        ));
      }
    } catch (e) {
      if (mounted) _showError('Failed to remove user: $e');
    }
  }

  Future<void> _toggleUserActive(String userId, bool enable) async {
    if (!_canManageUsers) {
      _showError('Only mithunsrinivas86@gmail.com can update user status.');
      return;
    }

    if (userId == _currentUserId && !enable) {
      _showError('You cannot disable your own account.');
      return;
    }

    try {
      await Supabase.instance.client
          .from('users')
          .update({'is_active': enable}).eq('id', userId);
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(enable
              ? 'User enabled successfully.'
              : 'User disabled successfully.'),
          backgroundColor: enable ? AdminColors.success : AdminColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to ${enable ? 'enable' : 'disable'} user: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = responsivePadding(context);

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminPageHeader(
            title: 'Users',
            subtitle: '${_users.length} registered users',
            action: _buildHeaderAction(),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _loading
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: AdminColors.accent),
                  ))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 900) {
                        return _buildTable();
                      }
                      return _buildCardList();
                    },
                  ),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // ── Desktop Table ────────────────────────────────────────────────────────────

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 780),
        child: Container(
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(children: [
                _h('USER', 3),
                _h('EMAIL', 3),
                _h('ROLE', 1),
                _h('JOINED', 2),
                _h('STATUS', 1),
                _h('ACTIONS', 3),
              ]),
            ),
            const Divider(height: 1, color: AdminColors.border),
            if (_users.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: Text('No users yet.',
                        style: TextStyle(
                            fontFamily: 'Manrope',
                            color: AdminColors.textMuted))),
              ),
            ..._users.asMap().entries.map((e) {
              final u = e.value;
              final date = DateTime.parse(u['created_at'] as String? ??
                      DateTime.now().toIso8601String())
                  .toLocal();
              final isAdmin = u['role'] == 'admin';
              final isPrimary = u['is_primary_admin'] == true;
              final isActive = u['is_active'] as bool? ?? true;
              final email = u['email'] as String? ?? '';

              return Column(children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(children: [
                    // User + avatar
                    Expanded(
                        flex: 3,
                        child: Row(children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isPrimary
                                  ? AdminColors.accent.withOpacity(0.15)
                                  : isAdmin
                                      ? AdminColors.info.withOpacity(0.15)
                                      : AdminColors.surfaceHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                ((u['full_name'] as String?)?.isNotEmpty == true
                                        ? u['full_name']![0]
                                        : (u['email'] as String?)?.isNotEmpty ==
                                                true
                                            ? u['email']![0]
                                            : '?')
                                    .toUpperCase(),
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isPrimary
                                        ? AdminColors.accent
                                        : isAdmin
                                            ? AdminColors.info
                                            : Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u['full_name'] as String? ?? '—',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ])),
                    Expanded(
                        flex: 3,
                        child: Text(email,
                            style: const TextStyle(
                                fontSize: 11, color: AdminColors.textSecondary),
                            overflow: TextOverflow.ellipsis)),
                    // Role badge
                    Expanded(flex: 1, child: _roleBadge(u)),
                    // Date
                    Expanded(
                        flex: 2,
                        child: Text('${date.day}/${date.month}/${date.year}',
                            style: const TextStyle(
                                fontSize: 11, color: AdminColors.textMuted))),
                    // Status toggle
                    Expanded(
                        flex: 1,
                        child: _canManageUsers
                            ? Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: isActive,
                                  onChanged: (value) =>
                                      _toggleUserActive(u['id'], value),
                                  activeThumbColor: AdminColors.success,
                                  inactiveThumbColor: AdminColors.error,
                                ),
                              )
                            : Center(
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: isActive
                                          ? AdminColors.success
                                          : AdminColors.error),
                                ),
                              )),
                    // Actions
                    Expanded(
                        flex: 3,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: _buildActions(
                              u, email, isPrimary, isAdmin, false),
                        )),
                  ]),
                ),
                if (e.key < _users.length - 1)
                  const Divider(height: 1, color: AdminColors.border),
              ]);
            }),
          ]),
        ),
      ),
    );
  }

  // ── Mobile Card List ─────────────────────────────────────────────────────────

  Widget _buildCardList() {
    if (_users.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(48),
        child: Text('No users yet.',
            style:
                TextStyle(fontFamily: 'Manrope', color: AdminColors.textMuted)),
      ));
    }
    return Column(
      children: _users.map((u) {
        final isAdmin = u['role'] == 'admin';
        final isPrimary = u['is_primary_admin'] == true;
        final isActive = u['is_active'] as bool? ?? true;
        final email = u['email'] as String? ?? '';
        final date = DateTime.parse(
                u['created_at'] as String? ?? DateTime.now().toIso8601String())
            .toLocal();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      u['full_name'] as String? ?? '—',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  _roleBadge(u),
                ],
              ),
              const SizedBox(height: 4),
              Text(email,
                  style: const TextStyle(
                      fontSize: 11, color: AdminColors.textSecondary)),
              const SizedBox(height: 4),
              Text('Joined: ${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                      fontSize: 10, color: AdminColors.textMuted)),
              const SizedBox(height: 12),
              // Status toggle for mobile
              Row(
                children: [
                  const Text('Status: ',
                      style: TextStyle(
                          fontSize: 11, color: AdminColors.textSecondary)),
                  _canManageUsers
                      ? Expanded(
                          child: Switch(
                            value: isActive,
                            onChanged: (value) =>
                                _toggleUserActive(u['id'], value),
                            activeThumbColor: AdminColors.success,
                            inactiveThumbColor: AdminColors.error,
                          ),
                        )
                      : Expanded(
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                                fontSize: 11,
                                color: isActive
                                    ? AdminColors.success
                                    : AdminColors.error),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: _buildActions(u, email, isPrimary, isAdmin, true),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _roleBadge(Map<String, dynamic> u) {
    final isAdmin = u['role'] == 'admin';
    final isPrimary = u['is_primary_admin'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary
            ? AdminColors.accent.withOpacity(0.1)
            : isAdmin
                ? AdminColors.info.withOpacity(0.1)
                : AdminColors.surfaceHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPrimary)
            const Icon(Icons.shield_outlined,
                color: AdminColors.accent, size: 10),
          if (isPrimary) const SizedBox(width: 4),
          Text(
            isPrimary
                ? 'PRIMARY ADMIN'
                : (u['role'] as String? ?? 'customer').toUpperCase(),
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                color: isPrimary
                    ? AdminColors.accent
                    : isAdmin
                        ? AdminColors.info
                        : AdminColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Map<String, dynamic> u, String email, bool isPrimary,
      bool isAdmin, bool isMobile) {
    if (!_currentIsPrimary && !_canManageUsers) return const SizedBox();

    final children = <Widget>[
      // Role toggle (only primary admin can manage roles)
      if (_currentIsPrimary && !isPrimary)
        if (!isAdmin)
          _actionBtn(
            'Make Admin',
            Icons.admin_panel_settings_outlined,
            AdminColors.accent,
            () => _setRole(u['id'], 'admin'),
          )
        else
          _actionBtn(
            'Revoke Admin',
            Icons.person_off_outlined,
            AdminColors.error,
            () => _setRole(u['id'], 'customer'),
          ),
      // Password reset (only primary admin)
      if (_currentIsPrimary)
        _actionBtn(
          'Reset Pwd',
          Icons.lock_reset_outlined,
          AdminColors.info,
          () => _sendPasswordReset(email),
        ),
      // Delete user (default manager can remove users)
      if (_canManageUsers)
        _actionBtn(
          'Remove',
          Icons.delete_outline,
          AdminColors.error,
          () => _deleteUser(u['id'], email),
        ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    } else {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: children,
      );
    }
  }

  Widget _h(String t, int flex) => Expanded(
      flex: flex,
      child: Text(t,
          style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.textMuted)));

  Widget _actionBtn(
          String label, IconData icon, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ]),
        ),
      );
}
