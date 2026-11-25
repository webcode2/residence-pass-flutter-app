import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:estate/shared/models/user_model.dart';
import 'package:estate/shared/notifications/fcm_service.dart';
import 'package:estate/shared/config/api_config.dart';
import 'package:estate/shared/auth/session_store.dart';

enum AppViewMode {
  resident,
  gatehouse,
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal()
      : _sessionStore = SessionStore(),
        _settingsClient = null;
  AuthService.isolated(
      {required SessionStore store, http.Client? settingsClient})
      : _sessionStore = store,
        _settingsClient = settingsClient;
  final SessionStore _sessionStore;
  final http.Client? _settingsClient;

  Future<void> restoreSession() async {
    try {
      final session = await _sessionStore.read(_baseUrl);
      if (session == null) return;
      final user =
          UserModel.fromJson(Map<String, dynamic>.from(session['user']));
      _appId = session['app_id'] as String;
      _accessToken = session['token'] as String;
      _setTokenCodeLength((session['code_length'] as int?) ?? 6);
      activeViewModeNotifier.value =
          session['view_mode'] == 'gatehouse' && user.isGuard
              ? AppViewMode.gatehouse
              : AppViewMode.resident;
      _armExpiry();
      currentUserNotifier.value = user;
      if (!user.mustChangePassword) _syncFcmAuth(_accessToken);
    } catch (_) {
      developer.log('Secure session restoration unavailable',
          name: 'AuthService');
    }
  }

  Future<void> _persistSession(UserModel user) => _sessionStore.save({
        'backend': _baseUrl,
        'token': _accessToken,
        'app_id': _appId,
        'user': user.toJson(),
        'code_length': tokenCodeLength,
        'view_mode': activeViewMode.name,
      });

  final ValueNotifier<UserModel?> currentUserNotifier =
      ValueNotifier<UserModel?>(null);
  final ValueNotifier<AppViewMode> activeViewModeNotifier =
      ValueNotifier<AppViewMode>(AppViewMode.resident);

