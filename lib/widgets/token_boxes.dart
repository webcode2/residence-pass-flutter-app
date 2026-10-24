import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class TokenBoxes extends StatelessWidget {
  final String token;
  final bool isDark;
  final VoidCallback onCopied;

  const TokenBoxes({
    super.key,
    required this.token,
    required this.isDark,
    required this.onCopied,
  });

  @override
  Widget build(BuildContext context) {
    final chars = token.split('');
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive width ratio: dynamically distribute across screen width
    // Leave 24px padding on each side, gap between boxes = 8px
    const horizontalPadding = 48.0;
    final totalGaps = 8.0 * (chars.length - 1);
    final calculatedBoxWidth = ((screenWidth - horizontalPadding - totalGaps) / chars.length).clamp(46.0, 68.0);
    final calculatedBoxHeight = (calculatedBoxWidth * 1.15).clamp(54.0, 80.0);
    final fontSize = (calculatedBoxWidth * 0.48).clamp(22.0, 32.0);

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: token));
        HapticFeedback.lightImpact();
        onCopied();
      },
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: chars.map((char) => _buildDigitBox(char, calculatedBoxWidth, calculatedBoxHeight, fontSize)).toList(),
        ),
      ),
    );
  }

  Widget _buildDigitBox(String char, double width, double height, double fontSize) {
    final borderColor = isDark ? TokenTheme.darkBorder : TokenTheme.lightBorder;
    final bgColor = isDark ? TokenTheme.darkSurface : TokenTheme.lightSurface;
    final textColor = isDark ? TokenTheme.darkTextPrimary : TokenTheme.lightTextPrimary;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1.8,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: TokenTheme.primaryMint.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
