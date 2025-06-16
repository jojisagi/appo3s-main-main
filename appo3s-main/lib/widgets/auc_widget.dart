import 'package:flutter/material.dart';

class AUCWidget extends StatelessWidget {
  const AUCWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Center(child: Text('Área bajo la curva:')),
          const SizedBox(width: 8),
          Text('0.0'),
           const SizedBox(width: 8),
          ElevatedButton(onPressed: () {}, child: const Text('Calcular')),
        ],
      ),
    );
  }
}
