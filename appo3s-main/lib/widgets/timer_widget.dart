import 'package:flutter/material.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});
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
