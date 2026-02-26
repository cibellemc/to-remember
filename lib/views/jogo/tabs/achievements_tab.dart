import 'package:flutter/material.dart';

class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.star, size: 100, color: Colors.blue), // Changed icon
          SizedBox(height: 20),
          Text(
            'Minhas Conquistas', // Changed text
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Visualize seus marcos aqui.', // Changed text
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
