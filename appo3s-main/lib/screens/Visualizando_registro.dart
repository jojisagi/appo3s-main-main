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
  /* ───── buffers ───── */
  late Muestreo _ozOriginal, _phOriginal, _condOriginal; // datos reales guardados
  late Muestreo _oz, _ph, _cond;                         // lo que se pinta/ani­ma

  /* ───── control animación ───── */
  Timer? _timer;
  bool   _simulating = false;
  int    _idx        = 0;      // punto actual 0…N-1
  late int _total;             // puntos totales

  /* ───── INIT ───── */
  @override
  void initState() {
    super.initState();

    // 1️⃣  Clones con los datos reales del registro
    _ozOriginal   = widget.record.muestreoOzone.deepCopy();
    _phOriginal   = widget.record.muestreoPh.deepCopy();
    _condOriginal = widget.record.muestreoConductivity.deepCopy();

    // 2️⃣  MOSTRARLOS inmediatamente (no en 0)
    _oz   = _ozOriginal.deepCopy();
    _ph   = _phOriginal.deepCopy();
    _cond = _condOriginal.deepCopy();

    _total = _ozOriginal.count;          // todas las series comparten la pauta
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /* ───── helpers ───── */
  void _copiarPunto(Muestreo src, Muestreo dst, int i) {
    if (i < src.count) dst.updateSample(i, src[i].copy());
  }

  /* ───── animación ───── */
  Future<void> _startSim() async {
    if (_simulating || _total == 0) return;

    setState(() {
      _simulating = true;
      _idx        = 0;
      // ⇢ vaciamos para reconstruir desde cero
      _oz   = _ozOriginal.cloneEmpty();
      _ph   = _phOriginal.cloneEmpty();
      _cond = _condOriginal.cloneEmpty();
    });

    _timer = Timer.periodic(const Duration(milliseconds: 600), (t) async {
      _copiarPunto(_ozOriginal  , _oz  , _idx);
      _copiarPunto(_phOriginal  , _ph  , _idx);
      _copiarPunto(_condOriginal, _cond, _idx);

      setState(() {});
      _idx++;

      if (_idx >= _total) {
        t.cancel();
        await _saveAndFinish();
      }
    });
  }

  Future<void> _saveAndFinish() async {
    // una vez completada la animación, consideramos los buffers “reales”
    _ozOriginal   = _oz.deepCopy();
    _phOriginal   = _ph.deepCopy();
    _condOriginal = _cond.deepCopy();

    final actualizado = widget.record.copyWith(
      fechaHora            : DateTime.now(),
      muestreoOzone        : _ozOriginal,
      muestreoPh           : _phOriginal,
      muestreoConductivity : _condOriginal,
    );
    await context.read<RecordService>().saveRecord(actualizado);

    setState(() => _simulating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulación guardada')),
      );
    }
  }

  /* ───── UI ───── */
  @override
  Widget build(BuildContext context) {
    final btnStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            record_widget_simple(
              contaminante : Text(widget.record.contaminante),
              concentracion: Text('${widget.record.concentracion} ppm'),
              fechaHora    : Text(DateFormat.yMd().add_jm()
                  .format(widget.record.fechaHora)),
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                icon : const Icon(Icons.play_arrow),
                label: const Text('Simular'),
                style: btnStyle,
                onPressed: _simulating ? null : _startSim,
              ),
            ),
            if (_simulating) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _total == 0 ? 0 : _idx / _total,
                backgroundColor: Colors.grey.shade300,
              ),
            ],

            const SizedBox(height: 24),
            Creando_OzoneChart(muestreo: _oz),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Creando_ConductivityChart(muestreo: _cond)),
                const SizedBox(width: 20),
                Expanded(child: Creando_PhChart(muestreo: _ph)),
              ],
            ),

            const SizedBox(height: 32),
            Center(
              child: Wrap(
                spacing: 20,
                children: [
                  ElevatedButton(
                    style: btnStyle,
                    onPressed: () => saveToTxt(
                      context,
                      widget.record.contaminante,      // String
                      widget.record.concentracion,     // double
                      widget.record.fechaHora,         // DateTime
                      _ozOriginal, _phOriginal, _condOriginal,
                    ),
                    child: const Text('Guardar txt'),
                  ),
                  ElevatedButton(
                    style: btnStyle,
                    onPressed: () => saveToCsv(
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
