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

/// Number of options shown per level (index 0 = level 1)
const _optionCounts = [2, 3, 4, 6, 8];
const _totalRounds  = 6;

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class MatchingGamePage extends StatefulWidget {
  const MatchingGamePage({super.key});

  @override
  State<MatchingGamePage> createState() => _MatchingGamePageState();
}

class _MatchingGamePageState extends State<MatchingGamePage> {
  // Game state
  bool _loading = true;
  bool _canPop = false;

  int _currentRound = 0;
  int _hits = 0;
  int _mistakes = 0;

  late int _initialLevel;
  late int _currentLevel;
  Map<String, dynamic>? _progress;

  List<Map<String, dynamic>> _allStimuli = [];
  Map<String, dynamic>? _target;
  List<Map<String, dynamic>> _options = [];
  List<double> _responseTimes = [];
  DateTime? _roundStart;

  /// IDs dos estímulos já usados como alvo nesta sessão.
  final Set<dynamic> _usedTargetIds = {};

  // Feedback state
  int? _selectedIndex;
  bool? _selectedCorrect;

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
    _progress   = await repo.getPatientGameProgress(patientId, 'matching');

    _initialLevel = _currentLevel = _progress?['current_level'] as int? ?? 1;
    _buildRound();

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

  // ── Round logic ───────────────────────────────────────────────────────────

  void _buildRound() {
    final pool = FuzzyDifficultyController.filterStimuliForLevel(
      _allStimuli, _currentLevel,
    );
    if (pool.isEmpty) return;

    final rng = Random();

    // Filtra alvos ainda não usados nesta sessão
    final available = pool.where((s) => !_usedTargetIds.contains(s['id'])).toList();
    // Se todos já foram usados, reinicia o ciclo (jogo longo ou pool pequeno)
    final candidatePool = available.isNotEmpty ? available : pool;

    _target = candidatePool[rng.nextInt(candidatePool.length)];
    _usedTargetIds.add(_target!['id']);

    final distractors = (List<Map<String, dynamic>>.from(pool)
          ..removeWhere((s) => s['id'] == _target!['id'])
          ..shuffle(rng))
        .take((_optionCounts[(_currentLevel - 1).clamp(0, 4)] - 1))
        .toList();

    _options = [_target!, ...distractors]..shuffle(rng);
    _selectedIndex   = null;
    _selectedCorrect = null;
    _roundStart      = DateTime.now();
  }

