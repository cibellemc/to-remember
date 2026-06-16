import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/fuzzy_difficulty_controller.dart';
import '../../data/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _primary  = Color(0xFF009688);
const _bg       = Color(0xFFF4F7F6);
const _surface  = Color(0xFFFFFFFF);
const _textMain = Color(0xFF1A2E2C);
const _textSub  = Color(0xFF5A7571);

const _totalRounds = 5;

/// Number of PAIRS per level (index 0 = level 1)
const _pairCounts = [2, 3, 4, 6, 8];

// ─────────────────────────────────────────────────────────────────────────────
// CARD MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _Card {
  final String id;
  final String uniqueKey;
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
  bool _isInitialLoading = true;
  bool _isTransitioning = false;
  bool _isNextRoundReady = false;
  String _transitionTitle = 'Mandou bem!';
  String _transitionButtonText = 'Próxima Etapa';
  bool _canPop  = false;

  bool _previewPhase = true;

  late int _initialLevel;
  late int _currentLevel;
  Map<String, dynamic>? _progress;

  List<Map<String, dynamic>> _allStimuli = [];
  List<_Card> _cards = [];

  final Set<dynamic> _usedPairIds = {};

  // ── Session-level (5 rounds) ──────────────────────────────────────────────
  int _currentRound  = 0;
  int _totalHits     = 0;
  int _totalMistakes = 0;
  final List<double> _responseTimes  = [];
  final List<double> _sessionScores  = [];
  final List<Map<String, dynamic>> _roundDetails = [];

  // ── Round-level ───────────────────────────────────────────────────────────
  int?      _firstIdx;
  int?      _secondIdx;
  bool      _isChecking   = false;
  int       _pairsFound   = 0;
  int       _roundHits    = 0;
  int       _roundMistakes = 0;
  DateTime? _roundStartTime;

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

    String? patientId = repo.patientProfile?['id']?.toString();
    if (patientId == null) {
      await repo.getPatientProfile();
      patientId = repo.patientProfile?['id']?.toString();
    }
    if (patientId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _allStimuli   = await repo.fetchStimuli();
    _progress     = await repo.getPatientGameProgress(patientId, 'memory');
    _initialLevel = _currentLevel = _progress?['current_level'] as int? ?? 1;

    final cpRound = _progress?['checkpoint_round'] as int?;
    if (cpRound != null && cpRound > 0) {
      _currentRound = cpRound;
      _totalHits = _progress?['checkpoint_hits'] as int? ?? 0;
      _totalMistakes = _progress?['checkpoint_mistakes'] as int? ?? 0;

      final usedIds = _progress?['checkpoint_used_ids'] as List? ?? [];
      _usedPairIds.addAll(usedIds);

      final cpTimes = _progress?['checkpoint_times'];
      if (cpTimes is Map) {
        final rawTimes = cpTimes['response_times'] as List? ?? [];
        _responseTimes.addAll(rawTimes.map((t) => (t as num).toDouble()));
        final rawScores = cpTimes['session_scores'] as List? ?? [];
        _sessionScores.addAll(rawScores.map((s) => (s as num).toDouble()));
      }
    }

    final newCards = _generateBoard();
    await _precacheCards(newCards);
    if (!mounted) return;

    setState(() {
      _cards = newCards;
      _previewPhase = true;
      _firstIdx = null;
      _secondIdx = null;
      _isChecking = false;
      _pairsFound = 0;
      _isInitialLoading = false;
    });
  }

  Future<void> _handleExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Saída'),
        content: const Text(
          'Deseja mesmo sair? O progresso desta partida não será salvo no histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if ((ok ?? false) && mounted) {
      final repo = context.read<AuthRepository>();
      final patientId = repo.patientProfile?['id']?.toString();
      if (patientId != null) {
        await repo.clearGameCheckpoint(patientId: patientId, gameType: 'memory');
      }
      setState(() => _canPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _handleExitFromTransition() async {
    // Se o nível foi concluído, os dados já foram salvos. Podemos sair sem aviso.
    if (_transitionTitle == 'Nível Concluído!') {
      setState(() => _canPop = true);
      Navigator.of(context).pop();
      return;
    }
    // Caso contrário, salva o checkpoint parcial no banco e sai.
    final repo      = context.read<AuthRepository>();
    final patientId = repo.patientProfile?['id']?.toString();
    if (patientId != null && (_totalHits > 0 || _totalMistakes > 0)) {
      await repo.saveGameCheckpoint(
        patientId: patientId,
        gameType: 'memory',
        round: _currentRound,
        hits: _totalHits,
        mistakes: _totalMistakes,
        targets: 0,
        usedIds: _usedPairIds.toList(),
        times: {
          'response_times': _responseTimes,
          'session_scores': _sessionScores,
        },
      );
    }
    
    if (mounted) {
      setState(() => _canPop = true);
      Navigator.of(context).pop();
    }
  }

  // ── Board builder ─────────────────────────────────────────────────────────

  List<_Card> _generateBoard() {
    final pairCount = _pairCounts[(_currentLevel - 1).clamp(0, 4)];
    final pool = FuzzyDifficultyController.filterStimuliForLevel(
      _allStimuli,
      _currentLevel,
    );

    final rng = Random();

    var available = pool.where((s) => !_usedPairIds.contains(s['id'])).toList();
    if (available.length < pairCount) {
      _usedPairIds.clear();
      available = List.from(pool);
    }

    available.shuffle(rng);
    final selected = available.take(pairCount).toList();

    for (final s in selected) {
      _usedPairIds.add(s['id']);
    }

    final cards = selected.expand((s) {
      final id    = s['id'].toString();
      final url   = s['url_imagem'] as String;
      final score = (s['selection_score'] as num).toDouble();
      return [
        _Card(id: id, uniqueKey: '${id}_a', imageUrl: url, selectionScore: score),
        _Card(id: id, uniqueKey: '${id}_b', imageUrl: url, selectionScore: score),
      ];
    }).toList()
      ..shuffle(rng);

    for (final c in cards) {
      c.faceUp = true;
    }
    return cards;
  }

  Future<void> _precacheCards(List<_Card> cards) async {
    if (!mounted) return;
    final urls = cards.map((c) => c.imageUrl).toSet();
    await Future.wait(
      urls.map((url) => precacheImage(NetworkImage(url), context)),
    );
  }

  // ── Game flow ─────────────────────────────────────────────────────────────

  void _startGame() {
    setState(() {
      for (final c in _cards) {
        c.faceUp = false;
      }
      _previewPhase    = false;
      _roundStartTime  = DateTime.now();
      _roundHits       = 0;
      _roundMistakes   = 0;
    });
  }

  Future<void> _nextRound() async {
    if (!mounted) return;
    if (_currentRound + 1 >= _totalRounds) {
      _finishGame();
    } else {
      setState(() {
        _isTransitioning = true;
        _isNextRoundReady = false;
        _transitionTitle = 'Mandou bem!';
        _transitionButtonText = 'Próxima Rodada';
      });
      
      final nextCards = _generateBoard();
      await _precacheCards(nextCards);
      
      if (mounted) {
        setState(() {
          _currentRound++;
          _cards = nextCards;
          _previewPhase = true;
          _firstIdx = null;
          _secondIdx = null;
          _isChecking = false;
          _pairsFound = 0;
          _roundHits = 0;
          _roundMistakes = 0;
          _isNextRoundReady = true;
        });
      }
    }
  }

  // ── Card tap logic ────────────────────────────────────────────────────────

  Future<void> _onCardTap(int index) async {
    if (_previewPhase || _isChecking) return;
    final card = _cards[index];
    if (card.faceUp || card.matched) return;

    setState(() => card.faceUp = true);

    if (_firstIdx == null) {
      _firstIdx = index;
      return;
    }

    _secondIdx  = index;
    _isChecking = true;

    if (_cards[_firstIdx!].id == _cards[_secondIdx!].id) {
      setState(() {
        _cards[_firstIdx!].matched = true;
        _cards[_secondIdx!].matched = true;
        _totalHits++;
        _roundHits++;
        _pairsFound++;
        _firstIdx   = null;
        _secondIdx  = null;
        _isChecking = false;
      });

      if (_pairsFound >= _pairCounts[(_currentLevel - 1).clamp(0, 4)]) {
        final durationMs = DateTime.now().difference(_roundStartTime!).inMilliseconds.toDouble();
        final pairsCount = _pairCounts[(_currentLevel - 1).clamp(0, 4)];
        _responseTimes.add(durationMs / pairsCount);
        for (final c in _cards) {
          if (c.matched) _sessionScores.add(c.selectionScore);
        }
        _roundDetails.add({
          'round': _currentRound + 1,
          'hits': _roundHits,
          'mistakes': _roundMistakes,
          'time_ms': durationMs.round(),
        });
        await Future.delayed(const Duration(milliseconds: 600));
        _nextRound();
      }
    } else {
      _totalMistakes++;
      _roundMistakes++;
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _cards[_firstIdx!].faceUp  = false;
        _cards[_secondIdx!].faceUp = false;
        _firstIdx   = null;
        _secondIdx  = null;
        _isChecking = false;
      });
    }
  }

  // ── Finish & FIS ─────────────────────────────────────────────────────────

  Future<void> _finishGame() async {
    final repo      = context.read<AuthRepository>();
    final patientId = repo.patientProfile?['id']?.toString();
    if (patientId == null) return;

    final totalAttempts = _totalHits + _totalMistakes;
    final precision     = totalAttempts == 0 ? 1.0 : _totalHits / totalAttempts;
    final avgTimeMs     = _responseTimes.isEmpty
        ? 0.0
        : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;

    final rawBaseline = _progress?['baseline_response_time'] as num?;
    double? baselineMs = rawBaseline?.toDouble();
    if (baselineMs != null && baselineMs > 3500.0) {
      baselineMs = null;
    }
    final rawHistory = _progress?['precision_history'] as List? ?? [];
    final history    = rawHistory.map((v) => (v as num).toDouble()).toList();

    final avgScore = _sessionScores.isEmpty
        ? 0.72
        : _sessionScores.reduce((a, b) => a + b) / _sessionScores.length;

    final result = FuzzyDifficultyController.evaluate(
      precision: precision,
      baselineMs: baselineMs,
      avgResponseTimeMs: avgTimeMs,
      avgSelectionScore: avgScore,
      precisionHistory: history,
      currentLevel: _currentLevel,
      gameType: 'memory',
    );

    // ignore: avoid_print
    print('''
    ─────────── FIS DEBUG (memória) ───────────
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
    ───────────────────────────────────────────
    ''');

    final updatedHistory =
        [...history, precision].reversed.take(5).toList().reversed.toList();
    final newBaseline =
        FuzzyDifficultyController.updateBaseline(baselineMs, avgTimeMs, precision);

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
        hits: _totalHits,
        mistakes: _totalMistakes,
        avgResponseTimeMs: avgTimeMs.round(),
        fuzzyDecision: result.decision,
        performanceData: {
          'pairs_count': _pairCounts[(_currentLevel - 1).clamp(0, 4)],
          'rounds': _totalRounds,
          'round_details': List<Map<String, dynamic>>.from(_roundDetails),
        },
      ),
      repo.clearGameCheckpoint(
        patientId: patientId,
        gameType: 'memory',
      ),
    ]);

    _progress = {
      ...(_progress ?? {}),
      'current_level': result.newLevel,
      'baseline_response_time': newBaseline,
      'precision_history': updatedHistory,
      'checkpoint_round': null,
      'checkpoint_hits': null,
      'checkpoint_mistakes': null,
      'checkpoint_targets': null,
      'checkpoint_used_ids': null,
      'checkpoint_times': null,
    };

    if (mounted) {
      setState(() {
        _isTransitioning = true;
        _isNextRoundReady = false;
        _transitionTitle = 'Nível Concluído!';
        _transitionButtonText = 'Próximo Nível';
      });
      
      _currentLevel  = result.newLevel;
      _initialLevel  = result.newLevel;
      _usedPairIds.clear();
      
      final nextCards = _generateBoard();
      await _precacheCards(nextCards);

      if (mounted) {
        setState(() {
          _currentRound  = 0;
          _totalHits     = 0;
          _totalMistakes = 0;
          _responseTimes.clear();
          _sessionScores.clear();
          _roundDetails.clear();
          _roundHits     = 0;
          _roundMistakes = 0;
          _cards = nextCards;
          _previewPhase = true;
          _firstIdx = null;
          _secondIdx = null;
          _isChecking = false;
          _pairsFound = 0;
          _isNextRoundReady = true;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Stack(
            children: [
              _buildContent(),
              if (_isTransitioning)
                Positioned.fill(
                  child: Container(
                    color: _bg,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 80),
                          const SizedBox(height: 24),
                          Text(
                            _transitionTitle,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _textMain,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          if (!_isNextRoundReady)
                            const CircularProgressIndicator(color: _primary)
                          else
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 240,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() => _isTransitioning = false);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      _transitionButtonText,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _handleExitFromTransition,
                                  child: const Text(
                                    'Sair do Jogo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _textSub,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final pairCount  = _pairCounts[(_currentLevel - 1).clamp(0, 4)];
    final totalCards = pairCount * 2;
    final cols       = totalCards <= 8 ? 2 : (totalCards == 12 ? 3 : 4);
    final rows       = totalCards ~/ cols;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final W = constraints.maxWidth;
              final H = constraints.maxHeight;

              const padding    = 20.0;
              const gap        = 12.0;
              const btnH       = 54.0;
              const btnPadding = 24.0; // top(8) + bottom(16)

              final availH = _previewPhase ? H - btnH - btnPadding : H - gap;
              final gridW  = W - 2 * padding;
              final gridH  = availH - gap;

              final cellW = (gridW - (cols - 1) * gap) / cols;
              final cellH = (gridH - (rows - 1) * gap) / rows;
              final cell  = max(1.0, min(cellW, cellH));

              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width:  cell * cols + gap * (cols - 1),
                        height: cell * rows + gap * (rows - 1),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: gap,
                            crossAxisSpacing: gap,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _cards.length,
                          itemBuilder: (_, i) {
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
                  ),
                  if (_previewPhase)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: SizedBox(
                        width:  double.infinity,
                        height: btnH,
                        child: ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Pronto!',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textMain,
                  ),
                ),
                const SizedBox(height: 6),
                if (_previewPhase)
                  const Text(
                    'Memorize as cartas!',
                    style: TextStyle(fontSize: 13, color: _textSub),
                  )
                else
                  _RoundProgress(current: _currentRound, total: _totalRounds),
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
// ROUND PROGRESS
// ─────────────────────────────────────────────────────────────────────────────

class _RoundProgress extends StatelessWidget {
  final int current, total;
  const _RoundProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final done   = i < current;
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width:  active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: done || active
                ? _primary
                : _primary.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLIP CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _FlipCard extends StatefulWidget {
  final _Card        card;
  final bool         isFaceUp;
  final VoidCallback onTap;
  const _FlipCard({required this.card, required this.isFaceUp, required this.onTap});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
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
