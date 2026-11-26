import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:estate/shared/ui/theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final Duration duration;

  const SplashScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ),
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();

    _timer = Timer(widget.duration, () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onFinished();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: TokenTheme.pageBg(isDark),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: TokenTheme.pageBg(isDark),
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Radial Mint Glow on White
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      isDark
                          ? TokenTheme.darkTint(0.10)
                          : TokenTheme.primaryMint.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      isDark
                          ? TokenTheme.darkInfo.withValues(alpha: 0.08)
                          : const Color(0xFF0284C7).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Subtle Ring Perimeter
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? TokenTheme.darkBorder
                      : TokenTheme.primaryMint.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? TokenTheme.darkBorder
                      : TokenTheme.primaryMintDark.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
                  child: Column(
                    children: [
                      const Spacer(),

                      // Central Brand Emblem (Residence 'R' Monogram Crest)
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Security Crest with Brand Lettermark 'R'
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      isDark ? TokenTheme.darkSurface : TokenTheme.primaryMintLight,
                                      isDark ? TokenTheme.darkCard : TokenTheme.primaryMintDark,
                                      isDark ? TokenTheme.darkSurface : const Color(0xFF047857),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: isDark ? null : [
                                    BoxShadow(
                                      color: TokenTheme.primaryMint.withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark ? TokenTheme.darkCard : Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Text(
                                      'R',
                                      style: TextStyle(
                                        fontSize: 52,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: isDark ? TokenTheme.darkCard : Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: isDark ? null : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                          border: Border.all(
                                            color: TokenTheme.primaryMintDark,
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.lock_rounded,
                                          size: 11,
                                          color: isDark ? TokenTheme.darkAccent : TokenTheme.primaryMintDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Brand Name
                              Text(
                                'Residence',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: isDark ? TokenTheme.darkTextPrimary : const Color(0xFF0F172A),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Security Tagline
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    size: 14,
                                    color: isDark ? TokenTheme.darkAccent : TokenTheme.primaryMintDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Zero-Trust Smart Access & Identity',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? TokenTheme.darkTextSecondary : const Color(0xFF64748B),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Bottom Security Protocol & Progress
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  backgroundColor: isDark ? TokenTheme.darkBorder : const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(isDark
                                      ? TokenTheme.darkAccent
                                      : TokenTheme.primaryMintDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 12,
                                  color: isDark ? TokenTheme.darkTextSecondary : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'AES-256 GCM ENCRYPTED • RESIDENCE CORE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? TokenTheme.darkTextSecondary : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
