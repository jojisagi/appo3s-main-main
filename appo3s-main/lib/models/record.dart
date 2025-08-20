// lib/models/record.dart
import 'package:meta/meta.dart';
import 'muestreo.dart';

@immutable
class Record {
  final String   id;             // opcional (Mongo _id → String)
  final String   contaminante;
  final double   concentracion;
  final DateTime fechaHora;

  final Muestreo muestreoOzone;
  final Muestreo muestreoPh;
  final Muestreo muestreoConductivity;
  final Muestreo muestreoTemperatura;

  const Record({
    this.id = '',
    required this.contaminante,
    required this.concentracion,
    required this.fechaHora,
    required this.muestreoOzone,
    required this.muestreoPh,
    required this.muestreoConductivity,
    required this.muestreoTemperatura
  });

  /* ─── único constructor desde JSON (REST / Mongo) ─── */
  factory Record.fromJson(
      Map<String, dynamic> json, {
        String id = '',
      }) {
    /* --- fechaHora puede venir de varias formas --- */
    final rawFecha = json['fechaHora'];

    DateTime fecha;
    if (rawFecha is DateTime) {
      fecha = rawFecha;
    } else if (rawFecha is int) {
      // milisegundos desde epoch
      fecha = DateTime.fromMillisecondsSinceEpoch(rawFecha);
    } else if (rawFecha is String) {
      fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
    } else {
      fecha = DateTime.now();
    }

    return Record(
      id             : id, // por si lo llamas con BSON _id
      contaminante   : json['contaminante']  as String? ?? '',
      concentracion  : (json['concentracion'] as num?)?.toDouble() ?? 0.0,
      fechaHora      : fecha,
      // Si el campo no existe o es null ⇒ Muestreo vacío
      muestreoOzone       : Muestreo.fromJson(
          (json['muestreo_ozone']       as Map<String,dynamic>?) ?? {}),
      muestreoPh          : Muestreo.fromJson(
          (json['muestreo_ph']          as Map<String,dynamic>?) ?? {}),
      muestreoConductivity: Muestreo.fromJson(
          (json['muestreo_conductivity'] as Map<String,dynamic>?) ?? {}),
       muestreoTemperatura: Muestreo.fromJson(
          (json['muestreo_temperatura'] as Map<String,dynamic>?) ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    // Si usas el _id de Mongo como String lo añades aquí
    if (id.isNotEmpty) 'id': id,
    'contaminante'         : contaminante,
    'concentracion'        : concentracion,
    // Guarda como ISO-8601; en tu API lo puedes convertir si quieres
    'fechaHora'            : fechaHora.toIso8601String(),
    'muestreo_ozone'       : muestreoOzone.toJson(),
    'muestreo_ph'          : muestreoPh.toJson(),
    'muestreo_conductivity': muestreoConductivity.toJson(),
     'muestreo_temperatura': muestreoTemperatura .toJson(),
  };

  /* ─── copias ─── */
  Record copyWith({
    String?   id,
    String?   contaminante,
    double?   concentracion,
    DateTime? fechaHora,
    Muestreo? muestreoOzone,
    Muestreo? muestreoPh,
    Muestreo? muestreoConductivity,
  Muestreo? muestreoTemperatura,
  }) =>
      Record(
        id                   : id ?? this.id,
        contaminante         : contaminante ?? this.contaminante,
        concentracion        : concentracion ?? this.concentracion,
        fechaHora            : fechaHora ?? this.fechaHora,
        muestreoOzone        : muestreoOzone        ?? this.muestreoOzone,
        muestreoPh           : muestreoPh           ?? this.muestreoPh,
        muestreoConductivity : muestreoConductivity ?? this.muestreoConductivity,
        muestreoTemperatura : muestreoTemperatura ?? this.muestreoTemperatura,
      );

  /// Copia profunda (clona los muestreos)
  Record deepCopy() => Record(
    id                   : id,
    contaminante         : contaminante,
    concentracion        : concentracion,
    fechaHora            : fechaHora,
    muestreoOzone        : muestreoOzone.deepCopy(),
    muestreoPh           : muestreoPh.deepCopy(),
    muestreoConductivity : muestreoConductivity.deepCopy(),
    muestreoTemperatura: muestreoTemperatura.deepCopy(),
  );
}
