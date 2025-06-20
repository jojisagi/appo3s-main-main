import '../models/muestreo.dart';

class Record {

  final String contaminante;
  final double concentracion;
  final DateTime fechaHora;
  final Muestreo muestreo_ozone;
  final Muestreo muestreo_ph;
  final Muestreo muestreo_conductivity;



  Record({
    required this.contaminante,
    required this.concentracion,
    required this.fechaHora,
    Muestreo? muestreo_ozone,
    Muestreo? muestreo_ph,
    Muestreo? muestreo_conductivity,
  })  : muestreo_ozone = muestreo_ozone ?? Muestreo(),
        muestreo_ph = muestreo_ph ?? Muestreo(),
        muestreo_conductivity = muestreo_conductivity ?? Muestreo();

  factory Record.fromJson(Map<String, dynamic> json) => Record(
       
        contaminante: json['contaminante'] as String,
        concentracion: (json['concentracion'] as num).toDouble(),
        fechaHora: DateTime.parse(json['fechaHora'] as String),
        muestreo_ozone: json['muestreo_ozone'] != null
            ? Muestreo.fromJson(json['muestreo_ozone'] as Map<String, dynamic>)
            : null,
        muestreo_ph: json['muestreo_ph'] != null
            ? Muestreo.fromJson(json['muestreo_ph'] as Map<String, dynamic>)
            : null,
        muestreo_conductivity: json['muestreo_conductivity'] != null
            ? Muestreo.fromJson(
                json['muestreo_conductivity'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {

        'contaminante': contaminante,
        'concentracion': concentracion,
        'fechaHora': fechaHora.toIso8601String(),
        'muestreo_ozone': muestreo_ozone.toJson(),
        'muestreo_ph': muestreo_ph.toJson(),
        'muestreo_conductivity': muestreo_conductivity.toJson(),
      };

  Record copyWith({
    String? tipo,
    String? contaminante,
    double? concentracion,
    DateTime? fechaHora,
    Muestreo? muestreo_ozone,
    Muestreo? muestreo_ph,
    Muestreo? muestreo_conductivity,
  }) {
    return Record(
 
      contaminante: contaminante ?? this.contaminante,
      concentracion: concentracion ?? this.concentracion,
      fechaHora: fechaHora ?? this.fechaHora,
      muestreo_ozone: muestreo_ozone ?? this.muestreo_ozone,
      muestreo_ph: muestreo_ph ?? this.muestreo_ph,
      muestreo_conductivity: muestreo_conductivity ?? this.muestreo_conductivity,
    );
  }
}
