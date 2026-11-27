import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six PIN dots and a phone-style keypad. The bottom-left key is the fingerprint button
/// when [onFingerprint] is given.
class PinPad extends StatelessWidget {
  final String value;
  final int length;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFingerprint;
  final bool enabled;
  final bool error;

  const PinPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.length = 6,
    this.onFingerprint,
    this.enabled = true,
    this.error = false,
  });

  void _tap(String digit) {
    if (!enabled || value.length >= length) return;
    HapticFeedback.selectionClick();
    onChanged(value + digit);
  }

  void _back() {
    if (!enabled || value.isEmpty) return;
    onChanged(value.substring(0, value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dotColor = error ? scheme.error : scheme.primary;
    Widget key(Widget child, VoidCallback? onTap, String label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Semantics(
              button: true,
              label: label,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: enabled ? onTap : null,
                child: SizedBox(height: 64, child: Center(child: child)),
              ),
            ),
          ),
        );
    Widget digit(String d) => key(
        Text(d, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: scheme.onSurface)),
        () => _tap(d),
        d);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
        label: '${value.length} of $length digits entered',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            final filled = i < value.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? dotColor : Colors.transparent,
                border: Border.all(color: filled ? dotColor : scheme.outline, width: 1.5),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 28),
      for (final row in const [
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
      ])
        Row(children: [for (final d in row) digit(d)]),
      Row(children: [
        onFingerprint == null
            ? const Expanded(child: SizedBox())
            : key(Icon(Icons.fingerprint_rounded, size: 32, color: scheme.primary), onFingerprint,
                'Use fingerprint'),
        digit('0'),
        key(Icon(Icons.backspace_outlined, size: 24, color: scheme.onSurfaceVariant), _back, 'Delete'),
      ]),
    ]);
  }
}
