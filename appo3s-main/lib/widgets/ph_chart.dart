import 'package:flutter/material.dart';

class PhChart extends StatelessWidget {
  const PhChart({super.key});
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.purple.shade50,
        child: const Center(child: Text('Gráfica pH')),
      ),
    );
  }
}
