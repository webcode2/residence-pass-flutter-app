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

  // Dark theme colors
  static const Color darkBg = Color(0xFF080E12);
  static const Color darkSurface = Color(0xFF15201B);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFADB9B1);
  static const Color darkCardBg = Color(0xFF18251E);
  static const Color darkBorder = Color(0xFF265947);

  // Page vs card surfaces: keep enough contrast that white cards read clearly
  // against the page in light mode, and raised cards read in dark mode.
  static const Color lightPageBg = Color(0xFFF9F8F6);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkPageBg = Color(0xFF080E12);
  static const Color darkCard = Color(0xFF18251E);

  static Color pageBg(bool isDark) => isDark ? darkPageBg : lightPageBg;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
}
