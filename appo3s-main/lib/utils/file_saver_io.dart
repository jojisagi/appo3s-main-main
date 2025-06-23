// File: lib/utils/file_saver_io.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/muestreo.dart';



Future<void> saveToTxt(BuildContext context,
   Text contaminante,
   Text concentracion,
   Text fechaHora,
    Muestreo muestreo_ozone,  
    Muestreo muestreo_ph,
    Muestreo muestreo_conductivity
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
  Future<void> saveToCsv(BuildContext context,
   Text contaminante,
   Text concentracion,
   Text fechaHora,
    Muestreo muestreo_ozone,  
    Muestreo muestreo_ph,
    Muestreo muestreo_conductivity
) 
  
  
   async {
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