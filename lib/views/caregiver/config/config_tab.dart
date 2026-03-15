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
          onTap: () {},
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
                title: const Text('Sair?'),
                content: const Text('Deseja realmente sair da sua conta?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sair', style: TextStyle(color: Colors.red)),
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
