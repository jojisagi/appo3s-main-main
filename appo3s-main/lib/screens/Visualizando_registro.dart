import 'package:flutter/material.dart';
import '../widgets/creando_ozone_chart.dart';
import '../widgets/creando_conductivity_chart.dart';
import '../widgets/creando_ph_chart.dart';
import '../widgets/record_widget_simple.dart';
import '../models/muestreo.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../utils/file_saver.dart';


class VisualizandoRegistros extends StatefulWidget {
  final Text contaminante;
  final Text concentracion;
  final Text fechaHora;
  Muestreo muestreo_ozone = Muestreo();
  Muestreo muestreo_ph= Muestreo();
   Muestreo muestreo_conductivity = Muestreo();


   VisualizandoRegistros({
    super.key,
    required this.fechaHora,
    required this.contaminante,
    required this.concentracion,
    required this.muestreo_ozone,
    required this.muestreo_ph,
    required this.muestreo_conductivity,

  });

  @override
  State<VisualizandoRegistros> createState() => _VisualizandoRegistrosState();
}


class _VisualizandoRegistrosState extends State<VisualizandoRegistros> {

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: _GraphsBody(
        muestreo_ozone: widget.muestreo_ozone,
        muestreo_ph: widget.muestreo_ph,
        muestreo_conductivity: widget.muestreo_conductivity,
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
  final Text contaminante;
  final Text concentracion;
  final Text fechaHora;

  const _GraphsBody({
    required this.muestreo_ozone,
    required this.muestreo_ph,
    required this.muestreo_conductivity,
    required this.fechaHora,
    required this.contaminante,
    required this.concentracion,
  });

Future<void> _saveToTxt(BuildContext context) async {
  saveToTxt(
    context,
    contaminante,
    concentracion,
    fechaHora,
    muestreo_ozone,
    muestreo_ph,
    muestreo_conductivity,
  );
}

Future<void> _saveToCsv(BuildContext context) async {
  saveToCsv(
    context,
    contaminante,
    concentracion,
    fechaHora,
    muestreo_ozone,
    muestreo_ph,
    muestreo_conductivity,
  );
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Widget de registro
          record_widget_simple(
            contaminante: contaminante,
            concentracion: concentracion,
            fechaHora: fechaHora,
          ),

          const SizedBox(height: 20),

          // Contenedor para los botones centrados
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _saveToTxt(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(120, 40),
                    ),
                    child: const Text('Guardar en txt', style: TextStyle(fontSize: 14)),
                  ),

                  const SizedBox(width: 20),

                  ElevatedButton(
                    onPressed: () => _saveToCsv(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(120, 40),
                    ),
                    child: const Text('Guardar en csv', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Gráficos
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /* ────── O₃ (toma todo el ancho) ────── */
              Expanded(                      // o SizedBox(height: 260) si prefieres altura fija
                flex: 1,                     // opcional: lo hace más alto que los de abajo
                child: Creando_OzoneChart(
                  muestreo: muestreo_ozone,
                  key: ValueKey(muestreo_ozone.hashCode),
                ),
              ),
              const SizedBox(height: 12),

              /* ────── fila con Conduct y pH ────── */
              Expanded(                      // ocupa el resto del espacio vertical
                flex: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Creando_ConductivityChart(
                        muestreo: muestreo_conductivity,
                        key: ValueKey(muestreo_conductivity.hashCode),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Creando_PhChart(
                        muestreo: muestreo_ph,
                        key: ValueKey(muestreo_ph.hashCode),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}