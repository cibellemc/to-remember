import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/fuzzy_difficulty_controller.dart';
import '../../data/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _primary     = Color(0xFF009688);
const _primaryDark = Color(0xFF00796B);
const _bg          = Color(0xFFF4F7F6);
const _surface     = Color(0xFFFFFFFF);
const _textMain    = Color(0xFF1A2E2C);
const _textSub     = Color(0xFF5A7571);

const _totalRounds      = 5;
const _miniatureHideSec = 4; // níveis 3 e 4: miniatura desaparece após N segundos

/// (colunas, linhas, qtd de alvos) por nível (índice 0 = nível 1).
const _levelCfg = [
  (2, 3, 2), // nível 1 → 6 células, 2 alvos
  (3, 3, 2), // nível 2 → 9 células, 2 alvos
  (3, 3, 3), // nível 3 → 9 células, 3 alvos
  (3, 4, 3), // nível 4 → 12 células, 3 alvos
  (3, 4, 4), // nível 5 → 12 células, 4 alvos
];

enum _Phase { memorize, board }

// ─────────────────────────────────────────────────────────────────────────────
// BOARD CELL
// ─────────────────────────────────────────────────────────────────────────────

class _BoardCell {
  final Map<String, dynamic> stimulus;
  final bool isTarget;
  bool found    = false;
  bool revealed = false; // alvos não encontrados exibidos brevemente no fim da rodada

  _BoardCell({required this.stimulus, required this.isTarget});
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class OccurrencesGamePage extends StatefulWidget {
  const OccurrencesGamePage({super.key});

  @override
  State<OccurrencesGamePage> createState() => _OccurrencesGamePageState();
}

class _OccurrencesGamePageState extends State<OccurrencesGamePage> {
  bool _isInitialLoading = true;
  bool _isTransitioning = false;
  bool _isNextRoundReady = false;
  String _transitionTitle = 'Mandou bem!';
  String _transitionButtonText = 'Próxima Etapa';
  bool _canPop  = false;

  _Phase _phase = _Phase.memorize;

  late int _initialLevel;
  late int _currentLevel;
  Map<String, dynamic>? _progress;

  List<Map<String, dynamic>> _allStimuli       = [];
  final List<Map<String, dynamic>> _sessionStimuli = [];
  Map<String, dynamic>? _target;
  List<_BoardCell>       _board                = [];

  int _currentRound      = 0;
  int _roundTargetsFound = 0;
  int _totalHits         = 0;
  int _totalMistakes     = 0;
  int _totalTargets      = 0;

  final Set<dynamic> _usedTargetIds = {};
  final List<double> _responseTimes = [];
  DateTime?          _boardShowTime;

  bool   _miniatureVisible = true;
  Timer? _miniatureTimer;
  int?   _wrongTapIndex;
  Timer? _wrongTapTimer;
  bool   _boardLocked = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _miniatureTimer?.cancel();
    _wrongTapTimer?.cancel();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

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

    _allStimuli = await repo.fetchStimuli();
    _progress   = await repo.getPatientGameProgress(patientId, 'ocorrencias');
    _initialLevel = _currentLevel = _progress?['current_level'] as int? ?? 1;

    final cpRound = _progress?['checkpoint_round'] as int?;
    if (cpRound != null && cpRound > 0) {
      _currentRound = cpRound;
      _totalHits = _progress?['checkpoint_hits'] as int? ?? 0;
      _totalMistakes = _progress?['checkpoint_mistakes'] as int? ?? 0;
      _totalTargets = _progress?['checkpoint_targets'] as int? ?? 0;

      final usedIds = _progress?['checkpoint_used_ids'] as List? ?? [];
      _usedTargetIds.addAll(usedIds);

      final rawTimes = _progress?['checkpoint_times'] as List? ?? [];
      _responseTimes.addAll(rawTimes.map((t) => (t as num).toDouble()));
    }

    _buildRound();
    await _precacheStimuli();
    if (mounted) setState(() => _isInitialLoading = false);
  }

  Future<void> _precacheStimuli() async {
    if (!mounted) return;
    final urls = _board.map((c) => c.stimulus['url_imagem'] as String).toSet();
    await Future.wait(
      urls.map((url) => precacheImage(NetworkImage(url), context)),
    );
  }

  // ── Round logic ───────────────────────────────────────────────────────────

