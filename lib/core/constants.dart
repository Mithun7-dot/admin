// ─────────────────────────────────────────────────────────────────────────────
// constants.dart — App-wide configuration values
//
// AppConstants holds the Supabase project URL and anonymous key.
// The anon key is the public-facing key — it is safe to ship in Flutter Web
// because Supabase Row-Level Security (RLS) policies control what each user
// can actually read or write.
//
// How to find these values:
//   Supabase Dashboard → Project Settings → API → Project URL & anon key
// ─────────────────────────────────────────────────────────────────────────────

class AppConstants {
  // Private constructor — prevents instantiation (all members are static)
  AppConstants._();

  /// Base URL of the Supabase project (used for API calls + Storage)
  static const String supabaseUrl = 'https://dpvvgioytyfhigrnsdyo.supabase.co';

  /// Public anon key — used to initialise the Supabase client on the frontend
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwdnZnaW95dHlmaGlncm5zZHlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MDcyNTMsImV4cCI6MjA5MTI4MzI1M30.8afzf1dR2D-knqnqPzLqbn4cION9g2cO4Oag3aKCV9M';
}
