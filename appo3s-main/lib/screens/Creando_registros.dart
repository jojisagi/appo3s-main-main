import 'package:appo3s/widgets/timer_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/ozone_chart.dart';
import '../widgets/conductivity_chart.dart';
import '../widgets/ph_chart.dart';
import '../widgets/auc_widget.dart';
import '../widgets/record_form.dart';
import '../widgets/editing_samples.dart';
import '../models/muestreo.dart';

class CreandoRegistros extends StatefulWidget {
  const CreandoRegistros({super.key});

  @override
  State<CreandoRegistros> createState() => _CreandoRegistrosState();
}

class _CreandoRegistrosState extends State<CreandoRegistros> {
   Muestreo muestreo = Muestreo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficas')),
      body: _GraphsBody(muestreo: muestreo),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'EditingSamples',
            child: const Icon(Icons.timer),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
                child: EditingSamples(muestreo: muestreo),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'RecordForm',
            child: const Icon(Icons.check),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
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
  final Muestreo muestreo;
  
  const _GraphsBody({required this.muestreo});
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timer en la parte superior
          TimerWidget(muestreo: muestreo),
          const SizedBox(height: 20),
          
          // Gráficas en dos columnas debajo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    const OzoneChart(),
                    const SizedBox(height: 12),
                    const AUCWidget(),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const ConductivityChart(),
                    const SizedBox(height: 12),
                    const PhChart(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}