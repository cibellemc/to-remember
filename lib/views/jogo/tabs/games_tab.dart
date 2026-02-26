import 'package:flutter/material.dart';

class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Jogos Liberados',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildGameButton(context, 'Memória', Icons.memory),
              _buildGameButton(context, 'Puzzle', Icons.extension),
              // Add more games here
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameButton(BuildContext context, String title, IconData icon) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(150, 150),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        // Navigate to game
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
