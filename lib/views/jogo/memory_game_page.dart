import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/fuzzy_difficulty_controller.dart';
import '../../data/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _primary     = Color(0xFF009688);
const _bg          = Color(0xFFF4F7F6);
const _surface     = Color(0xFFFFFFFF);
const _textMain    = Color(0xFF1A2E2C);
const _textSub     = Color(0xFF5A7571);

/// Number of PAIRS per level (index 0 = level 1)
const _pairCounts = [2, 3, 4, 6, 8];

// ─────────────────────────────────────────────────────────────────────────────
// CARD MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _Card {
  final String id;        // stimuli id as string (duplicate for pair)
  final String uniqueKey; // id + '_a' or '_b'
  final String imageUrl;
  final double selectionScore;

  bool faceUp  = false;
  bool matched = false;

  _Card({
    required this.id,
    required this.uniqueKey,
    required this.imageUrl,
    required this.selectionScore,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class MemoryGamePage extends StatefulWidget {
  const MemoryGamePage({super.key});

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage> {
  bool _loading = true;
  bool _canPop = false;

  late int _initialLevel;
  late int _currentLevel;
  Map<String, dynamic>? _progress;

  List<Map<String, dynamic>> _allStimuli = [];
  List<_Card> _cards = [];
  List<double> _responseTimes = [];

  /// IDs dos pares já usados nesta sessão (evita repetir os mesmos estímulos).
  final Set<dynamic> _usedPairIds = {};

  int? _firstIdx;
  int? _secondIdx;
  bool _isChecking = false;
  int _hits    = 0;
  int _mistakes = 0;
  int _pairsFound = 0;

  DateTime? _lastFlip;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _init() async {
    final repo = context.read<AuthRepository>();

    // Após hot restart o perfil pode ainda não estar na memória — busca do banco.
    String? patientId = repo.patientProfile?['id']?.toString();
    if (patientId == null) {
      await repo.getPatientProfile();
      patientId = repo.patientProfile?['id']?.toString();
    }
    if (patientId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _allStimuli = await repo.fetchStimuli();
    _progress   = await repo.getPatientGameProgress(patientId, 'memory');
    _initialLevel = _currentLevel = _progress?['current_level'] as int? ?? 1;

    _buildBoard();
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Saída'),
        content: const Text(
          'Deseja mesmo sair? O progresso desta partida não será salvo no histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleExit() async {
    final shouldExit = await _showExitConfirmationDialog(context);
    if (shouldExit && mounted) {
      setState(() => _canPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  void _buildBoard() {
    final pairCount = _pairCounts[(_currentLevel - 1).clamp(0, 4)];
    final pool = FuzzyDifficultyController.filterStimuliForLevel(
      _allStimuli, _currentLevel,
    );

    final rng = Random();

    // Filtra pares ainda não usados nesta sessão
    var available = pool.where((s) => !_usedPairIds.contains(s['id'])).toList();
    // Se restar menos itens que o necessário, reinicia o ciclo
    if (available.length < pairCount) {
      _usedPairIds.clear();
      available = List.from(pool);
    }

    available.shuffle(rng);
    final selected = available.take(pairCount).toList();

    // Registra os pares escolhidos como usados
    for (final s in selected) {
      _usedPairIds.add(s['id']);
    }

    _cards = selected.expand((s) {
      final id    = s['id'].toString();
      final url   = s['url_imagem'] as String;
      final score = (s['selection_score'] as num).toDouble();
      return [
        _Card(id: id, uniqueKey: '${id}_a', imageUrl: url, selectionScore: score),
        _Card(id: id, uniqueKey: '${id}_b', imageUrl: url, selectionScore: score),
      ];
    }).toList()..shuffle(rng);

    _firstIdx    = null;
    _secondIdx   = null;
    _isChecking  = false;
    _hits        = 0;
    _mistakes    = 0;
    _pairsFound  = 0;
    _responseTimes = [];
    _lastFlip    = DateTime.now();
  }

  // ── Card tap logic ────────────────────────────────────────────────────────

  Future<void> _onCardTap(int index) async {
    if (_isChecking) return;
    final card = _cards[index];
    if (card.faceUp || card.matched) return;

    // Record time between flips
    final now     = DateTime.now();
    final elapsed = now.difference(_lastFlip!).inMilliseconds;
    _lastFlip     = now;
    _responseTimes.add(elapsed.toDouble());

    setState(() => card.faceUp = true);

    if (_firstIdx == null) {
      _firstIdx = index;
      return;
    }

    _secondIdx  = index;
    _isChecking = true;

    if (_cards[_firstIdx!].id == _cards[_secondIdx!].id) {
      // Match!
      setState(() {
        _cards[_firstIdx!].matched = true;
        _cards[_secondIdx!].matched = true;
        _hits++;
        _pairsFound++;
        _firstIdx = null;
        _secondIdx = null;
        _isChecking = false;
      });
      if (_pairsFound >= _pairCounts[(_currentLevel - 1).clamp(0, 4)]) {
        await _finishGame();
      }
    } else {
      // No match
      _mistakes++;
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _cards[_firstIdx!].faceUp  = false;
        _cards[_secondIdx!].faceUp = false;
        _firstIdx  = null;
        _secondIdx = null;
        _isChecking = false;
      });
    }
  }

  // ── Finish & FIS ─────────────────────────────────────────────────────────

  Future<void> _finishGame() async {
    final repo      = context.read<AuthRepository>();
    final patientId = repo.patientProfile?['id']?.toString();
    if (patientId == null) return;

    final totalAttempts = _hits + _mistakes;
    final precision     = totalAttempts == 0 ? 1.0 : _hits / totalAttempts;
    final avgTimeMs     = _responseTimes.isEmpty
        ? 0.0
        : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;

    final baselineMs    = (_progress?['baseline_response_time'] as num?)?.toDouble();
    final rawHistory    = _progress?['precision_history'] as List? ?? [];
    final history       = rawHistory.map((v) => (v as num).toDouble()).toList();

    final usedStimuli = _cards.where((c) => c.matched).toList();
    final avgScore    = usedStimuli.isEmpty
        ? 0.72
        : usedStimuli
              .map((c) => c.selectionScore)
              .reduce((a, b) => a + b) /
          usedStimuli.length;

    final result = FuzzyDifficultyController.evaluate(
      precision: precision,
      baselineMs: baselineMs,
      avgResponseTimeMs: avgTimeMs,
      avgSelectionScore: avgScore,
      precisionHistory: history,
      currentLevel: _currentLevel,
      gameType: 'memory',
    );

        // Debug — aparece no console do VS Code / Android Studio
    print('''
    ─────────── FIS DEBUG ───────────
    Entradas:
      precisão:       ${(precision * 100).toStringAsFixed(1)}%
      latência norm:  ${baselineMs == null ? '1.0 (sem baseline)' : (avgTimeMs / baselineMs).toStringAsFixed(2)}
      carga BOSS:     ${FuzzyDifficultyController.computeBossLoad(avgScore).toStringAsFixed(2)}
      consistência:   ${FuzzyDifficultyController.computeConsistency(history).toStringAsFixed(3)}
      histórico:      $history

    Saída:
      score fuzzy:    ${result.score.toStringAsFixed(3)}
      decisão:        ${result.decision}
      nível anterior: $_currentLevel
      nível novo:     ${result.newLevel}
    ─────────────────────────────────
    ''');


    final updatedHistory = [...history, precision].reversed.take(5).toList().reversed.toList();
    final newBaseline    = FuzzyDifficultyController.updateBaseline(baselineMs, avgTimeMs, precision);

    setState(() {
      _currentLevel = result.newLevel;
    });

    await Future.wait([
      repo.upsertPatientGameProgress(
        patientId: patientId,
        gameType: 'memory',
        currentLevel: result.newLevel,
        baselineResponseTime: newBaseline,
        precisionHistory: updatedHistory,
      ),
      repo.saveGameSession(
        patientId: patientId,
        gameType: 'memory',
        initialLevel: _initialLevel,
        finalLevel: result.newLevel,
        hits: _hits,
        mistakes: _mistakes,
        avgResponseTimeMs: avgTimeMs.round(),
        fuzzyDecision: result.decision,
        performanceData: {
          'pairs_count': _pairCounts[(_currentLevel - 1).clamp(0, 4)],
        },
      ),
    ]);

    if (mounted) {
      setState(() {
        _initialLevel = _currentLevel;
        _buildBoard();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(child: _buildGame()),
      ),
    );
  }

  Widget _buildGame() {
    final pairCount  = _pairCounts[(_currentLevel - 1).clamp(0, 4)];
    final totalCards = pairCount * 2;
    // 2 colunas para níveis 1-3 (≤8 cartas), 4 colunas para níveis 4-5
    final cols = totalCards <= 8 ? 2 : 4;

    return Column(
      children: [
        _buildHeader(pairCount),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, i) {
                final card = _cards[i];
                return _FlipCard(
                  card: card,
                  isFaceUp: card.faceUp || card.matched,
                  onTap: () => _onCardTap(i),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader(int pairCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _textSub),
            onPressed: _handleExit,
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Jogo da Memória',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_pairsFound de $pairCount pares encontrados',
                  style: const TextStyle(fontSize: 13, color: _textSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }


}

// ─────────────────────────────────────────────────────────────────────────────
// FLIP CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _FlipCard extends StatefulWidget {
  final _Card card;
  final bool isFaceUp;
  final VoidCallback onTap;
  const _FlipCard({required this.card, required this.isFaceUp, required this.onTap});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isFaceUp) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.isFaceUp && !old.isFaceUp) _ctrl.forward();
    if (!widget.isFaceUp && old.isFaceUp) _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final angle  = _anim.value * pi;
          final isBack = angle < pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack ? _buildBack() : _buildFront(),
          );
        },
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.favorite_rounded, color: Colors.white54, size: 32),
      ),
    );
  }

  Widget _buildFront() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: widget.card.matched
              ? Border.all(color: _primary, width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            widget.card.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: _textSub),
            ),
          ),
        ),
      ),
    );
  }
}


