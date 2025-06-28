// lib/screens/creando_registros.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/muestreo.dart';
import '../models/record.dart';
import '../services/record_service.dart';
import '../widgets/creando_conductivity_chart.dart';
import '../widgets/creando_ozone_chart.dart';
import '../widgets/creando_ph_chart.dart';
import '../widgets/editing_samples.dart';
import '../widgets/record_form.dart';
import '../widgets/timer_widget.dart';
import '../services/server_renamed.dart';
class CreandoRegistros extends StatefulWidget {
  /// Si viene **null** → modo “nuevo registro”.
  /// Si viene un registro → modo “edición”.
  final Record? original;

  const CreandoRegistros({super.key, this.original});

  @override
  State<CreandoRegistros> createState() => _CreandoRegistrosState();
}

class _CreandoRegistrosState extends State<CreandoRegistros> {
/* ───────────────────────── 1. ESTADO PRINCIPAL ───────────────────────── */
  late Record   _record;           // único «source of truth»
  late Muestreo _ozone;
  late Muestreo _ph;
  late Muestreo _conductivity;
  final Muestreo _timePattern = Muestreo(); // pauta mm:ss del Timer

  bool     _patternSet  = false;
  bool     _started     = false;
  bool     _formEnabled = false;
  Duration _elapsed     = Duration.zero;
  Timer?   _ticker;
  final    _rnd = Random();

/* ───────────────────────── 2. INIT / DISPOSE ───────────────────────── */
  @override
  void initState() {
    super.initState();

    // ① Registro existente  o  ② esqueleto “vacío” (no se insertará aún)
    _record = widget.original ??
        Record(
          contaminante         : 'O₃',           // marcador temporal
          concentracion        : 0,
          fechaHora            : DateTime.now(),
          muestreoOzone        : Muestreo(),
          muestreoPh           : Muestreo(),
          muestreoConductivity : Muestreo(),
        );

    // Los buffers NO deben apuntar al mismo objeto
    _ozone        = _record.muestreoOzone.deepCopy();
    _ph           = _record.muestreoPh.deepCopy();
    _conductivity = _record.muestreoConductivity.deepCopy();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

/* ───────────────────────── 3. CALLBACKS PATRÓN ───────────────────────── */
  void _onSetPattern(Muestreo nuevo) {
    _patternSet  = true;
    _started     = false;
    _formEnabled = false;
    _elapsed     = Duration.zero;
    _ticker?.cancel();

    _timePattern.inicializar_con_otro_muestreo(nuevo);
    _ozone       .inicializar_con_otro_muestreo(nuevo);
    _ph          .inicializar_con_otro_muestreo(nuevo);
    _conductivity.inicializar_con_otro_muestreo(nuevo);

    setState(() {});
  }

/* ───────────────────────── 4. START / INJECT ───────────────────────── */
  void _onStart() {
    if (!_patternSet || _timePattern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes definir al menos una muestra')),
      );
      return;
    }
    if (_started) return;

    _started = true;
    _ticker  = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      _injectMockValuesIfNeeded();
      if (mounted) setState(() {}); // actualiza cronómetro
    });
  }

  void _injectMockValuesIfNeeded() {
    /* ─── Fin de la pauta ─── */
    if (_timePattern.index_actual >= _timePattern.count) {
      _ticker?.cancel();
      _started     = false;
      _formEnabled = true;

      // Clona resultados en el objeto principal
      _record = _record.copyWith(
        muestreoOzone        : _ozone.deepCopy(),
        muestreoPh           : _ph.deepCopy(),
        muestreoConductivity : _conductivity.deepCopy(),
        fechaHora            : DateTime.now(),
      );

      // ⭐ Sólo se guarda automáticamente si veníamos **editando** uno existente.
      if (widget.original != null) {
        context.read<RecordService>().saveRecord(_record);
      }

      setState(() {});
      return;
    }

    /* ─── Punto alcanzado ─── */
    final smp = _timePattern[_timePattern.index_actual];
    if (_elapsed.inSeconds < smp.totalSeconds) return;

    final m   = smp.selectedMinutes;
    final sec = smp.selectedSeconds;

    _ozone       .actualizarMuestras_time(m, sec, _rnd.nextDouble()*100);            // 0-1 ppm
    _ph          .actualizarMuestras_time(m, sec, 1 + _rnd.nextDouble() * 13);   // 1-14
    _conductivity.actualizarMuestras_time(m, sec, _rnd.nextDouble() * 2000);     // 0-2000 µS

    _timePattern.index_actual++;
    setState(() {}); // refresco inmediato
  }

/* ───────────────────────── 5. UI ───────────────────────── */
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.original == null
          ? 'Nuevo registro'
          : 'Editando registro'),
    ),
    body: _GraphsBody(
      key                 : ValueKey(_timePattern.hashCode),
      muestreoTime        : _timePattern,
      muestreoOzone       : _ozone,
      muestreoPh          : _ph,
      muestreoConductivity: _conductivity,
      onStart             : _onStart,
    ),
    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /* ---- SET PATRÓN ---- */
        FloatingActionButton.extended(
          heroTag : 'Set',
          icon    : const Icon(Icons.timer),
          label   : const Text('Set'),
          onPressed: () => showModalBottomSheet(
            context           : context,
            isScrollControlled: true,
            builder           : (_) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: EditingSamples(
                muestreo        : _timePattern.deepCopy(),
                onSamplesUpdated: _onSetPattern,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        /* ---- CAPTURAR ---- */
        FloatingActionButton.extended(
          heroTag : 'Record',
          icon    : const Icon(Icons.check),
          label   : const Text('Capturar'),
          backgroundColor: _formEnabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          onPressed: _formEnabled
              ? () => showModalBottomSheet(
            context           : context,
            isScrollControlled: true,
            builder           : (_) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child : RecordForm(
                muestreoOzone       : _ozone,
                muestreoPh          : _ph,
                muestreoConductivity: _conductivity,
              ),
            ),
          )
              : () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
              Text('Debes completar el muestreo primero.'),
            ),
          ),
        ),
      ],
    ),
  );
}

/* ──────────────────── cuerpo con gráficas ──────────────────── */
class _GraphsBody extends StatelessWidget {
  final Muestreo     muestreoTime;
  final Muestreo     muestreoOzone;
  final Muestreo     muestreoPh;
  final Muestreo     muestreoConductivity;
  final VoidCallback onStart;

  const _GraphsBody({
    super.key,
    required this.muestreoTime,
    required this.muestreoOzone,
    required this.muestreoPh,
    required this.muestreoConductivity,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TimerWidget(muestreo: muestreoTime, onStart: onStart),
        const SizedBox(height: 20),
        Creando_OzoneChart(
          key     : ValueKey(muestreoOzone.hashCode),
          muestreo: muestreoOzone,
        ),
        const SizedBox(height: 20),
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