  void _buildRound() {
    final idx = (_currentLevel - 1).clamp(0, 4);
    final (cols, rows, targetCount) = _levelCfg[idx];
    final total     = cols * rows;
    final distCount = total - targetCount;

    final pool = FuzzyDifficultyController.filterStimuliForLevel(
      _allStimuli,
      _currentLevel,
      minRequired: total + 1,
    );
    if (pool.isEmpty) return;

    final rng = Random();

    final available  = pool.where((s) => !_usedTargetIds.contains(s['id'])).toList();
    final candidates = available.isNotEmpty ? available : pool;
    _target = candidates[rng.nextInt(candidates.length)];
    _usedTargetIds.add(_target!['id']);

    final distractors = (List<Map<String, dynamic>>.from(pool)
          ..removeWhere((s) => s['id'] == _target!['id'])
          ..shuffle(rng))
        .take(distCount)
        .toList();

    _board = [
      ...List.generate(targetCount, (_) => _BoardCell(stimulus: _target!, isTarget: true)),
      ...distractors.map((s) => _BoardCell(stimulus: s, isTarget: false)),
    ]..shuffle(rng);

    _sessionStimuli.add(_target!);
    _sessionStimuli.addAll(distractors);

    _roundTargetsFound = 0;
    _totalTargets     += targetCount;
    _phase             = _Phase.memorize;
    _miniatureVisible  = true;
    _boardLocked       = false;
    _wrongTapIndex     = null;
    _miniatureTimer?.cancel();
  }

  void _onReady() {
    setState(() => _phase = _Phase.board);
    _boardShowTime = DateTime.now();

    if (_currentLevel == 3 || _currentLevel == 4) {
      _miniatureTimer?.cancel();
      _miniatureTimer = Timer(const Duration(seconds: _miniatureHideSec), () {
        if (mounted) setState(() => _miniatureVisible = false);
      });
    } else if (_currentLevel >= 5) {
      setState(() => _miniatureVisible = false);
    }
  }

  void _onCellTap(int index) {
    if (_boardLocked) return;
    final cell = _board[index];
    if (cell.found || cell.revealed) return;

    if (cell.isTarget) {
      final idx         = (_currentLevel - 1).clamp(0, 4);
      final targetCount = _levelCfg[idx].$3;

      setState(() {
        cell.found = true;
        _roundTargetsFound++;
        _totalHits++;
      });

      if (_roundTargetsFound >= targetCount) {
        _boardLocked = true;
        _responseTimes.add(
          DateTime.now().difference(_boardShowTime!).inMilliseconds.toDouble(),
        );
        Future.delayed(const Duration(milliseconds: 800), _nextRound);
      }
    } else {
      _totalMistakes++;
      setState(() => _wrongTapIndex = index);
      _wrongTapTimer?.cancel();
      _wrongTapTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _wrongTapIndex = null);
      });
    }
  }


  Future<void> _nextRound() async {
    _miniatureTimer?.cancel();
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
      // Damos um pequeno fôlego para a tela de overlay aparecer antes do buildRound
      await Future.delayed(const Duration(milliseconds: 50));
      
      _currentRound++;
      _buildRound();
      await _precacheStimuli();
      
      if (mounted) {
        setState(() => _isNextRoundReady = true);
      }
    }
  }

  // ── Finish & FIS ─────────────────────────────────────────────────────────

  Future<void> _finishGame() async {
    final repo      = context.read<AuthRepository>();
    final patientId = repo.patientProfile?['id']?.toString();
    if (patientId == null) return;

    final total     = _totalHits + _totalMistakes;
    final precision = total == 0 ? 0.0 : (_totalHits / total).clamp(0.0, 1.0);
    final avgTimeMs = _responseTimes.isEmpty
        ? 0.0
        : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;

    final baselineMs = (_progress?['baseline_response_time'] as num?)?.toDouble();
    final rawHistory = _progress?['precision_history'] as List? ?? [];
    final history    = rawHistory.map((v) => (v as num).toDouble()).toList();

    final avgScore = _sessionStimuli.isEmpty
        ? 0.72
        : _sessionStimuli
              .map((s) => (s['selection_score'] as num).toDouble())
              .reduce((a, b) => a + b) /
          _sessionStimuli.length;

    final result = FuzzyDifficultyController.evaluate(
      precision: precision,
      baselineMs: baselineMs,
      avgResponseTimeMs: avgTimeMs,
      avgSelectionScore: avgScore,
      precisionHistory: history,
      currentLevel: _currentLevel,
      gameType: 'ocorrencias',
    );

    // ignore: avoid_print
    print('''
    ─────────── FIS DEBUG (ocorrências) ───────────
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
    ──────────────────────────────────────────────
    ''');

    final updatedHistory =
        [...history, precision].reversed.take(5).toList().reversed.toList();
    final newBaseline =
        FuzzyDifficultyController.updateBaseline(baselineMs, avgTimeMs, precision);

    setState(() => _currentLevel = result.newLevel);

    await Future.wait([
      repo.upsertPatientGameProgress(
        patientId: patientId,
        gameType: 'ocorrencias',
        currentLevel: result.newLevel,
        baselineResponseTime: newBaseline,
        precisionHistory: updatedHistory,
      ),
      repo.saveGameSession(
        patientId: patientId,
        gameType: 'ocorrencias',
        initialLevel: _initialLevel,
        finalLevel: result.newLevel,
        hits: _totalHits,
        mistakes: _totalMistakes,
        avgResponseTimeMs: avgTimeMs.round(),
        fuzzyDecision: result.decision,
        performanceData: {
          'total_targets': _totalTargets,
          'rounds': _totalRounds,
        },
      ),
      repo.clearGameCheckpoint(
        patientId: patientId,
        gameType: 'ocorrencias',
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
      await Future.delayed(const Duration(milliseconds: 50));
      
      _currentRound  = 0;
      _totalHits     = 0;
      _totalMistakes = 0;
      _totalTargets  = 0;
      _responseTimes.clear();
      _sessionStimuli.clear();
      _initialLevel = _currentLevel;
      _usedTargetIds.clear();
      _buildRound();
      await _precacheStimuli();

      if (mounted) {
        setState(() => _isNextRoundReady = true);
      }
    }
  }

  // ── Exit ──────────────────────────────────────────────────────────────────

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
        await repo.clearGameCheckpoint(patientId: patientId, gameType: 'ocorrencias');
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
        gameType: 'ocorrencias',
        round: _currentRound,
        hits: _totalHits,
        mistakes: _totalMistakes,
        targets: _totalTargets,
        usedIds: _usedTargetIds.toList(),
        times: _responseTimes,
      );
    }
    
    if (mounted) {
      setState(() => _canPop = true);
      Navigator.of(context).pop();
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
              _phase == _Phase.memorize ? _buildMemorize() : _buildBoard(),
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

  // ── Header ────────────────────────────────────────────────────────────────

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Encontre as Ocorrências',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textMain,
                  ),
                ),
                if (_phase == _Phase.board) ...[
                  const SizedBox(height: 6),
                  _RoundProgress(current: _currentRound, total: _totalRounds),
                ],
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Memorize phase ────────────────────────────────────────────────────────

  Widget _buildMemorize() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              _target!['url_imagem'] as String,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: _textSub,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryDark,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Memorize esta imagem',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Rodada ${_currentRound + 1} de $_totalRounds',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _onReady,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Board phase ───────────────────────────────────────────────────────────

  Widget _buildBoard() {
    final idx = (_currentLevel - 1).clamp(0, 4);
    final (cols, rows, targetCount) = _levelCfg[idx];

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final W = constraints.maxWidth;
              final H = constraints.maxHeight;

              const padding    = 24.0;
              const gap        = 8.0;

              final gridW = W - 2 * padding;
              final gridH = H - padding;

              final cellW = (gridW - (cols - 1) * gap) / cols;
              final cellH = (gridH - (rows - 1) * gap) / rows;
              final cell  = max(1.0, min(cellW, cellH));

              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width:  cell * cols + gap * (cols - 1),
                              height: cell * rows + gap * (rows - 1),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: gap,
                                  crossAxisSpacing: gap,
                                  childAspectRatio: 1,
                                ),
                                itemCount: _board.length,
                                itemBuilder: (_, i) => _BoardTile(
                                  cell:    _board[i],
                                  isWrong: i == _wrongTapIndex,
                                  onTap:   _boardLocked
                                      ? null
                                      : () => _onCellTap(i),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_currentLevel < 5)
                          Positioned(
                            top: 8,
                            right: padding,
                            child: AnimatedOpacity(
                              opacity:  _miniatureVisible ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 600),
                              child: _Miniature(stimulus: _target!),
                            ),
                          ),
                      ],
                    ),
                  ),

                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
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

