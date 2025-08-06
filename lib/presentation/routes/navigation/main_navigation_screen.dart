import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../pages/screens/event_feed_screen.dart';

/// Tela principal de navegação da aplicação.
///
/// Exibe as principais abas do app: feed de eventos, agenda e promoções.
/// Recebe [isAdmin] para definir permissões administrativas nas telas filhas.
class MainNavigationScreen extends StatelessWidget {
  /// Indica se o usuário é administrador.
  final bool isAdmin;

  /// Construtor do [MainNavigationScreen].
  const MainNavigationScreen({Key? key, required this.isAdmin})
      : super(key: key);

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
  const _MainNavigationScreen({Key? key, required this.isAdmin})
      : super(key: key);

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
    CalendarScreen(),
    PromotionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: 'Eventos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_month,
              color: Colors.white,
            ),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/megaphone.png',
              height: 24,
              width: 24,
              color: Colors.white,
            ),
            label: 'Eventos',
          ),
        ],
      ),
    );
  }
}

/// Tela da agenda de eventos.
///
/// Exibe o conteúdo relacionado à agenda.
class CalendarScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agenda')),
      body: Center(child: Text('Conteúdo da agenda aqui')),
    );
  }
}

/// Tela de promoções.
///
/// Exibe o conteúdo relacionado às promoções.
class PromotionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agenda')),
      body: Center(child: Text('Conteúdo de promocoes aqui')),
    );
  }
}
