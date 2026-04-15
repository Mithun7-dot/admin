import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../layouts/admin_layout.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});
  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    // Check if current user is CEO
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    final me = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', authUser.id)
        .single();
    if (me['role'] != 'ceo') {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Access Denied: Only CEO can access roles.')));
      }
      return;
    }

    try {
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
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateRole(String id, String newRole) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'role': newRole}).eq('id', id);
      if (mounted) _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Role updated!'),
            backgroundColor: AdminColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = responsivePadding(context);

    return Scaffold(
        backgroundColor: AdminColors.bg,
        body: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AdminPageHeader(
              title: 'Role Management',
              subtitle: 'Manage staff roles and access'),
          const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AdminColors.accent))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 700) return _buildTable();
                      return _buildCardList();
                    },
                  ),
          ),
          const SizedBox(height: 40),
        ])));
  }

  // ── Desktop Table ──────────────────────────────────────────────────────────
  Widget _buildTable() {
    if (_users.isEmpty) {
      return const Center(
          child: Text('No users found', style: TextStyle(color: Colors.white)));
    }
    return Container(
        decoration: BoxDecoration(
          color: AdminColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.border),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              _h('USER', 4),
              _h('EMAIL', 4),
              _h('ROLE', 3),
            ]),
          ),
          const Divider(height: 1, color: AdminColors.border),
          ..._users.asMap().entries.map((e) {
            final u = e.value;
            final isCEO = u['role'] == 'ceo';
            return Column(children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                        flex: 4,
                        child: Text(u['full_name'] ?? '—',
                            style: const TextStyle(
                                color: Colors.white, fontFamily: 'Manrope'))),
                    Expanded(
                        flex: 4,
                        child: Text(u['email'] ?? '—',
                            style: const TextStyle(
                                color: AdminColors.textMuted,
                                fontFamily: 'Manrope'),
                            overflow: TextOverflow.ellipsis)),
                    Expanded(
                        flex: 3,
                        child: isCEO
                            ? const Text('CEO',
                                style: TextStyle(
                                    color: AdminColors.accent,
                                    fontFamily: 'Epilogue',
                                    fontWeight: FontWeight.bold))
                            : Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 150),
                                child: DropdownButtonFormField<String>(
                                  initialValue: u['role'],
                                  dropdownColor: AdminColors.surfaceHigh,
                                  decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Manrope',
                                      fontSize: 11),
                                  isDense: true,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'customer',
                                        child: Text('Customer')),
                                    DropdownMenuItem(
                                        value: 'admin', child: Text('Admin')),
                                    DropdownMenuItem(
                                        value: 'stock_manager',
                                        child: Text('Stock Manager')),
                                    DropdownMenuItem(
                                        value: 'pricing_manager',
                                        child: Text('Pricing Manager')),
                                    DropdownMenuItem(
                                        value: 'order_manager',
                                        child: Text('Order Manager')),
                                    DropdownMenuItem(
                                        value: 'qa_manager',
                                        child: Text('QA/Review Manager')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) _updateRole(u['id'], v);
                                  },
                                ),
                              )),
                  ],
                ),
              ),
              if (e.key < _users.length - 1)
                const Divider(height: 1, color: AdminColors.border),
            ]);
          }),
        ]));
  }

  // ── Mobile Card List ────────────────────────────────────────────────────────
  Widget _buildCardList() {
    if (_users.isEmpty) {
      return const Center(
          child: Text('No users found', style: TextStyle(color: Colors.white)));
    }

    return Column(
      children: _users.map((u) {
        final isCEO = u['role'] == 'ceo';
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
              // Name
              Text(u['full_name'] ?? '—',
                  style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 4),
              // Email
              Text(u['email'] ?? '—',
                  style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: AdminColors.textMuted),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              // Role selector
              if (isCEO)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('CEO',
                      style: TextStyle(
                          color: AdminColors.accent,
                          fontFamily: 'Epilogue',
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: u['role'],
                  dropdownColor: AdminColors.surfaceHigh,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    isDense: true,
                  ),
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'Manrope', fontSize: 13),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'customer', child: Text('Customer')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                        value: 'stock_manager', child: Text('Stock Manager')),
                    DropdownMenuItem(
                        value: 'pricing_manager',
                        child: Text('Pricing Manager')),
                    DropdownMenuItem(
                        value: 'order_manager', child: Text('Order Manager')),
                    DropdownMenuItem(
                        value: 'qa_manager', child: Text('QA/Review Manager')),
                  ],
                  onChanged: (v) {
                    if (v != null) _updateRole(u['id'], v);
                  },
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _h(String t, int flex) => Expanded(
      flex: flex,
      child: Text(t,
          style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.textMuted)));
}
