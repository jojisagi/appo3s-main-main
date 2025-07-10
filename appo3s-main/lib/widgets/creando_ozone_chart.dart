import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/muestreo.dart';
import '../models/sample.dart';

class Creando_OzoneChart extends StatelessWidget {
  const Creando_OzoneChart({
    super.key,
    required this.muestreo,
    this.useViewport = false,
  });

  final Muestreo muestreo;
  final bool     useViewport;

  @override
  Widget build(BuildContext context) {
    const emphColor = Color.fromARGB(255, 159, 206, 238);

    final List<Sample> data = useViewport
        ? ((muestreo as dynamic).inView as List<Sample>? ?? muestreo.samples)
        : muestreo.samples;

    /* ───── Sin datos ───── */
    if (data.isEmpty) return _empty(context, emphColor);

    /* ───── Spots ───── */
    final original = data
        .map((s) => FlSpot(
      (s.selectedMinutes * 60 + s.selectedSeconds).toDouble(),
      s.y,
    ))
        .toList();

    final List<FlSpot> spots = original.first.x == 0
        ? original
        : [FlSpot(0, original.first.y), ...original];

    /* ───── Estadísticas ───── */
    final ys   = data.map((e) => e.y).toList();
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final avgY = ys.reduce((a, b) => a + b) / ys.length;
    final auc  = _auc(spots);

    final maxYaxis = maxY < 100 ? 100.0 : (maxY * 1.1).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Monitoreo de Ozono',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
        ),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: spots.last.x,
              minY: 0,
              maxY: maxYaxis,
              gridData: const FlGridData(
                show: true,
                horizontalInterval: 10,
              ),
              lineTouchData: const LineTouchData(
                handleBuiltInTouches: true,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots        : spots,
                  isCurved     : true,
                  barWidth     : 2,
                  color        : Colors.blue,
                  dotData      : const FlDotData(show: true),
                  belowBarData : BarAreaData(
                    show : true,
                    color: emphColor.withOpacity(.25),
                  ),
                ),
              ],
              titlesData: _titlesData(spots, 'ppm'),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _statsRow(context, maxY, minY, avgY, auc),
      ],
    );
  }

  /* ─ Helpers ─ */

  FlTitlesData _titlesData(List<FlSpot> spots, String yLabel) => FlTitlesData(
    bottomTitles: AxisTitles(
      axisNameWidget: const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('min:seg',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      sideTitles: SideTitles(
        showTitles  : true,
        reservedSize: 40,
        interval    : ((spots.last.x - spots.first.x) / 8)
            .clamp(1, double.infinity),
        getTitlesWidget: (v, _) {
          final m = v ~/ 60;
          final s = (v % 60).toInt();
          return Text('$m:${s.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10));
        },
      ),
    ),
    leftTitles: AxisTitles(
      axisNameWidget: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(yLabel,
            style:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      axisNameSize: 24,
      sideTitles: SideTitles(
        showTitles  : true,
        reservedSize: 40,
        interval    : 20,
        getTitlesWidget: (v, _) =>
            Text(v.toInt().toString(),
                style: const TextStyle(fontSize: 10)),
      ),
    ),
    rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false)),
    topTitles  : const AxisTitles(
        sideTitles: SideTitles(showTitles: false)),
  );

  Widget _statsRow(BuildContext ctx, double maxY, double minY, double avgY,
      double auc) =>
      Padding(
        padding: const EdgeInsets.all(16),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _card(ctx, 'Máximo', '${maxY.toStringAsFixed(2)} ppm'),
              const SizedBox(width: 12),
              _card(ctx, 'Mínimo', '${minY.toStringAsFixed(2)} ppm'),
              const SizedBox(width: 12),
              _card(ctx, 'Promedio', '${avgY.toStringAsFixed(2)} ppm'),
              const SizedBox(width: 12),
              _card(ctx, 'Área (AUC)', '${auc.toStringAsFixed(2)} ppm·s'),
            ],
          ),

      );

  Widget _card(BuildContext ctx, String t, String v) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(t, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(v,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  double _auc(List<FlSpot> s) {
    double area = 0;
    for (var i = 1; i < s.length; i++) {
      area += (s[i].x - s[i - 1].x) * ((s[i].y + s[i - 1].y) / 2);
    }
    return area;
  }

  Widget _empty(BuildContext ctx, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Monitoreo de Ozono',
            style: Theme.of(ctx).textTheme.headlineSmall,
            textAlign: TextAlign.center),
      ),
      AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: c,
          child: const Center(child: Text('Sin datos aún')),
        ),
      ),
    ],
  );
}