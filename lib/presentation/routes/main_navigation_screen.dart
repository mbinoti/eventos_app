import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../pages/event_feed_screen.dart';
import '../../services/platform_info.dart';

/// Tela principal de navegação da aplicação.
///
/// Exibe as principais abas do app: agenda e guia local.
/// Recebe [isAdmin] para definir permissões administrativas nas telas filhas.
class MainNavigationScreen extends StatelessWidget {
  /// Indica se o usuário é administrador.
  final bool isAdmin;

  /// Construtor do [MainNavigationScreen].
  const MainNavigationScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return _MainNavigationScreen(isAdmin: isAdmin);
  }
}

/// Widget de estado para a navegação principal.
///
/// Responsável por controlar a navegação entre as abas e manter o estado selecionado.
/// Recebe [isAdmin] para repassar às telas filhas.
class _MainNavigationScreen extends StatefulWidget {
  /// Indica se o usuário é administrador.
  final bool isAdmin;

  /// Construtor do [_MainNavigationScreen].
  const _MainNavigationScreen({required this.isAdmin});

  @override
  __MainNavigationScreenState createState() => __MainNavigationScreenState();
}

/// Estado do widget [_MainNavigationScreen].
///
/// Gerencia o índice da aba selecionada e exibe o conteúdo correspondente.
class __MainNavigationScreenState extends State<_MainNavigationScreen> {
  /// Índice da aba atualmente selecionada.
  int _selectedIndex = 0;

  /// Lista de telas exibidas nas abas.
  late final List<Widget> _screens = [
    EventFeedScreen(isAdmin: widget.isAdmin),
    LocalGuideScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isIOS = isCupertinoPlatform;

    if (isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.location_solid),
              label: 'Guia Local',
            ),
          ],
        ),
        tabBuilder: (context, index) => _screens[index],
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(
              Icons.calendar_month,
            ),
            label: 'Agenda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Guia local',
          ),
        ],
      ),
    );
  }
}

/// Tela de guia local.
///
/// Exibe o conteúdo relacionado a empresas e serviços locais.
class LocalGuideScreen extends StatelessWidget {
  const LocalGuideScreen({super.key});

  static const TextStyle _bodyStyle = TextStyle(
    inherit: false,
    color: Color(0xFFE0E0E0),
    fontSize: 18,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
    decorationColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    final isIOS = isCupertinoPlatform;
    if (isIOS) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Guia Local'),
        ),
        child: SafeArea(
          child: Center(
            child: Text('Conteudo do guia local aqui', style: _bodyStyle),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Guia Local')),
      body: const Center(
        child: Text('Conteúdo do guia local aqui', style: _bodyStyle),
      ),
    );
  }
}
