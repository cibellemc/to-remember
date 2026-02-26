import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pacientes Monitorados',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Maria Silva'),
            subtitle: const Text('Último acesso: Hoje, 14:30'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to Patient Details
            },
          ),
        ),
        // Add more patients here
      ],
    );
  }
}
