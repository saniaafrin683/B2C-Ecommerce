import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/admin/admin_dashboard_service.dart';

class AdminTrendChart extends StatelessWidget {
  const AdminTrendChart({
    super.key,
    required this.points,
    required this.color,
    this.currency = false,
  });

  final List<AdminTrendPoint> points;
  final Color color;
  final bool currency;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const AdminChartEmpty(message: 'No trend data available yet.');
    }
    final maxValue = points.fold<double>(
      0,
      (maximum, point) => math.max(maximum, point.value),
    );
    final total = points.fold<double>(0, (sum, point) => sum + point.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                currency ? _money(total) : total.toStringAsFixed(0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              '${points.length} month${points.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 170,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(
              values: points.map((point) => point.value).toList(),
              maximum: maxValue,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _axisLabels(points)
              .map(
                (label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  List<String> _axisLabels(List<AdminTrendPoint> values) {
    if (values.length <= 3) return values.map((point) => point.label).toList();
    return [
      values.first.label,
      values[values.length ~/ 2].label,
      values.last.label,
    ];
  }
}

class AdminDistributionChart extends StatelessWidget {
  const AdminDistributionChart({
    super.key,
    required this.items,
    required this.colors,
  });

  final List<AdminDistributionItem> items;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AdminChartEmpty(message: 'No status data available yet.');
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.count);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 12,
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Expanded(
                  flex: math.max(1, item.count),
                  child: ColoredBox(color: colors[index % colors.length]),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(items.length, (index) {
          final item = items[index];
          final color = colors[index % colors.length];
          final percentage = total == 0 ? 0 : item.count * 100 / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${item.count} · ${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class AdminChartEmpty extends StatelessWidget {
  const AdminChartEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 150,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insights_outlined,
            color: Color(0xFF94A3B8),
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    ),
  );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.maximum,
    required this.color,
  });

  final List<double> values;
  final double maximum;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = size.height * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;
    final denominator = maximum <= 0 ? 1 : maximum;
    final step = values.length == 1 ? 0.0 : size.width / (values.length - 1);
    final points = List.generate(values.length, (index) {
      final x = values.length == 1 ? size.width / 2 : index * step;
      final y =
          size.height - (values[index] / denominator * (size.height - 12));
      return Offset(x, y.clamp(6, size.height));
    });

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dotPaint = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.maximum != maximum ||
      oldDelegate.color != color;
}

String _money(double value) => '৳${value.toStringAsFixed(2)}';
