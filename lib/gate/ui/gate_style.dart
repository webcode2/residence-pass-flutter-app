import 'package:estate/shared/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GatePalette {
  GatePalette.of(BuildContext context)
      : dark = Theme.of(context).brightness == Brightness.dark;

  final bool dark;
  Color get canvas => TokenTheme.pageBg(dark);
  Color get surface => TokenTheme.card(dark);
  Color get ink =>
      dark ? TokenTheme.darkTextPrimary : TokenTheme.lightTextPrimary;
  Color get muted =>
      dark ? TokenTheme.darkTextSecondary : const Color(0xFF4F6259);
  Color get line => dark ? TokenTheme.darkBorder : TokenTheme.lightBorder;
  Color get accent => dark ? TokenTheme.darkAccent : TokenTheme.primaryMint;
  Color get tint => dark ? TokenTheme.darkTint() : const Color(0xFFEAF1E7);
  Color get danger => dark ? TokenTheme.darkError : const Color(0xFFAA342D);
  Color get warning =>
      dark ? TokenTheme.darkWarning : const Color(0xFF855300);
  Color get info => dark ? TokenTheme.darkInfo : const Color(0xFF255E89);
  Color get action => dark ? TokenTheme.darkAccent : TokenTheme.primaryMint;

  BoxDecoration panel({Color? color}) => BoxDecoration(
        color: color ?? surface,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(12),
      );
}

AppBar gateHeader(
  BuildContext context,
  String title, {
  String? subtitle,
  List<Widget>? actions,
  bool overArtwork = false,
}) {
  final palette = GatePalette.of(context);
  final shell = Scaffold.maybeOf(context);
  return AppBar(
    leading: shell?.hasDrawer == true
        ? IconButton(
            tooltip: 'Open guard menu',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              shell!.openDrawer();
            },
          )
        : null,
    backgroundColor: overArtwork
        ? WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.scrolledUnder)
                ? palette.surface
                : Colors.transparent)
        : palette.surface,
    systemOverlayStyle: overArtwork
        ? (palette.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent)
        : null,
    foregroundColor: palette.ink,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    centerTitle: false,
    toolbarHeight: subtitle == null ? 60 : 72,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
        if (subtitle != null)
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: palette.muted)),
      ],
    ),
    actions: ModalRoute.isCurrentOf(context) == false ? null : actions,
    bottom: overArtwork
        ? null
        : PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: palette.line),
          ),
  );
}

class GateEmptyState extends StatelessWidget {
  const GateEmptyState(this.icon, this.message, {super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = GatePalette.of(context);
    return DecoratedBox(
      decoration: palette.panel(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: palette.muted),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted)),
          ],
        ),
      ),
    );
  }
}

class GateStatus extends StatelessWidget {
  const GateStatus(this.label, this.color, {super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      );
}

class GateIcon extends StatelessWidget {
  const GateIcon(this.icon, this.color, {super.key});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: color),
        ),
      );
}
