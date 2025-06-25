// lib/widgets/creando_conductivity_chart.dart
//
// Gráfica de Conductividad Eléctrica para un Muestreo
// --------------------------------------------------
// • Eje Y:   0 – 2000 µS  (tick cada 400)
// • Eje X:   tiempo (mm:ss)
// • Estadísticas rápidas (máx, mín, prom)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:appo3s/models/muestreo.dart';
import 'package:appo3s/models/sample.dart';

class Creando_ConductivityChart extends StatelessWidget {
  const Creando_ConductivityChart({super.key, required this.muestreo});
  final Muestreo muestreo;

  @override
  Widget build(BuildContext context) {
    const emphColor = Color.fromARGB(255, 226, 238, 159);
    final samples   = muestreo.samples;

    /* ────────── SIN DATOS ────────── */
    if (samples.isEmpty) {
      return _empty(context, emphColor);
    }

    /* ────────── Conversión a puntos ────────── */
    final original = samples
        .map((s) => FlSpot(
      (s.selectedMinutes * 60 + s.selectedSeconds).toDouble(),
      s.y ?? 0.0,
    ))
        .toList();

    // ► Punto fantasma en t = 0   (para arrancar desde el origen)
    final List<FlSpot> spots;
    if (original.first.x == 0) {
      spots = original;
    } else {
      spots = [FlSpot(0, original.first.y)]..addAll(original);
    }

    /* ────────── Estadísticas rápidas ────────── */
    final ys   = samples.map((s) => s.y ?? 0.0).toList();
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final avgY = ys.fold<double>(0, (p, c) => p + c) / ys.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Monitoreo de Conductividad',
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
              maxY: 2000,

              gridData: const FlGridData(
                show: true,
                horizontalInterval: 200, // cada 200 µS
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  color: Colors.blue,
                  dotData: const FlDotData(show: true),
                  belowBarData:
                  BarAreaData(show: true, color: emphColor.withOpacity(.3)),
                ),
              ],

              titlesData: FlTitlesData(
                /* ── Eje X: mm:ss ── */
                bottomTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('min:seg',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  axisNameSize: 24,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: ((spots.last.x - spots.first.x) / 8)
                        .clamp(1, double.infinity),
                    getTitlesWidget: (v, _) {
                      final m = v ~/ 60;
                      final s = (v % 60).toInt();
                      return Text('$m:${s.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),

                /* ── Eje Y: µS ── */
                leftTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('µS/cm',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  axisNameSize: 24,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    interval: 400,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),

              borderData: FlBorderData(show: true),
            ),
          ),
        ),

        const SizedBox(height: 8),

        /* ────────── TARJETAS DE STATS ────────── */
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard(context, 'Máximo', '${maxY.toStringAsFixed(2)} µS'),
              _statCard(context, 'Mínimo', '${minY.toStringAsFixed(2)} µS'),
              _statCard(context, 'Promedio', '${avgY.toStringAsFixed(2)} µS'),
            ],
          ),
        ),
      ],
    );
  }

  /* ─── Tarjeta reutilizable ─── */
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

  /* ─────────── Placeholder cuando no hay datos ─────────── */
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
