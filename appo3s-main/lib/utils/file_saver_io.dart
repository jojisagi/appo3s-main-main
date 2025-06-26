import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/muestreo.dart';

String _fmtTime(int m, int s) => '${m.toString().padLeft(2, '0')}:'
    '${s.toString().padLeft(2, '0')}';

String _muestreoTxt(String titulo, Muestreo m) {
  final b = StringBuffer('\n$titulo\n');
  for (final s in m.samples) {
    b.writeln('  • (${_fmtTime(s.selectedMinutes, s.selectedSeconds)}) → '
        '${s.y.toStringAsFixed(4)}');
  }
  return b.toString();
}

String _muestreoCsv(String serie, Muestreo m) {
  final b = StringBuffer();
  for (final s in m.samples) {
    b.writeln('$serie,${_fmtTime(s.selectedMinutes, s.selectedSeconds)},'
        '${s.y}');
  }
  return b.toString();
}

/* ─────────────────────────── TXT ─────────────────────────── */
Future<void> saveToTxt(
    BuildContext context,
    String   contaminante,
    double   concentracion,
    DateTime fechaHora,
    Muestreo muestreoOzone,
    Muestreo muestreoPh,
    Muestreo muestreoConductivity,
    ) async {
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo TXT',
      fileName   : 'muestreo_${DateTime.now().millisecondsSinceEpoch}.txt',
      allowedExtensions: ['txt'],
    );
    if (path == null) return;

    final txt = '''
Registro de Muestreo
=====================
Contaminante  : $contaminante
Concentración : ${concentracion.toStringAsFixed(4)} ppm
Fecha/Hora    : $fechaHora

PUNTOS (t = mm:ss,  y = valor)

${_muestreoTxt('OZONO (ppm)',          muestreoOzone)}
${_muestreoTxt('pH (unidades)',        muestreoPh)}
${_muestreoTxt('CONDUCTIVIDAD (µS/cm)',muestreoConductivity)}
''';

    await File(path).writeAsString(txt);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Archivo guardado en: $path')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

/* ─────────────────────────── CSV ─────────────────────────── */
Future<void> saveToCsv(
    BuildContext context,
    String   contaminante,
    double   concentracion,
    DateTime fechaHora,
    Muestreo muestreoOzone,
    Muestreo muestreoPh,
    Muestreo muestreoConductivity,
    ) async {
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo CSV',
      fileName   : 'muestreo_${DateTime.now().millisecondsSinceEpoch}.csv',
      allowedExtensions: ['csv'],
    );
    if (path == null) return;

    final b = StringBuffer();
    b.writeln('contaminante,concentracion,fecha_hora');
    b.writeln('$contaminante,$concentracion,$fechaHora\n');

    b.writeln('serie,t,valor');
    b.write(_muestreoCsv('ozone'       , muestreoOzone));
    b.write(_muestreoCsv('ph'          , muestreoPh));
    b.write(_muestreoCsv('conductivity', muestreoConductivity));

    await File(path).writeAsString(b.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Archivo guardado en: $path')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
