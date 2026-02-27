import 'package:flutter/material.dart';

class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo & Title
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'To Remember',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conquistas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '2 de 5 desbloqueadas',
              style: TextStyle(fontSize: 18, color: Colors.blueGrey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.4,
              minHeight: 10,
              backgroundColor: Colors.blueGrey.shade50,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 32),

          // Achievements List
          _buildAchievementItem(
            context,
            title: 'Primeiro Jogo',
            description: 'Complete seu primeiro jogo.',
            icon: Icons.star_outline,
            isUnlocked: true,
          ),
          _buildAchievementItem(
            context,
            title: 'Boa Memoria',
            description: 'Complete o jogo da memoria 3 vezes.',
            icon: Icons.bolt,
            isUnlocked: true,
          ),
          _buildAchievementItem(
            context,
            title: 'Correspondencia Perfeita',
            description: 'Acerte todas as rodadas de correspondencia.',
            icon: Icons.lock_outline,
            isUnlocked: false,
          ),
          _buildAchievementItem(
            context,
            title: 'Sequencia de 5',
            description: 'Jogue 5 dias seguidos.',
            icon: Icons.lock_outline,
            isUnlocked: false,
          ),
          _buildAchievementItem(
            context,
            title: 'Mestre da Memoria',
            description: 'Complete a memoria em menos de 12 jogadas.',
            icon: Icons.lock_outline,
            isUnlocked: false,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isUnlocked,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? primaryColor.withOpacity(0.2)
              : Colors.blueGrey.shade50,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? primaryColor.withOpacity(0.15)
                  : Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isUnlocked ? primaryColor : Colors.blueGrey.shade300,
              size: 28,
            ),
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
                    color: isUnlocked
                        ? Colors.black87
                        : Colors.blueGrey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnlocked
                        ? Colors.blueGrey.shade600
                        : Colors.blueGrey.shade300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
