// ─────────────────────────────────────────────────────────────────────────────
// admin_layout.dart — Responsive shell + shared reusable widgets
//
// This file contains:
//   • AdminLayout        — Responsive wrapper (sidebar on desktop, drawer on mobile)
//   • _DesktopLayout     — Permanent sidebar + content side-by-side
//   • _MobileLayout      — AppBar + Drawer for narrower screens
//   • _Sidebar           — Navigation panel with all route links + sign out
//   • _SidebarTile       — Individual nav item with active highlight
//   • _NavItem           — Data class for a navigation entry
//   • AdminPageHeader    — Reusable top-of-page title + action button row
//   • AdminStatCard      — Reusable metric card used on the Dashboard
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../widgets/admin_brand_logo.dart';

/// Root layout widget — decides desktop vs mobile based on screen width.
/// Wrapped around all authenticated screens via ShellRoute in router.dart.
class AdminLayout extends StatelessWidget {
  final Widget child; // The currently active screen widget
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // > 900px wide → permanent sidebar (desktop/tablet landscape)
    final isWide = MediaQuery.of(context).size.width > 900;
    if (isWide) return _DesktopLayout(child: child);
    return _MobileLayout(child: child);
  }
}

// ── Desktop Layout ────────────────────────────────────────────────────────────
// Permanent sidebar on the left, content fills the right side.
class _DesktopLayout extends StatelessWidget {
  final Widget child;
  const _DesktopLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Row(
        children: [
          const _Sidebar(), // Fixed 240px wide sidebar
          Expanded(child: child), // Screen content fills remaining space
        ],
      ),
    );
  }
}

// ── Mobile Layout ─────────────────────────────────────────────────────────────
// AppBar with hamburger menu; sidebar slides in as a Drawer.
class _MobileLayout extends StatelessWidget {
  final Widget child;
  const _MobileLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      drawer: const Drawer(
        backgroundColor: AdminColors.sidebar,
        child: _Sidebar(), // Same sidebar widget, now inside a Drawer
      ),
      appBar: AppBar(
        backgroundColor: AdminColors.sidebar,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(), // Open the drawer
          ),
        ),
        title: const Text('ADMIN PANEL'),
      ),
      body: child,
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
// Navigation panel. Reads the current route from GoRouter to highlight the
// active item. Sign Out button at the bottom clears the Supabase session.
class _Sidebar extends StatefulWidget {
  const _Sidebar();

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  String _role = 'admin';
  bool _loading = true;

  static const _allItems = [
    _NavItem(
        '/dashboard', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', [
      'ceo',
      'admin',
      'stock_manager',
      'pricing_manager',
      'order_manager',
      'qa_manager'
    ]),
    _NavItem('/products', Icons.inventory_2_outlined, Icons.inventory_2,
        'Products', ['ceo', 'admin', 'stock_manager', 'pricing_manager']),
    _NavItem('/orders', Icons.receipt_long_outlined, Icons.receipt_long,
        'Orders', ['ceo', 'admin', 'order_manager']),
    _NavItem('/categories', Icons.category_outlined, Icons.category,
        'Categories', ['ceo', 'admin', 'stock_manager']),
    _NavItem('/banners', Icons.image_outlined, Icons.image, 'Banners',
        ['ceo', 'admin']),
    _NavItem('/discover', Icons.view_carousel_outlined, Icons.view_carousel,
        'Discover', ['ceo', 'admin']),
    _NavItem('/users', Icons.people_outline, Icons.people, 'Users',
        ['ceo', 'admin', 'qa_manager']),
    _NavItem('/coupons', Icons.local_offer_outlined, Icons.local_offer,
        'Coupons', ['ceo', 'admin', 'pricing_manager']),
    _NavItem('/roles', Icons.admin_panel_settings_outlined,
        Icons.admin_panel_settings, 'Roles', ['ceo']),
  ];

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    try {
      final user = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', session.user.id)
          .single();
      if (mounted) {
        setState(() {
          _role = user['role'] as String;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    // Filter items by role
    final allowedItems =
        _allItems.where((item) => item.allowedRoles.contains(_role)).toList();

    return Container(
      width: 240,
      color: AdminColors.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: AdminBrandLogo(showSubtitle: true),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: AdminColors.border),
            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AdminColors.accent))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: allowedItems.map((item) {
                        final active = location.startsWith(item.route);
                        return _SidebarTile(item: item, active: active);
                      }).toList(),
                    ),
            ),

            // ── Sign Out button ───────────────────────────────────────────────
            Container(height: 1, color: AdminColors.border),
            InkWell(
              onTap: () => _logout(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AdminColors.error, size: 18),
                    SizedBox(width: 12),
                    Text('SIGN OUT',
                        style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.error)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Signs out of Supabase and navigates to the login screen.
  void _logout(BuildContext context) {
    Supabase.instance.client.auth.signOut().then((_) {
      if (context.mounted) context.go('/login');
    });
  }
}

