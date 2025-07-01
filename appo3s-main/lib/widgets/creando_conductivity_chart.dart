import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/muestreo.dart';
import '../models/sample.dart';

class Creando_ConductivityChart extends StatelessWidget {
  const Creando_ConductivityChart({
    super.key,
    required this.muestreo,
    this.useViewport = false,
  });

  final Muestreo muestreo;
  final bool     useViewport;

  @override
  Widget build(BuildContext context) {
    const emphColor = Color.fromARGB(255, 226, 238, 159);

    // Usa el viewport si existe; de lo contrario, todos los samples.
    final List<Sample> data = useViewport
        ? ((muestreo as dynamic).inView as List<Sample>? ?? muestreo.samples)
        : muestreo.samples;

    /* ───── Sin datos ───── */
    if (data.isEmpty) return _empty(context, emphColor);

    /* ───── Conversión a FlSpot ───── */
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

    // Eje Y se expande si el máximo real supera 2 000 µS.
    final maxYaxis = maxY < 2000 ? 2000.0 : (maxY * 1.1).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Monitoreo de Conductividad',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        /* ─── Gráfica ─── */
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
                horizontalInterval: 200,
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
                    show  : true,
                    color : emphColor.withOpacity(.30),
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

  /* ─ Helpers UI ─ */

  FlTitlesData _titlesData(List<FlSpot> spots) => FlTitlesData(
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
      axisNameWidget: const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Text('µS/cm',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      axisNameSize: 24,
      sideTitles: SideTitles(
        showTitles  : true,
        reservedSize: 46,
        interval    : 400,
        getTitlesWidget: (v, _) =>
            Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
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
            _statCard(ctx, 'Máximo', '${maxY.toStringAsFixed(2)} µS'),
            _statCard(ctx, 'Mínimo', '${minY.toStringAsFixed(2)} µS'),
            _statCard(ctx, 'Promedio', '${avgY.toStringAsFixed(2)} µS'),
          ],
        ),
      );

  Widget _statCard(BuildContext ctx, String t, String v) => Card(
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

  Widget _empty(BuildContext ctx, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Monitoreo de Conductividad',
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
