class Record {
  final String contaminante;
  final double concentracion;
  final DateTime fechaHora;

  Record({
    required this.contaminante,
    required this.concentracion,
    required this.fechaHora,
  });

  // ─── Deserializar desde Mongo / JSON ───
  factory Record.fromJson(Map<String, dynamic> json) => Record(
    contaminante: json['contaminante'] as String,
    concentracion: (json['concentracion'] as num).toDouble(),
    fechaHora: DateTime.parse(json['fechaHora'] as String),
  );

  // ─── Serializar para POST ───
  Map<String, dynamic> toJson() => {
    'contaminante': contaminante,
    'concentracion': concentracion,
    'fechaHora': fechaHora.toIso8601String(),
  };
}
