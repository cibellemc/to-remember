import 'package:flutter/material.dart';
import '../memory_game_page.dart';
import '../matching_game_page.dart';
import '../occurrences_game_page.dart';

class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header Logo & Title
          Center(
            child: Column(
              children: [
                Text(
                  'Escolha um jogo para exercitar a mente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Text(
          //   'Jogos disponiveis',
          //   style: TextStyle(
          //     fontSize: 20,
          //     fontWeight: FontWeight.bold,
          //     color: Colors.blueGrey.shade900,
          //   ),
          // ),
          // const SizedBox(height: 16),

          // Game Cards
          _buildGameCard(
            context,
            title: 'Jogo da Memória',
            description:
                'Encontre os pares de cartas iguais e treine sua memória.',
            icon: Icons.style_rounded,
            cardColor: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemoryGamePage()),
              );
            },
          ),
          // const SizedBox(height: 24),
          // _buildGameCard(
          //   context,
          //   title: 'Correspondência',
          //   description: 'Veja uma imagem e encontre a mesma entre as opções.',
          //   icon: Icons.find_in_page_rounded,
          //   cardColor: Colors.indigo,
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const MatchingGamePage()),
          //     );
          //   },
          // ),
          const SizedBox(height: 24),
          _buildGameCard(
            context,
            title: 'Encontre as Ocorrências',
            description:
                'Memorize a imagem-alvo e encontre todas as suas ocorrências no tabuleiro.',
            icon: Icons.search_rounded,
            cardColor: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OccurrencesGamePage(),
                ),
              );
            },
          ),
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Icon Header
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardColor.withValues(alpha: 0.8), cardColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.blueGrey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Action Button (visual only, tap handled by parent)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
