import 'package:eventos_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:eventos_app/presentation/routes/navigation/main_navigation_screen.dart';
import 'package:eventos_app/services/push_notification_service.dart'; // 1. Importar o serviço
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_theme.dart';

// 2. Delegar o handler de background para o serviço
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.backgroundHandler(message);
}

void main(List<String> args) async {
  final isAdmin = args.contains('admin');

  // Inicializar o Firebase
  // Isso é necessário para usar o Firebase Messaging e outros serviços do Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inicializar o serviço de notificações push
  // Configurar o Firebase Messaging para receber notificações
  // Define como as notificações devem se apresentar quando o app está em primeiro plano.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // Exibir um alerta (banner)
    badge: true, // Atualizar o número no ícone do app
    sound: true, // Tocar um som
  );

  // Registrar o handler de background
  // Isso permite que o app receba notificações mesmo quando está em segundo plano ou fechado
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    BlocProvider(
      create: (_) => ThemeCubit(),
      child: MainApp(isAdmin: isAdmin),
    ),
  );
}

class MainApp extends StatefulWidget {
  final bool isAdmin;
  const MainApp({super.key, required this.isAdmin});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // 3. Limpar o initState e chamar o serviço
    // Usamos addPostFrameCallback para garantir que o context está pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return ScaffoldMessenger(
          child: MaterialApp(
            navigatorKey: PushNotificationService.navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: MainNavigationScreen(),
          ),
        );
      },
    );
  }
}
