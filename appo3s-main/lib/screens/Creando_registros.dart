import 'package:appo3s/widgets/timer_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/ozone_chart.dart';
import '../widgets/conductivity_chart.dart';
import '../widgets/ph_chart.dart';
import '../widgets/auc_widget.dart';
import '../widgets/record_form.dart';
import '../widgets/editing_samples.dart';

class Creando_registros extends StatelessWidget {
  const Creando_registros({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficas')),
      body: const _GraphsBody(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'EditingSamples',
            child: const Icon(Icons.timer),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const Padding(
                padding: EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
                child: Editing_samples(),
              ),
            ),
          ),
          const SizedBox(height: 16), // Space between buttons
          FloatingActionButton(
            heroTag: 'RecordForm', // Unique tag required when multiple FABs exist
            child: const Icon(Icons.check),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const Padding(
                padding: EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
                child: RecordForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphsBody extends StatelessWidget {
  const _GraphsBody();
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda (más ancha - proporción 3)
          Expanded(
            flex: 3, // 60% del espacio si la derecha es 2
            child: Column(
              children: [
                TimerWidget(),
                const SizedBox(height: 12),
                const OzoneChart(),
                const SizedBox(height: 12),
                const AUCWidget(),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Columna derecha (más estrecha - proporción 2)
          Expanded(
            flex: 2, // 40% del espacio
            child: Column(
              children: [
                const SizedBox(height: 12),
                const ConductivityChart(),
                const SizedBox(height: 12),
                const PhChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}