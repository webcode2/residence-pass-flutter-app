import 'package:estate/gate/data/visitor_api.dart';
import 'package:estate/gate/ui/guest_token_field.dart';
import 'package:estate/gate/ui/gate_style.dart';
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

  final Future<VerificationResult> Function(String)? previewToken;
  final Future<VerificationResult> Function(String, VerificationResult)?
      approveToken;

  const GatehouseHomeScreen({
    super.key,
    required this.isDark,
    this.previewToken,
    this.approveToken,
  });

  @override
  State<GatehouseHomeScreen> createState() => _GatehouseHomeScreenState();
}

class _GatehouseHomeScreenState extends State<GatehouseHomeScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  VerificationResult? _lastResult;
  String? _verificationError;
  bool _isVerifying = false;
  bool _isApproving = false;

  bool get _hasPreview =>
      _lastResult?.canCheckIn == true || _lastResult?.canBookOut == true;

  /// Minimum chars before the guard can tap Verify (security requirement: always 4)
  static const int minVerifyLength = 4;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onClear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _codeCtrl.clear();
      _lastResult = null;
      _verificationError = null;
    });
    _focusNode.requestFocus();
  }

  Future<void> _triggerVerification(String code,
      {VerificationResult? approval}) async {
    if (code.trim().length < minVerifyLength || _isVerifying) return;
    if (approval == null && _lastResult != null) return;
    final session = AuthService.instance.accessToken;
    HapticFeedback.mediumImpact();
    _focusNode.unfocus();
    setState(() {
      _isVerifying = true;
      _isApproving = approval != null;
      _lastResult = null;
      _verificationError = null;
    });
    try {
      final store = GatehouseStore.instance;
      final result = approval == null
          ? await (widget.previewToken ?? store.previewAccess)(code)
          : await (widget.approveToken ?? store.approveAccess)(code, approval);
      if (!mounted || AuthService.instance.accessToken != session) return;
      setState(() => _lastResult = result);
    } catch (e) {
      if (mounted && AuthService.instance.accessToken == session) {
        setState(() {
          _verificationError = e is VisitorApiError
              ? e.message
              : (_isApproving
                  ? 'Unable to confirm approval. Look up the token again.'
                  : 'Unable to look up the token. Please try again.');
        });
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = GatePalette.of(context);
    final isDark = palette.dark;
    final primaryTextColor = palette.ink;
    final secondaryTextColor = palette.muted;

    return AnimatedBuilder(
      animation: Listenable.merge([
        GatehouseStore.instance,
        GateVisitorStore.instance,
        AuthService.instance.estateNameNotifier,
      ]),
      builder: (context, _) {
        final currentPost = GatehouseStore.instance.currentGatePost;
        final onPremises = GatehouseStore.instance.onPremisesCount;
        final todayEntries = GatehouseStore.instance.todayEntriesCount;
        final todayExits = GatehouseStore.instance.todayExitsCount;
        final activePasses = GateVisitorStore.instance.activePasses;

        return Scaffold(
          backgroundColor: palette.canvas,
          appBar: gateHeader(
              context, AuthService.instance.estateNameNotifier.value ?? 'Home',
              subtitle: currentPost == 'Gatehouse' ? null : currentPost,
              actions: const [NotificationBell()]),
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
                      horizontal: TokenTheme.pageSidePadding, vertical: 18),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      decoration: palette.panel().copyWith(
                            gradient: LinearGradient(
                              colors: [palette.surface, palette.tint],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned(
                            top: -50,
                            right: -38,
                            child: IgnorePointer(
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      width: 18,
                                      color: palette.accent
                                          .withValues(alpha: .045)),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -67,
                            left: -38,
                            child: IgnorePointer(
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: palette.accent.withValues(alpha: .04),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                            child: Column(
                              children: [
                                Text('Gate activity',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: palette.muted)),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _activityStat(
                                        palette, 'On site', onPremises),
                                    _activityStat(
                                        palette, 'Entries today', todayEntries),
                                    _activityStat(
                                        palette, 'Exits today', todayExits),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Main Keypad / Verification Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: palette.panel(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Guest token',
                                    style: TextStyle(
                                        color: palette.ink,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                              ),
                              if (_codeCtrl.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Clear token',
                                  color: palette.muted,
                                  onPressed: _isVerifying ? null : _onClear,
                                )
                              else
                                const SizedBox(height: 48, width: 48),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GuestTokenField(
                            controller: _codeCtrl,
                            focusNode: _focusNode,
                            readOnly: _isVerifying || _hasPreview,
                            onSubmitted: _triggerVerification,
                            onChanged: (_) => setState(() {
                              _lastResult = null;
                              _verificationError = null;
                            }),
                          ),

                          const SizedBox(height: 18),

                          // Verification Result Card (if verified)
                          if (_isVerifying)
                            Column(
                              children: [
                                LinearProgressIndicator(
                                    color: palette.accent,
                                    backgroundColor: palette.tint),
                                const SizedBox(height: 12),
                                Text(
                                    _isApproving
                                        ? 'Recording approval…'
                                        : 'Looking up token…',
                                    style: TextStyle(color: palette.muted)),
                              ],
                            )
                          else if (_lastResult != null)
                            _buildResultCard(_lastResult!, isDark,
                                primaryTextColor, secondaryTextColor)
                          else ...[
                            if (_verificationError != null) ...[
                              Semantics(
                                liveRegion: true,
                                child: Container(
                                  decoration: palette.panel(
                                      color: palette.danger
                                          .withValues(alpha: .08)),
                                  padding: const EdgeInsets.all(12),
                                  child: Text(_verificationError!,
                                      style: TextStyle(color: palette.danger)),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _codeCtrl.text.length >=
                                        minVerifyLength
                                    ? () => _triggerVerification(_codeCtrl.text)
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: palette.action,
                                  foregroundColor:
                                      isDark ? TokenTheme.darkBg : Colors.white,
                                  disabledBackgroundColor: isDark
                                      ? const Color(0xFF343C39)
                                      : const Color(0xFFE3E5E3),
                                  disabledForegroundColor: palette.muted,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Look up token'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text('Active visitor passes (${activePasses.length})',
                        style: TextStyle(
                            color: palette.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),

                    if (activePasses.isEmpty)
                      const GateEmptyState(Icons.people_outline_rounded,
                          'No active visitor passes.')
                    else
                      ...activePasses.map((pass) {
                        final isCheckedIn =
                            pass.status == VisitorStatus.checkedIn;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: palette.panel(),
                          child: Row(
                            children: [
                              GateIcon(
                                isCheckedIn
                                    ? Icons.login_rounded
                                    : Icons.hourglass_top_rounded,
                                isCheckedIn ? palette.accent : palette.warning,
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
                                          : 'Pending entry',
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

                    const SizedBox(height: 16),
                  ],
                )),
          ),
        );
      },
    );
  }

  Widget _activityStat(GatePalette palette, String label, int value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Text('$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: palette.ink)),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
    VerificationResult res,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final palette = GatePalette.of(context);
    final pending = res.canCheckIn || res.canBookOut;
    final statusColor =
        pending || res.isValid ? palette.accent : palette.danger;
    final host = [res.hostResident, res.hostUnit]
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');

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
          Semantics(
            liveRegion: true,
            child: GateStatus(
              pending
                  ? (res.isBookout ? 'Review exit' : 'Review entry')
                  : res.isValid
                      ? (res.isBookout ? 'Exit authorized' : 'Entry authorized')
                      : 'Access denied',
              statusColor,
            ),
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
          Text(host.isEmpty ? 'Host name unavailable' : 'Host: $host',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor)),
          const SizedBox(height: 8),
          Text(
            res.message,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 12),
          if (pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: _onClear, child: const Text('Cancel')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        _triggerVerification(_codeCtrl.text, approval: res),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            )
          else
            OutlinedButton(
              onPressed: _onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.accent,
                side: BorderSide(color: palette.line),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Enter next token'),
            ),
        ],
      ),
    );
  }
}
