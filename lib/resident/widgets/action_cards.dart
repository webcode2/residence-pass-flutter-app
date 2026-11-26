import 'package:flutter/material.dart';
import 'package:estate/shared/ui/theme.dart';

class ActionCards extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const ActionCards({
    super.key,
    required this.isDark,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionTile(
          icon: Icons.copy_rounded,
          label: 'Copy',
          onTap: onCopy,
        ),
        const SizedBox(width: 24),
        _buildActionTile(
          icon: Icons.share_rounded,
          label: 'Share',
          onTap: onShare,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final cardBg = TokenTheme.card(isDark);
    final iconColor =
        isDark ? TokenTheme.darkAccent : TokenTheme.primaryMintDark;
    final labelColor =
        isDark ? TokenTheme.darkTextSecondary : TokenTheme.lightTextSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: TokenTheme.primaryMint.withValues(alpha: 0.2),
            highlightColor: TokenTheme.primaryMint.withValues(alpha: 0.1),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      isDark ? TokenTheme.darkBorder : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
