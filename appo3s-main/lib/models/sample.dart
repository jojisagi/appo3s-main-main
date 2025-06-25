/// ─────────────────────────────────────────────────────────────
///  Modelo de punto (muestra) usado en los muestreos/gráficas.
/// ─────────────────────────────────────────────────────────────
class Sample {
  final int    numSample;        // 1…N
  final int    selectedMinutes;  // tiempo
  final int    selectedSeconds;  //  "
  double       y;                // valor medido

  Sample({
    required this.numSample,
    required this.selectedMinutes,
    required this.selectedSeconds,
    required this.y,
  });

  /* ╭──── helpers de tiempo ────╮ */
  Duration get duration      => Duration(
    minutes: selectedMinutes,
    seconds: selectedSeconds,
  );
  int    get totalSeconds    => selectedMinutes * 60 + selectedSeconds;
  String get formattedTime   =>
      '${selectedMinutes.toString().padLeft(2, '0')}:'
          '${selectedSeconds.toString().padLeft(2, '0')}';

  /* ╭───── JSON ─────╮ */
  factory Sample.fromJson(Map<String, dynamic> j) => Sample(
    numSample       : (j['n'] as int?)    ?? 0,          // NEW
    selectedMinutes : (j['m'] as int?)    ?? 0,          // NEW
    selectedSeconds : (j['s'] as int?)    ?? 0,          // NEW
    y               : (j['y'] as num?)?.toDouble() ?? 0, // NEW
  );

  Map<String, dynamic> toJson() => {
    'n': numSample,
    'm': selectedMinutes,
    's': selectedSeconds,
    'y': y,
  };

  /* ╭───── copias ─────╮ */
  Sample copy() => Sample(
    numSample       : numSample,
    selectedMinutes : selectedMinutes,
    selectedSeconds : selectedSeconds,
    y               : y,
  );

  Sample copyWith({
    int?    numSample,
    int?    selectedMinutes,
    int?    selectedSeconds,
    double? y,
  }) =>
      Sample(
        numSample       : numSample        ?? this.numSample,
        selectedMinutes : selectedMinutes ?? this.selectedMinutes,
        selectedSeconds : selectedSeconds ?? this.selectedSeconds,
        y               : y               ?? this.y,
      );
}
