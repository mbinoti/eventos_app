import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static const androidChannelId = 'eventos_app_channel';
  static const androidChannelName = 'Eventos App';
  static const androidChannelDescription =
      'Notificacoes sobre eventos e novidades do app.';

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    androidChannelId,
    androidChannelName,
    description: androidChannelDescription,
    importance: Importance.high,
  );

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize({
    void Function(Map<String, dynamic> data)? onNotificationTap,
  }) async {
    if (_initialized) {
      return;
    }

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _handlePayload(response.payload, onNotificationTap);
      },
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    final launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handlePayload(
        launchDetails?.notificationResponse?.payload,
        onNotificationTap,
      );
    }

    _initialized = true;
  }

  static Future<void> display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final title = _messageTitle(message);
      final body = _messageBody(message);

      if (title == null && body == null) {
        debugPrint('Notificacao local ignorada: sem titulo ou corpo.');
        return;
      }

      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (error) {
      debugPrint('Nao foi possivel exibir a notificacao local: $error');
    }
  }

  static String? _messageTitle(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title'] ??
        message.data['titulo'];
    return _nonEmptyString(title);
  }

  static String? _messageBody(RemoteMessage message) {
    final body = message.notification?.body ??
        message.data['body'] ??
        message.data['mensagem'];
    return _nonEmptyString(body);
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static void _handlePayload(
    String? payload,
    void Function(Map<String, dynamic> data)? onNotificationTap,
  ) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        onNotificationTap?.call(decoded);
        return;
      }
    } catch (_) {
      // Payloads from older notifications may be just the route string.
    }

    onNotificationTap?.call({'route': payload});
  }
}
