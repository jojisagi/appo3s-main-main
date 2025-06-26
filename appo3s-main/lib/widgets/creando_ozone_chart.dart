// lib/widgets/creando_ozone_chart.dart
//
// Gráfica de Ozono (O₃) para un Muestreo
// -------------------------------------
// • Eje Y:   0 – 100 ppm   (cambia el rango si tu sensor mide otra cosa)
// • Eje X:   tiempo (mm:ss)
// • Estadísticas rápidas y AUC
//

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:appo3s/models/muestreo.dart';

class Creando_OzoneChart extends StatelessWidget {
  const Creando_OzoneChart({super.key, required this.muestreo});
  final Muestreo muestreo;

  @override
  Widget build(BuildContext context) {
    const emphColor = Color.fromARGB(255, 159, 206, 238);
    final samples = muestreo.samples;

    /* ───────────── Sin datos ───────────── */
    if (samples.isEmpty) {
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
            child: Container(
              color: emphColor,
              child: const Center(child: Text('Sin datos aún')),
            ),
          ),
        ],
      );
    }

    /* ───────────── Conversión a puntos ───────────── */
    final original = samples
        .map((s) => FlSpot(
      (s.selectedMinutes * 60 + s.selectedSeconds).toDouble(),
      s.y,
    ))
        .toList();

    // Punto fantasma en t = 0  (para que la curva arranque del origen)
    final List<FlSpot> spots;
    if (original.first.x == 0) {
      spots = original;
    } else {
      spots = [FlSpot(0, original.first.y)]..addAll(original);
    }

    /* ───────────── Estadísticas ───────────── */
    final ys   = samples.map((s) => s.y).toList();
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final avgY = ys.fold<double>(0, (p, c) => p + c) / ys.length;
    final auc  = _calculateAUC(spots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Monitoreo de Ozono',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
        ),

        /* ───────────── Gráfica ───────────── */
        AspectRatio(
          aspectRatio: 16 / 9,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: spots.last.x,
              minY: 0,
              maxY: 100, // ← ajusta si tus datos superan 100 ppm

              gridData: const FlGridData(
                show: true,
                horizontalInterval: 10, // cada 10 ppm
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  color: Colors.blue,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: emphColor.withOpacity(.25),
                  ),
                ),
              ],

              titlesData: FlTitlesData(
                /* ── Eje X: mm:ss ── */
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
                    reservedSize: 40,
                    getTitlesWidget: (v, _) {
                      final m = v ~/ 60;
                      final s = (v % 60).toInt();
                      return Text('$m:${s.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),

                /* ── Eje Y: ppm ── */
                leftTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('ppm',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  axisNameSize: 24,
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20, // etiqueta cada 20 ppm
                    reservedSize: 40,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
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

        /* ───────────── Tarjetas estadísticas ───────────── */
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard(context, 'Máximo', '${maxY.toStringAsFixed(2)} ppm'),
              _statCard(context, 'Mínimo', '${minY.toStringAsFixed(2)} ppm'),
              _statCard(context, 'Promedio', '${avgY.toStringAsFixed(2)} ppm'),
              _statCard(context, 'Área (AUC)',
                  '${auc.toStringAsFixed(2)} ppm·s'),
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

  /* ─── Área bajo la curva (método del trapecio) ─── */
  double _calculateAUC(List<FlSpot> spots) {
    double area = 0;
    for (var i = 1; i < spots.length; i++) {
      final x1 = spots[i - 1].x;
      final y1 = spots[i - 1].y;
      final x2 = spots[i].x;
      final y2 = spots[i].y;
      area += (x2 - x1) * ((y1 + y2) / 2);
    }
    return area;
  }
}
