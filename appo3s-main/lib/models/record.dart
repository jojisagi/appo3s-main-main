class Record {
  final String contaminante;   // “ozono” si lo ingresas a mano
  final double concentracion;
  final DateTime fechaHora;

  /// 'o3' | 'cond' | 'ph'   ← para gráficas
  final String tipo;

  Record({
    required this.contaminante,
    required this.concentracion,
    required this.fechaHora,
    required this.tipo,
  });

  factory Record.fromJson(Map<String,dynamic> j) => Record(
    contaminante: j['contaminante'] ?? j['tipo'],
    concentracion: (j['concentracion'] ?? j['value']).toDouble(),
    fechaHora: DateTime.parse(j['fechaHora'] ?? j['timestamp']),
    tipo: j['tipo'] ?? 'o3',
  );

  Map<String,dynamic> toJson() => {
    'contaminante': contaminante,
    'concentracion': concentracion,
    'fechaHora': fechaHora.toIso8601String(),
    'tipo': tipo,
  };
}