class _BoardTile extends StatelessWidget {
  final _BoardCell    cell;
  final bool          isWrong;
  final VoidCallback? onTap;

  const _BoardTile({
    required this.cell,
    required this.isWrong,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color?    overlayColor;
    IconData? overlayIcon;

    if (cell.found) {
      overlayColor = Colors.green;
      overlayIcon  = Icons.check_circle_rounded;
    } else if (cell.revealed) {
      overlayColor = Colors.orange;
      overlayIcon  = Icons.visibility_rounded;
    } else if (isWrong) {
      overlayColor = Colors.red;
      overlayIcon  = Icons.cancel_rounded;
    }

    return GestureDetector(
      onTap: (cell.found || cell.revealed) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: overlayColor ?? Colors.transparent,
            width: overlayColor != null ? 3 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  cell.stimulus['url_imagem'] as String,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: _textSub),
                  ),
                ),
              ),
              if (overlayColor != null)
                Positioned.fill(
                  child: Container(
                    color: overlayColor.withValues(alpha: 0.22),
                    child: Center(
                      child: Icon(
                        overlayIcon,
                        color: overlayColor,
                        size: 32,
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
}

class _Miniature extends StatelessWidget {
  final Map<String, dynamic> stimulus;
  const _Miniature({required this.stimulus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  76,
      height: 76,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                stimulus['url_imagem'] as String,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: _textSub),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: _primaryDark.withValues(alpha: 0.82),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: const Text(
                  'Alvo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
