// ─────────────────────────────────────────────────────────────────────────────
// main.dart — App entry point
//
// 1. Calls WidgetsFlutterBinding.ensureInitialized() so async work is safe
//    before runApp().
// 2. Initialises Supabase with URL + anon key from AppConstants.
// 3. Wraps the app in ProviderScope so Riverpod providers (e.g. the router)
//    are available throughout the widget tree.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'infrastructure/router.dart';
import 'infrastructure/theme.dart';

void main() async {
  // Required before any async call in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to the Supabase project
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // ProviderScope is required at the root for flutter_riverpod to work
  runApp(const ProviderScope(child: AdminApp()));
}

// Root widget — a ConsumerWidget so it can read Riverpod providers
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  Future<bool> _onWillPop(BuildContext context) async {
    if (Navigator.of(context).canPop()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Exit app'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (result == true) {
      SystemNavigator.pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the GoRouter instance from the Riverpod provider
    final router = ref.watch(adminRouterProvider);

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: MaterialApp.router(
        title: 'Rockstar — Admin',
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.darkTheme, // Apply the custom dark theme
        routerConfig: router, // Hand routing control to GoRouter
      ),
    );
  }
}
