import 'package:flutter/material.dart';
import 'tabs/games_tab.dart';
import 'tabs/achievements_tab.dart';
import 'tabs/profile_tab.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  int _currentIndex = 0;
  int _lastIndex = 0;
  bool _isMovingForward = true;

  final List<Widget> _tabs = const [
    GamesTab(),
    AchievementsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentIndex != _lastIndex) {
      _isMovingForward = _currentIndex > _lastIndex;
      _lastIndex = _currentIndex;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final isIncoming =
                (child.key as ValueKey<int>).value == _currentIndex;

            Offset begin;
            if (_isMovingForward) {
              begin = isIncoming
                  ? const Offset(1.0, 0.0)
                  : const Offset(-1.0, 0.0);
            } else {
              begin = isIncoming
                  ? const Offset(-1.0, 0.0)
                  : const Offset(1.0, 0.0);
            }

            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            );
          },
          child: Container(
            key: ValueKey<int>(_currentIndex),
            child: _tabs[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.blueGrey.shade50)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          elevation: 0,
          backgroundColor: Colors.white,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.blueGrey.shade300,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.videogame_asset_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.videogame_asset),
              ),
              label: 'Jogos',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.emoji_events_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.emoji_events),
              ),
              label: 'Conquistas',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.account_circle_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.account_circle),
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
