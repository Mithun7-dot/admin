// ─────────────────────────────────────────────────────────────────────────────
// orders_screen.dart — Order management screen (responsive)
// Route: /orders
//
// Features:
//   • Lists all orders with customer info (joined from `users` table)
//   • Filter chips at top: All | Pending | Confirmed | Processing |
//     Shipped | Delivered | Cancelled
//   • Inline status update dropdown — changes order status immediately
//   • Colour-coded status badges
//   • Responsive: table on desktop, card list on mobile
//
// Supabase tables: orders (joined with users)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../layouts/admin_layout.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filter = 'all'; // Currently selected filter chip

  // All possible filter options shown as chips
  final _statuses = [
    'all',
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches orders from Supabase.
  /// If _filter is 'all' → fetches everything.
  /// Otherwise → adds .eq('status', _filter) to narrow results.
  /// The join `.select('*, users(email,full_name,phone)')` pulls customer info
  /// from the `users` table automatically via the foreign key.
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final data = _filter == 'all'
          ? await Supabase.instance.client
              .from('orders')
              .select('*, users(email,full_name,phone)')
              .order('created_at', ascending: false)
          : await Supabase.instance.client
              .from('orders')
              .select('*, users(email,full_name,phone)')
              .eq('status', _filter)
              .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (error, stack) {
      debugPrint('Orders load exception: $error\n$stack');
      if (mounted) {
        setState(() {
          _orders = [];
          _loading = false;
        });
      }
    }
  }

  /// Updates the status of a single order in the database.
  /// Called when the admin changes the dropdown for a row.
  Future<void> _updateStatus(String orderId, String status) async {
    await Supabase.instance.client
        .from('orders')
        .update({'status': status}).eq('id', orderId);
    if (mounted) _load(); // Refresh the list after update
  }

  @override
  Widget build(BuildContext context) {
    final pad = responsivePadding(context);

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
                title: 'Orders', subtitle: '${_orders.length} orders'),
            const SizedBox(height: 24),

            // ── Filter chips ──────────────────────────────────────────────────
            // Horizontally scrollable row of filter buttons at the top
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statuses.map((s) {
                    final active = _filter == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          // Update filter and reload data from Supabase
                          setState(() => _filter = s);
                          _load();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            // Active chip: gold background; inactive: dark card
                            color:
                                active ? AdminColors.accent : AdminColors.card,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: active
                                    ? AdminColors.accent
                                    : AdminColors.border),
                          ),
                          child: Text(s.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Manrope', fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w800,
                                // Active chip: black text; inactive: muted text
                                color: active
                                    ? Colors.black
                                    : AdminColors.textSecondary,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: _loading
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                              color: AdminColors.accent)))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 800) return _buildTable();
                        return _buildCardList();
                      },
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Desktop Table ──────────────────────────────────────────────────────────
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        children: [
          // Table header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              _h('ORDER', 2),
              _h('CUSTOMER', 3),
              _h('TOTAL', 1),
              _h('STATUS', 2),
              _h('DATE', 2),
              _h('UPDATE', 2),
            ]),
          ),
          const Divider(height: 1, color: AdminColors.border),

          if (_orders.isEmpty)
            const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: Text('No orders found',
                        style: TextStyle(
                            fontFamily: 'Manrope',
                            color: AdminColors.textMuted)))),

          // One row per order
          ..._orders.asMap().entries.map((e) {
            final o = e.value;
            // `users` is the joined object from the foreign key relationship
            final user = o['users'] as Map<String, dynamic>?;
            final email = user?['email'] as String? ?? '—';
            final mobile = user?['phone'] as String? ?? '—';
            final date = DateTime.parse(o['created_at'] as String).toLocal();

            return Column(children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  // Order number
                  Expanded(
                      flex: 2,
                      child: Text(o['order_number'] as String? ?? '—',
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white))),

                  // Customer email + mobile (from joined users table)
                  Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email,
                              style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  color: AdminColors.textSecondary),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(mobile,
                              style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  color: AdminColors.textMuted),
                              overflow: TextOverflow.ellipsis),
                        ],
                      )),

                  // Order total
                  Expanded(
                      flex: 1,
                      child: Text('₹${o['total']}',
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white))),

                  // Colour-coded status badge
                  Expanded(
                      flex: 2,
                      child: _OrderStatusBadge(status: o['status'] as String)),

                  // Formatted date
                  Expanded(
                      flex: 2,
                      child: Text('${date.day}/${date.month}/${date.year}',
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              color: AdminColors.textMuted))),

                  // ── Status dropdown ────────────────────────────────────────
                  Expanded(
                      flex: 2,
                      child: DropdownButton<String>(
                        value: o['status'] as String,
                        dropdownColor: AdminColors.surfaceHigh,
                        underline:
                            Container(height: 1, color: AdminColors.border),
                        style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            color: Colors.white),
                        isExpanded: true,
                        items: [
                          'pending',
                          'confirmed',
                          'processing',
                          'shipped',
                          'delivered',
                          'cancelled',
                          'refunded'
                        ]
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) _updateStatus(o['id'] as String, v);
                        },
                      )),
                ]),
              ),
              if (e.key < _orders.length - 1)
                const Divider(height: 1, color: AdminColors.border),
            ]);
          }),
        ],
      ),
    );
  }

  // ── Mobile Card List ────────────────────────────────────────────────────────
  Widget _buildCardList() {
    if (_orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
            child: Text('No orders found',
                style: TextStyle(
                    fontFamily: 'Manrope', color: AdminColors.textMuted))),
      );
    }

    return Column(
      children: _orders.map((o) {
        final user = o['users'] as Map<String, dynamic>?;
        final email = user?['email'] as String? ?? '—';
        final mobile = user?['phone'] as String? ?? '—';
        final date = DateTime.parse(o['created_at'] as String).toLocal();
        final status = o['status'] as String;

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
              // Order number + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(o['order_number'] as String? ?? '—',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  _OrderStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),
              // Customer email + mobile number
              Text(email,
                  style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: AdminColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(mobile,
                  style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: AdminColors.textMuted),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              // Total + date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹${o['total']}',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          color: AdminColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              // Update status dropdown
              Row(
                children: [
                  const Text('Update: ',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: AdminColors.textMuted)),
                  Expanded(
                    child: DropdownButton<String>(
                      value: status,
                      dropdownColor: AdminColors.surfaceHigh,
                      underline:
                          Container(height: 1, color: AdminColors.border),
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: Colors.white),
                      isExpanded: true,
                      items: [
                        'pending',
                        'confirmed',
                        'processing',
                        'shipped',
                        'delivered',
                        'cancelled',
                        'refunded'
                      ]
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _updateStatus(o['id'] as String, v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Helper: table header cell with uppercase label and muted color.
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

// ── Order Status Badge ────────────────────────────────────────────────────────
// Note: This is a local copy; the Dashboard has its own identical _StatusBadge.
// They are kept separate to avoid coupling between screens.
class _OrderStatusBadge extends StatelessWidget {
  final String status;
  const _OrderStatusBadge({required this.status});

  static const _colors = {
    'pending': Color(0xFFFF9800),
    'confirmed': Color(0xFF2196F3),
    'processing': Color(0xFF9C27B0),
    'shipped': Color(0xFF00BCD4),
    'delivered': Color(0xFF4CAF50),
    'cancelled': Color(0xFFEF5350),
    'refunded': Color(0xFFEF5350),
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[status] ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              color: c)),
    );
  }
}
