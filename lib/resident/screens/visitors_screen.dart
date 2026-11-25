import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/resident/models/visitor_pass.dart';
import 'package:estate/resident/state/visitor_store.dart';
import 'package:estate/resident/screens/create_token_screen.dart';
import 'package:estate/resident/screens/all_active_passes_screen.dart';

class VisitorsScreen extends StatelessWidget {
  final bool isDark;

  const VisitorsScreen({super.key, required this.isDark});

  void _openCreatePassScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTokenScreen(isDark: isDark),
      ),
    );
  }

  void _openAllPassesScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllActivePassesScreen(
          isDark: isDark,
          onOpenPassModal: _openPassActionModal,
        ),
      ),
    );
  }

  void _openPassActionModal(BuildContext context, VisitorPass pass) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = TokenTheme.card(isDark);
        final primaryTextColor =
            isDark ? Colors.white : const Color(0xFF111827);
        final secondaryTextColor =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isCheckedIn = pass.status == VisitorStatus.checkedIn;
            final hasBookoutCode =
                pass.bookoutCode != null && pass.bookoutCode!.isNotEmpty;

            return Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header with Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pass.visitorName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCheckedIn
                                    ? 'Currently verified on premises'
                                    : 'Awaiting entry at security gate',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCheckedIn
                                ? const Color(0xFF10B981)
                                    .withValues(alpha: 0.16)
                                : const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (isCheckedIn
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            pass.statusLabel,
                            style: TextStyle(
                              color: isCheckedIn
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Active Entry Code Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF263238)
                              : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ENTRY OTP PASSCODE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: secondaryTextColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pass.code,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: TokenTheme.primaryMintDark,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 22),
                            color: TokenTheme.primaryMintDark,
                            tooltip: 'Copy OTP',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: pass.code));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Entry code ${pass.code} copied!'),
                                  backgroundColor: TokenTheme.primaryMintDark,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Book-Out Exit Section (Only when Checked In)
                    if (isCheckedIn) ...[
                      const SizedBox(height: 22),
                      Text(
                        'EXIT GATE BOOK-OUT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: secondaryTextColor,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (hasBookoutCode) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF13231B)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  TokenTheme.primaryMint.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '4-Digit Exit Passcode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: TokenTheme.primaryMintDark,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: TokenTheme.primaryMintDark,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Valid for 2h',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                pass.bookoutCode!.split('').join('   '),
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: primaryTextColor,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Present this exit code at the exit gate keypad to complete checkout.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Book Out Actions
                      Row(
                        children: [
                          if (!hasBookoutCode)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final code = await VisitorStore.instance
                                        .generateBookOutCode(pass.id);
                                    if (!ctx.mounted) return;
                                    HapticFeedback.mediumImpact();
                                    setModalState(() {
                                      pass.bookoutCode = code;
                                    });
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(e.toString())));
                                    }
                                  }
                                },
                                icon: const Icon(Icons.qr_code_rounded,
                                    color: Colors.white, size: 22),
                                label: const Text(
                                  'Generate Exit Token',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TokenTheme.primaryMintDark,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          if (hasBookoutCode) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Present the exit code at the gate. Departure is recorded after guard verification.'),
                                      backgroundColor:
                                          TokenTheme.primaryMintDark,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.logout_rounded,
                                    color: Colors.white, size: 22),
                                label: const Text(
                                  'Done',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                iconSize: 22,
                                onPressed: () async {
                                  final text =
                                      'Hi ${pass.visitorName}, here is your Residence exit gate code: ${pass.bookoutCode}. Present it at the gate when leaving.';
                                  HapticFeedback.lightImpact();
                                  try {
                                    await Share.share(text,
                                        subject: 'Residence Exit Passcode');
                                  } catch (e) {
                                    Clipboard.setData(
                                        ClipboardData(text: text));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Exit passcode copied to clipboard!')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.share_rounded),
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = TokenTheme.pageBg(isDark);
    final cardBg = TokenTheme.card(isDark);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Visitors',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Create New Pass',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TokenTheme.primaryMint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: TokenTheme.primaryMintDark.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: TokenTheme.primaryMintDark,
                size: 22,
              ),
            ),
            onPressed: () => _openCreatePassScreen(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: AnimatedBuilder(
        animation: VisitorStore.instance,
        builder: (context, _) {
          final activePasses = VisitorStore.instance.activePasses;
          final displayedPasses = activePasses.take(2).toList();
          final hasMorePasses = activePasses.length > 2;
          final pastPasses = VisitorStore.instance.pastPasses;
          final frequentGuests = VisitorStore.instance.frequentGuests;

          return RefreshIndicator(
              onRefresh: VisitorStore.instance.refresh,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                children: [
                  if (VisitorStore.instance.loading)
                    const LinearProgressIndicator(),
                  if (VisitorStore.instance.error != null)
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          Text(VisitorStore.instance.error!),
                          TextButton(
                              onPressed: VisitorStore.instance.refresh,
                              child: const Text('Retry loading visitors')),
                        ])),
                  // Frequent Guests Section (Edge-to-Edge scrolling)
                  if (frequentGuests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: TokenTheme.pageSidePadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: TokenTheme.primaryMintDark,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'FREQUENT GUESTS',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: secondaryTextColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '1-tap quick pass',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 164,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: TokenTheme.pageSidePadding),
                        scrollDirection: Axis.horizontal,
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        itemCount: frequentGuests.length,
                        itemBuilder: (context, index) {
                          final guest = frequentGuests[index];
                          return _buildFrequentGuestCard(
                            guest: guest,
                            isDark: isDark,
                            cardBg: cardBg,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            context: context,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Active Passes Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: TokenTheme.pageSidePadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: TokenTheme.primaryMintDark,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ACTIVE PASSES (${activePasses.length})',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: secondaryTextColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        if (hasMorePasses)
                          GestureDetector(
                            onTap: () => _openAllPassesScreen(context),
                            child: const Row(
                              children: [
                                Text(
                                  'View all',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: TokenTheme.primaryMintDark,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: TokenTheme.primaryMintDark,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (activePasses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: TokenTheme.pageSidePadding),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF21262D)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.badge_outlined,
                                  size: 36,
                                  color: secondaryTextColor.withValues(
                                      alpha: 0.5)),
                              const SizedBox(height: 10),
                              Text(
                                'No active visitor passes right now.',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Display at most 2 active passes
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: TokenTheme.pageSidePadding),
                      child: Column(
                        children: displayedPasses
                            .map((pass) => _buildActivePassCard(
                                  pass: pass,
                                  isDark: isDark,
                                  primaryTextColor: primaryTextColor,
                                  secondaryTextColor: secondaryTextColor,
                                  context: context,
                                  onTap: () =>
                                      _openPassActionModal(context, pass),
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Past Visitors History Section
                  if (pastPasses.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: TokenTheme.pageSidePadding),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: TokenTheme.primaryMintDark,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PAST VISITOR HISTORY',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: secondaryTextColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: TokenTheme.pageSidePadding),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF263238)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.35 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: pastPasses.asMap().entries.map((entry) {
                              final index = entry.key;
                              final pass = entry.value;
                              final isLast = index == pastPasses.length - 1;

                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.history_rounded,
                                          size: 20, color: secondaryTextColor),
                                    ),
                                    title: Text(
                                      pass.visitorName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.5,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'OTP: ${pass.code} • Checked Out',
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      indent: 64,
                                      color: isDark
                                          ? Colors.white10
                                          : const Color(0xFFF1F5F9),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                ],
              ));
        },
      ),
    );
  }

  Widget _buildActivePassCard({
    required VisitorPass pass,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final cardBg = TokenTheme.card(isDark);
    final isCheckedIn = pass.status == VisitorStatus.checkedIn;
    final statusColor =
        isCheckedIn ? const Color(0xFF10B981) : TokenTheme.primaryMintDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCheckedIn
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF263238) : const Color(0xFFE2E8F0)),
          width: isCheckedIn ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                // Ultra Compact Icon
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    isCheckedIn ? Icons.login_rounded : Icons.vpn_key_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),

                // Title & Status/Expiry Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pass.visitorName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            isCheckedIn ? 'Checked In' : 'Valid Pass',
                            style: TextStyle(
                                fontSize: 11,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isCheckedIn ? 'Inside' : 'Active OTP',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (pass.bookoutCode != null) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Exit: ${pass.bookoutCode}',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  color: Color(0xFF10B981),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Prominent Bold Pass Code & Inline Action Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isCheckedIn
                                  ? const Color(0xFF10B981)
                                  : TokenTheme.primaryMintDark)
                              .withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        pass.code,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isCheckedIn
                              ? const Color(0xFF10B981)
                              : (isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A)),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCheckedIn
                              ? const Color(0xFF10B981)
                              : TokenTheme.primaryMintDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7)),
                        ),
                        child: Text(
                          isCheckedIn ? 'Book Out' : 'Options',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRelationshipColor(String rel) {
    switch (rel.toLowerCase()) {
      case 'delivery':
        return const Color(0xFF0D9488); // Refined Slate Teal
      case 'cleaner':
      case 'service':
      case 'maintenance':
        return const Color(0xFF10B981); // Emerald Mint
      case 'family':
        return TokenTheme.primaryMintDark; // Deep Brand Mint
      case 'friend':
        return TokenTheme.primaryMintDark; // Brand Mint
      default:
        return const Color(0xFF0F766E); // Deep Teal
    }
  }

  IconData _getRelationshipIcon(String rel) {
    switch (rel.toLowerCase()) {
      case 'delivery':
        return Icons.delivery_dining_rounded;
      case 'cleaner':
      case 'service':
      case 'maintenance':
        return Icons.cleaning_services_rounded;
      case 'family':
        return Icons.favorite_rounded;
      case 'friend':
        return Icons.sentiment_satisfied_alt_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Widget _buildFrequentGuestCard({
    required FrequentGuest guest,
    required bool isDark,
    required Color cardBg,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required BuildContext context,
  }) {
    final relColor = _getRelationshipColor(guest.relationship);
    final relIcon = _getRelationshipIcon(guest.relationship);

    return Container(
      width: 172,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF263238) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Mint Squircle Avatar & Theme Chip Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: TokenTheme.primaryMint.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TokenTheme.primaryMint.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        guest.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: TokenTheme.primaryMintDark,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7.5, vertical: 4),
                    decoration: BoxDecoration(
                      color: relColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: relColor.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(relIcon, size: 12, color: relColor),
                        const SizedBox(width: 4),
                        Text(
                          guest.relationship,
                          style: TextStyle(
                            fontSize: 11,
                            color: relColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Middle: Guest Name & Fast Pass Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    guest.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.flash_on_rounded,
                          size: 12, color: TokenTheme.primaryMintDark),
                      const SizedBox(width: 2),
                      Text(
                        '1-Tap Fast Pass',
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Bottom Action Button: Theme-aligned Instant Pass
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final newPass =
                          await VisitorStore.instance.createVisitorToken(
                        visitorName: guest.name,
                        relationship: guest.relationship,
                      );
                      if (!context.mounted) return;
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Instant pass ${newPass.code} created for ${guest.name}!'),
                          backgroundColor: TokenTheme.primaryMintDark,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 15),
                  label: const Text(
                    'Instant Pass',
                    style:
                        TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        TokenTheme.primaryMint.withValues(alpha: 0.16),
                    foregroundColor: TokenTheme.primaryMintDark,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                      side: BorderSide(
                        color:
                            TokenTheme.primaryMintDark.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
