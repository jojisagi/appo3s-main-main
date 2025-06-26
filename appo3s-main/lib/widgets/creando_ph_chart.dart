// widgets/creando_ph_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/muestreo.dart';
import '../models/sample.dart';

class Creando_PhChart extends StatelessWidget {
  final Muestreo muestreo;
  const Creando_PhChart({super.key, required this.muestreo});

  @override
  Widget build(BuildContext context) {
    const Color emphColor = Color.fromARGB(255, 238, 159, 159);
    final List<Sample> samples = muestreo.samples;

    /* ────────── SIN DATOS ────────── */
    if (samples.isEmpty) return _empty(context, emphColor);

    /* ────────── puntos ────────── */
    // 1. lista original convertida a FlSpot
    final original = samples
        .map((s) => FlSpot(
      (s.selectedMinutes * 60 + s.selectedSeconds).toDouble(),
      s.y,
    ))
        .toList();

    // 2. si el primer dato NO está en t=0, añadimos un “punto fantasma”
    final List<FlSpot> spots;
    if (original.first.x == 0) {
      spots = original;
    } else {
      spots = [FlSpot(0, original.first.y)]..addAll(original);
    }

    /* ────────── stats rápidas ────────── */
    final ys   = samples.map((e) => e.y).toList();
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final avgY = ys.fold<double>(0, (p, c) => p + c) / ys.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Monitoreo de pH',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
        ),

        /* ────────── GRÁFICA ────────── */
        AspectRatio(
          aspectRatio: 16 / 9,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: spots.last.x,
              minY: 0,
              maxY: 14,

              gridData: const FlGridData(
                show: true,
                horizontalInterval: 1, // cada 1 pH
              ),

              lineBarsData: [
                LineChartBarData(
                  spots   : spots,
                  isCurved: true,
                  barWidth: 2,
                  color   : Colors.blue,
                  dotData : const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show : true,
                    color: emphColor.withOpacity(.25),
                  ),
                ),
              ],

              titlesData: FlTitlesData(
                /* — eje X etiquetado en mm:ss — */
                bottomTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text(
                      'min:seg', // o  'µS/cm'
                      style:
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: ((spots.last.x - spots.first.x) / 8)
                        .clamp(1, double.infinity),
                    getTitlesWidget: (v, _) {
                      final m = v ~/ 60;
                      final s = (v % 60).toInt();
                      return Text('$m:${s.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10));
                    },
                    reservedSize: 32,
                  ),
                ),
                /* — eje Y cada unidad de pH — */
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    reservedSize: 28,
                  ),
                ),
                rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles :
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),

              borderData: FlBorderData(show: true),
            ),
          ),
        ),

        const SizedBox(height: 8),

        /* ────────── TARJETAS DE STATS ────────── */
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statCard(context, 'Máximo', maxY.toStringAsFixed(2)),
            _statCard(context, 'Mínimo', minY.toStringAsFixed(2)),
            _statCard(context, 'Promedio', avgY.toStringAsFixed(2)),
          ],
        ),
      ],
    );
  }

  /* ────────── helpers ────────── */

  Widget _empty(BuildContext ctx, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Monitoreo de pH',
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

  Widget _statCard(BuildContext context, String t, String v) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(t,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(v,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}
