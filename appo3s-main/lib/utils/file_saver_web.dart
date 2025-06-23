// File: lib/utils/file_saver_web.dart
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../models/muestreo.dart';



void saveToTxt(BuildContext context,
   Text contaminante,
   Text concentracion,
   Text fechaHora,
    Muestreo muestreo_ozone,  
    Muestreo muestreo_ph,
    Muestreo muestreo_conductivity
)  async

 {
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

  void saveToCsv
  (BuildContext context,
   Text contaminante,
   Text concentracion,
   Text fechaHora,
    Muestreo muestreo_ozone,  
    Muestreo muestreo_ph,
    Muestreo muestreo_conductivity
)  async
   {
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