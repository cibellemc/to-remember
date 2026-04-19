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
    final authRepo = context.watch<AuthRepository>();
    
    // Check for missing PIN and show mandatory dialog
    if (!authRepo.isPinSet && authRepo.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMandatoryPinDialog(context, authRepo);
      });
    }

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

  void _showMandatoryPinDialog(BuildContext context, AuthRepository repo) {
    final pinController = TextEditingController();
    String? error;
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Force user to set PIN
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Configurar PIN de Segurança'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Identificamos que sua conta ainda não possui um PIN de segurança. '
                'Ele é obrigatório para garantir a proteção dos dados ao alternar entre visões.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (pinController.text.length != 4) {
                        setDialogState(() => error = 'O PIN deve ter 4 dígitos');
                        return;
                      }

                      setDialogState(() => loading = true);
                      try {
                        await repo.updateSecurityPin(pinController.text);
                        await repo.checkSecurityPinSet();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() {
                          error = 'Erro ao salvar PIN';
                          loading = false;
                        });
                      }
                    },
              child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar PIN'),
            ),
          ],
        ),
      ),
    );
  }
}
