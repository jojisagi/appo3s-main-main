import 'sample.dart';

/// ─────────────────────────────────────────────────────────────
///  Colección de `Sample`s + utilidades de tiempo y “viewport”.
/// ─────────────────────────────────────────────────────────────
class Muestreo {
  /* ——— configuración de ventana visible ——— */
  /// Duración (seg.) del tramo que se dibuja en pantalla.
  static const int viewLenSec = 120;          // 2 min (cámbialo si quieres)

  /// Segundo ( 0 … ∞ ) donde comienza la ventana que se muestra.
  int viewStartSec = 0;

  /* ——— datos crudos ——— */
  Duration? maxDuration;                      // aún no usado, pero conservado
  int       index_actual = 0;                 // lleva la cuenta en tiempo real
  final List<Sample> _samples;

  Muestreo({this.maxDuration, List<Sample>? samples})
      : _samples = samples ?? [];

  /* ╭─────── JSON / persistencia ────────╮ */
  factory Muestreo.fromJson(Map<String, dynamic> j) => Muestreo(
    maxDuration: j['maxDuration'] != null
        ? Duration(microseconds: j['maxDuration'] as int)
        : null,
    samples: (j['samples'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Sample.fromJson)
        .toList(),
  )
    ..index_actual = (j['index_actual'] as int?) ?? 0
    ..viewStartSec = (j['viewStartSec'] as int?) ?? 0;

  Map<String, dynamic> toJson() => {
    'maxDuration' : maxDuration?.inMicroseconds,
    'index_actual': index_actual,
    'viewStartSec': viewStartSec,
    'samples'     : _samples.map((s) => s.toJson()).toList(),
  };

  /* ╭─────── getters estilo-lista ────────╮ */
  int    get count      => _samples.length;
  bool   get isEmpty    => _samples.isEmpty;
  bool   get isNotEmpty => _samples.isNotEmpty;
  Sample get first      => _samples.first;
  Sample get last       => _samples.last;
  List<Sample> get samples => List.unmodifiable(_samples);
  Sample operator [](int i) => _samples[i];

  /// Tiempo (en segundos) del último punto.
  int get lastTime => isEmpty ? 0 : last.totalSeconds;

  /* ╭─────── *nueva* vista filtrada ────────╮ */
  /// Samples que caen dentro de la ventana `[viewStartSec, viewStartSec+viewLenSec]`.
  List<Sample> get inView {
    final end = viewStartSec + viewLenSec;
    return _samples
        .where((s) => s.totalSeconds >= viewStartSec && s.totalSeconds <= end)
        .toList();
  }

  /* ╭────────── edición / utilidades ──────────╮ */
  void addSample   (Sample s)        => _samples.add(s);
  void updateSample(int i, Sample s) => _samples[i] = s;
  void removeSample(int i)           => _samples.removeAt(i);
  void clearSamples()                => _samples.clear();

  /* ——— orden y renumeración ——— */
  void sortByTime() =>
      _samples.sort((a, b) => a.totalSeconds.compareTo(b.totalSeconds));

  void renum() {
    for (var i = 0; i < _samples.length; i++) {
      _samples[i] = _samples[i].copyWith(numSample: i + 1);
    }
  }

  /* ——— copias ——— */
  Muestreo deepCopy() => Muestreo(
    maxDuration: maxDuration,
    samples    : _samples.map((s) => s.copy()).toList(),
  )
    ..index_actual = index_actual
    ..viewStartSec = viewStartSec;

  void inicializar_con_otro_muestreo(Muestreo otro) {
    clearSamples();
    _samples.addAll(otro._samples.map((s) => s.copy()));
    index_actual = otro.index_actual;
    viewStartSec = otro.viewStartSec;
  }

  /* ——— helpers demo ——— */
  Sample getSample(int i) => _samples[i];

  /// Actualiza por tiempo (m, s)
  void actualizarMuestras_time(int m, int s, double y) {
    for (final smp in _samples) {
      if (smp.selectedMinutes == m && smp.selectedSeconds == s) {
        smp.y = y;
        break;
      }
    }
  }

  /// Actualiza usando `index_actual`
  void actualizarMuestras_index(double y) {
    if (_samples.isEmpty) return;
    _samples[index_actual].y = y;
    index_actual = (index_actual + 1).clamp(0, _samples.length);
  }

  /// Copia vacía (todos los valores Y=0)
  Muestreo cloneEmpty() => Muestreo(
    maxDuration: maxDuration,
    samples    : _samples.map((s) => s.copyWith(y: 0)).toList(),
  )
    ..viewStartSec = viewStartSec;          // mantiene la misma ventana
}