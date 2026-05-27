import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'presentation/routes/main_navigation_screen.dart';
import 'presentation/viewmodels/event_feed_view_model.dart';
import 'presentation/viewmodels/theme_view_model.dart';
import 'repositories/event_repository.dart';
import 'repositories/storage_repository.dart';
import 'services/env.dart';
import 'services/push_notification_service.dart';

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
/// O ícone/admin aparece somente quando ADMIN_MODE for exatamente 'admin'.
void main() async {
  final isAdmin = Env.adminMode.toLowerCase() == 'admin';

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Configura apresentação de notificações em foreground.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Define o handler para mensagens em background.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  _disableDebugPaintOverlays();

  // Inicializa o app com MultiProvider para gerenciar estados globais.
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => EventRepository()),
        Provider(create: (_) => StorageRepository()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(
          create: (context) => EventFeedViewModel(
            context.read<EventRepository>(),
          ),
        ),
      ],
      child: MainApp(isAdmin: isAdmin),
    ),
  );
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
      _disableDebugPaintOverlays();
      WidgetsBinding.instance.scheduleFrame();
      PushNotificationService.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeViewModel>().themeMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Passa a flag isAdmin para a tela principal de navegação.
      home: MainNavigationScreen(
        isAdmin: widget.isAdmin,
      ),
    );
  }
}
