import 'package:flutter/material.dart';
import '../theme.dart';

class HelpBottomSheet extends StatelessWidget {
  final bool isDark;

  const HelpBottomSheet({super.key, required this.isDark});

  static void show(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HelpBottomSheet(isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? TokenTheme.darkSurface : TokenTheme.lightSurface;
    final titleColor = isDark ? TokenTheme.darkTextPrimary : TokenTheme.lightTextPrimary;
    final bodyColor = isDark ? TokenTheme.darkTextSecondary : TokenTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TokenTheme.primaryMint.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: TokenTheme.primaryMint,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'How to use your Gate Token',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStep(
              number: '1',
              title: 'Approach Gate / Boom Barrier',
              description: 'Drive or walk to any authorized entrance gate or pedestrian turnstile.',
              bodyColor: bodyColor,
              titleColor: titleColor,
            ),
            const SizedBox(height: 16),
            _buildStep(
              number: '2',
              title: 'Display or Enter Passcode',
              description: 'Show your 5-digit code to the optical scanner or read out the token to security.',
              bodyColor: bodyColor,
              titleColor: titleColor,
            ),
            const SizedBox(height: 16),
            _buildStep(
              number: '3',
              title: 'Instant Gate Clearance',
              description: 'Security or terminal validates the token instantly. The boom barrier lifts for seamless access.',
              bodyColor: bodyColor,
              titleColor: titleColor,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TokenTheme.primaryMint,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required Color bodyColor,
    required Color titleColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: TokenTheme.primaryMint.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: TokenTheme.primaryMint,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: bodyColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
