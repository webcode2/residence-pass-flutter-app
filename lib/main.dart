import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:estate/firebase_options.dart';
import 'package:estate/shared/notifications/fcm_service.dart';
import 'package:estate/shared/auth/auth_service.dart';
import 'package:estate/shared/sos/alarm_service.dart';
import 'package:estate/shared/sos/sos_alarm_screen.dart';
import 'package:estate/shared/models/user_model.dart';
import 'package:estate/resident/resident_app.dart';
import 'package:estate/resident/screens/chat_screen.dart';
import 'package:estate/gate/screens/gate_chat_thread_screen.dart';
import 'package:estate/gate/gate_app.dart';
import 'package:estate/shared/auth/screens/register_screen.dart';
import 'package:estate/shared/auth/screens/change_password_screen.dart';
import 'package:estate/shared/auth/screens/splash_screen.dart';
import 'package:estate/shared/ui/theme.dart';
import 'package:estate/shared/ui/widgets/biometric_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase asynchronously in the background so app launch never blocks or freezes
  AlarmService.initialize();
  _initServicesInBackground();

  await AuthService.instance.restoreSession();
  runApp(const SecurityTokenApp());
}

Future<void> _initServicesInBackground() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 2));

    await FCMService.instance.initialize().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Background service init notice (continuing safely): $e');
  }
}

class SecurityTokenApp extends StatefulWidget {
  const SecurityTokenApp({super.key});

  @override
  State<SecurityTokenApp> createState() => _SecurityTokenAppState();
}

