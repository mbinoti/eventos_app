import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app_theme.dart';
import 'presentation/cubits/event_feed/event_feed_cubit.dart';
import 'presentation/cubits/theme/theme_cubit.dart';
import 'presentation/routes/navigation/main_navigation_screen.dart';
import 'repositories/event_repository.dart';
import 'services/push_notification_service.dart';

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
/// [args] Lista de argumentos de inicialização. Se contiver 'admin', o app inicia em modo admin.
void main(List<String> args) async {
  final isAdmin = args.contains('admin');

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

  // Inicializa o app com MultiBlocProvider para gerenciar estados globais.
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => EventFeedCubit(EventRepository())),
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
      PushNotificationService.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Utiliza BlocBuilder para alternar o tema do app dinamicamente.
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          // Passa a flag isAdmin para a tela principal de navegação.
          home: MainNavigationScreen(
            isAdmin: widget.isAdmin,
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
///
/// # Como o gerenciamento de estado é utilizado neste projeto
///
/// Este projeto utiliza o padrão Cubit do pacote [flutter_bloc] para gerenciar o estado da aplicação.
/// Abaixo estão os principais pontos sobre o uso do gerenciamento de estado:
///
/// - **EventFeedCubit**: Gerencia o estado do feed de eventos, controlando o carregamento, sucesso, erro e lista vazia.
///   Os widgets escutam as mudanças de estado usando `BlocBuilder<EventFeedCubit, EventFeedState>`.
///
/// - **CadastroEventoCubit**: Gerencia o estado do cadastro de novos eventos, controlando o progresso, sucesso e erro do cadastro.
///   Utilizado nas telas de cadastro para mostrar carregamento, sucesso ou erro conforme o estado.
///
/// - **ThemeCubit**: Gerencia o tema do app (claro/escuro). O widget principal (`MainApp`) utiliza `BlocBuilder<ThemeCubit, ThemeMode>`
///   para alternar dinamicamente o tema da aplicação.
///
/// ## Funcionamento
/// - Os Cubits são criados no início do app usando `MultiBlocProvider`.
/// - Os widgets escutam as mudanças de estado usando `BlocBuilder` ou `BlocListener`.
/// - Quando uma ação ocorre (ex: carregar eventos, cadastrar evento), um método do Cubit é chamado e um novo estado é emitido.
/// - A interface é reconstruída automaticamente de acordo com o novo estado.
///
/// ## Vantagens
/// - Organização: Lógica de negócio separada da interface.
/// - Reatividade: UI sempre sincronizada com o estado.
/// - Testabilidade: Fácil de testar a lógica dos Cubits separadamente.
///
/// Para mais detalhes, consulte a documentação dos próprios Cubits e States no
