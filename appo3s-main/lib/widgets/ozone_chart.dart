import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/record_service.dart';

class OzoneChart extends StatelessWidget {
  const OzoneChart({super.key});
  @override
  Widget build(BuildContext context) {
    final records = context.watch<RecordService>().records;
    if (records.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.blueGrey.shade50,
          child: const Center(child: Text('Sin datos aún')),
        ),
      );
    }

    final spots = records
        .map((r) => FlSpot(
      r.fechaHora.millisecondsSinceEpoch.toDouble(),
      r.concentracion,
    ))
        .toList();

    final minX = spots.first.x;
    final maxX = spots.last.x;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text(
                  DateFormat.Hm().format(
                    DateTime.fromMillisecondsSinceEpoch(value.toInt()),
                  ),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles:
              SideTitles(showTitles: true, reservedSize: 40),
            ),
          ),
        ),
      ),
    );
  }
}
