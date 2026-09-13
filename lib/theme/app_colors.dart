import 'package:flutter/material.dart';

class AppColors {
  // ─── Reference Design System Palette (Single Source of Truth) ───
  // Primary Backgrounds
  static const Color lightBg = Color(0xFFFBF9F4);         // Warm cream/ivory background
  static const Color cardWhite = Color(0xFFFFFFFF);       // Pure white card surfaces
  static const Color cardMuted = Color(0xFFF4F0E6);       // Warm sand/cream secondary card surface
  static const Color cardBorder = Color(0xFFEDE8DF);      // Subtle warm card border

  // Primary & Secondary Brand Colors
  static const Color forestGreen = Color(0xFF16382B);     // Deep forest green (main CTA, active pills, badges)
  static const Color primaryGreen = Color(0xFF16382B);    // Primary brand alias
  static const Color sageGreen = Color(0xFF5C946E);       // Sage green (completed checks, progress, graphs)
  static const Color mintLight = Color(0xFFEAF4EC);       // Soft sage/mint container background
  static const Color sageDark = Color(0xFF3B684B);        // Deep sage

  // Accents from Reference Image
  static const Color accentPeach = Color(0xFFF38D68);     // Soft peach / coral (heart rate, alerts)
  static const Color accentCoral = Color(0xFFF38D68);     // Heart rate alias
  static const Color accentOrange = Color(0xFFF4A261);    // Warm orange (streak flame, calories)
  static const Color accentGold = Color(0xFFE8A838);      // Trophy gold
  static const Color skyBlue = Color(0xFF4B9CD3);         // Muted sky blue (hydration, SpO2)
  static const Color primaryTeal = Color(0xFF4B9CD3);     // Teal/blue alias
  static const Color skyLight = Color(0xFFEBF5FB);        // Soft blue container
  static const Color lavender = Color(0xFF8B80F9);        // Soft lavender / purple (sleep, workout tags)
  static const Color lavenderLight = Color(0xFFF3F0FF);   // Soft purple container
  static const Color secondaryBlue = Color(0xFF8B80F9);   // Secondary blue/purple alias

  // Typography & Neutral Text
  static const Color textPrimary = Color(0xFF18221B);     // Deep slate/forest black for high legibility
  static const Color textSecondary = Color(0xFF6C7A70);   // Muted sage slate for subtitles
  static const Color neutralGray = Color(0xFF8E9B92);     // Light muted neutral gray
  static const Color textMuted = Color(0xFFA5B2A9);       // Placeholder text

  // ─── Semantic & Compatibility Aliases ───
  static const Color pulseRed = accentPeach;
  static const Color voltCyan = skyBlue;
  static const Color irisViolet = lavender;
  static const Color solarAmber = accentOrange;
  static const Color borderSubtle = cardBorder;

  static const Color zenDarkBg = Color(0xFF13201A);
  static const Color zenDarkCard = Color(0xFF1B2E25);
  static const Color zenDarkElevated = Color(0xFF243B30);
  static const Color zenMint = sageGreen;
  static const Color zenMintLight = mintLight;
  static const Color zenAmber = accentOrange;
  static const Color zenAmberLight = Color(0xFFFCE8D3);
  static const Color zenLavender = lavender;
  static const Color zenLavenderLight = lavenderLight;
  static const Color zenSky = skyBlue;
  static const Color zenSkyLight = skyLight;
  static const Color zenCoral = accentPeach;
  static const Color zenCoralLight = Color(0xFFFDECE6);
  static const Color zenBorder = cardBorder;

  // Legacy mappings for existing codebase components
  static const Color primary = forestGreen;
  static const Color primaryLight = sageGreen;
  static const Color primaryContainer = mintLight;
  static const Color secondary = sageGreen;
  static const Color coral = accentPeach;
  static const Color green = sageGreen;
  static const Color blue = skyBlue;
  static const Color pink = Color(0xFFF472B6);
  static const Color yellow = accentGold;
  static const Color teal = skyBlue;
  static const Color orange = accentOrange;

  static const Color backgroundDeep = lightBg;
  static const Color surfaceCard = cardWhite;
  static const Color surfaceElevated = cardWhite;

  static const Color darkBg = lightBg;
  static const Color darkSurface = cardWhite;
  static const Color darkSurfaceContainer = cardWhite;
  static const Color darkSurfaceContainerLow = cardMuted;
  static const Color darkSurface2 = cardMuted;
  static const Color darkOnSurface = textPrimary;
  static const Color darkOnSurfaceVariant = textSecondary;
  static const Color darkOutline = cardBorder;

  static const Color lightSurface = cardWhite;
  static const Color lightSurfaceContainer = cardWhite;
  static const Color lightSurfaceContainerLow = cardMuted;
  static const Color lightOnSurface = textPrimary;
  static const Color lightOnSurfaceVariant = textSecondary;
  static const Color lightOutline = cardBorder;

  // ─── Subtle Shadows & Effects ───
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF16382B).withValues(alpha: 0.04),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: forestGreen.withValues(alpha: 0.25),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  // ─── Reference Gradients ───
  static const LinearGradient gradientForestSage = LinearGradient(
    colors: [forestGreen, sageGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientTealGreen = LinearGradient(
    colors: [skyBlue, sageGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientPeachOrange = LinearGradient(
    colors: [accentPeach, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientPrimary = gradientForestSage;
  static const LinearGradient gradientCyan = gradientTealGreen;
  static const LinearGradient gradientCoral = gradientPeachOrange;
  static const LinearGradient gradientAmber = LinearGradient(
    colors: [accentOrange, accentGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientSecondary = gradientTealGreen;
  static const LinearGradient gradientGreen = LinearGradient(
    colors: [sageGreen, Color(0xFF7BAE7F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientBlue = LinearGradient(
    colors: [skyBlue, Color(0xFF70BFE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientStreak = gradientPeachOrange;
}
