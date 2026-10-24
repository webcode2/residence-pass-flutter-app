import 'dart:convert';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';
import 'api_config.dart';
import 'alarm_service.dart';
import 'auth_service.dart';
import 'sos_delivery.dart';
import 'notification_inbox.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data['type'] == 'sos_live') {
    await SosDelivery.acknowledge(message.data, background: true);
  }
  developer.log('FCM Background message received: ${message.messageId}',
      name: 'FCMService');
}

class FCMService with WidgetsBindingObserver {
  static final FCMService instance = FCMService._internal();
  factory FCMService() => instance;
  FCMService._internal();

  // Resolved lazily: FirebaseMessaging.instance throws if Firebase isn't initialized yet.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final _accessEvents = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get accessEvents => _accessEvents.stream;
  final _chatEvents = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatEvents => _chatEvents.stream;
  final pendingChatThread = ValueNotifier<String?>(null);
  bool _initialized = false;
  bool _listenersReady = false;
  bool _observingLifecycle = false;
  String? _appId;
  final pendingSOS = ValueNotifier<Map<String, dynamic>?>(null);
  final pendingSOSReport = ValueNotifier<Map<String, dynamic>?>(null);
  final Set<String> _seenSOS = {};

  void handleChatMessage(Map<String, dynamic> data, {bool opened = false}) {
    if (AuthService.instance.isAuthenticated &&
        data['app_id'] == AuthService.instance.appId &&
        data['type'] != 'estate_settings_changed') {
      if (opened) {
        NotificationInbox.instance.markEventRead(data);
      } else {
        NotificationInbox.instance.refresh();
      }
    }
    if (data['type'] == 'estate_settings_changed') {
      if (data['app_id'] == AuthService.instance.appId &&
          AuthService.instance.isAuthenticated) {
        AuthService.instance.refreshEstateSettings(invalidate: true);
      }
      return;
    }
    if (['sos_alert', 'sos_live', 'sos_missed'].contains(data['type'])) {
      if (data['sender_id'] == AuthService.instance.currentUser?.id ||
          data['alert_id'] is! String ||
          (_userAuthToken != null && data['app_id'] != _appId)) {
        return;
      }
      final id = data['alert_id'] as String;
      if (opened) {
        pendingSOS.value = {...data, 'allow_alarm': false};
        return;
      }
      if (!_seenSOS.add('${data['type']}.$id')) return;
      final live = SosDelivery.canRing(data);
      if (live) {
        SosDelivery.acknowledge(data, deviceToken: _cachedFcmToken);
        pendingSOS.value = {...data, 'allow_alarm': true};
      } else {
        pendingSOSReport.value = {...data, 'allow_alarm': false};
      }
      return;
    }
    if (data['type'] == 'visitor_access') {
      _accessEvents.add(Map<String, dynamic>.from(data));
    }
    if (data['type'] != 'chat_message' || data['thread_id'] is! String) return;
    _chatEvents.add(Map<String, dynamic>.from(data));
    if (opened) pendingChatThread.value = data['thread_id'] as String;
  }

  String? _cachedFcmToken;
  String? _userAuthToken;
  String _backendBaseUrl = ApiConfig.baseUrl;

  String? get currentFcmToken => _cachedFcmToken;

  /// Set the backend base URL (e.g. https://api.yourdomain.com)
  void setBackendUrl(String url) {
    _backendBaseUrl =
        url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Set the user's active JWT authentication token and immediately sync device FCM token
  Future<void> setUserAuthToken(String? token, {String? appId}) async {
    if (token == null) {
      final oldToken = _userAuthToken;
      final oldAppId = _appId;
      NotificationInbox.instance.clear();
      _userAuthToken = null;
      _appId = null;
      pendingSOS.value = null;
      pendingSOSReport.value = null;
      _seenSOS.clear();
      if (oldToken == null || oldAppId == null || _cachedFcmToken == null) {
        return;
      }
      try {
        await http
            .delete(Uri.parse('$_backendBaseUrl/api/v1/users/me/fcm-token'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $oldToken',
                  'X-App-Id': oldAppId
                },
                body: jsonEncode({'fcm_token': _cachedFcmToken}))
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
      return;
    }
    _userAuthToken = token;
    NotificationInbox.instance.refresh();
    _appId = appId ?? _appId;
    if (!token.startsWith('demo_') && !_initialized) await initialize();
    if (_userAuthToken != null && _cachedFcmToken != null) {
      await syncTokenWithBackend(_cachedFcmToken!);
    }
  }

  /// Initialize Firebase Messaging, request permissions, get initial token, and listen to token rotation
  Future<void> initialize({String? initialAuthToken}) async {
    _userAuthToken = initialAuthToken ?? _userAuthToken;
    if (Firebase.apps.isEmpty || _initialized) return;
    _initialized = true;
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }

    try {
      await AlarmService.initialize();
      await _messaging.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);
      if (!_listenersReady) {
        _listenersReady = true;
        FirebaseMessaging.onMessage
            .listen((message) => handleChatMessage(message.data));
        FirebaseMessaging.onMessageOpenedApp
            .listen((message) => handleChatMessage(message.data, opened: true));
      }
      // 1. Request notification permissions
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log('FCM Authorization status: ${settings.authorizationStatus}',
          name: 'FCMService');

      // 2. Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Retrieve initial device token
      final String? token = await _messaging.getToken();
      if (token != null) {
        _cachedFcmToken = token;

        await syncTokenWithBackend(token);
      }

      // 4. ALWAYS listen to token changes and update backend automatically
      _messaging.onTokenRefresh.listen((String newToken) async {
        _cachedFcmToken = newToken;
        await syncTokenWithBackend(newToken);
      });

      final initial = await _messaging.getInitialMessage();
      if (initial != null) handleChatMessage(initial.data, opened: true);
    } catch (e, stack) {
      _initialized = false;
      developer.log('Error initializing FCM service: $e',
          error: e, stackTrace: stack, name: 'FCMService');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _userAuthToken != null) {
      _refreshDeviceRegistration();
      NotificationInbox.instance.refresh();
    }
  }

  Future<void> _refreshDeviceRegistration() async {
    if (!_initialized) {
      await initialize();
      return;
    }
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _cachedFcmToken = token;
        await syncTokenWithBackend(token);
      }
    } catch (_) {
      // Retry on the next foreground event, without polling the server.
    }
  }

  /// Push updated device FCM token to the backend for the current user
  Future<bool> syncTokenWithBackend(String fcmToken) async {
    if (_userAuthToken == null ||
        _appId == null ||
        _userAuthToken!.startsWith('demo_')) {
      developer.log(
          'User auth token not set yet. FCM token cached for next login sync.',
          name: 'FCMService');
      return false;
    }

    try {
      final url = Uri.parse('$_backendBaseUrl/api/v1/users/me/fcm-token');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_userAuthToken',
              'X-App-Id': _appId ?? '',
            },
            body: jsonEncode({
              'fcm_token': fcmToken,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        developer.log('Successfully synced FCM token to backend for user',
            name: 'FCMService');
        return true;
      } else {
        developer.log(
            'Failed to sync FCM token. Server responded with: ${response.statusCode} - ${response.body}',
            name: 'FCMService');
        return false;
      }
    } catch (e) {
      developer.log('Network error while syncing FCM token to backend: $e',
          error: e, name: 'FCMService');
      return false;
    }
  }
}
