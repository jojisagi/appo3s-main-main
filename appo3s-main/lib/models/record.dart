class Record {
  final String contaminante;
  final double concentracion;
  final DateTime fechaHora;      // ← ahora incluye hora

  Record({
    required this.contaminante,
    required this.concentracion,
    required this.fechaHora,
  });

  Map<String, dynamic> toJson() => {
    'contaminante': contaminante,
    'concentracion': concentracion,
    'fechaHora': fechaHora.toIso8601String(),
  };

  factory Record.fromJson(Map<String, dynamic> j) => Record(
    contaminante: j['contaminante'],
    concentracion: (j['concentracion'] as num).toDouble(),
    fechaHora: DateTime.parse(j['fechaHora']),
  );
}
