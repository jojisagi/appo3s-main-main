import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/esp32_service.dart';
import '../models/record.dart';

class GraphsScreen extends StatelessWidget {
  const GraphsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1- Instancia del servicio con la IP de tu ESP32
    final esp = Esp32Service(
      esp32Ip       : '192.168.1.55',   // ⬅️ cámbiala por la tuya
      syncToBackend : true,
    )..startPolling();

    return ChangeNotifierProvider.value(
      value: esp,
      child: const _GraphsBody(),
    );
  }
}

class _GraphsBody extends StatelessWidget {
  const _GraphsBody();

  // ------- Widget de gráfica reutilizable --------
  Widget _chart({
    required List<Record> puntos,
    required Color color,
  }) {
    if (puntos.isEmpty) return const Center(child: Text('Sin datos'));

    final spots = puntos.map(
          (r) => FlSpot(
        r.fechaHora.millisecondsSinceEpoch.toDouble(),
        r.concentracion,
      ),
    ).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        gridData  : const FlGridData(show: true, horizontalInterval: .1),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (spots.length / 4).clamp(1, 999).toDouble(),
              getTitlesWidget: (v, _) => Text(
                DateFormat.Hms().format(
                  DateTime.fromMillisecondsSinceEpoch(v.toInt()),
                ),
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots    : spots,
            isCurved : true,
            barWidth : 2,
            color    : color,
            dotData  : FlDotData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 150),
      // swapAnimationCurve: Curves.easeInOut,   // opcional
    );
  }

  @override
  Widget build(BuildContext context) {
    final srv  = context.watch<Esp32Service>();

    final o3   = srv.buffer['o3']   ?? <Record>[];
    final cond = srv.buffer['cond'] ?? <Record>[];
    final ph   = srv.buffer['ph']   ?? <Record>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Gráficas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ---- O₃ tiempo real ----
            SizedBox(
              height: 260,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _chart(puntos: o3, color: Colors.cyan),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ---- Conductividad & pH ----
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 180,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _chart(puntos: cond, color: Colors.green),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 180,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _chart(puntos: ph, color: Colors.deepPurple),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
