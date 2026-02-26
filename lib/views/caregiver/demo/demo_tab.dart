import 'package:flutter/material.dart';

class DemoTab extends StatelessWidget {
  const DemoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_fill, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Modo Demo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Testar como o idoso (Sem salvar dados)',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Start Demo logic
            },
            child: const Text('Iniciar Demo'),
          ),
        ],
      ),
    );
  }
}
