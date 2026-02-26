import 'package:flutter/material.dart';

class ConfigTab extends StatelessWidget {
  const ConfigTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Sua Conta'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('PIN de Segurança'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notificações'),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Sair', style: TextStyle(color: Colors.red)),
          onTap: () {},
        ),
      ],
    );
  }
}
