// lib/screens/visualizando_registro.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/muestreo.dart';
import '../models/record.dart';
import '../services/record_service.dart';
import '../widgets/creando_conductivity_chart.dart';
import '../widgets/creando_ozone_chart.dart';
import '../widgets/creando_ph_chart.dart';
import '../widgets/record_widget_simple.dart';
import '../utils/file_saver.dart';

class VisualizandoRegistros extends StatefulWidget {
  final Record record;
  const VisualizandoRegistros({super.key, required this.record});

  @override
  State<VisualizandoRegistros> createState() => _VisualizandoRegistrosState();
}

class _VisualizandoRegistrosState extends State<VisualizandoRegistros> {
/* ────────── layout ────────── */
  static const double _chartH = 260;

/* ────────── buffers ────────── */
  late Muestreo _ozOriginal, _phOriginal, _condOriginal;
  late Muestreo _oz, _ph, _cond;

/* ────────── control animación ────────── */
  Timer? _timer;
  bool   _running   = false;   // ¿hay animación en curso?
  bool   _paused    = false;   // ¿está pausada?
  int    _idx       = 0;       // punto actual 0…N-1
  late int _total;             // puntos totales
  int    _interval  = 600;     // ms entre puntos (slider)

/* ────────── INIT / DISPOSE ────────── */
  @override
  void initState() {
    super.initState();

    _ozOriginal   = widget.record.muestreoOzone.deepCopy();
    _phOriginal   = widget.record.muestreoPh.deepCopy();
    _condOriginal = widget.record.muestreoConductivity.deepCopy();

    _oz   = _ozOriginal.deepCopy();
    _ph   = _phOriginal.deepCopy();
    _cond = _condOriginal.deepCopy();

    _total = _ozOriginal.count;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

/* ────────── helpers ────────── */
  void _copiarPunto(Muestreo src, Muestreo dst, int i) {
    if (i < src.count) dst.updateSample(i, src[i].copy());
  }

  void _programarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _interval), (t) async {
      _copiarPunto(_ozOriginal  , _oz  , _idx);
      _copiarPunto(_phOriginal  , _ph  , _idx);
      _copiarPunto(_condOriginal, _cond, _idx);
      setState(() {});
      if (++_idx >= _total) {
        t.cancel();
        await _finishSim();
      }
    });
  }

/* ────────── play / pausa ────────── */
  void _togglePlayPause() {
    if (_total == 0) return;             // sin datos

    if (!_running) {                     // ► iniciar
      setState(() {
        _running = true;
        _paused  = false;
        _idx     = 0;
        _oz   = _ozOriginal.cloneEmpty();
        _ph   = _phOriginal.cloneEmpty();
        _cond = _condOriginal.cloneEmpty();
      });
      _programarTimer();
    } else if (_paused) {                // ► reanudar
      setState(() => _paused = false);
      _programarTimer();
    } else {                             // ► pausar
      _timer?.cancel();
      setState(() => _paused = true);
    }
  }

