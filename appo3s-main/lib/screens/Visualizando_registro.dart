import 'package:flutter/material.dart';
import '../widgets/creando_ozone_chart.dart';
import '../widgets/creando_conductivity_chart.dart';
import '../widgets/creando_ph_chart.dart';
import '../widgets/record_widget_simple.dart';
import '../models/muestreo.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

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

Future<void> _saveToTxt(BuildContext context,
   Text contaminante,
   Text concentracion,
   Text fechaHora


) async {
    try {
      // Pedir al usuario donde guardar
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo TXT',
        fileName: 'muestreo_${DateTime.now().millisecondsSinceEpoch}.txt',
        allowedExtensions: ['txt'],
      );
      
      if (outputPath != null) {
        final file = File(outputPath);
        String content = """
Registro de Muestreo
=====================
Contaminante: ${contaminante}
Concentración: ${concentracion}
Fecha/Hora: ${fechaHora}

Datos completos:
${muestreo_ozone.toString()}
${muestreo_ph.toString()}
${muestreo_conductivity.toString()}
""";
        await file.writeAsString(content);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo guardado en: $outputPath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Implementación similar para _saveToCsv()
  Future<void> _saveToCsv(BuildContext context) async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo CSV',
        fileName: 'muestreo_${DateTime.now().millisecondsSinceEpoch}.csv',
        allowedExtensions: ['csv'],
      );
      
      if (outputPath != null) {
        final file = File(outputPath);
        StringBuffer content = StringBuffer();
        content.writeln('Tipo,Fecha,Valor');
        
        // Agregar datos al CSV (igual que en el ejemplo anterior)
        
        
        await file.writeAsString(content.toString());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo CSV guardado en: $outputPath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
                    onPressed: () => _saveToTxt(context, contaminante, concentracion, fechaHora),
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