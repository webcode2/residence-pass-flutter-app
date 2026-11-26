import 'package:estate/gate/data/visitor_api.dart';

/// In-memory verification state for the current gatehouse identity.
class GuestTokenVerification {
  GuestTokenVerification({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static const _missesBeforeCooldown = 2;
  static const _cooldown = Duration(seconds: 60);

  final DateTime Function() _now;
  final _misses = <String, int>{};
  final _cooldowns = <String, DateTime>{};
  int _generation = 0;

  Future<dynamic> verify(
    String code,
    Future<dynamic> Function(String normalizedCode) request,
  ) async {
    final normalized = code.trim().toUpperCase();
    final now = _now();
    _cooldowns.removeWhere((_, expiry) => !now.isBefore(expiry));
    if (_cooldowns.containsKey(normalized)) {
      throw const VisitorApiError('Token not found');
    }

    final generation = _generation;
    try {
      final result = await request(normalized);
      if (generation == _generation) _misses.remove(normalized);
      return result;
    } on VisitorApiError catch (error) {
      if (generation == _generation && !_cooldowns.containsKey(normalized)) {
        if (error.isMissingGuestToken) {
          final count = (_misses[normalized] ?? 0) + 1;
          if (count == _missesBeforeCooldown) {
            _misses.remove(normalized);
            _cooldowns[normalized] = _now().add(_cooldown);
          } else {
            _misses[normalized] = count;
          }
        } else {
          _misses.remove(normalized);
        }
      }
      rethrow;
    }
  }

  void clear() {
    _generation++;
    _misses.clear();
    _cooldowns.clear();
  }
}
