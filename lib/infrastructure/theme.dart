// ─────────────────────────────────────────────────────────────────────────────
// theme.dart — Design system: colors, typography, and global widget styles
//
// Contains two classes:
//   • AdminColors — all color constants used across the admin panel
//   • AdminTheme  — a complete Material 3 ThemeData (dark mode)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central color palette for the admin panel.
/// All screens reference these constants — never use raw hex values in screens.
class AdminColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0A0A0A); // Deepest black — page BG
  static const Color surface = Color(0xFF131313); // Cards, dialogs
  static const Color surfaceHigh = Color(0xFF1C1B1B); // Input fields, dropdowns
  static const Color card = Color(0xFF1A1A1A); // Table containers
  static const Color border = Color(0xFF2A2A2A); // All borders and dividers

  // ── Brand / Text ───────────────────────────────────────────────────────────
  static const Color primary =
      Color(0xFFFFFFFF); // White — rarely used directly
  static const Color onPrimary = Color(0xFF1A1C1C); // Text on white buttons
  static const Color textPrimary = Color(0xFFE5E2E1); // Main body text
  static const Color textSecondary = Color(0xFFC6C6C6); // Secondary info text
  static const Color textMuted = Color(0xFF919191); // Labels, table headers

  // ── Accent / Status ────────────────────────────────────────────────────────
  static const Color accent = Color(0xFFE8C547); // Gold — CTAs, active nav item
  static const Color success = Color(0xFF4CAF50); // Green — Active, Delivered
  static const Color warning = Color(0xFFFF9800); // Orange — Pending orders
  static const Color error = Color(0xFFEF5350); // Red — Delete, Cancelled
  static const Color info = Color(0xFF2196F3); // Blue — Confirmed orders

  // ── Sidebar ────────────────────────────────────────────────────────────────
  static const Color sidebar = Color(0xFF111111); // Sidebar background
  static const Color sidebarActive = Color(0xFF1E1E1E); // Active nav item BG
}

/// Generates the app-wide Material 3 dark theme.
/// Applied once in main.dart via `MaterialApp.router(theme: AdminTheme.darkTheme)`.
class AdminTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AdminColors.bg,

      // Color scheme controls what Material widgets use for their default colors
      colorScheme: const ColorScheme.dark(
        primary: AdminColors.accent, // Accent gold as the primary color
        onPrimary: Colors.black, // Text on accent-colored buttons
        surface: AdminColors.surface,
        onSurface: AdminColors.textPrimary,
        error: AdminColors.error,
      ),

      // ── Typography ─────────────────────────────────────────────────────────
      // Base font is Manrope; headings use Epilogue (heavier, display-style)
      textTheme:
          GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.epilogue(
                color: AdminColors.textPrimary, fontWeight: FontWeight.w900)
            .copyWith(fontFamilyFallback: ['sans-serif']),
        headlineLarge: GoogleFonts.epilogue(
                color: AdminColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 24)
            .copyWith(fontFamilyFallback: ['sans-serif']),
        headlineMedium: GoogleFonts.epilogue(
                color: AdminColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)
            .copyWith(fontFamilyFallback: ['sans-serif']),
        titleLarge: GoogleFonts.manrope(
                color: AdminColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14)
            .copyWith(fontFamilyFallback: ['sans-serif']),
        bodyMedium:
            GoogleFonts.manrope(color: AdminColors.textSecondary, fontSize: 13)
                .copyWith(fontFamilyFallback: ['sans-serif']),
        labelSmall: GoogleFonts.manrope(
                color: AdminColors.textMuted,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700)
            .copyWith(fontFamilyFallback: ['sans-serif']),
      ),

      // ── AppBar ─────────────────────────────────────────────────────────────
      // Only used on mobile (drawer mode) — desktop uses the permanent sidebar
      appBarTheme: AppBarTheme(
        backgroundColor: AdminColors.sidebar,
        elevation: 0,
        titleTextStyle: GoogleFonts.epilogue(
                color: AdminColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)
            .copyWith(fontFamilyFallback: ['sans-serif']),
        iconTheme: const IconThemeData(color: AdminColors.textPrimary),
      ),

      // ── Elevated Button (primary CTA — gold background, black text) ────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.accent,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)
              .copyWith(fontFamilyFallback: ['sans-serif']),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero), // Square corners
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Outlined Button (secondary action — transparent, white border) ─────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.textPrimary,
          side: const BorderSide(color: AdminColors.border),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle:
              GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12)
                  .copyWith(fontFamilyFallback: ['sans-serif']),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Input / TextField ──────────────────────────────────────────────────
      // All TextFields across the app share this style automatically
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surfaceHigh,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AdminColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AdminColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AdminColors.accent, width: 1.5)),
        labelStyle:
            GoogleFonts.manrope(color: AdminColors.textMuted, fontSize: 12)
                .copyWith(fontFamilyFallback: ['sans-serif']),
        hintStyle:
            GoogleFonts.manrope(color: AdminColors.textMuted, fontSize: 13)
                .copyWith(fontFamilyFallback: ['sans-serif']),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AdminColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AdminColors.border)),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
          color: AdminColors.border, thickness: 1, space: 0),

      // ── Dialog ─────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AdminColors.border)),
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AdminColors.surfaceHigh,
        contentTextStyle: GoogleFonts.manrope(color: AdminColors.textPrimary)
            .copyWith(fontFamilyFallback: ['sans-serif']),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior
            .floating, // Floats above content instead of docking at bottom
      ),
    );
  }
}
