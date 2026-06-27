import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:eventos_app/core/errors/error_logger.dart';
import 'package:eventos_app/firebase_options.dart';
import 'package:eventos_app/services/device_identity_service.dart';
import 'package:eventos_app/services/local_notification_service.dart';

/// Serviço centralizado para gerenciamento de notificações push (Firebase Messaging) e navegação por notificações.
///
/// Responsabilidades:
/// - Inicializar o Firebase Messaging e solicitar permissões.
/// - Salvar e atualizar o token do dispositivo no Firestore.
/// - Registrar handlers para notificações em foreground, background e quando o app é aberto por uma notificação.
/// - Exibir notificações locais quando necessário.
/// - Navegar para rotas específicas ao clicar em notificações.
class PushNotificationService {
  static const _eventsTopic = 'eventos';

  /// Chave global para navegação via notificações.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static AppErrorLogger _errorLogger = const NoopErrorLogger();
  static DeviceIdentityService _deviceIdentityService = DeviceIdentityService();
  static Future<void>? _initialization;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _onMessageSubscription;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  /// Inicializa o serviço de notificações push e registra todos os listeners necessários.
  ///
  /// - Solicita permissão no iOS e Android 13+.
  /// - Salva o token do dispositivo no Firestore.
  /// - Registra listeners para atualização de token, recebimento de notificações em foreground/background,
  ///   e navegação ao clicar em notificações.
  /// - Simuladores iOS nao registram push remoto.
  static Future<void> initialize({
    AppErrorLogger? errorLogger,
    DeviceIdentityService? deviceIdentityService,
  }) {
    if (errorLogger != null) {
      _errorLogger = errorLogger;
    }
    if (deviceIdentityService != null) {
      _deviceIdentityService = deviceIdentityService;
    }

    return _initialization ??= _initializeSafely();
  }

  static Future<void> _initializeSafely() async {
    try {
      await _initialize();
    } catch (error, stackTrace) {
      _initialization = null;
      debugPrint('Nao foi possivel inicializar notificacoes push: $error');
      await _logError(
        error,
        stackTrace,
        operation: 'initialize_push_notifications',
      );
    }
  }

  static Future<void> _initialize() async {
    // Inicializa o serviço de notificações locais (exibe notificações no foreground)
    await LocalNotificationService.initialize(
      onNotificationTap: _handleNotificationData,
    );

    final messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _registerMessageHandlers(messaging);

    // Solicita permissão para notificações no iOS e Android 13+.
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final hasPermission =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!hasPermission) {
      debugPrint('Permissao de notificacao negada.');
      return;
    }

    // Detecta se está rodando em emulador/simulador
    final isSimulator = await _isEmulator();
    if (Platform.isIOS && isSimulator) {
      debugPrint('Rodando em simulador iOS; push remoto nao sera registrado.');
      return;
    }

    // Obtém e salva o token do dispositivo
    await _registerCurrentToken(messaging);

    // Atualiza o token no Firestore quando ele muda
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription =
        messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('Token do dispositivo atualizado.');
      await _saveTokenToFirestore(newToken);
      await _subscribeToEventsTopic(messaging);
    });
  }

  static void _registerMessageHandlers(FirebaseMessaging messaging) {
    // Handler para quando o app é aberto a partir do estado TERMINADO por uma notificação
    messaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('App aberto por notificacao em estado terminado.');
        _handleNotificationClick(message);
      }
    });

    // Handler para notificações recebidas em primeiro plano
    _onMessageSubscription?.cancel();
    _onMessageSubscription =
        FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('Mensagem push recebida em primeiro plano.');

      if (Platform.isAndroid || message.notification == null) {
        await LocalNotificationService.display(message);
      }
    });

    // Handler para quando o app é aberto a partir do estado de BACKGROUND por uma notificação
    _onMessageOpenedAppSubscription?.cancel();
    _onMessageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('App aberto por notificacao em background.');
      _handleNotificationClick(message);
    });
  }

  /// Verifica se está rodando em simulador/emulador.
  /// Retorna true se não for dispositivo físico.
  static Future<bool> _isEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return !androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      }
    } catch (error, stackTrace) {
      debugPrint('Nao foi possivel detectar emulador: $error');
      await _logError(
        error,
        stackTrace,
        operation: 'detect_device_kind',
      );
    }
    return false;
  }

  static Future<void> _registerCurrentToken(FirebaseMessaging messaging) async {
    try {
      final token = await messaging.getToken();
      if (token == null) {
        debugPrint('FCM nao retornou token para este dispositivo.');
        return;
      }

      debugPrint('Token do dispositivo obtido.');
      await _saveTokenToFirestore(token);
      await _subscribeToEventsTopic(messaging);
    } catch (error, stackTrace) {
      debugPrint('Nao foi possivel registrar token FCM: $error');
      await _logError(
        error,
        stackTrace,
        operation: 'register_fcm_token',
      );
    }
  }

  static Future<void> _subscribeToEventsTopic(
    FirebaseMessaging messaging,
  ) async {
    try {
      await messaging.subscribeToTopic(_eventsTopic);
      debugPrint('Dispositivo inscrito no topico $_eventsTopic.');
    } catch (error, stackTrace) {
      debugPrint('Nao foi possivel inscrever no topico $_eventsTopic: $error');
      await _logError(
        error,
        stackTrace,
        operation: 'subscribe_to_events_topic',
      );
    }
  }

  /// Salva o token do dispositivo na coleção 'device_tokens' do Firestore.
  ///
  /// Permite identificar e enviar notificações para dispositivos específicos.
  static Future<void> _saveTokenToFirestore(String token) async {
    final deviceId = await _deviceIdentityService.getOrCreateDeviceId();
    final tokensCollection =
        FirebaseFirestore.instance.collection('device_tokens');

    await tokensCollection.doc(deviceId).set({
      'deviceId': deviceId,
      'fcmToken': token,
      'topic': _eventsTopic,
      'updatedAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
    }, SetOptions(merge: true));

    debugPrint('Token salvo no Firestore.');
  }

  /// Handler de background para notificações push.
  ///
  /// Deve ser registrado no main() para garantir que notificações sejam processadas quando o app está fechado.
  static Future<void> backgroundHandler(RemoteMessage message) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('Mensagem push recebida em background.');
  }

  /// Lida com a navegação ao clicar em uma notificação push.
  ///
  /// Extrai a rota do campo 'data' do payload da notificação e navega para ela usando a chave global.
  /// Exemplo de payload:
  /// {
  ///   "notification": {"title": "...", "body": "..."},
  ///   "data": { "route": "/detalhes_evento", "id": "123" }
  /// }
  static void _handleNotificationClick(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  static void _handleNotificationData(Map<String, dynamic> data) {
    final route = data['route'];
    if (route is! String || route.trim().isEmpty) {
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator indisponivel para abrir notificacao.');
      return;
    }

    if (route == '/' || route == '/agenda') {
      navigator.popUntil((currentRoute) => currentRoute.isFirst);
      return;
    }

    try {
      navigator.pushNamed(route, arguments: data);
    } catch (error) {
      debugPrint('Nao foi possivel abrir a rota da notificacao: $error');
    }
  }

  static Future<void> _logError(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) async {
    await _errorLogger.log(
      error,
      stackTrace: stackTrace,
      feature: 'push_notifications',
      operation: operation,
      context: {
        'topic': _eventsTopic,
        'platform': Platform.operatingSystem,
      },
    );
  }
}
