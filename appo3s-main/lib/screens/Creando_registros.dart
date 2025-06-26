import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/muestreo.dart';
import '../widgets/creando_ozone_chart.dart';
import '../widgets/creando_conductivity_chart.dart';
import '../widgets/creando_ph_chart.dart';
import '../widgets/editing_samples.dart';
import '../widgets/record_form.dart';
import '../widgets/timer_widget.dart';

class CreandoRegistros extends StatefulWidget {
  const CreandoRegistros({super.key});

  @override
  State<CreandoRegistros> createState() => _CreandoRegistrosState();
}

class _CreandoRegistrosState extends State<CreandoRegistros> {
  /* ───────── Buffers ───────── */
  final Muestreo _ozone        = Muestreo();
  final Muestreo _ph           = Muestreo();
  final Muestreo _conductivity = Muestreo();
  final Muestreo _timePattern  = Muestreo();             // pauta general

  /* ───────── Control de estado ───────── */
  bool    _patternSet   = false;   // se pulsó “Set” en EditingSamples
  bool    _started      = false;   // se pulsó “Start”
  bool    _formEnabled  = false;   // RecordForm habilitado
  Duration _elapsed     = Duration.zero;
  Timer?   _ticker;
  final    _rnd = Random();

  /* =========================================================
     ============  P A T T E R N     H A N D L E R  ===========
     ========================================================= */
  void _onSetPattern(Muestreo nuevo) {
    // (1) Configura pero NO arranca todavía
    _patternSet  = true;
    _started     = false;
    _formEnabled = false;
    _elapsed     = Duration.zero;
    _ticker?.cancel();

    // clona la pauta en los cuatro muestreos
    _timePattern.inicializar_con_otro_muestreo(nuevo);
    _ozone       .inicializar_con_otro_muestreo(nuevo);
    _ph          .inicializar_con_otro_muestreo(nuevo);
    _conductivity.inicializar_con_otro_muestreo(nuevo);

    setState(() {});
  }

  /* =========================================================
     ============  S T A R T     H A N D L E R  ===============
     ========================================================= */
  void _onStart() {
    if (!_patternSet) return;                 // seguridad
    if (_started)    return;                 // ya corriendo

    _started = true;
    _ticker  = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      _injectMockValuesIfNeeded();
    });
    setState(() {});
  }

  /* =========================================================
     ==============  A U T O - I N J E C T I O N  =============
     ========================================================= */
  void _injectMockValuesIfNeeded() {
    // ¿hemos procesado toda la pauta?
    if (_timePattern.index_actual >= _timePattern.count) {
      _formEnabled = true;        // ✅  ya se puede abrir RecordForm
      _ticker?.cancel();
      return;
    }

    final s = _timePattern.getSample(_timePattern.index_actual);
    final targetSec = s.selectedMinutes * 60 + s.selectedSeconds;

    if (_elapsed.inSeconds >= targetSec) {
      // ——— modo demo: aleatorios ———
      final m = s.selectedMinutes;
      final sec = s.selectedSeconds;

      _ozone       .actualizarMuestras_time(m, sec, _rnd.nextDouble() * 1.0);      // 0-1 ppm
      _ph          .actualizarMuestras_time(m, sec, 1 + _rnd.nextDouble() * 13.0); // 1-14
      _conductivity.actualizarMuestras_time(m, sec, _rnd.nextDouble() * 2000);     // 0-2000 µS

      //para valores reales
      /*
      final realO₃  = miSensor.ozone;        // ppm
      final realPh  = miSensor.ph;           // 1-14
      final realCond= miSensor.conductivity; // µS/cm
       */

      _timePattern.index_actual++;   // pasa al siguiente instante
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /* =========================================================
     ======================   U I   ===========================
     ========================================================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficas')),

      body: _GraphsBody(
        key                 : ValueKey(_timePattern.hashCode),
        muestreoTime        : _timePattern,
        muestreoOzone       : _ozone,
        muestreoPh          : _ph,
        muestreoConductivity: _conductivity,
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /* ——— ①  EDITAR PATRÓN ——— */
          FloatingActionButton.extended(
            heroTag : 'Set',
            icon    : const Icon(Icons.timer),
            label   : const Text('Set'),
            onPressed: () => showModalBottomSheet(
              context           : context,
              isScrollControlled: true,
              builder           : (_) => Padding(
                padding: const EdgeInsets.only(
                    bottom: 20, left: 20, right: 20, top: 10),
                child: EditingSamples(
                  muestreo        : _timePattern.deepCopy(),
                  onSamplesUpdated: _onSetPattern,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          /* ——— ②  START ——— */
          FloatingActionButton.extended(
            heroTag : 'Start',
            icon    : const Icon(Icons.play_arrow),
            label   : const Text('Start'),
            backgroundColor:
            _patternSet && !_started ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            onPressed: _patternSet && !_started
                ? _onStart
                : null,                      // deshabilitado visualmente
          ),
          const SizedBox(height: 16),

          /* ——— ③  CAPTURA MANUAL ——— */
          FloatingActionButton.extended(
            heroTag : 'Record',
            icon    : const Icon(Icons.check),
            label   : const Text('Capturar'),
            backgroundColor:
            _formEnabled ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            onPressed: _formEnabled
                ? () => showModalBottomSheet(
              context           : context,
              isScrollControlled: true,
              builder           : (_) => Padding(
                padding: const EdgeInsets.only(
                    bottom: 20, left: 20, right: 20, top: 10),
                child: RecordForm(
                  muestreo_ozone       : _ozone,
                  muestreo_ph          : _ph,
                  muestreo_conductivity: _conductivity,
                ),
              ),
            )
                : () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Debes completar el muestreo primero.'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ──────────────────────── Gráficas y timer ──────────────────────── */
class _GraphsBody extends StatelessWidget {
  final Muestreo muestreoTime;
  final Muestreo muestreoOzone;
  final Muestreo muestreoPh;
  final Muestreo muestreoConductivity;

  const _GraphsBody({
    super.key,
    required this.muestreoTime,
    required this.muestreoOzone,
    required this.muestreoPh,
    required this.muestreoConductivity,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TimerWidget(muestreo: muestreoTime),
        const SizedBox(height: 20),

        /* ——— OZONO a toda anchura ——— */
        Creando_OzoneChart(
          key     : ValueKey(muestreoOzone.hashCode),
          muestreo: muestreoOzone,
        ),
        const SizedBox(height: 20),

        /* ——— Conductividad  +  pH ——— */
        Row(
          children: [
            Expanded(
              child: Creando_ConductivityChart(
                key     : ValueKey(muestreoConductivity.hashCode),
                muestreo: muestreoConductivity,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Creando_PhChart(
                key     : ValueKey(muestreoPh.hashCode),
                muestreo: muestreoPh,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}