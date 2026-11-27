import 'package:estate/resident/data/visitor_api.dart';
import 'package:estate/shared/notifications/fcm_service.dart';
import 'package:flutter/foundation.dart';
import 'package:estate/resident/models/visitor_pass.dart';
import 'package:estate/shared/auth/auth_service.dart';

class VisitorStore extends ChangeNotifier {
  static final VisitorStore instance = VisitorStore._internal();
  factory VisitorStore() => instance;
  VisitorStore._internal() {
    AuthService.instance.currentUserNotifier.addListener(() {
      _requestVersion++;
      loading = false;
      error = null;
      _passes.clear();
      _frequentGuests.clear();
      notifyListeners();
      refresh();
    });
    FCMService.instance.accessEvents.listen((_) => refresh());
    if (VisitorApi.isLive) {
      _passes.clear();
      _frequentGuests.clear();
      refresh();
    }
  }

  bool loading = false;
  String? error;
  int _requestVersion = 0;
  Future<void> refresh() async {
    if (!VisitorApi.isLive) return;
    final version = ++_requestVersion;
    final token = AuthService.instance.accessToken;
    loading = true;
    notifyListeners();
    try {
      final rows = await VisitorApi.request('tokens/visitor/history') as List;
      if (version != _requestVersion ||
          token != AuthService.instance.accessToken) {
        return;
      }
      _passes
        ..clear()
        ..addAll(rows.map(
            (row) => VisitorPass.fromJson(Map<String, dynamic>.from(row))));
      error = null;
    } catch (e) {
      if (version == _requestVersion) error = e.toString();
    } finally {
      if (version == _requestVersion) {
        loading = false;
        notifyListeners();
      }
    }
  }

  final List<VisitorPass> _passes = [];
  final List<FrequentGuest> _frequentGuests = [];

  List<VisitorPass> get activePasses =>
      _passes.where((p) => p.status != VisitorStatus.checkedOut).toList();

  List<VisitorPass> get pastPasses =>
      _passes.where((p) => p.status == VisitorStatus.checkedOut).toList();

  VisitorPass? get lastGeneratedPass =>
      _passes.isNotEmpty ? _passes.first : null;

  List<FrequentGuest> get frequentGuests => List.unmodifiable(_frequentGuests);

  /// The server issues the visitor code. The phone never invents one.
  Future<VisitorPass> createVisitorToken({
    required String visitorName,
    bool saveAsFrequent = false,
    String relationship = 'Guest',
  }) async {
    if (!VisitorApi.isLive) {
      throw Exception(
          'Sign in to the estate server. Passes are issued by the server.');
    }
    final row = await VisitorApi.request('tokens/visitor',
        body: {'visitor_name': visitorName.trim()});
    final pass = VisitorPass.fromJson(Map<String, dynamic>.from(row));
    _passes.insert(0, pass);
    if (saveAsFrequent &&
        !_frequentGuests.any((guest) =>
            guest.name.toLowerCase() == visitorName.trim().toLowerCase())) {
      _frequentGuests.add(FrequentGuest(
          id: 'fq-${pass.id}',
          name: visitorName.trim(),
          relationship: relationship,
          lastVisited: DateTime.now()));
    }
    notifyListeners();
    return pass;
  }

  /// The server issues the book-out code.
  Future<VisitorPass> generateBookOutCode(VisitorPass current) async {
    if (!VisitorApi.isLive) {
      throw Exception(
          'Sign in to the estate server. Exit codes are issued by the server.');
    }
    final token = AuthService.instance.accessToken;
    final row = await VisitorApi.request(
        'tokens/visitor/${current.id}/book-out',
        body: {});
    if (token != AuthService.instance.accessToken) {
      throw StateError('Your session changed. Open this pass again.');
    }
    final pass =
        _passes.firstWhere((p) => p.id == current.id, orElse: () => current);
    pass.bookoutCode = row['bookout_code'];
    pass.bookoutExpiresAt = VisitorPass.parseTime(row['expires_at']);
    notifyListeners();
    return pass;
  }
}
