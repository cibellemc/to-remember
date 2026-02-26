import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 60)),
          const SizedBox(height: 20),
          const Text(
            'Seu Nome',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Card(
            color: Colors.amber.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.brown),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Progresso salvo só neste celular.\nConecte a um familiar.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            onPressed: () {
              // Generate Code Logic
            },
            child: const Text(
              'Gerar Código de Conexão',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
