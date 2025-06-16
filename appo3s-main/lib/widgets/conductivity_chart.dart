import 'package:flutter/material.dart';

class ConductivityChart extends StatelessWidget {
  const ConductivityChart({super.key});
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.green.shade50,
        child: const Center(child: Text('Gráfica Conductividad')),
      ),
    );
  }
}
