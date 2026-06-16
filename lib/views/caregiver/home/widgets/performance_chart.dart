import 'package:flutter/material.dart';

class PerformanceChart extends StatelessWidget {
  final List<double> minPoints;
  final List<double> maxPoints;
  final List<int> matchCounts;
  final List<String> xLabels;
  final double minY;
  final double maxY;
  final String Function(double) yLabelFormatter;
  final Color color;
  final String emptyMessage;

  const PerformanceChart({
    super.key,
    required this.minPoints,
    required this.maxPoints,
    required this.matchCounts,
    required this.xLabels,
    required this.minY,
    required this.maxY,
    required this.yLabelFormatter,
    this.color = const Color(0xFF009688),
    this.emptyMessage = 'Sem partidas registradas ainda.',
  });

  @override
  Widget build(BuildContext context) {
    if (maxPoints.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                emptyMessage,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem(const Color(0xFFF59E0B), 'Pior resultado'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFF0D9488), 'Melhor resultado'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _BarChartPainter(
                minPoints: minPoints,
                maxPoints: maxPoints,
                matchCounts: matchCounts,
                xLabels: xLabels,
                minY: minY,
                maxY: maxY,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> minPoints;
  final List<double> maxPoints;
  final List<int> matchCounts;
  final List<String> xLabels;
  final double minY;
  final double maxY;
  final Color color;

  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  _BarChartPainter({
    required this.minPoints,
    required this.maxPoints,
    required this.matchCounts,
    required this.xLabels,
    required this.minY,
    required this.maxY,
    required this.color,
  });

  void _drawText(Canvas canvas, String text, double x, double y, Color color, double fontSize,
      {bool bold = false, TextAlign align = TextAlign.center}) {
    _textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
      ),
    );
    _textPainter.layout();

    double xOffset = x;
    if (align == TextAlign.center) {
      xOffset = x - _textPainter.width / 2;
    } else if (align == TextAlign.right) {
      xOffset = x - _textPainter.width;
    }

    _textPainter.paint(canvas, Offset(xOffset, y - _textPainter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    const double leftMargin = 45.0;
    const double rightMargin = 15.0;
    const double topPadding = 30.0;
    const double bottomPadding = 55.0;

    final double chartWidth = w - leftMargin - rightMargin;
    final double chartHeight = h - topPadding - bottomPadding;

    // Draw background grid lines (horizontal) and Y labels
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final val = maxY - (i * (maxY - minY) / 3);
      final yGrid = topPadding + (i * chartHeight / 3);

      canvas.drawLine(Offset(leftMargin, yGrid), Offset(w - rightMargin, yGrid), gridPaint);

      _drawText(
        canvas,
        "${(val * 100).round()}%",
        leftMargin - 12,
        yGrid,
        Colors.grey.shade500,
        11,
        bold: true,
        align: TextAlign.right,
      );
    }

    if (maxPoints.isEmpty) return;

    final double range = maxY - minY;

    double getY(double val) {
      if (range == 0) return topPadding + chartHeight / 2;
      final pct = ((val - minY) / range).clamp(0.0, 1.0);
      return topPadding + chartHeight - (pct * chartHeight);
    }

    final double sectionWidth = chartWidth / maxPoints.length;
    // Adapt bar width dynamically, but make it significantly thicker
    final double barWidth = (sectionWidth * 0.25).clamp(16.0, 36.0);

    for (int i = 0; i < maxPoints.length; i++) {
      final centerX = leftMargin + (i * sectionWidth) + (sectionWidth / 2);
      final yTop = getY(maxPoints[i]);
      final yBottom = getY(minPoints[i]);
      final count = matchCounts[i];

      // Draw X-axis label (date)
      _drawText(canvas, xLabels[i], centerX, h - 34.0, Colors.grey.shade700, 12, bold: true);

      // Draw match count label
      final countText = count == 1 ? "1 partida" : "$count partidas";
      _drawText(canvas, countText, centerX, h - 14.0, Colors.grey.shade400, 10);

      if (count == 1 || (maxPoints[i] - minPoints[i]).abs() < 0.005) {
        // Draw single bar (Best)
        final yBottomBar = getY(0.0); // Baseline at 0%

        final rect = RRect.fromLTRBAndCorners(
          centerX - barWidth / 2,
          yTop,
          centerX + barWidth / 2,
          yBottomBar,
          topLeft: Radius.circular(barWidth / 4),
          topRight: Radius.circular(barWidth / 4),
        );

        final fillPaint = Paint()..color = const Color(0xFF0D9488);

        canvas.drawRRect(rect, fillPaint);

        // Draw accuracy value on top
        _drawText(
          canvas,
          "${(maxPoints[i] * 100).round()}%",
          centerX,
          yTop - 12,
          const Color(0xFF0D9488),
          12,
          bold: true,
        );
      } else {
        // Draw two bars side-by-side: Worst (left) and Best (right)
        const double gap = 4.0;
        final leftBarCenterX = centerX - barWidth / 2 - gap;
        final rightBarCenterX = centerX + barWidth / 2 + gap;
        final yBottomBar = getY(0.0); // Baseline at 0%

        // 1. Worst Bar (Left)
        final worstRect = RRect.fromLTRBAndCorners(
          leftBarCenterX - barWidth / 2,
          yBottom,
          leftBarCenterX + barWidth / 2,
          yBottomBar,
          topLeft: Radius.circular(barWidth / 4),
          topRight: Radius.circular(barWidth / 4),
        );
        final worstPaint = Paint()..color = const Color(0xFFF59E0B);
        canvas.drawRRect(worstRect, worstPaint);
        // Draw worst value on top
        _drawText(
          canvas,
          "${(minPoints[i] * 100).round()}%",
          leftBarCenterX,
          yBottom - 12,
          const Color(0xFFD97706),
          11,
          bold: true,
        );

        // 2. Best Bar (Right)
        final bestRect = RRect.fromLTRBAndCorners(
          rightBarCenterX - barWidth / 2,
          yTop,
          rightBarCenterX + barWidth / 2,
          yBottomBar,
          topLeft: Radius.circular(barWidth / 4),
          topRight: Radius.circular(barWidth / 4),
        );
        final bestPaint = Paint()..color = const Color(0xFF0D9488);
        canvas.drawRRect(bestRect, bestPaint);
        // Draw best value on top
        _drawText(
          canvas,
          "${(maxPoints[i] * 100).round()}%",
          rightBarCenterX,
          yTop - 12,
          const Color(0xFF0D9488),
          11,
          bold: true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.maxPoints != maxPoints ||
        oldDelegate.minPoints != minPoints ||
        oldDelegate.matchCounts != matchCounts ||
        oldDelegate.color != color;
  }
}
