import 'package:flutter/material.dart';
import 'jogo_page.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Vamos aprender a jogar!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.psychology, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('Encontre os pares...', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Simulate tutorial completion and navigate to Home
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const PatientHomePage(),
                  ),
                );
              },
              child: const Text('Entendi! Começar Jogo'),
            ),
          ],
        ),
      ),
    );
  }
}
