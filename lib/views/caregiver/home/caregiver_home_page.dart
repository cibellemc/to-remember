import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../view_models/caregiver_viewmodel.dart';
import '../dashboard/dashboard_tab.dart';
import '../config/config_tab.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({super.key});

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [DashboardTab(), ConfigTab()];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CaregiverViewModel(context.read<AuthRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel do Gestor'),
          automaticallyImplyLeading: false,
        ),
        body: _tabs[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Config',
            ),
          ],
        ),
      ),
    );
  }
}