class _SecurityTokenAppState extends State<SecurityTokenApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.currentUserNotifier
        .addListener(_onSettingsIdentityChanged);
    _onSettingsIdentityChanged();
    FCMService.instance.pendingChatThread.addListener(_openPendingChat);
    FCMService.instance.pendingSOS.addListener(_openSOS);
    FCMService.instance.pendingSOSReport.addListener(_showSOSReport);
    AuthService.instance.currentUserNotifier.addListener(_openPendingChat);
    AuthService.instance.currentUserNotifier.addListener(_openSOS);
  }

  String? _settingsSessionToken;
  void _onSettingsIdentityChanged() {
    final token = AuthService.instance.accessToken;
    if (_settingsSessionToken == token) return;
    _settingsSessionToken = token;
    _refreshEstateSettings();
  }

  void _refreshEstateSettings() {
    AuthService.instance.refreshEstateSettings(invalidate: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshEstateSettings();
  }

  void _openPendingChat() {
    if (_openingChat ||
        _showSplash ||
        !AuthService.instance.isAuthenticated ||
        AuthService.instance.currentUser?.mustChangePassword == true ||
        FCMService.instance.pendingChatThread.value == null) {
      return;
    }
    _openingChat = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openingChat = false;
      if (!mounted || !AuthService.instance.isAuthenticated) return;
      final id = FCMService.instance.pendingChatThread.value;
      final navigator = _navigatorKey.currentState;
      if (id == null || navigator == null) return;
      FCMService.instance.pendingChatThread.value = null;
      // Each module opens its own chat screen; the two never share UI or state.
      final inGate = AuthService.instance.activeViewModeNotifier.value ==
              AppViewMode.gatehouse &&
          AuthService.instance.currentUser!.isGuard;
      navigator.push(MaterialPageRoute<void>(
          builder: (_) => inGate
              ? GateChatThreadScreen(threadId: id, isGuard: true)
              : ChatScreen(threadId: id, isGuard: false)));
    });
  }

  void _showSOSReport() {
    final data = FCMService.instance.pendingSOSReport.value;
    if (data == null ||
        !AuthService.instance.isAuthenticated ||
        data['app_id'] != AuthService.instance.appId) {
      return;
    }
    FCMService.instance.pendingSOSReport.value = null;
    _messengerKey.currentState?.showSnackBar(SnackBar(
        duration: const Duration(seconds: 12),
        content: Text(
            '${data['sender_name'] ?? 'An estate member'} reported an SOS at ${data['house_location'] ?? 'their home'}.'),
        action: SnackBarAction(
            label: 'View',
            onPressed: () {
              FCMService.instance.pendingSOS.value = {
                ...data,
                'allow_alarm': false
              };
            })));
  }

  bool _showingSOS = false;
  void _openSOS() {
    if (_showingSOS ||
        _showSplash ||
        !AuthService.instance.isAuthenticated ||
        AuthService.instance.currentUser?.mustChangePassword == true) {
      return;
    }
    final data = FCMService.instance.pendingSOS.value;
    if (data == null ||
        data['app_id'] != AuthService.instance.appId ||
        data['sender_id'] == AuthService.instance.currentUser?.id) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _showingSOS) return;
      final nav = _navigatorKey.currentState;
      if (nav == null) return;
      _showingSOS = true;
      FCMService.instance.pendingSOS.value = null;
      await nav.push(MaterialPageRoute<void>(
          builder: (_) => SosAlarmScreen(
              alertId: data['alert_id'] as String,
              initialAlert: data,
              allowAlarm: data['allow_alarm'] == true)));
      _showingSOS = false;
      _openSOS();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService.instance.currentUserNotifier
        .removeListener(_onSettingsIdentityChanged);
    FCMService.instance.pendingChatThread.removeListener(_openPendingChat);
    FCMService.instance.pendingSOS.removeListener(_openSOS);
    FCMService.instance.pendingSOSReport.removeListener(_showSOSReport);
    AuthService.instance.currentUserNotifier.removeListener(_openPendingChat);
    AuthService.instance.currentUserNotifier.removeListener(_openSOS);
    super.dispose();
  }

  ThemeMode _themeMode = ThemeMode.light;
  bool _showSplash = true;

  void _toggleTheme() {
    if (!mounted) return;
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _hideSplash() {
    if (!mounted) return;
    setState(() {
      _showSplash = false;
    });
    _openPendingChat();
    _openSOS();
  }

  static const SystemUiOverlayStyle _lightOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: TokenTheme.lightPageBg,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle _darkOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: TokenTheme.darkPageBg,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    final overlay = _themeMode == ThemeMode.dark ? _darkOverlay : _lightOverlay;

    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      navigatorKey: _navigatorKey,
      title: 'Residence',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
                seedColor: TokenTheme.primaryMintDark,
                brightness: Brightness.light)
            .copyWith(
                primary: TokenTheme.primaryMintDark,
                onPrimary: Colors.white,
                surface: TokenTheme.lightPageBg),
        scaffoldBackgroundColor: TokenTheme.lightPageBg,
        fontFamily: 'Inter',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(systemOverlayStyle: _lightOverlay),
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (context) =>
              const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: TokenTheme.darkAccent,
          onPrimary: TokenTheme.darkBg,
          primaryContainer: TokenTheme.darkTint(),
          onPrimaryContainer: TokenTheme.darkAccent,
          primaryFixed: TokenTheme.darkAccent,
          primaryFixedDim: TokenTheme.darkAccent,
          onPrimaryFixed: TokenTheme.darkBg,
          onPrimaryFixedVariant: TokenTheme.darkAccent,
          secondary: TokenTheme.darkAccent,
          onSecondary: TokenTheme.darkBg,
          secondaryContainer: TokenTheme.darkTint(0.10),
          onSecondaryContainer: TokenTheme.darkAccent,
          tertiary: TokenTheme.darkAccent,
          onTertiary: TokenTheme.darkBg,
          tertiaryContainer: TokenTheme.darkTint(0.10),
          onTertiaryContainer: TokenTheme.darkAccent,
          error: TokenTheme.darkError,
          onError: TokenTheme.darkBg,
          errorContainer: TokenTheme.darkError.withValues(alpha: 0.14),
          onErrorContainer: TokenTheme.darkError,
          surface: TokenTheme.darkSurface,
          onSurface: TokenTheme.darkTextPrimary,
          surfaceContainerLowest: TokenTheme.darkBg,
          surfaceContainerLow: TokenTheme.darkSurface,
          surfaceContainer: TokenTheme.darkSurface,
          surfaceContainerHigh: TokenTheme.darkCard,
          surfaceContainerHighest: TokenTheme.darkCard,
          onSurfaceVariant: TokenTheme.darkTextSecondary,
          outline: TokenTheme.darkBorder,
          outlineVariant: TokenTheme.darkBorder,
          shadow: Colors.transparent,
          scrim: Colors.black,
          inverseSurface: TokenTheme.lightSurface,
          onInverseSurface: TokenTheme.lightTextPrimary,
          inversePrimary: TokenTheme.primaryMint,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBackgroundColor: TokenTheme.darkBg,
        canvasColor: TokenTheme.darkBg,
        fontFamily: 'Inter',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: _darkOverlay,
          backgroundColor: TokenTheme.darkSurface,
          foregroundColor: TokenTheme.darkTextPrimary,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: TokenTheme.darkCard,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: TokenTheme.darkCard,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: TokenTheme.darkSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: TokenTheme.darkAccent,
          foregroundColor: TokenTheme.darkBg,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          disabledElevation: 0,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: TokenTheme.darkCard,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(
          color: TokenTheme.darkBorder,
          thickness: 1,
          space: 1,
        ),
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (context) =>
              const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      // Screens without an AppBar (Home, Profile) otherwise keep whatever style the
      // last AppBar set, so apply the theme's style app-wide.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: _showSplash ? _lightOverlay : overlay,
        child: BiometricGate(child: child ?? const SizedBox.shrink()),
      ),
      home: _showSplash
          ? SplashScreen(
              onFinished: _hideSplash,
            )
          : ValueListenableBuilder<UserModel?>(
              valueListenable: AuthService.instance.currentUserNotifier,
              builder: (context, user, child) {
                if (user == null) {
                  return RegisterScreen(
                    onToggleTheme: _toggleTheme,
                    isDark: _themeMode == ThemeMode.dark,
                  );
                }
                if (user.mustChangePassword) {
                  return const ChangePasswordScreen();
                }
                return ValueListenableBuilder<AppViewMode>(
                  valueListenable: AuthService.instance.activeViewModeNotifier,
                  builder: (context, activeMode, _) {
                    if (activeMode == AppViewMode.gatehouse && user.isGuard) {
                      return GatehouseAppScaffold(
                        onToggleTheme: _toggleTheme,
                        isDark: _themeMode == ThemeMode.dark,
                      );
                    }
                    return AppScaffold(
                      onToggleTheme: _toggleTheme,
                      isDark: _themeMode == ThemeMode.dark,
                    );
                  },
                );
              },
            ),
    );
  }
}