/* ────────── fin animación ────────── */
  Future<void> _finishSim() async {
    _ozOriginal   = _oz.deepCopy();
    _phOriginal   = _ph.deepCopy();
    _condOriginal = _cond.deepCopy();

    await context.read<RecordService>().saveRecord(
      widget.record.copyWith(
        fechaHora            : DateTime.now(),
        muestreoOzone        : _ozOriginal,
        muestreoPh           : _phOriginal,
        muestreoConductivity : _condOriginal,
      ),
    );

    setState(() {
      _running = false;
      _paused  = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Simulación guardada')));
    }
  }

/* ────────── fallback si el muestreo está vacío ────────── */
  Widget _safeChart(Widget chart, Muestreo m) {
    if (m.count == 0) {
      return Container(
        alignment: Alignment.center,
        height   : _chartH,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Sin datos'),
      );
    }
    return chart;
  }

/* ────────── UI ────────── */
  @override
  Widget build(BuildContext context) {
    final btnStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    );

    final noData   = _total == 0;
    final icon     = !_running ? Icons.play_arrow : (_paused ? Icons.play_arrow : Icons.pause);
    final caption  = !_running ? 'Simular'
        : (_paused ? 'Reanudar'
        : 'Pausa');

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /* ─── cabecera ─── */
            record_widget_simple(
              contaminante : Text(widget.record.contaminante),
              concentracion: Text('${widget.record.concentracion} ppm'),
              fechaHora    : Text(DateFormat.yMd().add_jm()
                  .format(widget.record.fechaHora)),
            ),
            const SizedBox(height: 20),

            /* ─── botón play/pause ─── */
            Center(
              child: ElevatedButton.icon(
                icon : Icon(icon),
                label: Text(caption),
                style: btnStyle.copyWith(
                  backgroundColor: noData
                      ? MaterialStateProperty.all(Colors.grey)
                      : btnStyle.backgroundColor,
                ),
                onPressed: noData ? null : _togglePlayPause,
              ),
            ),

            if (_running && !_paused) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _idx / (_total == 0 ? 1 : _total),
                backgroundColor: Colors.grey.shade300,
              ),
            ],

            if (_running) ...[
              const SizedBox(height: 12),

              /// ───── velocidad (lento ←→ rápido) ─────
              Slider(
                // el valor que mueve el usuario va de 0 (lento) → 1900 (rápido)
                min:    0,
                max: 1900,
                divisions: 19,
                // convertimos el valor real [_interval] (100-2000 ms)
                // a “posición” de 0-1900 => pos = 2000 - _interval
                value: (2000 - _interval).toDouble(),
                label: '${_interval} ms',               // texto emergente
                onChanged: (v) {
                  // v es 0-1900 → intervalo = 2000 - v
                  setState(() => _interval = 2000 - v.round());
                  if (_running && !_paused) _programarTimer();
                },
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ◀◀  Más lento
                  IconButton(
                    icon: const Icon(Icons.fast_rewind_rounded, size: 32),
                    tooltip: 'Más lento',
                    onPressed: () {
                      setState(() {
                        _interval = (_interval + 200).clamp(100, 2000);
                      });
                      if (_running && !_paused) _programarTimer();
                    },
                  ),
                  const SizedBox(width: 24),
                  //   ▶▶  Más rápido
                  IconButton(
                    icon: const Icon(Icons.fast_forward_rounded, size: 32),
                    tooltip: 'Más rápido',
                    onPressed: () {
                      setState(() {
                        _interval = (_interval - 200).clamp(100, 2000);
                      });
                      if (_running && !_paused) _programarTimer();
                    },
                  ),
                ],
              ),

            ],

            const SizedBox(height: 24),

            /* ─── Gráfica Ozono ─── */
            _safeChart(Creando_OzoneChart(muestreo: _oz), _oz),

            const SizedBox(height: 24),

            /* ─── Conductividad + pH (responsive) ─── */
            LayoutBuilder(
              builder: (ctx, cons) {
                final wide = cons.maxWidth >= 680;
                final children = [
                  Expanded(
                    child: _safeChart(
                        Creando_ConductivityChart(muestreo: _cond), _cond),
                  ),
                  if (wide) const SizedBox(width: 20) else const SizedBox(height: 20),
                  Expanded(
                    child: _safeChart(
                        Creando_PhChart(muestreo: _ph), _ph),
                  ),
                ];
                return wide
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: children)
                    : Column(children: children);
              },
            ),

            const SizedBox(height: 32),

            /* ─── botones Guardar ─── */
            Center(
              child: Wrap(
                spacing: 20,
                children: [
                  ElevatedButton(
                    style: btnStyle,
                    onPressed: noData
                        ? null
                        : () => saveToTxt(
                      context,
                      widget.record.contaminante,
                      widget.record.concentracion,
                      widget.record.fechaHora,
                      _ozOriginal, _phOriginal, _condOriginal,
                    ),
                    child: const Text('Guardar txt'),
                  ),
                  ElevatedButton(
                    style: btnStyle,
                    onPressed: noData
                        ? null
                        : () => saveToCsv(
                      context,
                      widget.record.contaminante,
                      widget.record.concentracion,
                      widget.record.fechaHora,
                      _ozOriginal, _phOriginal, _condOriginal,
                    ),
                    child: const Text('Guardar csv'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
