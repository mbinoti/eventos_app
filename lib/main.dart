import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'core/errors/error_logger.dart';
import 'firebase_options.dart';
import 'presentation/routes/main_navigation_screen.dart';
import 'presentation/viewmodels/event_feed_view_model.dart';
import 'presentation/viewmodels/theme_view_model.dart';
import 'repositories/event_repository.dart';
import 'repositories/storage_repository.dart';
import 'services/env.dart';
import 'services/push_notification_service.dart';
import 'services/platform_info.dart';

AppErrorLogger _appErrorLogger = const NoopErrorLogger();

const _appLocale = Locale('pt', 'BR');
const _supportedLocales = [
  _appLocale,
  Locale('pt'),
];
const _localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

void _reportGlobalError(Object error, StackTrace stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'global_error_handler',
      context: ErrorDescription('Erro global nao tratado'),
    ),
  );
}

void _logFlutterError(FlutterErrorDetails details) {
  unawaited(
    _appErrorLogger.log(
      details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      feature: 'flutter_framework',
      operation: details.context?.toDescription() ?? 'framework_error',
      fatal: true,
    ),
  );
}

void _configureGlobalErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    _reportGlobalError(error, stackTrace);
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ocorreu um erro inesperado na interface.\nTente reiniciar o aplicativo.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  };
}

void _disableDebugPaintOverlays() {
  assert(() {
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintPointersEnabled = false;
    debugPaintLayerBordersEnabled = false;
    debugRepaintRainbowEnabled = false;
    debugRepaintTextRainbowEnabled = false;
    return true;
  }());
}

/// Handler para mensagens recebidas em background pelo Firebase Messaging.
///
/// Este método é chamado quando uma notificação push é recebida enquanto o app
/// está em segundo plano ou fechado.
///
/// [message] Mensagem recebida do Firebase.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.backgroundHandler(message);
}

/// Função principal da aplicação.
///
/// Inicializa o Firebase, configura as opções de notificação e executa o app.
///
/// ADMIN_MODE=admin libera o acesso administrativo sem exigir login.
void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _configureGlobalErrorHandling();

      final isAdmin = Env.adminMode.toLowerCase() == 'admin';

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _appErrorLogger = FirestoreErrorLogger();

        // Define o handler para mensagens em background.
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        _disableDebugPaintOverlays();

        // Inicializa o app com MultiProvider para gerenciar estados globais.
        runApp(
          MultiProvider(
            providers: [
              Provider<AppErrorLogger>.value(value: _appErrorLogger),
              Provider(
                create: (_) => EventRepository(
                  errorLogger: _appErrorLogger,
                ),
              ),
              Provider(create: (_) => StorageRepository()),
              ChangeNotifierProvider(create: (_) => ThemeViewModel()),
              ChangeNotifierProvider(
                create: (context) => EventFeedViewModel(
                  context.read<EventRepository>(),
                  errorLogger: context.read<AppErrorLogger>(),
                ),
              ),
            ],
            child: MainApp(isAdmin: isAdmin),
          ),
        );
      } catch (error, stackTrace) {
        _reportGlobalError(error, stackTrace);
        runApp(const _BootstrapErrorApp());
      }
    },
    _reportGlobalError,
  );
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _appLocale,
      supportedLocales: _supportedLocales,
      localizationsDelegates: _localizationsDelegates,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nao foi possivel inicializar o aplicativo.\nConfira a conexao com internet e servicos do Firebase.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget principal da aplicação.
///
/// Recebe um parâmetro [isAdmin] para definir permissões de administrador.
class MainApp extends StatefulWidget {
  /// Indica se o usuário é administrador.
  final bool isAdmin;

  /// Construtor do MainApp.
  const MainApp({super.key, required this.isAdmin});

  @override
  State<MainApp> createState() => _MainAppState();
}

/// Estado do widget [MainApp].
///
/// Responsável por inicializar serviços e construir a árvore de widgets principal.
class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Inicializa o serviço de notificações push após o primeiro frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _disableDebugPaintOverlays();
      WidgetsBinding.instance.scheduleFrame();
      unawaited(
        PushNotificationService.initialize(
          errorLogger: context.read<AppErrorLogger>(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeViewModel>().themeMode;

    if (isCupertinoPlatform) {
      return CupertinoApp(
        navigatorKey: PushNotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        locale: _appLocale,
        supportedLocales: _supportedLocales,
        localizationsDelegates: _localizationsDelegates,
        theme: CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemBlue,
          barBackgroundColor: Color(0xFF121212),
          scaffoldBackgroundColor: Colors.black,
        ),
        home: MainNavigationScreen(
          isAdmin: widget.isAdmin,
        ),
      );
    }

    return MaterialApp(
      navigatorKey: PushNotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: _appLocale,
      supportedLocales: _supportedLocales,
      localizationsDelegates: _localizationsDelegates,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: MainNavigationScreen(
        isAdmin: widget.isAdmin,
      ),
    );
  }
}
