import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

import '../models/muestreo.dart';

/// ─── helpers ──────────────────────────────────────────────────────────
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

/// ─── exportar TXT ─────────────────────────────────────────────────────
void saveToTxt(
    BuildContext context,
    String contaminante,
    double concentracion,
    DateTime fechaHora,
    Muestreo muestreoOzone,
    Muestreo muestreoPh,
    Muestreo muestreoConductivity,
    Muestreo muestreoTemperatura,
    ) {
  final content = '''
Registro de Muestreo
=====================
Contaminante  : $contaminante
Concentración : ${concentracion.toStringAsFixed(4)} ppm
Fecha/Hora    : $fechaHora

PUNTOS (t = mm:ss,  y = valor)

${_muestreoTxt('OZONO (ppm)',          muestreoOzone)}
${_muestreoTxt('TEMPERATURA (°C))',muestreoTemperatura)}
${_muestreoTxt('pH (unidades)',        muestreoPh)}
${_muestreoTxt('CONDUCTIVIDAD (µS/cm)',muestreoConductivity)}
''';

  final bytes = utf8.encode(content);
  final blob  = html.Blob([bytes], 'text/plain');
  final url   = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download',
        'muestreo_${DateTime.now().millisecondsSinceEpoch}.txt')
    ..click();

  html.Url.revokeObjectUrl(url);
}

/// ─── exportar CSV ─────────────────────────────────────────────────────
void saveToCsv(
    BuildContext context,
    String contaminante,
    double concentracion,
    DateTime fechaHora,
    Muestreo muestreoOzone,
    Muestreo muestreoPh,
    Muestreo muestreoConductivity,
    Muestreo muestreoTemperatura
    ) {
  final b = StringBuffer();
  b.writeln('contaminante,concentracion,fecha_hora');
  b.writeln('$contaminante,$concentracion,$fechaHora\n');

  b.writeln('serie,t,valor');
  b.write(_muestreoCsv('ozone'       , muestreoOzone));
  b.write(_muestreoCsv('temperature'     , muestreoTemperatura));
  b.write(_muestreoCsv('ph'          , muestreoPh));
  b.write(_muestreoCsv('conductivity', muestreoConductivity));

  final bytes = utf8.encode(b.toString());
  final blob  = html.Blob([bytes], 'text/csv');
  final url   = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download',
        'muestreo_${DateTime.now().millisecondsSinceEpoch}.csv')
    ..click();

  html.Url.revokeObjectUrl(url);
}
