import 'package:flutter/material.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/resident/models/visitor_pass.dart';
import 'package:estate/resident/state/visitor_store.dart';
import 'package:estate/resident/screens/create_token_screen.dart';

class AllActivePassesScreen extends StatelessWidget {
  final bool isDark;
  final Function(BuildContext, VisitorPass) onOpenPassModal;

  const AllActivePassesScreen({
    super.key,
    required this.isDark,
    required this.onOpenPassModal,
  });

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Active Passes',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: VisitorStore.instance,
        builder: (context, _) {
          final activePasses = VisitorStore.instance.activePasses;

          if (activePasses.isEmpty) {
            return RefreshIndicator(
                onRefresh: VisitorStore.instance.refresh,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: 260,
                          child: Center(
                              child: Text('No active visitor passes right now',
                                  style: TextStyle(color: secondaryTextColor))))
                    ]));
          }

          return RefreshIndicator(
              onRefresh: VisitorStore.instance.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: TokenTheme.pageSidePadding, vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                itemCount: activePasses.length,
                itemBuilder: (context, index) {
                  final pass = activePasses[index];
                  final isCheckedIn = pass.status == VisitorStatus.checkedIn;
                  final statusColor = isCheckedIn
                      ? const Color(0xFF10B981)
                      : TokenTheme.primaryMintDark;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCheckedIn
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : (isDark
                                ? const Color(0xFF263238)
                                : const Color(0xFFE2E8F0)),
                        width: isCheckedIn ? 1.2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onOpenPassModal(context, pass),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
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
                                  isCheckedIn
                                      ? Icons.login_rounded
                                      : Icons.vpn_key_rounded,
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
                                          isCheckedIn
                                              ? 'Checked In'
                                              : 'Valid Pass',
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
                                            color: statusColor.withValues(
                                                alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isCheckedIn
                                                ? 'Inside'
                                                : 'Active OTP',
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                      onPressed: () =>
                                          onOpenPassModal(context, pass),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isCheckedIn
                                            ? const Color(0xFF10B981)
                                            : TokenTheme.primaryMintDark,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(7)),
                                      ),
                                      child: Text(
                                        isCheckedIn ? 'Book Out' : 'Options',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800),
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
                },
              ));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TokenTheme.primaryMintDark,
        elevation: 4,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CreateTokenScreen(isDark: isDark)),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          'New Token',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
