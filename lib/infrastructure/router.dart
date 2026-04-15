// ─────────────────────────────────────────────────────────────────────────────
// router.dart — All app routes + authentication guard
//
// Uses GoRouter (declarative routing library) exposed via a Riverpod Provider.
// The router has two sections:
//   1. A public /login route
//   2. A ShellRoute (all authenticated routes wrapped in AdminLayout)
//
// Auth guard logic (the `redirect` callback):
//   - If there is no active Supabase session → send to /login
//   - If there IS a session → check users table for role == 'admin'
//   - If role is not admin → sign out and send to /login
//   - Otherwise → allow navigation
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/products_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/banners_screen.dart';
import '../screens/featured_strips_screen.dart';
import '../screens/users_screen.dart';
import '../screens/coupons_screen.dart';
import '../screens/roles_screen.dart';
import '../layouts/admin_layout.dart';

// Valid admin roles
const _validRoles = ['admin', 'ceo', 'stock_manager', 'pricing_manager', 'order_manager', 'qa_manager'];

final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLogin = state.matchedLocation == '/login';

      if (session == null) return isLogin ? null : '/login';

      if (!isLogin) {
        try {
          final user = await Supabase.instance.client
              .from('users')
              .select('role')
              .eq('id', session.user.id)
              .maybeSingle();

          if (user == null || !_validRoles.contains(user['role'])) return '/login';
        } catch (_) {
          return '/login';
        }
      }
      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const AdminLoginScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(path: '/dashboard',  builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/products',   builder: (_, __) => const ProductsScreen()),
          GoRoute(path: '/orders',     builder: (_, __) => const AdminOrdersScreen()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
          GoRoute(path: '/banners',    builder: (_, __) => const BannersScreen()),
          GoRoute(path: '/discover',   builder: (_, __) => const FeaturedStripsScreen()),
          GoRoute(path: '/users',      builder: (_, __) => const UsersScreen()),
          GoRoute(path: '/coupons',    builder: (_, __) => const CouponsScreen()),
          GoRoute(path: '/roles',      builder: (_, __) => const RolesScreen()),
        ],
      ),
    ],
  );
});