  Timer? _expiryTimer;
  void _armExpiry() {
    _expiryTimer?.cancel();
    if (_accessToken == null) return;
    final claims = jsonDecode(utf8.decode(
            base64Url.decode(base64Url.normalize(_accessToken!.split('.')[1]))))
        as Map<String, dynamic>;
    final expiry = DateTime.fromMillisecondsSinceEpoch(
        (claims['exp'] as num).toInt() * 1000,
        isUtc: true);
    final remaining = expiry.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      logout();
      return;
    }
    _expiryTimer = Timer(remaining, logout);
  }

  String? _accessToken;
  String _appId = '';
  String _baseUrl = ApiConfig.baseUrl;

  UserModel? get currentUser => currentUserNotifier.value;
  bool get isAuthenticated => currentUserNotifier.value != null;
  AppViewMode get activeViewMode => activeViewModeNotifier.value;
  String? get accessToken => _accessToken;
  String get baseUrl => _baseUrl;
  String get appId => _appId;

  /// Length of visitor access tokens for this estate (4–6 chars, admin-controlled)
  final tokenCodeLengthNotifier = ValueNotifier<int>(6);
  int get tokenCodeLength => tokenCodeLengthNotifier.value;
  void _setTokenCodeLength(int length) {
    tokenCodeLengthNotifier.value = length;
  }

  Future<void>? _settingsRefresh;
  bool _settingsRefreshAgain = false;
  Future<void> refreshEstateSettings({bool invalidate = false}) {
    if (_settingsRefresh != null) {
      if (invalidate) _settingsRefreshAgain = true;
      return _settingsRefresh!;
    }
    return _settingsRefresh = _fetchEstateSettings().whenComplete(() {
      _settingsRefresh = null;
      if (_settingsRefreshAgain) {
        _settingsRefreshAgain = false;
        refreshEstateSettings();
      }
    });
  }

  Future<void> _fetchEstateSettings() async {
    final token = _accessToken;
    final estate = _appId;
    if (token == null || currentUser?.mustChangePassword == true) return;
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/estates/mobile-settings');
      final headers = {'Authorization': 'Bearer $token', 'X-App-Id': estate};
      final response = await (_settingsClient?.get(uri, headers: headers) ??
              http.get(uri, headers: headers))
          .timeout(const Duration(seconds: 10));
      if (token != _accessToken ||
          estate != _appId ||
          response.statusCode != 200) {
        return;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final length = data['token_code_length'];
      if (data['app_id'] != estate ||
          length is! int ||
          ![4, 5, 6, 8].contains(length)) {
        return;
      }
      _setTokenCodeLength(length);
      if (currentUser != null) await _persistSession(currentUser!);
    } catch (_) {
      /* Retain the last saved settings offline; retry on the next event/resume. */
    }
  }

  void switchActiveViewMode(AppViewMode mode) {
    activeViewModeNotifier.value = mode;
    if (currentUser != null) {
      _persistSession(currentUser!).catchError((Object _) {});
    }
  }

  void toggleActiveViewMode() {
    activeViewModeNotifier.value =
        activeViewModeNotifier.value == AppViewMode.gatehouse
            ? AppViewMode.resident
            : AppViewMode.gatehouse;
  }

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    FCMService.instance.setBackendUrl(_baseUrl);
  }

  void setAppId(String id) {
    _appId = id;
  }

  /// Register a new resident using an invite/registration code from a Landlord/Caretaker
  Future<Map<String, dynamic>> registerWithInviteCode({
    required String email,
    required String password,
    required String fullName,
    required String inviteCode,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();

    try {
      final url = Uri.parse('$_baseUrl/api/v1/users/register')
          .replace(queryParameters: {'registration_code': cleanCode});
      final body = jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'full_name': fullName.trim(),
        'roles': ['resident'],
      });

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final registered = jsonDecode(response.body) as Map<String, dynamic>;
        final tenantId = registered['app_id'] as String?;
        if (tenantId == null || tenantId.isEmpty) {
          throw StateError('Registration did not return an estate identity.');
        }
        // Auto login using only the estate resolved from the landlord invitation.
        return await login(email: email, password: password, appId: tenantId);
      } else {
        final errorData = _parseError(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ??
              errorData['message'] ??
              'Registration failed. Please check your invite code.',
        };
      }
    } catch (e) {
      developer.log('Backend request failed or offline: $e',
          name: 'AuthService');

      return {
        'success': false,
        'message':
            'Cannot reach the estate server. Check your connection and try again.'
      };
    }
  }

  /// Log in with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? appId,
  }) async {
    final tenantId = (appId ?? _appId).trim().toUpperCase();

    try {
      final url = Uri.parse('$_baseUrl/api/v1/auth/login');
      final body = jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      });

      developer.log('Logging in user: $email at $url', name: 'AuthService');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-App-Id': tenantId,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenObj = data['token'];
        _accessToken = tokenObj?['access_token'];
        _setTokenCodeLength((data['token_code_length'] as int?) ?? 6);

        final userObj = data['user'];
        if (_accessToken == null) {
          throw StateError('Server did not return an access token.');
        }
        _appId = tenantId;
        final user = UserModel.fromJson(userObj);
        if (user.isGuard && !user.isResident) {
          activeViewModeNotifier.value = AppViewMode.gatehouse;
        } else {
          activeViewModeNotifier.value = AppViewMode.resident;
        }

        await _persistSession(user);
        _armExpiry();
        currentUserNotifier.value = user;

        if (_accessToken != null && !user.mustChangePassword) {
          _syncFcmAuth(_accessToken);
        }

        return {
          'success': true,
          'user': user,
          'token': _accessToken,
        };
      } else {
        final errorData = _parseError(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ??
              errorData['message'] ??
              'Incorrect email or password.',
        };
      }
    } catch (e) {
      developer.log('Login backend request failed or offline: $e',
          name: 'AuthService');

      return {
        'success': false,
        'message':
            'Cannot reach the estate server. Check your connection and try again.'
      };
    }
  }

  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/api/v1/auth/change-password'),
              headers: {
                'Content-Type': 'application/json',
                'X-App-Id': _appId,
                'Authorization': 'Bearer $_accessToken'
              },
              body: jsonEncode({
                'current_password': currentPassword,
                'new_password': newPassword
              }))
          .timeout(const Duration(seconds: 15));
      final data = _parseError(response.body);
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': data['detail'] is String
              ? data['detail']
              : 'Check your password and try again.'
        };
      }
      _accessToken = data['token']['access_token'] as String;
      _setTokenCodeLength(
          (data['token_code_length'] as int?) ?? tokenCodeLength);
      final updatedUser =
          UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _persistSession(updatedUser);
      _armExpiry();
      currentUserNotifier.value = updatedUser;
      _syncFcmAuth(_accessToken);
      return {'success': true};
    } catch (_) {
      return {
        'success': false,
        'message':
            'Unable to change your password. Check your connection and retry.'
      };
    }
  }

  int _sessionRevision = 0;
  bool _updatingProfile = false;

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> details) async {
    if (_accessToken == null) {
      return {'success': false, 'message': 'Sign in to edit your profile.'};
    }
    final revision = _sessionRevision;
    if (_updatingProfile) {
      return {
        'success': false,
        'message': 'Please wait for your changes to save.'
      };
    }
    _updatingProfile = true;
    try {
      final response = await http
          .patch(Uri.parse('$_baseUrl/api/v1/users/me/profile'),
              headers: {
                'Authorization': 'Bearer $_accessToken',
                'X-App-Id': _appId,
                'Content-Type': 'application/json'
              },
              body: jsonEncode(details))
          .timeout(const Duration(seconds: 15));
      if (revision != _sessionRevision) {
        return {
          'success': false,
          'message': 'Your session has ended. Sign in again.'
        };
      }
      if (response.statusCode != 200) {
        final detail = _parseError(response.body)['detail'];
        return {
          'success': false,
          'message': detail is String ? detail : 'Check your details and retry.'
        };
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = UserModel.fromJson(Map<String, dynamic>.from(data['user']));
      _accessToken = data['token']['access_token'] as String;
      _setTokenCodeLength(
          (data['token_code_length'] as int?) ?? tokenCodeLength);
      await _persistSession(user);
      if (revision != _sessionRevision) {
        return {
          'success': false,
          'message': 'Your session has ended. Sign in again.'
        };
      }
      _armExpiry();
      currentUserNotifier.value = user;
      _syncFcmAuth(_accessToken);
      return {'success': true};
    } catch (_) {
      return {
        'success': false,
        'message':
            'Unable to save your profile. Check your connection and retry.'
      };
    } finally {
      _updatingProfile = false;
    }
  }

  Future<void> refreshProfile() async {
    if (_updatingProfile ||
        _accessToken == null ||
        currentUser?.mustChangePassword == true) {
      return;
    }
    final token = _accessToken;
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/v1/users/me/profile'), headers: {
        'Authorization': 'Bearer $token',
        'X-App-Id': _appId
      }).timeout(const Duration(seconds: 10));
      if (_updatingProfile || token != _accessToken) return;
      if (response.statusCode == 401) {
        logout();
        return;
      }
      if (response.statusCode != 200) return;
      final user = UserModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)));
      await _persistSession(user);
      if (token == _accessToken) currentUserNotifier.value = user;
    } catch (_) {/* Offline sessions retain the last securely saved profile. */}
  }

  /// Log out user
  void logout() {
    _sessionRevision++;
    _expiryTimer?.cancel();
    final oldToken = _accessToken;
    final oldAppId = _appId;
    _sessionStore.clear().catchError((Object _) {});
    _endServerSession(oldToken, oldAppId);
    _accessToken = null;
    FCMService.instance.pendingChatThread.value = null;
    currentUserNotifier.value = null;
    _setTokenCodeLength(6);
  }

  Future<void> _endServerSession(String? token, String appId) async {
    // Unregister this device while its token still authorizes the delete request.
    // Local logout and secure-storage deletion never wait for the network.
    try {
      await FCMService.instance.setUserAuthToken(null, appId: appId);
      if (token != null) {
        await http.post(Uri.parse('$_baseUrl/api/v1/auth/logout'), headers: {
          'Authorization': 'Bearer $token',
          'X-App-Id': appId,
        }).timeout(const Duration(seconds: 5));
      }
    } catch (_) {}
  }

  /// Push notification sync must never block or break sign-in.
  void _syncFcmAuth(String? token) {
    try {
      FCMService.instance
          .setUserAuthToken(token, appId: _appId)
          .catchError((Object e) {
        developer.log('FCM auth sync skipped: $e', name: 'AuthService');
      });
    } catch (e) {
      developer.log('FCM auth sync skipped: $e', name: 'AuthService');
    }
  }

  Map<String, dynamic> _parseError(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'detail': body};
    }
  }
}
