// lib/widgets/creando_conductivity_chart.dart
// Gráfica de Conductividad Eléctrica para un Muestreo

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:appo3s/models/muestreo.dart';
import 'package:appo3s/models/sample.dart';

class Creando_ConductivityChart extends StatelessWidget {
  final Muestreo muestreo;
  const Creando_ConductivityChart({super.key, required this.muestreo});

  @override
  Widget build(BuildContext context) {
    const Color emphColor = Color.fromARGB(255, 226, 238, 159);
    final List<Sample> samples = muestreo.samples;

    /* ───────────── Sin datos ───────────── */
    if (samples.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Monitoreo de Conductividad',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: emphColor,
              child: const Center(child: Text('Sin datos aún')),
            ),
          ),
        ],
      );
    }

    /* ───────────── Conversión a puntos ───────────── */
    final spots = samples
        .map((s) => FlSpot(
      (s.selectedMinutes * 60 + s.selectedSeconds).toDouble(),
      s.y ?? 0.0,
    ))
        .toList();

    /* ───────────── Estadísticas ───────────── */
    final maxYVal = samples.map((s) => s.y ?? 0).reduce((a, b) => a > b ? a : b);
    final minYVal = samples.map((s) => s.y ?? 0).reduce((a, b) => a < b ? a : b);
    final avgYVal =
        samples.map((s) => s.y ?? 0).reduce((a, b) => a + b) / samples.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Monitoreo de Conductividad',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
        ),

        /* ───────────── Gráfica ───────────── */
        AspectRatio(
          aspectRatio: 16 / 9,
          child: LineChart(
            LineChartData(
              // >>> ejes solicitados <<<
              minX : spots.isEmpty ? 0 : spots.first.x,
              maxX: spots.isEmpty ? 0 : spots.last.x,
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
                // —— eje X: mm:ss ——
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, _) {
                      final m = value ~/ 60;
                      final s = (value % 60).toInt();
                      return Text(
                        '$m:${s.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                // —— eje Y: 0-2000 µS ——
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 400, // etiqueta cada 400 µS (para no saturar)
                    getTitlesWidget: (value, _) => Text(
                      '${value.toInt()}',
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

        /* ───────────── Tarjetas estadísticas ───────────── */
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard(context, 'Máximo', '${maxYVal.toStringAsFixed(2)} µS'),
              _statCard(context, 'Mínimo', '${minYVal.toStringAsFixed(2)} µS'),
              _statCard(context, 'Promedio', '${avgYVal.toStringAsFixed(2)} µS'),
            ],
          ),
        ),
      ],
    );
  }

  /* — Tarjeta reutilizable — */
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
}
