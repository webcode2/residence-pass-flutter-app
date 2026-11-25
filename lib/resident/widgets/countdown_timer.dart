import 'package:flutter/material.dart';
import 'package:estate/shared/ui/theme.dart';

class CountdownTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isDark;

  const CountdownTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeFormatted = '$minutes:${seconds.toString().padLeft(2, '0')}';
    final progress = totalSeconds > 0 ? (remainingSeconds / totalSeconds) : 0.0;

    final textColor = isDark ? TokenTheme.darkTextSecondary : TokenTheme.lightTextSecondary;
    const ringColor = TokenTheme.primaryMint;
    final bgTrackColor = isDark ? Colors.white12 : Colors.black12;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Code valid for $timeFormatted',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(bgTrackColor),
              ),
              CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 2.2,
                strokeCap: StrokeCap.round,
                valueColor: const AlwaysStoppedAnimation<Color>(ringColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
