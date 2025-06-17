class Record {
  final String tipo;          // 'o3', 'cond', 'ph'
  final String contaminante;
  final double concentracion;
  final DateTime fechaHora;

  Record({
    required this.tipo,
    required this.contaminante,
    required this.concentracion,
    required this.fechaHora,
  });

  factory Record.fromJson(Map<String, dynamic> j) => Record(
    tipo: j['tipo'] as String? ?? 'o3',
    contaminante: j['contaminante'] as String,
    concentracion: (j['concentracion'] as num).toDouble(),
    fechaHora: DateTime.parse(j['fechaHora'] as String),
  );

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'contaminante': contaminante,
    'concentracion': concentracion,
    'fechaHora': fechaHora.toIso8601String(),
  };
}
