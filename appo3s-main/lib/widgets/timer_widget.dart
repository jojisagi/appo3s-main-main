import 'package:appo3s/models/muestreo.dart';
import 'package:flutter/material.dart';

class TimerWidget extends StatelessWidget {
  Muestreo muestreo = Muestreo();
   TimerWidget({required this.muestreo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Text('Timer')),
          ElevatedButton(onPressed: () {}, child: const Text('Iniciar')),
        ],
      ),
    );
  }
}
