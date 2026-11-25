import 'package:estate/shared/ui/theme.dart';
import 'package:estate/shared/ui/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:estate/gate/models/visitor_pass.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/gate/state/gatehouse_store.dart';
import 'package:estate/gate/state/gate_visitor_store.dart';

class GatehouseHomeScreen extends StatefulWidget {
  final bool isDark;

  const GatehouseHomeScreen({super.key, required this.isDark});

  @override
  State<GatehouseHomeScreen> createState() => _GatehouseHomeScreenState();
}

class _GatehouseHomeScreenState extends State<GatehouseHomeScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  VerificationResult? _lastResult;
  bool _isVerifying = false;

  /// Minimum chars before the guard can tap Verify (security requirement: always 4)
  static const int minVerifyLength = 4;

  /// Preferred code length from the latest estate settings snapshot.
  int get defaultCodeLength => AuthService.instance.tokenCodeLength;

  @override
  void initState() {
    super.initState();
    AuthService.instance.tokenCodeLengthNotifier.addListener(_settingsChanged);
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _settingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AuthService.instance.tokenCodeLengthNotifier
        .removeListener(_settingsChanged);
    _codeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onClear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _codeCtrl.clear();
      _lastResult = null;
    });
    _focusNode.requestFocus();
  }

  Future<void> _onPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim().toUpperCase();
    if (text != null && text.isNotEmpty) {
      final cleaned = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (cleaned.isNotEmpty) {
        final code = cleaned;
        HapticFeedback.lightImpact();
        setState(() {
          _codeCtrl.text = code;
          _lastResult = null;
        });
        _triggerVerification(code);
      }
    }
  }

  Future<void> _triggerVerification(String code) async {
    if (code.trim().isEmpty || _isVerifying) return;
    HapticFeedback.mediumImpact();
    _focusNode.unfocus();
    setState(() {
      _isVerifying = true;
      _lastResult = null;
    });
    try {
      final result = await GatehouseStore.instance.verifyAccess(code);
      if (!mounted) return;
      setState(() => _lastResult = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF4F6F9);
    final cardBg = isDark ? const Color(0xFF161E2E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation:
          Listenable.merge([GatehouseStore.instance, GateVisitorStore.instance]),
      builder: (context, _) {
        final currentPost = GatehouseStore.instance.currentGatePost;
        final onPremises = GatehouseStore.instance.onPremisesCount;
        final todayEntries = GatehouseStore.instance.todayEntriesCount;
        final todayExits = GatehouseStore.instance.todayExitsCount;
        final activePasses = GateVisitorStore.instance.activePasses;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
            elevation: 0,
            titleSpacing: 20,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF0D9488),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'GATEHOUSE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ONLINE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currentPost,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: const [NotificationBell()],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: borderColor, height: 1),
            ),
          ),
          body: SafeArea(
            child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    GateVisitorStore.instance.refresh(),
                    AuthService.instance.refreshEstateSettings(invalidate: true)
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: TokenTheme.pageSidePadding, vertical: 14),
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  children: [
                    // Quick Shift Metrics
                    Row(
                      children: [
                        _buildMetricCard(
                          label: 'On Premises',
                          value: '$onPremises',
                          color: const Color(0xFF0284C7),
                          icon: Icons.people_alt_rounded,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          label: 'Entries Today',
                          value: '$todayEntries',
                          color: const Color(0xFF10B981),
                          icon: Icons.login_rounded,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          label: 'Exits Cleared',
                          value: '$todayExits',
                          color: const Color(0xFFF59E0B),
                          icon: Icons.logout_rounded,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Main Keypad / Verification Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.35 : 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header Label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.security_rounded,
                                        color: Color(0xFF0D9488), size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'VISITOR TOKEN VERIFIER',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: secondaryTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: _onPaste,
                                    borderRadius: BorderRadius.circular(6),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.content_paste_rounded,
                                              size: 13,
                                              color: Color(0xFF0D9488)),
                                          SizedBox(width: 4),
                                          Text(
                                            'PASTE',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D9488),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_codeCtrl.text.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: _onClear,
                                      borderRadius: BorderRadius.circular(6),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        child: Text(
                                          'CLEAR',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Code Display Boxes (Alphanumeric, Responsive)
                          _buildCodeDisplay(isDark, primaryTextColor,
                              secondaryTextColor, borderColor),

                          const SizedBox(height: 18),

                          // Verification Result Card (if verified)
                          if (_isVerifying)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(
                                  color: Color(0xFF0D9488)),
                            )
                          else if (_lastResult != null)
                            _buildResultCard(_lastResult!, isDark,
                                primaryTextColor, secondaryTextColor)
                          else ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _codeCtrl.text.length >=
                                        minVerifyLength
                                    ? () => _triggerVerification(_codeCtrl.text)
                                    : () => _focusNode.requestFocus(),
                                icon: Icon(
                                  _codeCtrl.text.length >= minVerifyLength
                                      ? Icons.verified_user_rounded
                                      : Icons.keyboard_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _codeCtrl.text.length >= minVerifyLength
                                      ? 'VERIFY TOKEN'
                                      : 'TAP TO ENTER TOKEN (min $minVerifyLength chars)',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _codeCtrl.text.length >= minVerifyLength
                                          ? const Color(0xFF0D9488)
                                          : const Color(0xFF94A3B8),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick List: Today's Active Passes (Fast 1-tap autofill for guards)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'VISITORS ON PREMISES (${activePasses.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (activePasses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            'No visitors on premises right now',
                            style: TextStyle(
                                fontSize: 13, color: secondaryTextColor),
                          ),
                        ),
                      )
                    else
                      ...activePasses.map((pass) {
                        final isCheckedIn =
                            pass.status == VisitorStatus.checkedIn;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isCheckedIn
                                          ? const Color(0xFF0284C7)
                                          : const Color(0xFF10B981))
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCheckedIn
                                      ? Icons.login_rounded
                                      : Icons.hourglass_top_rounded,
                                  color: isCheckedIn
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF10B981),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pass.visitorName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isCheckedIn
                                          ? 'Checked in • On premises'
                                          : 'Pending entry • Main Gate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 24),
                  ],
                )),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: color),
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeDisplay(
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final code = _codeCtrl.text;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Invisible TextField to receive system keyboard & barcode/RFID input
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                height: 56,
                child: TextField(
                  focusNode: _focusNode,
                  controller: _codeCtrl,
                  autofocus: false,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  onChanged: (val) {
                    final upper = val.toUpperCase();
                    if (val != upper) {
                      _codeCtrl.value = _codeCtrl.value.copyWith(
                        text: upper,
                        selection:
                            TextSelection.collapsed(offset: upper.length),
                      );
                    }
                    setState(() {
                      _lastResult = null;
                    });
                  },
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _triggerVerification(val.trim());
                    }
                  },
                ),
              ),
            ),

            // Start with the estate default; expand and wrap as more characters are entered.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _focusNode.requestFocus();
              },
              child: AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: LayoutBuilder(builder: (context, constraints) {
                  final visibleSlots = code.length > defaultCodeLength
                      ? code.length
                      : defaultCodeLength;
                  final columns = visibleSlots.clamp(
                      1,
                      (constraints.maxWidth / 38)
                          .floor()
                          .clamp(defaultCodeLength, 8));
                  final slotWidth =
                      (constraints.maxWidth - (columns - 1) * 6) / columns;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 8,
                    children: List.generate(visibleSlots, (index) {
                      final char = index < code.length ? code[index] : '';
                      final isFilled = char.isNotEmpty;
                      final isFocused =
                          _focusNode.hasFocus && index == code.length;
                      // The last visible slot beyond current input is a "ghost"
                      // preview slot (dashed border, muted dot)
                      final isPreview = !isFilled && index == code.length;

                      return SizedBox(
                        key: ValueKey('verification-code-slot-$index'),
                        width: slotWidth,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          height: 58,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: isPreview
                                ? Border.all(
                                    color: borderColor.withValues(alpha: 0.4),
                                    width: 1,
                                    strokeAlign: BorderSide.strokeAlignInside,
                                  )
                                : Border.all(
                                    color: isFilled
                                        ? const Color(0xFF0D9488)
                                        : (isFocused
                                            ? const Color(0xFF0D9488)
                                                .withValues(alpha: 0.6)
                                            : borderColor),
                                    width: isFilled ? 2 : (isFocused ? 1.5 : 1),
                                  ),
                            boxShadow: isFilled
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF0D9488)
                                          .withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              char.isNotEmpty ? char : '•',
                              style: TextStyle(
                                fontSize: char.isNotEmpty ? 22 : 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: char.isNotEmpty
                                    ? (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A))
                                    : isPreview
                                        ? (isDark
                                            ? Colors.white12
                                            : Colors.black12)
                                        : (isDark
                                            ? Colors.white24
                                            : Colors.black26),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_rounded,
                  size: 13,
                  color: secondaryTextColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap boxes to open device keyboard',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    VerificationResult res,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final statusColor = res.isValid
        ? const Color(0xFF10B981)
        : (res.isFound ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.isValid
                      ? 'AUTHORIZED PASS'
                      : (res.isFound ? 'PASS EXPIRED' : 'ACCESS DENIED'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: _onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            res.visitorName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Host: ${res.hostResident} • ${res.hostUnit}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),

          const SizedBox(height: 8),
          Text(
            res.message,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
