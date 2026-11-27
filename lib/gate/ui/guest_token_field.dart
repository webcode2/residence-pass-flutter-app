import 'dart:math' as math;

import 'package:estate/gate/ui/gate_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The cells are decorative. A single native field owns text, selection,
/// scrolling and the keyboard.
class GuestTokenField extends StatelessWidget {
  const GuestTokenField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.readOnly,
    required this.onChanged,
    this.onSubmitted,
  });

  // The backend can issue eight-character entry and exit tokens.
  static const _maxLength = 8;
  static final _lengthLimit = LengthLimitingTextInputFormatter(
    _maxLength,
    maxLengthEnforcement: MaxLengthEnforcement.enforced,
  );
  static final _preserveFullToken = TextInputFormatter.withFunction(
    (oldValue, newValue) {
      if (oldValue.text.length == _maxLength &&
          newValue.text.length > _maxLength) {
        return oldValue;
      }
      return _lengthLimit.formatEditUpdate(oldValue, newValue);
    },
  );

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool readOnly;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final palette = GatePalette.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style = TextStyle(
      color: palette.ink,
      fontFamily: 'monospace',
      fontSize: 21,
      height: 1.2,
    );
    final glyph = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final glyphWidth = glyph.width;
    final fieldHeight = math.max(52.0, glyph.height + 16);
    glyph.dispose();

    return LayoutBuilder(builder: (context, constraints) {
      return ListenableBuilder(
        listenable: Listenable.merge([controller, focusNode]),
        builder: (context, _) {
          final count = controller.text.length.clamp(4, _maxLength);
          final pitch =
              math.min(50.0, constraints.maxWidth / math.max(6, count));
          final active = controller.selection.extentOffset;
          final activeVisible = focusNode.hasFocus &&
              controller.text.length <= count &&
              active >= 0 &&
              active < count;
          return Center(
            child: SizedBox(
              width: pitch * count,
              height: fieldHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: readOnly ? null : focusNode.requestFocus,
                        child: Row(
                          children: List.generate(count, (index) {
                            final selected = activeVisible && index == active;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: DecoratedBox(
                                  key: ValueKey('guest-token-box-$index'),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? palette.tint
                                        : palette.canvas,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selected
                                          ? palette.accent
                                          : palette.line,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Semantics(
                        label: 'Guest token',
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          readOnly: readOnly,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          textDirection: TextDirection.ltr,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9]')),
                            _preserveFullToken,
                          ],
                          style: style.copyWith(
                            letterSpacing: math.max(0, pitch - glyphWidth) /
                                (scaler.scale(style.fontSize!) /
                                    style.fontSize!),
                          ),
                          decoration: null,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
