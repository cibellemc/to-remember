import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'tabs/games_tab.dart';
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

  void _showSwitchBackDialog(BuildContext context, AuthRepository repo) {
    final controller = TextEditingController();
    String? errorMessage;
    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'Confirmar PIN',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 22),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Digite seu PIN para voltar para a visão do gestor.',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('input_pin'),
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (errorMessage != null) {
                      setState(() => errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 12),
                    errorText: errorMessage,
                    errorStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryColor, width: 3),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 3),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.length < 4) return;
                  
                  final ok = await repo.verifySecurityPin(controller.text);
                  if (ok) {
                    repo.setRoleOverride(null);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    setState(() {
                      errorMessage = 'PIN incorreto!';
                      controller.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AuthRepository>();
    final isProfessional = repo.realRole == 'professional';
    final isOverride = repo.roleOverride != null;

    final List<Widget> activeTabs = [
      const GamesTab(),
      if (!isProfessional) const ProfileTab(),
    ];

    if (_currentIndex >= activeTabs.length) {
      _currentIndex = 0;
    }

    if (_currentIndex != _lastIndex) {
      _isMovingForward = _currentIndex > _lastIndex;
      _lastIndex = _currentIndex;
    }

    PreferredSizeWidget? appBar;
    if (isOverride) {
      appBar = AppBar(
        backgroundColor: const Color(0xFF1E293B), // Fundo escuro (alto contraste)
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          tooltip: 'Sair da Visão do Paciente',
          onPressed: () => _showSwitchBackDialog(context, repo),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility, color: Colors.white, size: 26),
            SizedBox(width: 10),
            Text(
              'VISÃO DO PACIENTE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
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
            child: activeTabs[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: activeTabs.length > 1
          ? Container(
              decoration: BoxDecoration(
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))
                ],
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
                unselectedItemColor: const Color(0xFF64748B),
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                selectedFontSize: 14,
                unselectedFontSize: 14,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
                iconSize: 28,
                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Icon(Icons.videogame_asset_outlined),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Icon(Icons.videogame_asset),
                    ),
                    label: 'JOGOS',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Icon(Icons.account_circle_outlined),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Icon(Icons.account_circle),
                    ),
                    label: 'PERFIL',
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: kBottomNavigationBarHeight + 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videogame_asset, color: Theme.of(context).primaryColor, size: 32),
                          const SizedBox(height: 4),
                          Text(
                            'JOGOS',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
