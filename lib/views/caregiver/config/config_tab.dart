import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../login/login_page.dart';

class ConfigTab extends StatelessWidget {
  const ConfigTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Configurações',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildConfigItem(
          icon: Icons.person_outline,
          title: 'Sua Conta',
          subtitle: 'Gerencie seus dados e perfil',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildConfigItem(
          icon: Icons.lock_outline,
          title: 'PIN de Segurança',
          subtitle: 'Proteja o acesso ao painel',
          onTap: () => _showSetPinDialog(context, authRepo),
        ),
        const SizedBox(height: 12),
        _buildConfigItem(
          icon: Icons.notifications_none_outlined,
          title: 'Notificações',
          subtitle: 'Configure alertas e avisos',
          onTap: () {},
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 12),
        _buildConfigItem(
          icon: Icons.logout,
          title: 'Sair da Conta',
          subtitle: 'Desconectar deste dispositivo',
          isDestructive: true,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text(
                  'Sair da Conta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                content: const Text('Deseja realmente sair da sua conta?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sair'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await authRepo.signOut();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            }
          },
        ),
      ],
    );
  }

  void _showSetPinDialog(BuildContext context, AuthRepository repo) {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    String? currentError;
    String? newError;
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Alterar PIN de Segurança',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Para sua segurança, informe o PIN atual e o novo PIN de 4 dígitos.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: currentPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                onChanged: (_) => setDialogState(() => currentError = null),
                decoration: InputDecoration(
                  labelText: 'PIN Atual',
                  counterText: '',
                  hintText: 'Digite o PIN atual',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, letterSpacing: 0),
                  errorText: currentError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_open_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                onChanged: (_) => setDialogState(() => newError = null),
                decoration: InputDecoration(
                  labelText: 'Novo PIN',
                  counterText: '',
                  hintText: 'Digite o novo PIN de 4 dígitos',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, letterSpacing: 0),
                  errorText: newError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      bool hasError = false;
                      if (currentPinController.text.length != 4) {
                        setDialogState(() => currentError = 'O PIN atual tem 4 dígitos');
                        hasError = true;
                      }
                      if (newPinController.text.length != 4) {
                        setDialogState(() => newError = 'O novo PIN deve ter 4 dígitos');
                        hasError = true;
                      }
                      if (hasError) return;

                      setDialogState(() => loading = true);
                      try {
                        // 1. Verify current PIN
                        final isCorrect = await repo.verifySecurityPin(currentPinController.text);
                        if (!isCorrect) {
                          setDialogState(() {
                            currentError = 'PIN atual incorreto';
                            loading = false;
                          });
                          return;
                        }

                        // 2. Update to new PIN
                        await repo.updateSecurityPin(newPinController.text);
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PIN de segurança atualizado com sucesso!'),
                              backgroundColor: Color(0xFF009688),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          newError = 'Erro ao atualizar PIN';
                          loading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.black87;
    final iconColor = isDestructive ? Colors.red.shade400 : const Color(0xFF009688);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.05)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
