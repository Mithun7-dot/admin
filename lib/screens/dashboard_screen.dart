// ─────────────────────────────────────────────────────────────────────────────
// dashboard_screen.dart — Overview/home screen
// Route: /dashboard
//
// Shows:
//   1. A responsive grid of 4 KPI stat cards (Revenue, Orders, Products, Customers)
//   2. A table of the 8 most recent orders
//
// Data fetching strategy:
//   - Uses Future.wait([...]) to fire all 6 Supabase queries IN PARALLEL,
//     which is faster than awaiting each one sequentially.
//   - FutureBuilder is used to show a loading state while data loads.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../layouts/admin_layout.dart';

/// Dashboard is a StatelessWidget because it doesn't hold mutable state.
/// All data is loaded async via FutureBuilder each time the widget builds.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Loads all 6 stats simultaneously using Future.wait.
  /// Returns a Map with keys: revenue, orders, products, customers,
  /// pendingOrders, activeProducts.
  Future<Map<String, dynamic>> _loadStats() async {
    final db = Supabase.instance.client;

    // Fire all queries at the same time (parallel, not sequential)
    final results = await Future.wait([
      db
          .from('orders')
          .select('total')
          .eq('payment_status', 'paid'), // [0] paid orders
      db.from('orders').select('id'), // [1] all orders
      db.from('products').select('id'), // [2] all products
      db.from('users').select('id'), // [3] all users (customers)
      db
          .from('orders')
          .select('id')
          .eq('status', 'pending'), // [4] pending orders
      db
          .from('products')
          .select('id')
          .eq('is_active', true), // [5] active products
    ]);

    // Calculate total revenue by summing all paid order totals
    final paidOrders = results[0] as List;
    final revenue = paidOrders.fold<double>(
        0, (sum, o) => sum + (o['total'] as num).toDouble());

    return {
      'revenue': revenue,
      'orders': (results[1] as List).length,
      'products': (results[2] as List).length,
      'customers': (results[3] as List).length,
      'pendingOrders': (results[4] as List).length,
      'activeProducts': (results[5] as List).length,
    };
  }

  /// Loads the 8 most recent orders, joining user email via foreign key.
  /// The `.select('order_number, status, total, created_at, users(email)')`
  /// automatically joins the `users` table on orders.user_id = users.id.
  Future<List<Map<String, dynamic>>> _loadRecentOrders() async {
    final data = await Supabase.instance.client
        .from('orders')
        .select('order_number, status, total, created_at, users(email)')
        .order('created_at', ascending: false) // Newest first
        .limit(8); // Only 8 rows
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    final pad = responsivePadding(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPageHeader(
            title: 'Dashboard',
            subtitle: 'Welcome back, Admin',
          ),
          const SizedBox(height: 32),

          // ── Stats Grid ──────────────────────────────────────────────────────
          // FutureBuilder rebuilds when _loadStats() completes.
          // Shows dashes (—) while loading.
          FutureBuilder<Map<String, dynamic>>(
            future: _loadStats(),
            builder: (context, snapshot) {
              final stats = snapshot.data; // null while loading
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive column count: 4 on wide, 2 on medium, 1 on narrow
                    final crossCount = constraints.maxWidth > 1200
                        ? 4
                        : constraints.maxWidth > 700
                            ? 2
                            : 1;
                    final aspect = constraints.maxWidth > 700 ? 2.0 : 2.8;
                    return GridView.count(
                      crossAxisCount: crossCount,
                      shrinkWrap: true,
                      crossAxisSpacing: isMobile ? 8 : 16,
                      mainAxisSpacing: isMobile ? 8 : 16,
                      childAspectRatio: aspect,
                      physics:
                          const NeverScrollableScrollPhysics(), // Outer scroll handles scrolling
                      children: [
                        AdminStatCard(
                          label: 'TOTAL REVENUE',
                          // Format to 0 decimal places; show — while loading
                          value: stats != null
                              ? '₹${(stats['revenue'] as double).toStringAsFixed(0)}'
                              : '—',
                          icon: Icons.currency_rupee,
                          color: AdminColors.accent,
                          change: 'All time revenue',
                        ),
                        AdminStatCard(
                          label: 'TOTAL ORDERS',
                          value: stats != null ? '${stats['orders']}' : '—',
                          icon: Icons.receipt_long_outlined,
                          color: AdminColors.info,
                          change:
                              '${stats?['pendingOrders'] ?? 0} pending', // Shows pending count
                        ),
                        AdminStatCard(
                          label: 'PRODUCTS',
                          value: stats != null ? '${stats['products']}' : '—',
                          icon: Icons.inventory_2_outlined,
                          color: AdminColors.success,
                          change: '${stats?['activeProducts'] ?? 0} active',
                        ),
                        AdminStatCard(
                          label: 'CUSTOMERS',
                          value: stats != null ? '${stats['customers']}' : '—',
                          icon: Icons.people_outline,
                          color: AdminColors.warning,
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // ── Recent Orders ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RECENT ORDERS',
                    style: TextStyle(
                        fontFamily: 'Epilogue',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2)),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadRecentOrders(),
                  builder: (context, snapshot) {
                    // Show spinner while waiting
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: AdminColors.accent),
                      ));
                    }

                    final orders = snapshot.data ?? [];

                    if (orders.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AdminColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: const Center(
                            child: Text('No orders yet',
                                style: TextStyle(
                                    fontFamily: 'Manrope',
                                    color: AdminColors.textMuted))),
                      );
                    }

                    // Mobile: card list instead of table
                    if (isMobile) {
                      return Column(
                        children: orders.map((o) {
                          final user = o['users'] as Map<String, dynamic>?;
                          final date = DateTime.parse(o['created_at'] as String)
                              .toLocal();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AdminColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(o['order_number'] as String? ?? '—',
                                        style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                    _StatusBadge(status: o['status'] as String),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(user?['email'] as String? ?? '—',
                                    style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 11,
                                        color: AdminColors.textSecondary),
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('₹${o['total']}',
                                        style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white)),
                                    Text(
                                        '${date.day}/${date.month}/${date.year}',
                                        style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 10,
                                            color: AdminColors.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }

                    // Desktop: table view
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(children: [
                              _hCell('ORDER', flex: 2),
                              _hCell('CUSTOMER', flex: 3),
                              _hCell('STATUS', flex: 2),
                              _hCell('TOTAL', flex: 1),
                              _hCell('DATE', flex: 2),
                            ]),
                          ),
                          const Divider(height: 1, color: AdminColors.border),

                          // One row per order
                          ...orders.asMap().entries.map((e) {
                            final o = e.value;
                            final user = o['users'] as Map<String, dynamic>?;
                            final date =
                                DateTime.parse(o['created_at'] as String)
                                    .toLocal();
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  child: Row(children: [
                                    _cell(o['order_number'] as String? ?? '—',
                                        flex: 2,
                                        bold: true,
                                        color: Colors.white),
                                    _cell(user?['email'] as String? ?? '—',
                                        flex: 3),
                                    Expanded(
                                      flex: 2,
                                      child: _StatusBadge(
                                          status: o['status'] as String),
                                    ),
                                    _cell('₹${o['total']}',
                                        flex: 1,
                                        bold: true,
                                        color: Colors.white),
                                    _cell(
                                        '${date.day}/${date.month}/${date.year}',
                                        flex: 2),
                                  ]),
                                ),
                                if (e.key < orders.length - 1)
                                  const Divider(
                                      height: 1, color: AdminColors.border),
                              ],
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Helper widgets ──────────────────────────────────────────────────────────

  /// Table header cell — uppercase muted text with a flex weight.
  Widget _hCell(String t, {int flex = 1}) => Expanded(
      flex: flex,
      child: Text(t,
          style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.textMuted)));

  /// Table data cell — normal or bold, with optional colour override.
  Widget _cell(String t, {int flex = 1, bool bold = false, Color? color}) =>
      Expanded(
          flex: flex,
          child: Text(t,
              style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? AdminColors.textSecondary),
              overflow: TextOverflow.ellipsis)); // Truncate long emails/names
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge — colour-coded pill showing order status
// Each status maps to a specific colour. The background is that colour at 12%
// opacity; the text is the full colour.
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  // Maps each order status string to its indicator colour
  static const _colors = {
    'pending': Color(0xFFFF9800), // Orange
    'confirmed': Color(0xFF2196F3), // Blue
    'processing': Color(0xFF9C27B0), // Purple
    'shipped': Color(0xFF00BCD4), // Cyan
    'delivered': Color(0xFF4CAF50), // Green
    'cancelled': Color(0xFFEF5350), // Red
    'refunded': Color(0xFFEF5350), // Red
  };

  @override
  Widget build(BuildContext context) {
    final c =
        _colors[status] ?? Colors.white; // Fallback to white if unknown status
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
