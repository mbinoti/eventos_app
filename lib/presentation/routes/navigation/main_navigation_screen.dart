import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../pages/screens/event_feed_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    EventFeedScreen(isAdmin: true), // ajuste se precisar passar parâmetro
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

class CalendarScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agenda')),
      body: Center(child: Text('Conteúdo da agenda aqui')),
    );
  }
}

class PromotionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agenda')),
      body: Center(child: Text('Conteúdo de promocoes aqui')),
    );
  }
}
