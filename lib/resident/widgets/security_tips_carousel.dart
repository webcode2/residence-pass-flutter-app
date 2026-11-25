import 'dart:async';
import 'package:flutter/material.dart';
import 'package:estate/resident/data/security_tips_service.dart';

class SecurityTipsCarousel extends StatefulWidget {
  const SecurityTipsCarousel({super.key});

  @override
  State<SecurityTipsCarousel> createState() => _SecurityTipsCarouselState();
}

class _SecurityTipsCarouselState extends State<SecurityTipsCarousel> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      final tips = SecurityTipsService.instance.tips;
      if (tips.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % tips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  IconData _getTipIcon(String iconType) {
    switch (iconType) {
      case 'shield':
        return Icons.shield_outlined;
      case 'logout':
        return Icons.logout_rounded;
      case 'lock':
        return Icons.lock_outline_rounded;
      case 'car':
        return Icons.directions_car_outlined;
      case 'fingerprint':
        return Icons.fingerprint_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SecurityTipsService.instance,
      builder: (context, _) {
        final tips = SecurityTipsService.instance.tips;
        if (tips.isEmpty) {
          return const Text(
            'Tap to generate instant entry/exit OTP',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          );
        }

        final currentTip = tips[_currentIndex % tips.length];

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = (_currentIndex + 1) % tips.length;
            });
            _startTimer();
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Row(
              key: ValueKey<int>(currentTip.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1.5, right: 6),
                  child: Icon(
                    _getTipIcon(currentTip.icon),
                    size: 14,
                    color: const Color(0xFFB8F532),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: '${currentTip.category}: ',
                          style: const TextStyle(
                            color: Color(0xFFB8F532),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: currentTip.tip),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
