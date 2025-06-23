import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../widgets/creando_ozone_chart.dart';
import '../widgets/creando_conductivity_chart.dart';
import '../widgets/creando_ph_chart.dart';
import '../widgets/record_widget_simple.dart';
import '../models/muestreo.dart';

class VisualizandoRegistros extends StatefulWidget {
  final Text contaminante;
  final Text concentracion;
  final Text fechaHora;
  Muestreo muestreo_ozone = Muestreo();
  Muestreo muestreo_ph = Muestreo();
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

  void _saveToTxtWeb() {
    final String content = """
Registro de Muestreo
=====================
Contaminante: ${contaminante.data}
Concentración: ${concentracion.data}
Fecha/Hora: ${fechaHora.data}

Datos completos:
${muestreo_ozone.toString()}
${muestreo_ph.toString()}
${muestreo_conductivity.toString()}
""";

    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "muestreo_${DateTime.now().millisecondsSinceEpoch}.txt")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _saveToCsvWeb() {
    final StringBuffer content = StringBuffer();
    content.writeln('Contaminante,Concentración,Fecha/Hora');
    content.writeln('${contaminante.data},${concentracion.data},${fechaHora.data}');

    final bytes = utf8.encode(content.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "muestreo_${DateTime.now().millisecondsSinceEpoch}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
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

          // Botones para guardar
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _saveToTxtWeb,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(120, 40),
                    ),
                    child: const Text('Guardar en txt', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _saveToCsvWeb,
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

          // Gráficas
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
