import 'package:flutter/foundation.dart';
import '../models/gate_log_model.dart';
import '../models/gate_chat_model.dart';
import '../models/visitor_pass.dart';
import 'visitor_store.dart';
import 'visitor_api.dart';
import 'auth_service.dart';

class VerificationResult {
  final bool isFound;
  final bool isValid;
  final bool isBookout;
  final VisitorPass? pass;
  final String visitorName;
  final String hostResident;
  final String hostUnit;
  final String message;
  final bool canCheckIn;
  final bool canBookOut;

  const VerificationResult({
    required this.isFound,
    required this.isValid,
    this.isBookout = false,
    this.pass,
    required this.visitorName,
    required this.hostResident,
    required this.hostUnit,
    required this.message,
    required this.canCheckIn,
    required this.canBookOut,
  });
}

class SecurityOfficer {
  final String id;
  final String name;
  final String badgeNumber;
  final String assignedPost;
  final String shiftHours;
  final String status; // "On Duty", "On Break", "Off Duty"
  final String phone;

  const SecurityOfficer({
    required this.id,
    required this.name,
    required this.badgeNumber,
    required this.assignedPost,
    required this.shiftHours,
    required this.status,
    required this.phone,
  });
}

class GatehouseStore extends ChangeNotifier {
  static final GatehouseStore instance = GatehouseStore._internal();
  factory GatehouseStore() => instance;
  GatehouseStore._internal() {
    VisitorStore.instance.addListener(notifyListeners);
    String? identity;
    AuthService.instance.currentUserNotifier.addListener(() {
      final user = AuthService.instance.currentUser;
      final next = user == null ? null : '${user.appId}.${user.id}';
      if (identity == next) return;
      identity = next;
      _logs.clear();
      historyError = null;
      notifyListeners();
    });
  }

  String _currentGuardStatus = 'On Duty'; // "On Duty", "On Break", "Off Duty"
  String _currentGatePost = 'Gatehouse';

  String get currentGuardStatus => _currentGuardStatus;
  String get currentGatePost => _currentGatePost;

  void setGuardStatus(String status) {
    _currentGuardStatus = status;
    notifyListeners();
  }

  void setGatePost(String post) {
    _currentGatePost = post;
    notifyListeners();
  }

  final List<GateLogEntry> _logs = [];
  final List<ResidentChatThread> _chatThreads = [];
  final List<SecurityOfficer> _officers = [];

  List<GateLogEntry> get logs => List.unmodifiable(_logs);
  List<ResidentChatThread> get chatThreads => List.unmodifiable(_chatThreads);
  List<SecurityOfficer> get officers => List.unmodifiable(_officers);

  int get totalUnreadChats =>
      _chatThreads.fold(0, (sum, t) => sum + t.unreadCount);

  int get todayEntriesCount =>
      _logs.where((l) => l.actionType == GateActionType.entryGranted).length;

  int get todayExitsCount =>
      _logs.where((l) => l.actionType == GateActionType.exitGranted).length;

  int get todayDeniedCount =>
      _logs.where((l) => l.actionType == GateActionType.accessDenied).length;

  int get onPremisesCount => VisitorStore.instance.activePasses
      .where((p) => p.status == VisitorStatus.checkedIn)
      .length;

  String? historyError;
  Future<void> refreshHistory() async {
    if (!VisitorApi.isLive) return;
    final token = AuthService.instance.accessToken;
    try {
      final since = Uri.encodeQueryComponent(DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 24))
          .toIso8601String());
      final result =
          await VisitorApi.request('access-logs/?limit=200&start_at=$since');
      if (token != AuthService.instance.accessToken) return;
      final rows = (result['logs'] as List).map((raw) {
        final row = Map<String, dynamic>.from(raw);
        final event = row['event_type'] as String? ?? '';
        return GateLogEntry(
            id: row['id'].toString(),
            timestamp: VisitorPass.parseTime(row['created_at']),
            visitorName: row['visitor_name'] as String? ?? 'Estate member',
            code: row['identifier'] as String? ?? '',
            hostResident: 'Not recorded',
            hostUnit: 'Not recorded',
            actionType: row['status'] != 'authorized'
                ? GateActionType.accessDenied
                : event.contains('bookout') ||
                        event.contains('book_out') ||
                        event.contains('exit')
                    ? GateActionType.exitGranted
                    : GateActionType.entryGranted,
            gateLocation: 'Not recorded',
            officerName: 'Not recorded',
            verificationMethod: event.replaceAll('_', ' '),
            denialReason: row['denial_reason'] as String?);
      }).toList();
      _logs
        ..clear()
        ..addAll(rows);
      historyError = null;
    } catch (_) {
      if (token == AuthService.instance.accessToken) {
        historyError = 'Unable to refresh gate history. Pull down to retry.';
      }
    }
    notifyListeners();
  }

  Future<VerificationResult> verifyAccess(String code) async {
    if (!VisitorApi.isLive) {
      throw StateError('Sign in to verify access with the estate server.');
    }
    final row = await VisitorApi.request(
        'verify/token/${Uri.encodeComponent(code.trim().toUpperCase())}');
    final exit = row['action'] == 'book_out';
    await VisitorStore.instance.refresh();
    notifyListeners();
    return VerificationResult(
        isFound: true,
        isValid: row['status'] == 'authorized',
        isBookout: exit,
        visitorName: row['visitor_name'] ?? 'Visitor',
        hostResident: row['resident_id'] ?? '',
        hostUnit: '',
        message: row['message'] ?? (exit ? 'Exit recorded' : 'Entry recorded'),
        canCheckIn: false,
        canBookOut: false);
  }

  /// Mark thread messages as read
  void markThreadRead(String residentId) {
    final index = _chatThreads.indexWhere((t) => t.residentId == residentId);
    if (index == -1) return;

    if (_chatThreads[index].unreadCount > 0) {
      _chatThreads[index] = _chatThreads[index].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }
}
