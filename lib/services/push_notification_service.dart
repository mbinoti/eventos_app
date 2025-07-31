import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
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
  /// Chave global para navegação via notificações.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Inicializa o serviço de notificações push e registra todos os listeners necessários.
  ///
  /// - Solicita permissão no iOS.
  /// - Salva o token do dispositivo no Firestore.
  /// - Registra listeners para atualização de token, recebimento de notificações em foreground/background,
  ///   e navegação ao clicar em notificações.
  /// - Emuladores não recebem push, apenas exibem mensagem de teste.
  static Future<void> initialize(BuildContext context) async {
    // Inicializa o serviço de notificações locais (exibe notificações no foreground)
    LocalNotificationService.initialize();

    final messaging = FirebaseMessaging.instance;

    // Solicita permissão para notificações no iOS
    if (Platform.isIOS) {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('❌ Permissão negada no iOS');
        return;
      }
      print('✅ Permissão concedida no iOS');
    } else {
      print('✅ Permissão automática no Android');
    }

    // Detecta se está rodando em emulador/simulador
    final isSimulator = await _isEmulator();
    if (isSimulator) {
      print('🧪 Rodando em simulador – SnackBar será usado no lugar de push.');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('🔔 Notificação simulada (modo teste)')),
      // );
      return;
    }

    // Obtém e salva o token do dispositivo
    final token = await messaging.getToken();
    print('🔐 Token do dispositivo: $token');
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Atualiza o token no Firestore quando ele muda
    messaging.onTokenRefresh.listen((newToken) async {
      print('♻️ Token atualizado: $newToken');
      await _saveTokenToFirestore(newToken);
    });

    // Handler para quando o app é aberto a partir do estado TERMINADO por uma notificação
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📱 App aberto do estado terminado pela notificação');
        _handleNotificationClick(message);
      }
    });

    // Handler para notificações recebidas em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📲 Mensagem em primeiro plano: ${message.notification?.title}');
      // Só exibe notificação local se não houver campo 'notification' (evita duplicidade)
      if (message.notification == null) {
        LocalNotificationService.display(message);
      }
    });

    // Handler para quando o app é aberto a partir do estado de BACKGROUND por uma notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 App aberto do estado de background pela notificação');
      _handleNotificationClick(message);
    });
  }

  /// Verifica se está rodando em simulador/emulador.
  /// Retorna true se não for dispositivo físico.
  static Future<bool> _isEmulator() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return !androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    }
    return false;
  }

  /// Salva o token do dispositivo na coleção 'device_tokens' do Firestore.
  ///
  /// Permite identificar e enviar notificações para dispositivos específicos.
  static Future<void> _saveTokenToFirestore(String token) async {
    final tokensCollection =
        FirebaseFirestore.instance.collection('device_tokens');
    await tokensCollection.doc(token).set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
    });
    print('✅ Token salvo no Firestore');
  }

  /// Handler de background para notificações push.
  ///
  /// Deve ser registrado no main() para garantir que notificações sejam processadas quando o app está fechado.
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('📩 [Background] Mensagem: ${message.messageId}');
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
    final String? route = message.data['route'];
    if (route != null) {
      navigatorKey.currentState?.pushNamed(route, arguments: message.data);
    }
  }
}
