import 'package:flutter/material.dart';
import '../widgets/creando_ozone_chart.dart';
import '../widgets/creando_conductivity_chart.dart';
import '../widgets/creando_ph_chart.dart';
import '../widgets/record_widget_simple.dart';
import '../models/muestreo.dart';

class VisualizandoRegistros extends StatefulWidget {
  final Text contaminante;
  final Text concentracion;
  final Text fechaHora;

  const VisualizandoRegistros({
    super.key,
    required this.fechaHora,
    required this.contaminante,
    required this.concentracion,
  });

  @override
  State<VisualizandoRegistros> createState() => _VisualizandoRegistrosState();
}

class _VisualizandoRegistrosState extends State<VisualizandoRegistros> {
  late Muestreo muestreo_ozone;
  late Muestreo muestreo_ph;
  late Muestreo muestreo_conductivity;
  late Muestreo muestreo_time;

  @override
  void initState() {
    super.initState();
    muestreo_ozone = Muestreo();
    muestreo_ph = Muestreo();
    muestreo_conductivity = Muestreo();
    muestreo_time = Muestreo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: _GraphsBody(
        muestreo_ozone: muestreo_ozone,
        muestreo_ph: muestreo_ph,
        muestreo_conductivity: muestreo_conductivity,
        muestreo_time: muestreo_time,
        fechaHora: widget.fechaHora,
        contaminante: widget.contaminante,
        concentracion: widget.concentracion,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [],
      ),
    );
  }
}

class _GraphsBody extends StatelessWidget {
  final Muestreo muestreo_ozone;
  final Muestreo muestreo_ph;
  final Muestreo muestreo_conductivity;
  final Muestreo muestreo_time;
  final Text contaminante;
  final Text concentracion;
  final Text fechaHora;

  const _GraphsBody({
    required this.muestreo_ozone,
    required this.muestreo_ph,
    required this.muestreo_conductivity,
    required this.muestreo_time,
    required this.fechaHora,
    required this.contaminante,
    required this.concentracion,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          record_widget_simple(
            contaminante: contaminante,
            concentracion: concentracion,
            fechaHora: fechaHora,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Creando_OzoneChart(muestreo: muestreo_ozone),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Creando_ConductivityChart(muestreo: muestreo_conductivity),
                    const SizedBox(height: 12),
                    Creando_PhChart(muestreo: muestreo_ph),
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