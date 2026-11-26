import 'package:flutter/material.dart';

class TokenTheme {
  static const double pageSidePadding = 12;
  // Shared web palette: primary hsl(158 40% 25%), background hsl(45 20% 97%).
  static const Color primaryMint = Color(0xFF265947);
  static const Color primaryMintDark = Color(0xFF265947);
  static const Color primaryMintLight = Color(0xFFCBDABD);

  // Warm neutral surfaces and forest green match the web dashboard.
  static const Color lightBg = Color(0xFFF9F8F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1F2825);
  static const Color lightTextSecondary = Color(0xFF68736E);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFD9D6CE);

  // Dark theme: neutral near-blacks. The mint accent is used only for active
  // controls, and tinted surfaces are a translucent wash of the brand colour
  // rather than a second, saturated green surface.
  static const Color darkBg = Color(0xFF0F1110);
  static const Color darkSurface = Color(0xFF171A18);
  static const Color darkCard = Color(0xFF1C1F1D);
  static const Color darkCardBg = darkCard;
  static const Color darkPageBg = darkBg;
  static const Color darkTextPrimary = Color(0xFFF2F4F2);
  static const Color darkTextSecondary = Color(0xFFA7AEA9);
  static const Color darkBorder = Color(0xFF2B302D);
  static const Color darkAccent = Color(0xFFA9C6B7);
  static const Color darkError = Color(0xFFE6A29B);
  static const Color darkWarning = Color(0xFFDFC48C);
  static const Color darkInfo = Color(0xFFA9C4DC);

  /// Low-opacity brand wash for dark-mode surfaces and status chips.
  static Color darkTint([double alpha = 0.14]) =>
      primaryMint.withValues(alpha: alpha);

  // Page vs card surfaces: keep enough contrast that white cards read clearly
  // against the page in light mode, and raised cards read in dark mode.
  static const Color lightPageBg = Color(0xFFF9F8F6);
  static const Color lightCard = Color(0xFFFFFFFF);

  static Color pageBg(bool isDark) => isDark ? darkPageBg : lightPageBg;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
}