  Future<void> _onOptionTap(int index) async {
    if (_selectedIndex != null) return; // already answered

    final elapsed = DateTime.now().difference(_roundStart!).inMilliseconds;
    _responseTimes.add(elapsed.toDouble());

    final correct = _options[index]['id'] == _target!['id'];
    setState(() {
      _selectedIndex   = index;
      _selectedCorrect = correct;
      if (correct) { _hits++; } else { _mistakes++; }
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (_currentRound + 1 >= _totalRounds) {
      await _finishGame();
    } else {
      setState(() {
        _currentRound++;
        _buildRound();
      });
    }
  }

  // ── Finish & FIS ─────────────────────────────────────────────────────────

  Future<void> _finishGame() async {
    final repo      = context.read<AuthRepository>();
    final patientId = repo.patientProfile?['id']?.toString();
    if (patientId == null) return;

    final precision    = _hits / _totalRounds;
    final avgTimeMs    = _responseTimes.isEmpty
        ? 0.0
        : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;

    final baselineMs   = (_progress?['baseline_response_time'] as num?)?.toDouble();
    final rawHistory   = _progress?['precision_history'] as List? ?? [];
    final history      = rawHistory.map((v) => (v as num).toDouble()).toList();
    final usedStimuli  = _options; // all stimuli seen this session
    final avgScore     = usedStimuli.isEmpty
        ? 0.72
        : usedStimuli
              .map((s) => (s['selection_score'] as num).toDouble())
              .reduce((a, b) => a + b) /
          usedStimuli.length;

    final result = FuzzyDifficultyController.evaluate(
      precision: precision,
      baselineMs: baselineMs,
      avgResponseTimeMs: avgTimeMs,
      avgSelectionScore: avgScore,
      precisionHistory: history,
      currentLevel: _currentLevel,
      gameType: 'matching',
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

    // Update history (keep last 5)
    final updatedHistory = [...history, precision].reversed.take(5).toList().reversed.toList();
    final newBaseline    = FuzzyDifficultyController.updateBaseline(baselineMs, avgTimeMs, precision);

    setState(() {
      _currentLevel = result.newLevel;
    });

    await Future.wait([
      repo.upsertPatientGameProgress(
        patientId: patientId,
        gameType: 'matching',
        currentLevel: result.newLevel,
        baselineResponseTime: newBaseline,
        precisionHistory: updatedHistory,
      ),
      repo.saveGameSession(
        patientId: patientId,
        gameType: 'matching',
        initialLevel: _initialLevel,
        finalLevel: result.newLevel,
        hits: _hits,
        mistakes: _mistakes,
        avgResponseTimeMs: avgTimeMs.round(),
        fuzzyDecision: result.decision,
        performanceData: {
          'stimuli_used': usedStimuli.map((s) => s['nome_arquivo']).toList(),
        },
      ),
    ]);

    if (mounted) {
      setState(() {
        _currentRound = 0;
        _hits = 0;
        _mistakes = 0;
        _responseTimes = [];
        _initialLevel = _currentLevel;
        _usedTargetIds.clear(); // nova sessão → alvos renovados
        _buildRound();
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
        body: SafeArea(
          child: _buildGame(),
        ),
      ),
    );
  }

  // ── Game UI ───────────────────────────────────────────────────────────────

  Widget _buildGame() {
    final optCount = _optionCounts[(_currentLevel - 1).clamp(0, 4)];
    final cols     = optCount <= 4 ? 2 : 3;
    final rows     = (optCount / cols).ceil();

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final W = constraints.maxWidth;
              final H = constraints.maxHeight;

              // Dedicate 35% of height to the target card, clamped between 100 and 200
              final targetHeight = (H * 0.35).clamp(100.0, 200.0);
              const topSpacing = 8.0;
              const midSpacing = 16.0;
              const bottomSpacing = 12.0;
              const itemSpacing = 12.0;

              final gridHeight = max(1.0, H - targetHeight - topSpacing - midSpacing - bottomSpacing);
              final gridW = max(1.0, W - 48.0);
              
              final cellWidth = max(1.0, (gridW - (cols - 1) * itemSpacing) / cols);
              final cellHeight = max(1.0, (gridHeight - (rows - 1) * itemSpacing) / rows);
              final itemSize = max(1.0, min(cellWidth, cellHeight));

              return Column(
                children: [
                  const SizedBox(height: topSpacing),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _TargetCard(stimulus: _target!, height: targetHeight),
                  ),
                  const SizedBox(height: midSpacing),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      height: gridHeight,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: itemSpacing,
                          crossAxisSpacing: itemSpacing,
                          childAspectRatio: cellWidth / cellHeight,
                        ),
                        itemCount: _options.length,
                        itemBuilder: (context, i) {
                          Color? overlay;
                          if (_selectedIndex != null) {
                            if (i == _selectedIndex) {
                              overlay = _selectedCorrect! ? Colors.green : Colors.red;
                            } else if (_options[i]['id'] == _target!['id']) {
                              overlay = Colors.green; // reveal correct
                            }
                          }
                          return Center(
                            child: SizedBox(
                              width: itemSize,
                              height: itemSize,
                              child: _OptionCard(
                                stimulus: _options[i],
                                overlay: overlay,
                                onTap: _selectedIndex == null ? () => _onOptionTap(i) : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: bottomSpacing),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Correspondência',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textMain,
                  ),
                ),
                const SizedBox(height: 6),
                _RoundProgress(
                  current: _currentRound,
                  total: _totalRounds,
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
        final done    = i < current;
        final active  = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width:  active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: done || active ? _primary : _primary.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final Map<String, dynamic> stimulus;
  final double height;
  const _TargetCard({required this.stimulus, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.15),
            blurRadius: 20,
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
                stimulus['url_imagem'] as String,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 60, color: _textSub),
                ),
              ),
            ),
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Encontre igual',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final Map<String, dynamic> stimulus;
  final Color? overlay;
  final VoidCallback? onTap;
  const _OptionCard({required this.stimulus, this.overlay, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: overlay ?? Colors.transparent,
            width: overlay != null ? 3 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  stimulus['url_imagem'] as String,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: _textSub),
                  ),
                ),
              ),
              if (overlay != null)
                Positioned.fill(
                  child: Container(
                    color: overlay!.withValues(alpha: 0.25),
                    child: Center(
                      child: Icon(
                        overlay == Colors.green
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: overlay,
                        size: 40,
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


