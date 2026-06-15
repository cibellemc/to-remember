import 'package:flutter/material.dart';

class PerformanceChart extends StatelessWidget {
  final List<double> dataPoints;
  final List<String> xLabels;
  final double minY;
  final double maxY;
  final String Function(double) yLabelFormatter;
  final Color color;
  final String emptyMessage;

  const PerformanceChart({
    super.key,
    required this.dataPoints,
    required this.xLabels,
    required this.minY,
    required this.maxY,
    required this.yLabelFormatter,
    this.color = const Color(0xFF009688),
    this.emptyMessage = 'Sem partidas registradas ainda.',
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
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
              Icon(Icons.show_chart_rounded, size: 48, color: Colors.grey.shade300),
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
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
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
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Y Axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    final val = maxY - (index * (maxY - minY) / 3);
                    return SizedBox(
                      width: 38,
                      child: Text(
                        yLabelFormatter(val),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                // Chart area
                Expanded(
                  child: CustomPaint(
                    painter: _LineChartPainter(
                      points: dataPoints,
                      minY: minY,
                      maxY: maxY,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X Axis labels
          Row(
            children: [
              const SizedBox(width: 46), // Align with chart area
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(xLabels.length, (index) {
                    return Expanded(
                      child: Text(
                        xLabels[index],
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> points;
  final double minY;
  final double maxY;
  final Color color;

  _LineChartPainter({
    required this.points,
    required this.minY,
    required this.maxY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw background grid lines (horizontal)
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final yGrid = i * h / 3;
      canvas.drawLine(Offset(0, yGrid), Offset(w, yGrid), gridPaint);
    }

    if (points.isEmpty) return;

    // Calculate chart line path
    final double dx = points.length > 1 ? w / (points.length - 1) : w;
    final double range = maxY - minY;

    double getY(double val) {
      if (range == 0) return h / 2;
      final pct = ((val - minY) / range).clamp(0.0, 1.0);
      return h - (pct * h);
    }

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = getY(points[i]);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    if (points.length > 1) {
      fillPath.lineTo((points.length - 1) * dx, h);
      fillPath.close();

      // Paint background gradient fill under the line
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTRB(0, 0, w, h));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Paint main connecting line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Paint dots on key values
    final outerDotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final innerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = getY(points[i]);

      // Shadow or border effect for the dot
      canvas.drawCircle(Offset(x, y), 5.5, outerDotPaint);
      canvas.drawCircle(Offset(x, y), 3.0, innerDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
