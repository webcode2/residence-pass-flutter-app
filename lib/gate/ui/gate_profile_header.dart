import 'package:estate/gate/ui/gate_style.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/shared/models/user_model.dart';
import 'package:flutter/material.dart';

class GateProfileHeader extends StatelessWidget {
  const GateProfileHeader({super.key, required this.user, required this.appId});

  final UserModel? user;
  final String appId;

  @override
  Widget build(BuildContext context) {
    final palette = GatePalette.of(context);
    final name = user?.displayName.trim() ?? '';
    final initials = name.isEmpty
        ? ''
        : name
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => String.fromCharCode(part.runes.first).toUpperCase())
            .join();
    final email = user?.email.trim() ?? '';
    final phone = user?.phone?.trim() ?? '';
    const avatarRadius = 33.0;
    const avatarBorder = 4.0;
    final backdropHeight = MediaQuery.paddingOf(context).top + 115;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(bottom: avatarRadius + avatarBorder),
              child: ExcludeSemantics(
                child: SizedBox(
                  width: double.infinity,
                  height: backdropHeight,
                  child: CustomPaint(painter: _ProfileMapPattern(palette.dark)),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(avatarBorder),
              decoration:
                  BoxDecoration(color: palette.canvas, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: palette.tint,
                foregroundColor: palette.accent,
                child: ExcludeSemantics(
                  child: initials.isEmpty
                      ? const Icon(Icons.badge_outlined, size: 28)
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(initials,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700)),
                        ),
                ),
              ),
            ),
          ],
        ),
        SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              children: [
                Text(name.isEmpty ? 'Security officer' : name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: palette.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                if (name.isNotEmpty)
                  Text('Security officer',
                      style: TextStyle(color: palette.muted, fontSize: 13)),
                if (email.isNotEmpty ||
                    phone.isNotEmpty ||
                    appId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (email.isNotEmpty)
                    _ProfileDetail(Icons.mail_outline, 'Email', email, palette),
                  if (phone.isNotEmpty)
                    _ProfileDetail(
                        Icons.phone_outlined, 'Phone', phone, palette),
                  if (appId.isNotEmpty)
                    _ProfileDetail(Icons.apartment_outlined, 'Estate App ID',
                        appId, palette),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail(this.icon, this.label, this.value, this.palette);

  final IconData icon;
  final String label;
  final String value;
  final GatePalette palette;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: palette.muted, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText(value,
                  semanticsLabel: '$label: $value',
                  style: TextStyle(color: palette.ink, fontSize: 14)),
            ),
          ],
        ),
      );
}

/// Original, abstract street grid. This artwork represents no actual location.
class _ProfileMapPattern extends CustomPainter {
  const _ProfileMapPattern(this.dark);

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final base = dark ? TokenTheme.darkSurface : const Color(0xFFD9E7DB);
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    canvas.save();
    canvas.scale(size.width / 360, size.height / 120);

    final blockPaint = Paint()
      ..color = dark ? TokenTheme.darkCard : const Color(0xFFC6DBC9);
    for (final block in [
      const Rect.fromLTWH(16, 15, 41, 25),
      const Rect.fromLTWH(84, 80, 50, 29),
      const Rect.fromLTWH(224, 11, 43, 21),
      const Rect.fromLTWH(292, 67, 53, 37),
    ]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(block, const Radius.circular(5)), blockPaint);
    }

    final street = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.3
      ..color = dark ? TokenTheme.darkBorder : const Color(0xFF9AB6A5);
    void road(List<Offset> points) {
      final path = Path()..addPolygon(points, false);
      canvas.drawPath(path, street);
    }

    for (final roadPoints in const [
      [
        Offset(0, 49),
        Offset(81, 49),
        Offset(115, 27),
        Offset(181, 27),
        Offset(212, 42),
        Offset(360, 42)
      ],
      [
        Offset(0, 74),
        Offset(145, 74),
        Offset(187, 55),
        Offset(280, 55),
        Offset(360, 58)
      ],
      [Offset(0, 105), Offset(63, 105), Offset(86, 115), Offset(360, 115)],
      [Offset(64, 0), Offset(64, 81), Offset(73, 91), Offset(73, 120)],
      [Offset(94, 0), Offset(94, 40), Offset(122, 54), Offset(150, 54)],
      [Offset(151, 0), Offset(151, 73), Offset(165, 89), Offset(165, 120)],
      [Offset(211, 0), Offset(211, 88), Offset(228, 111), Offset(228, 120)],
      [Offset(280, 0), Offset(280, 76), Offset(271, 89), Offset(271, 120)],
      [Offset(322, 0), Offset(322, 57)],
    ]) {
      road(roadPoints);
    }
    street
      ..strokeWidth = 3.2
      ..color = dark ? TokenTheme.darkAccent : const Color(0xFFF7F9F2);
    road(const [
      Offset(0, 89),
      Offset(95, 89),
      Offset(139, 62),
      Offset(231, 62),
      Offset(267, 83),
      Offset(360, 83)
    ]);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 360, 68),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            base.withValues(alpha: .88),
            base.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 360, 68)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ProfileMapPattern oldDelegate) =>
      oldDelegate.dark != dark;
}
