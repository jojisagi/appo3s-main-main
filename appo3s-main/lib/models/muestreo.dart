// lib/models/muestreo.dart
import '../models/sample.dart';

class Muestreo {
  Duration? maxDuration;
  int       index_actual = 0;          // usado por el timer demo
  final List<Sample> _samples;

  Muestreo({this.maxDuration, List<Sample>? samples})
      : _samples = samples ?? [];

  /* ────────── JSON helpers opcionales ────────── */
  factory Muestreo.fromJson(Map<String, dynamic> j) => Muestreo(
    maxDuration: j['maxDuration'] != null
        ? Duration(microseconds: j['maxDuration'] as int)
        : null,
    samples: (j['samples'] as List?)
        ?.map((e) => Sample.fromJson(e))
        .toList() ??
        [],
  )..index_actual = j['index_actual'] as int? ?? 0;

  Map<String, dynamic> toJson() => {
    'maxDuration': maxDuration?.inMicroseconds,
    'index_actual': index_actual,
    'samples': _samples.map((s) => s.toJson()).toList(),
  };

  /* ────────── getters tipo lista ────────── */
  int    get count => _samples.length;
  bool   get isEmpty => _samples.isEmpty;
  bool   get isNotEmpty => _samples.isNotEmpty;
  Sample get first => _samples.first;
  Sample get last  => _samples.last;
  Sample operator [](int i) => _samples[i];
  List<Sample> get samples => List.unmodifiable(_samples);

  /* ────────── edición básica ────────── */
  void addSample(Sample s)        => _samples.add(s);
  void updateSample(int i, Sample s) => _samples[i] = s;
  void removeSample(int i)        => _samples.removeAt(i);
  void clearSamples()             => _samples.clear();

  /* ────────── utilidades extra ────────── */
  /// Ordena por tiempo (mm:ss)
  void sortByTime() => _samples.sort((a, b) {
    final ta = a.selectedMinutes * 60 + a.selectedSeconds;
    final tb = b.selectedMinutes * 60 + b.selectedSeconds;
    return ta.compareTo(tb);
  });

  /// Vuelve a numerar numSample = 1..N (después de ordenar/eliminar)
  void renum() {
    for (var i = 0; i < _samples.length; i++) {
      _samples[i] = _samples[i].copyWith(numSample: i + 1);
    }
  }

  /// Copia profunda (para pasar a dialogs sin mutar el original)
  Muestreo deepCopy() => Muestreo(
    maxDuration: maxDuration,
    samples: _samples.map((s) => s.copy()).toList(),
  );

  /// Clona todas las muestras de otro muestreo
  void inicializar_con_otro_muestreo(Muestreo otro) {
    clearSamples();
    _samples.addAll(otro._samples.map((s) => s.copy()));
  }

  /* ────────── helpers demo (se usaban antes) ────────── */
  void actualizarMuestras_index(double y) {
    _samples[index_actual].y = y;
    index_actual = (index_actual + 1).clamp(0, _samples.length);
  }
  Sample getSample(int index) => _samples[index];
  void actualizarMuestras_time(int m, int s, double y) {
    for (final samp in _samples) {
      if (samp.selectedMinutes == m && samp.selectedSeconds == s) {
        samp.y = y;
        break;
      }
    }
  }
}
