// Crea el grafico de ozono para el muestreo
import 'package:appo3s/models/muestreo.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/record_service.dart';
import '../models/sample.dart';

class Creando_OzoneChart extends StatelessWidget {
  Muestreo muestreo ;
  Creando_OzoneChart({super.key, required this.muestreo});
  @override
  Widget build(BuildContext context) {

    const Color empahisisColor = const Color.fromARGB(255, 159, 206, 238);
    List<Sample> _samples =   muestreo.samples; 

    
    if (_samples.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Monitoreo de Ozono',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: empahisisColor,
              child: const Center(child: Text('Sin datos aún')),
            ),
          ),
        ],
      );
    }

    // Convertir muestras a puntos del gráfico
    final spots = _samples
        .map((r) => FlSpot(
              (r.selectedMinutes * 60 + r.selectedSeconds).toDouble(), // Segundos totales
              r.y ?? 0.0,
            ))
        .toList();

    final minX = spots.first.x;
    final maxX = spots.last.x;

    final minY= spots.first.y;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Calcular estadísticas (asumiendo que 'concentracion' es lo mismo que 'y')
    final maxConc = _samples.map((r) => r.y ?? 0).reduce((a, b) => a > b ? a : b);
    final minConc = _samples.map((r) => r.y ?? 0).reduce((a, b) => a < b ? a : b);
    final avgConc = _samples.map((r) => r.y ?? 0).reduce((a, b) => a + b) / _samples.length;
    final auc = calculateAUC(spots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Monitoreo de Ozono',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        
        AspectRatio(
          aspectRatio: 16 / 9,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: maxY*-1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: empahisisColor.withOpacity(0.3),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final minutes = (value ~/ 60);
                      final seconds = (value % 60).toInt();
                      return Text(
                        '$minutes:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(context, 'Máximo', '${maxConc.toStringAsFixed(2)} ppm'),
              _buildStatCard(context, 'Mínimo', '${minConc.toStringAsFixed(2)} ppm'),
              _buildStatCard(context, 'Promedio', '${avgConc.toStringAsFixed(2)} ppm'),
              _buildStatCard(context, 'Área (AUC)', '${auc.toStringAsFixed(2)} ppm·s'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
  // Widget para tarjetas de estadísticas
  Widget _buildStatCard(BuildContext context, String title, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }


 



double calculateAUC(List<FlSpot> spots) {
  double area = 0.0;
  for (int i = 1; i < spots.length; i++) {
    final x1 = spots[i - 1].x;
    final y1 = spots[i - 1].y;
    final x2 = spots[i].x;
    final y2 = spots[i].y;
    
    // Fórmula del trapecio: Área entre dos puntos = (base) * (altura promedio)
    final base = x2 - x1;  // Diferencia en tiempo (eje X)
    final avgHeight = (y1 + y2) / 2;  // Promedio de concentración (eje Y)
    area += base * avgHeight;
  }
  return area;
}