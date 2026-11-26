import 'package:flutter/material.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/shared/ui/widgets/sos_hold_button.dart';

/// Dedicated emergency screen for estate members.
///
/// The SOS control is intentionally absent from the tab screens; this is the
/// single, calm place for the distress alarm. Non-emergency reports live on
/// the separate incident report screen.
class SosCenterScreen extends StatelessWidget {
  const SosCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    final borderColor =
        isDark ? TokenTheme.darkBorder : TokenTheme.lightBorder;
    final cardColor = TokenTheme.card(isDark);
    final secondaryColor = isDark
        ? TokenTheme.darkTextSecondary
        : TokenTheme.lightTextSecondary;
    final alarmColor = isDark ? TokenTheme.darkError : const Color(0xFFB91C1C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS & emergencies'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TokenTheme.pageSidePadding,
                        vertical: 24,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 32),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emergency_outlined,
                                size: 36, color: alarmColor),
                            const SizedBox(height: 12),
                            Text(
                              'Emergency distress alarm',
                              textAlign: TextAlign.center,
                              style: text.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Press and hold for four seconds to alert every registered device in your estate. Release early to cancel.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: secondaryColor,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const SosHoldButton(),
                            const SizedBox(height: 14),
                            Text(
                              'Hold 4 seconds to send • Release early to cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
