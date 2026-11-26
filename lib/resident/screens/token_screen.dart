import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/resident/models/visitor_pass.dart';
import 'package:estate/resident/state/visitor_store.dart';
import 'package:estate/resident/widgets/token_boxes.dart';
import 'package:estate/resident/widgets/action_cards.dart';
import 'package:estate/resident/widgets/help_dialog.dart';

class TokenScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  final ValueNotifier<int>? newPassRequests;

  const TokenScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
    this.newPassRequests,
  });

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  @override
  void initState() {
    super.initState();
    widget.newPassRequests?.addListener(_showGenerateTokenSheet);
  }

  @override
  void dispose() {
    widget.newPassRequests?.removeListener(_showGenerateTokenSheet);
    super.dispose();
  }

  final String _gateLocation = 'Estate security gate';
  String _tokenType = 'Visitor Pass';

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style:
              const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: TokenTheme.primaryMintDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onCopyToken(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    _showNotification('Token $code copied to clipboard!');
  }

  String _buildShareMessage(
      String guestName, String code, String gateLocation) {
    return '🔑 Residence Gate Access Pass\n\n'
        '👤 Guest: $guestName\n'
        '🎟️ Access Code: $code\n'
        '📍 Gate: $gateLocation\n\n'
        'Present this alphanumeric code to estate security for verification.';
  }

  Future<void> _onNativeShare(
      String guestName, String code, String gateLocation) async {
    final shareMessage = _buildShareMessage(guestName, code, gateLocation);
    HapticFeedback.mediumImpact();
    try {
      await Share.share(
        shareMessage,
        subject: 'Residence Gate Pass for $guestName',
      );
    } catch (e) {
      Clipboard.setData(ClipboardData(text: shareMessage));
      _showNotification('Pass details copied to clipboard!');
    }
  }

  void _showGenerateTokenSheet() {
    String selectedType = _tokenType;
    final guestNameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setSheetState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
            final surfaceColor =
                isDark ? TokenTheme.darkSurface : TokenTheme.lightSurface;
            final primaryTextColor = isDark
                ? TokenTheme.darkTextPrimary
                : TokenTheme.lightTextPrimary;
            final secondaryTextColor = isDark
                ? TokenTheme.darkTextSecondary
                : TokenTheme.lightTextSecondary;

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
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
                      const SizedBox(height: 18),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: TokenTheme.primaryMint
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.key_rounded,
                              color: TokenTheme.primaryMintDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generate Gate Pass',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              Text(
                                'Create instant OTP for guest gate access',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          )),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Guest Name Input Field
                      Text(
                        'GUEST / RECIPIENT NAME',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: guestNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Alex Johnson / Delivery Driver',
                          filled: true,
                          fillColor: isDark
                              ? TokenTheme.darkCardBg
                              : const Color(0xFFF3F4F6),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Token Type Dropdown
                      Text(
                        'PASS TYPE',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? TokenTheme.darkCardBg
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            dropdownColor: surfaceColor,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Visitor Pass',
                                  child: Text('Visitor Pass')),
                              DropdownMenuItem(
                                  value: 'Guest Single Pass',
                                  child: Text('Guest Single Pass')),
                              DropdownMenuItem(
                                  value: 'Delivery & Courier',
                                  child: Text('Delivery & Courier')),
                              DropdownMenuItem(
                                  value: 'Service / Contractor',
                                  child: Text('Service / Contractor')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedType = val);
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Generate Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final name = guestNameCtrl.text.trim();
                              final guestName =
                                  name.isNotEmpty ? name : 'Guest Visitor';
                              await VisitorStore.instance.createVisitorToken(
                                visitorName: guestName,
                                relationship: selectedType,
                              );
                              if (!mounted || !sheetContext.mounted) return;
                              setState(() {
                                _tokenType = selectedType;
                              });
                              Navigator.pop(sheetContext);
                              HapticFeedback.mediumImpact();
                              _showNotification(
                                  'New pass generated for $guestName!');
                            } catch (e) {
                              if (mounted) _showNotification(e.toString());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TokenTheme.primaryMintDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Generate Pass Token',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    final primaryTextColor =
        isDark ? TokenTheme.darkTextPrimary : TokenTheme.lightTextPrimary;
    final secondaryTextColor =
        isDark ? TokenTheme.darkTextSecondary : TokenTheme.lightTextSecondary;

    return AnimatedBuilder(
      animation: VisitorStore.instance,
      builder: (context, _) {
        final lastPass = VisitorStore.instance.lastGeneratedPass;
        final guestName = lastPass?.visitorName ?? 'Guest Visitor';
        final token = lastPass?.code ?? '00000';
        final isCheckedIn = lastPass?.status == VisitorStatus.checkedIn;
        final isCheckedOut = lastPass?.status == VisitorStatus.checkedOut;

        final badgeText = lastPass != null
            ? (isCheckedIn
                ? 'CHECKED IN • MAIN GATE'
                : (isCheckedOut
                    ? 'COMPLETED / CHECKED OUT'
                    : 'ACTIVE PASS • READY FOR ENTRY'))
            : 'LAST GENERATED TOKEN';

        final badgeColor = isCheckedIn
            ? const Color(0xFF10B981)
            : (isCheckedOut
                ? const Color(0xFF94A3B8)
                : TokenTheme.primaryMintDark);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Digital Gate Token',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: RefreshIndicator(
                onRefresh: VisitorStore.instance.refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(
                      horizontal: TokenTheme.pageSidePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                      // Brand Logo: RESIDENCE
                      _buildBrandLogo(isDark),

                      const SizedBox(height: 22),

                      // Active status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Guest Name on top of the token
                      _buildGuestNameHeader(guestName, primaryTextColor),

                      const SizedBox(height: 16),

                      // Token Boxes (Screen width ratio responsive - always on screen)
                      TokenBoxes(
                        token: token,
                        isDark: isDark,
                        onCopied: () => _onCopyToken(token),
                      ),

                      const SizedBox(height: 12),

                      // Gate & Expiry hint
                      Text(
                        'Entry Gate: $_gateLocation',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Copy and Share; New Token is the floating button.
                      ActionCards(
                        isDark: isDark,
                        onCopy: () => _onCopyToken(token),
                        onShare: () =>
                            _onNativeShare(guestName, token, _gateLocation),
                      ),

                      const SizedBox(height: 32),

                      // "How to use the code?"
                      GestureDetector(
                        onTap: () => HelpBottomSheet.show(context, isDark),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.help_outline_rounded,
                                size: 16,
                                color: isDark
                                    ? TokenTheme.primaryMintLight
                                    : TokenTheme.primaryMintDark,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                  child: Text(
                                'How to use the access token?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? TokenTheme.primaryMintLight
                                      : TokenTheme.primaryMintDark,
                                  decoration: TextDecoration.underline,
                                  decorationColor: (isDark
                                          ? TokenTheme.primaryMintLight
                                          : TokenTheme.primaryMintDark)
                                      .withValues(alpha: 0.5),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                )),
          ),
        );
      },
    );
  }

  Widget _buildGuestNameHeader(String guestName, Color primaryTextColor) {
    return Text(
      guestName,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: primaryTextColor,
        letterSpacing: 0.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBrandLogo(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'RES',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: TokenTheme.primaryMint,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'IDENCE',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
