import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/muestreo.dart';
import '../models/sample.dart';

class Creando_temp_Chart extends StatelessWidget {
  const Creando_temp_Chart({
    super.key,
    required this.muestreo,
    this.useViewport = false,
  });

  final Muestreo muestreo;
  final bool     useViewport;

  @override
  Widget build(BuildContext context) {
    const Color emphColor = Color.fromARGB(255, 240, 147, 239);

    final List<Sample> data = useViewport
        ? ((muestreo as dynamic).inView as List<Sample>? ?? muestreo.samples)
        : muestreo.samples;

    if (data.isEmpty) return _empty(context, emphColor);

    final original = data
        .map((s) => FlSpot(
      (s.selectedMinutes * 60 + s.selectedSeconds).toDouble(),
      s.y,
    ))
        .toList();

    final List<FlSpot> spots = original.first.x == 0
        ? original
        : [FlSpot(0, original.first.y), ...original];

    final ys   = data.map((e) => e.y).toList();
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final avgY = ys.reduce((a, b) => a + b) / ys.length;

    final maxYaxis = maxY < 100 ? 100 : (maxY * 1.1).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Monitoreo de temperatura',
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
              maxY: 100,
              gridData: const FlGridData(
                show: true,
                horizontalInterval: 5,

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
              titlesData: _titlesData(spots),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _statsRow(context, maxY, minY, avgY),
      ],
    );
  }

  /* ─ Helpers ─ */

  FlTitlesData _titlesData(List<FlSpot> spots) => FlTitlesData(
    bottomTitles: AxisTitles(
      axisNameWidget: const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('min:seg',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      sideTitles: SideTitles(
        showTitles  : true,
        reservedSize: 32,
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
      axisNameWidget: const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Text('C',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      axisNameSize: 24,
      sideTitles: SideTitles(
        showTitles  : true,
        interval    : 10,
        reservedSize: 28,
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

  Widget _statsRow(BuildContext ctx, double maxY, double minY, double avgY) =>
      Padding(
        padding: const EdgeInsets.all(16),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              _card(ctx, 'Máximo', maxY.toStringAsFixed(2)),
              const SizedBox(width: 12),
              _card(ctx, 'Mínimo', minY.toStringAsFixed(2)),
              const SizedBox(width: 12),
              _card(ctx, 'Promedio', avgY.toStringAsFixed(2)),
            ],
          ),

      );

  Widget _card(BuildContext ctx, String t, String v) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(t,
              style:
              Theme.of(ctx).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              )),
          const SizedBox(height: 4),
          Text(v,
              style: Theme.of(ctx)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _empty(BuildContext ctx, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Monitoreo de temperatura',
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