// Resident copy of the gate chat look (copied, not shared, so gate redesigns never change residents).
import 'package:estate/shared/chat/chat_screen.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:flutter/material.dart';

/// Colours used by the guard's WhatsApp-style chat list.
///
/// These are deliberately local to `gate/`: resident chat keeps the shared
/// Material list styling while the guard experience gets its own presentation.
class WhatsAppPalette {
  const WhatsAppPalette(this.dark);

  final bool dark;

  // WhatsApp-inspired layout, Residence colours: the inbox keeps the same
  // forest-green brand and warm neutral surfaces as the rest of the app.
  Color get header => dark ? TokenTheme.darkSurface : TokenTheme.primaryMint;
  Color get canvas => TokenTheme.pageBg(dark);
  Color get surface => TokenTheme.card(dark);
  Color get searchFill => dark ? TokenTheme.darkCard : TokenTheme.lightSurface;
  Color get textPrimary =>
      dark ? TokenTheme.darkTextPrimary : TokenTheme.lightTextPrimary;
  Color get textSecondary =>
      dark ? TokenTheme.darkTextSecondary : TokenTheme.lightTextSecondary;
  Color get divider => dark ? TokenTheme.darkBorder : TokenTheme.lightBorder;
  Color get unread => dark ? TokenTheme.darkAccent : TokenTheme.primaryMint;
  Color get onUnread => dark ? TokenTheme.darkBg : Colors.white;
  Color get danger => dark ? TokenTheme.darkError : const Color(0xFFB91C1C);
}

/// A WhatsApp-like inbox row: circular avatar, name, timestamp, two-line
/// preview with a faded tail, and a green unread counter.
class WhatsAppChatTile extends StatelessWidget {
  const WhatsAppChatTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.dark,
  });

  final ChatInboxEntry entry;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final palette = WhatsAppPalette(dark);
    final unread = entry.unread > 0;
    var preview = entry.preview.trim();
    if (entry.lastSenderRole == 'security' ||
        entry.lastSenderRole == 'system') {
      preview = 'You: $preview';
    }
    if (preview.isEmpty) preview = entry.status;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            color: palette.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                WhatsAppAvatar(
                  name: entry.name,
                  imageUrl: entry.avatarUrl,
                  emergency: entry.emergency,
                  dark: dark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 16,
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            chatTimestamp(entry.lastMessageAt),
                            style: TextStyle(
                              color: unread
                                  ? palette.unread
                                  : palette.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FadingMessagePreview(
                              text: preview,
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 14,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            Semantics(
                              label: '${entry.unread} unread messages',
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 20),
                                height: 20,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                  color: palette.unread,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${entry.unread}',
                                  style: TextStyle(
                                    color: palette.onUnread,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, indent: 72, color: palette.divider),
      ],
    );
  }
}

/// Circular initials avatar with support for an optional profile image URL.
class WhatsAppAvatar extends StatelessWidget {
  const WhatsAppAvatar({
    super.key,
    required this.name,
    required this.dark,
    this.imageUrl,
    this.emergency = false,
  });

  final String name;
  final String? imageUrl;
  final bool emergency;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final palette = WhatsAppPalette(dark);
    final initials = _initials(name);
    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: _avatarColor(name),
      foregroundColor: Colors.white,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );

    Widget avatar = fallback;
    final url = imageUrl?.trim();
    if (url != null &&
        url.isNotEmpty &&
        Uri.tryParse(url)?.hasAbsolutePath == true) {
      avatar = ClipOval(
        child: Image.network(
          url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (emergency)
            Positioned(
              right: -1,
              bottom: -1,
              child: Semantics(
                label: 'Active emergency',
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: palette.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.surface, width: 2),
                  ),
                  child: const Icon(Icons.priority_high_rounded,
                      size: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lays out at most two lines and fades the tail of the last line when the
/// message continues beyond the visible area (WhatsApp-style truncation).
class FadingMessagePreview extends StatelessWidget {
  const FadingMessagePreview({
    super.key,
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _layoutPreview(
          normalized,
          constraints.maxWidth,
          style,
          Directionality.of(context),
          MediaQuery.textScalerOf(context),
        );
        if (layout.lines.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < layout.lines.length; i++)
              i == layout.lines.length - 1 && layout.truncated
                  ? ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.white.withAlpha(0)],
                        stops: const [0.78, 1],
                      ).createShader(bounds),
                      blendMode: BlendMode.dstIn,
                      child: Text(layout.lines[i],
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: style),
                    )
                  : Text(layout.lines[i],
                      maxLines: 1, overflow: TextOverflow.clip, style: style),
          ],
        );
      },
    );
  }
}

class _PreviewLayout {
  const _PreviewLayout(this.lines, this.truncated);

  final List<String> lines;
  final bool truncated;
}

/// Greedy two-line layout. Flutter's [LineMetrics] does not expose text
/// offsets on every supported engine, so the visible lines are measured
/// directly with [TextPainter].
_PreviewLayout _layoutPreview(
  String text,
  double maxWidth,
  TextStyle style,
  TextDirection direction,
  TextScaler scaler,
) {
  if (!maxWidth.isFinite || maxWidth <= 0) {
    return _PreviewLayout([text], false);
  }
  const maxLines = 2;
  final painter = TextPainter(textDirection: direction, textScaler: scaler);
  double widthOf(String value) {
    painter.text = TextSpan(text: value, style: style);
    painter.layout();
    return painter.width;
  }

  final lines = <String>[];
  var current = '';
  for (final word in text.split(' ')) {
    if (word.isEmpty) continue;
    final candidate = current.isEmpty ? word : '$current $word';
    if (widthOf(candidate) <= maxWidth) {
      current = candidate;
      continue;
    }
    if (current.isNotEmpty) {
      lines.add(current);
      current = '';
      if (lines.length == maxLines) return _PreviewLayout(lines, true);
    }
    if (widthOf(word) <= maxWidth) {
      current = word;
      continue;
    }
    var chunk = '';
    for (final rune in word.runes) {
      final character = String.fromCharCode(rune);
      if (chunk.isNotEmpty && widthOf(chunk + character) > maxWidth) {
        lines.add(chunk);
        if (lines.length == maxLines) return _PreviewLayout(lines, true);
        chunk = '';
      }
      chunk += character;
    }
    current = chunk;
  }
  if (current.isNotEmpty) lines.add(current);
  return _PreviewLayout(lines, false);
}

String chatTimestamp(Object? raw) {
  final value = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
  if (value == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  if (day == today) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  if (now.difference(value).inDays < 7) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[value.weekday - 1];
  }
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year.toString().substring(2)}';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) {
    final first = part.runes.first;
    return String.fromCharCode(first).toUpperCase();
  }).join();
}

Color _avatarColor(String name) {
  const colors = [
    Color(0xFF00A884),
    Color(0xFF128C7E),
    Color(0xFF53BDEB),
    Color(0xFF8E5BD0),
    Color(0xFFEF8A3C),
    Color(0xFFD98572),
  ];
  final hash = name.runes.fold<int>(0, (sum, rune) => sum + rune);
  return colors[hash % colors.length];
}
