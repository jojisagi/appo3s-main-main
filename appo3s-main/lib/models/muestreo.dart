import 'sample.dart';

/// ─────────────────────────────────────────────────────────────
///  Colección de `Sample`s + utilidades de tiempo.
/// ─────────────────────────────────────────────────────────────
class Muestreo {
  Duration? maxDuration;
  int index_actual = 0;
  final List<Sample> _samples;

  Muestreo({this.maxDuration, List<Sample>? samples})
      : _samples = samples ?? [];

  /* ╭───── JSON ─────╮ */
  factory Muestreo.fromJson(Map<String, dynamic> j) => Muestreo(
    maxDuration: j['maxDuration'] != null
        ? Duration(microseconds: j['maxDuration'] as int)
        : null,
    samples: (j['samples'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()          // NEW
        .map((e) => Sample.fromJson(e))
        .toList(),
  )
    ..index_actual = (j['index_actual'] as int?) ?? 0;    // NEW

  Map<String, dynamic> toJson() => {
    'maxDuration' : maxDuration?.inMicroseconds,
    'index_actual': index_actual,
    'samples'     : _samples.map((s) => s.toJson()).toList(),
  };

  /* ───── getters estilo lista ──── */
  int    get count      => _samples.length;
  bool   get isEmpty    => _samples.isEmpty;
  bool   get isNotEmpty => _samples.isNotEmpty;
  Sample get first      => _samples.first;
  Sample get last       => _samples.last;
  List<Sample> get samples => List.unmodifiable(_samples);
  Sample operator [](int i) => _samples[i];

  int get lastTime => isEmpty ? 0 : last.totalSeconds;

  /* ───── edición ──── */
  void addSample   (Sample s)        => _samples.add(s);
  void updateSample(int i, Sample s) => _samples[i] = s;
  void removeSample(int i)           => _samples.removeAt(i);
  void clearSamples()                => _samples.clear();

  /* ───── orden y renum. ──── */
  void sortByTime() =>
      _samples.sort((a, b) => a.totalSeconds.compareTo(b.totalSeconds));

  void renum() {
    for (var i = 0; i < _samples.length; i++) {
      _samples[i] = _samples[i].copyWith(numSample: i + 1);
    }
  }

  /* ───── copias ──── */
  Muestreo deepCopy() => Muestreo(
    maxDuration: maxDuration,
    samples    : _samples.map((s) => s.copy()).toList(),
  );

  void inicializar_con_otro_muestreo(Muestreo otro) {
    clearSamples();
    _samples.addAll(otro._samples.map((s) => s.copy()));
  }

  /* ───── helpers demo ──── */
  Sample getSample(int i) => _samples[i];

  void actualizarMuestras_time(int m, int s, double y) {
    for (final smp in _samples) {
      if (smp.selectedMinutes == m && smp.selectedSeconds == s) {
        smp.y = y;
        break;
      }
    }
  }

  void actualizarMuestras_index(double y) {
    if (_samples.isEmpty) return;
    _samples[index_actual].y = y;
    index_actual = (index_actual + 1).clamp(0, _samples.length);
  }

  Muestreo cloneEmpty() => Muestreo(
    maxDuration: maxDuration,
    samples    : _samples.map((s) => s.copyWith(y: 0)).toList(),
  );
}