// ── Sidebar Tile ──────────────────────────────────────────────────────────────
// Individual clickable nav item. Active state: gold left border + filled icon.
class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  const _SidebarTile({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        // Active items have a dark filled background
        color: active ? AdminColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            context.go(item.route); // Navigate using GoRouter
            // Close drawer if on mobile
            if (Scaffold.of(context).isDrawerOpen) {
              Navigator.of(context).pop();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: active
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // Gold left-side accent border for the active route
                    border: const Border(
                        left: BorderSide(color: AdminColors.accent, width: 2)),
                  )
                : null,
            child: Row(
              children: [
                // Filled icon when active, outline icon otherwise
                Icon(active ? item.filledIcon : item.icon,
                    color: active ? AdminColors.accent : AdminColors.textMuted,
                    size: 18),
                const SizedBox(width: 12),
                Text(item.label,
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? AdminColors.textPrimary
                            : AdminColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple data class holding one sidebar navigation entry.
class _NavItem {
  final String route;
  final IconData icon;
  final IconData filledIcon;
  final String label;
  final List<String> allowedRoles;
  const _NavItem(
      this.route, this.icon, this.filledIcon, this.label, this.allowedRoles);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets — used across multiple screens
// ─────────────────────────────────────────────────────────────────────────────

/// Standardised page header displayed at the top of every admin screen.
/// Shows: large page title, optional subtitle (e.g. item count), optional
/// action button on the right (e.g. "ADD PRODUCT").
/// Fully responsive: wraps on narrow screens.
class AdminPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action; // Typically an ElevatedButton

  const AdminPageHeader(
      {super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final hPad = isMobile ? 16.0 : 32.0;
    final titleSize = isMobile ? 20.0 : 26.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 20 : 40, hPad, 0),
      child: isMobile
          // Mobile: stack title and action vertically
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: 'Epilogue',
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: AdminColors.textMuted,
                          letterSpacing: 1)),
                ],
                if (action != null) ...[
                  const SizedBox(height: 16),
                  action!,
                ],
              ],
            )
          // Desktop: side by side
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontFamily: 'Epilogue',
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!,
                            style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                color: AdminColors.textMuted,
                                letterSpacing: 1)),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
    );
  }
}

/// Helper to get responsive horizontal padding
double responsivePadding(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w < 600) return 12.0;
  if (w < 900) return 20.0;
  return 32.0;
}

/// A metric card used on the Dashboard to display a key KPI.
///
/// Shows:
///   • [label] — small uppercase caption (e.g. "TOTAL REVENUE")
///   • [value] — large bold number (e.g. "₹42,000")
///   • [icon]  — displayed in a coloured rounded box
///   • [change] — optional small text below the value (e.g. "3 pending")
///
/// [color] tints the icon background at 12% opacity.
class AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? change; // Optional hint/change text shown below the value

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Label (e.g. "TOTAL ORDERS")
              Flexible(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: isMobile ? 9 : 11,
                        letterSpacing: 1.5,
                        color: AdminColors.textMuted,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),

              // Icon in a lightly tinted rounded box
              Container(
                width: isMobile ? 28 : 36,
                height: isMobile ? 28 : 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12), // 12% tint of the given color
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isMobile ? 14 : 18),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 16),

          // Large value number (e.g. "₹12,340")
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontFamily: 'Epilogue',
                    fontSize: isMobile ? 22 : 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),

          // Optional change/hint line (e.g. "5 pending")
          if (change != null) ...[
            SizedBox(height: isMobile ? 4 : 6),
            Text(change!,
                style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: isMobile ? 9 : 11,
                    color: AdminColors.success,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
