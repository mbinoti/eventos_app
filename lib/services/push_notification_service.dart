import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:eventos_app/services/local_notification_service.dart';

class PushNotificationService {
  // 1. Adicionamos a GlobalKey para controlar a navegação
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Inicializa o Firebase Messaging e salva o token no Firestore
  static Future<void> initialize(BuildContext context) async {
    // Inicialize o serviço de notificações locais
    LocalNotificationService.initialize();

    final messaging = FirebaseMessaging.instance;

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

    final isSimulator = await _isEmulator();
    if (isSimulator) {
      print('🧪 Rodando em simulador – SnackBar será usado no lugar de push.');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('🔔 Notificação simulada (modo teste)')),
      // );
      return;
    }

    final token = await messaging.getToken();
    print('🔐 Token do dispositivo: $token');

    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    messaging.onTokenRefresh.listen((newToken) async {
      print('♻️ Token atualizado: $newToken');
      await _saveTokenToFirestore(newToken);
    });

    // 2. Handler para quando o app é aberto a partir do estado TERMINADO
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📱 App aberto do estado terminado pela notificação');
        _handleNotificationClick(message);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📲 Mensagem em primeiro plano: ${message.notification?.title}');

      // AQUI ESTÁ A MUDANÇA:
      // Em vez de apenas imprimir, agora exibimos uma notificação local.
      if (message.notification != null) {
        LocalNotificationService.display(message);
      }
    });

    // 3. Handler para quando o app é aberto a partir do estado de BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 App aberto do estado de background pela notificação');
      _handleNotificationClick(message);
    });
  }

  /// Verifica se está rodando em simulador/emulador
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

  /// Salva o token na coleção 'device_tokens'
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

  /// Handler de background: precisa ser registrado no main()
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('📩 [Background] Mensagem: ${message.messageId}');
  }

  /// 4. Método centralizado para lidar com a navegação ao clicar na notificação
  static void _handleNotificationClick(RemoteMessage message) {
    // Extrai a rota do campo 'data' da notificação.
    // Exemplo de payload que você enviaria:
    // {
    //   "notification": {"title": "...", "body": "..."},
    //   "data": { "route": "/detalhes_evento", "id": "123" }
    // }
    final String? route = message.data['route'];
    if (route != null) {
      // Usa a chave global para navegar para a rota especificada
      navigatorKey.currentState?.pushNamed(route, arguments: message.data);
    }
  }
}
