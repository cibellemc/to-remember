import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// RESULT
// ─────────────────────────────────────────────────────────────────────────────

class FuzzyResult {
  final String decision; // 'Aumentar' | 'Manter' | 'Diminuir'
  final double score; // defuzzified value in [-1, 1]
  final int newLevel; // clamped to [1, 5]

  const FuzzyResult({
    required this.decision,
    required this.score,
    required this.newLevel,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class FuzzyDifficultyController {
  // Level → [minScore, maxScore) — no overlap between levels
  static const _levelRanges = [
    (0.82, 1.01), // Level 1
    (0.72, 0.82), // Level 2
    (0.62, 0.72), // Level 3
    (0.52, 0.62), // Level 4
    (0.50, 0.52), // Level 5
  ];

  // ── Membership helpers ────────────────────────────────────────────────────

  static double _trap(double x, double a, double b, double c, double d) {
    if (x < a || x > d) return 0.0;
    if (x >= b && x <= c) return 1.0;
    if (x < b) return (x - a) / (b - a);
    return (d - x) / (d - c);
  }

  static double _tri(double x, double a, double b, double c) {
    if (x < a || x > c) return 0.0;
    if (x == b) return 1.0;
    if (x < b) return (x - a) / (b - a);
    return (c - x) / (c - b);
  }

  // Precision
  static double _pLow(double p) => _trap(p, 0.00, 0.00, 0.60, 0.75);
  static double _pMid(double p) => _trap(p, 0.65, 0.75, 0.80, 0.88);
  static double _pHigh(double p) => _trap(p, 0.80, 0.88, 1.00, 1.00);

  // Latency (normalised: sessionAvg / baseline)
  static double _lFast(double l) => _trap(l, 0.00, 0.00, 0.80, 1.00);
  static double _lNormal(double l) => _tri(l, 0.80, 1.00, 1.20);
  static double _lSlow(double l) => _trap(l, 1.05, 1.25, 3.00, 3.00);

  // BOSS load (inverted normalised selection_score)
  static double _bLight(double c) => _trap(c, 0.00, 0.00, 0.30, 0.50);
  static double _bMid(double c) => _tri(c, 0.30, 0.50, 0.70);
  static double _bHeavy(double c) => _trap(c, 0.55, 0.75, 1.00, 1.00);

  // Consistency (std-dev of precision history)
  static double _sStable(double s) => _trap(s, 0.00, 0.00, 0.05, 0.10);
  static double _sUnstable(double s) => _trap(s, 0.05, 0.10, 1.00, 1.00);

  // ── Public helpers ────────────────────────────────────────────────────────

  /// Converts selection_score → BOSS load ∈ [0, 1]
  static double computeBossLoad(double selectionScore) =>
      ((0.9 - selectionScore) / 0.4).clamp(0.0, 1.0);

  /// Returns stimuli for a given level.
  /// If the level's score range yields fewer than [minRequired] items,
  /// progressively widens the window by ±0.10 until enough are found,
  /// falling back to the entire catalogue as a last resort.
  static List<Map<String, dynamic>> filterStimuliForLevel(
    List<Map<String, dynamic>> allStimuli,
    int level, {
    int minRequired = 8,
  }) {
    if (allStimuli.isEmpty) return [];

    final idx = (level - 1).clamp(0, 4);
    final (baseMin, baseMax) = _levelRanges[idx];

    for (double expand = 0.0; expand <= 0.50; expand += 0.10) {
      final lo = (baseMin - expand).clamp(0.0, 1.0);
      final hi = (baseMax + expand).clamp(0.0, 1.10);
      final filtered = allStimuli.where((s) {
        final score = (s['selection_score'] as num?)?.toDouble() ?? 0.0;
        return score >= lo && score < hi;
      }).toList();
      if (filtered.length >= minRequired) return filtered;
    }

    // Last resort: return everything
    return List.from(allStimuli);
  }

  /// Computes std-dev of precision history.
  /// Returns neutral 0.0 when history has < 3 entries (fully stable by default).
  static double computeConsistency(List<double> history) {
    if (history.length < 3) return 0.0;
    final n = history.length;
    final mean = history.reduce((a, b) => a + b) / n;
    final variance =
        history.map((p) => (p - mean) * (p - mean)).reduce((a, b) => a + b) / n;
    return sqrt(variance);
  }

  /// Updates the EMA baseline. Only updates when precision > 70%.
  /// Returns the new baseline, or the unchanged one if conditions not met.
  static double? updateBaseline(
    double? currentBaseline,
    double sessionAvgMs,
    double precision,
  ) {
    if (precision <= 0.70) return currentBaseline;
    if (currentBaseline == null) return sessionAvgMs;
    return 0.7 * currentBaseline + 0.3 * sessionAvgMs;
  }

  // ── Main inference ────────────────────────────────────────────────────────

  static FuzzyResult evaluate({
    required double precision, // hits / totalAttempts ∈ [0, 1]
    required double? baselineMs, // null on first session
    required double avgResponseTimeMs, // mean response time this session
    required double avgSelectionScore, // mean score of stimuli used
    required List<double> precisionHistory, // rolling last-5 precisions
    required int currentLevel, // 1–5
    String gameType = 'matching',
  }) {
    double adjPrecision = precision;
    if (gameType == 'memory') {
      // Memory game requires exploratory flips which shouldn't be penalized as "mistakes".
      // Perfect memory performance expected worst-case precision is N / (2N - 1).
      final pairCounts = [2, 3, 4, 6, 8];
      final n = pairCounts[(currentLevel - 1).clamp(0, 4)];
      final perfectPrecision = n / (2 * n - 1);
      adjPrecision = (precision / perfectPrecision).clamp(0.0, 1.0);
    }

    if (adjPrecision < 0.60) {
      return FuzzyResult(
        decision: 'Diminuir',
        score: -1.0,
        newLevel: (currentLevel - 1).clamp(1, 5),
      );
    }
    
    // Normalised latency (1.0 = Normal when baseline is unknown)
    final lNorm = baselineMs == null
        ? 1.0
        : (avgResponseTimeMs / baselineMs).clamp(0.0, 3.0);

    final cNorm = computeBossLoad(avgSelectionScore);
    final consistency = computeConsistency(precisionHistory);

    // Antecedent degrees
    final pL = _pLow(adjPrecision);
    final pM = _pMid(adjPrecision);
    final pH = _pHigh(adjPrecision);

    final lF = _lFast(lNorm);
    final lN = _lNormal(lNorm);
    final lS = _lSlow(lNorm);

    final bL = _bLight(cNorm);
    final bM = _bMid(cNorm);
    final bH = _bHeavy(cNorm);

    final sS = _sStable(consistency);
    final sU = _sUnstable(consistency);

    // Rules: (firing strength, singleton consequent)
    // singleton: -1=Diminuir  0=Manter  +1=Aumentar
    final rules = <(double, double)>[
      (pL, -1.0), // R0
      (min(pM, min(lS, bH)), -1.0), // R1
      (min(pM, min(lN, bL)), 0.0), // R2
      (min(pM, min(lN, min(bM, sS))), 0.0), // R3
      (min(pM, min(lN, min(bM, sU))), 0.0), // R4
      (min(pM, min(lF, sS)), 1.0), // R5
      (min(pH, lF), 1.0), // R6: High precision, fast latency -> increase (independent of load)
      (min(pH, min(lN, sS)), 1.0), // R7
      (min(pH, lS), 0.0), // R8
      (min(pH, sU), 0.0), // R9
    ];

    final totalW = rules.map((r) => r.$1).reduce((a, b) => a + b);
    final score = totalW == 0
        ? 0.0
        : rules.map((r) => r.$1 * r.$2).reduce((a, b) => a + b) / totalW;

    final String decision;
    final int newLevel;

    if (score >= 0.25) {
      decision = 'Aumentar';
      newLevel = (currentLevel + 1).clamp(1, 5);
    } else if (score <= -0.25) {
      decision = 'Diminuir';
      newLevel = (currentLevel - 1).clamp(1, 5);
    } else {
      decision = 'Manter';
      newLevel = currentLevel;
    }

    return FuzzyResult(decision: decision, score: score, newLevel: newLevel);
  }
}
