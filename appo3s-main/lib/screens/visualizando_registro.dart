// lib/screens/visualizando_registro.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/muestreo.dart';
import '../models/record.dart';
import '../models/sample.dart';
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
  State<VisualizandoRegistros> createState() =>
      _VisualizandoRegistrosState();
}

class _VisualizandoRegistrosState extends State<VisualizandoRegistros> {
  /* ───── Clones locales (para no tocar el registro original) ───── */
  late Muestreo oz, cond, ph;

  /* ───── Control de simulación ───── */
  Timer? _simTimer;
  bool   _simulating = false;
  int    _elapsed    = 0;
  int    _total      = 0;

  @override
  void initState() {
    super.initState();
    oz   = widget.record.muestreoOzone      .deepCopy();
    cond = widget.record.muestreoConductivity.deepCopy();
    ph   = widget.record.muestreoPh         .deepCopy();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  /* ───────────── Simulación ───────────── */

  Future<void> _pedirYArrancarSim() async {
    if (_simulating) return;

    final seg = await showDialog<int>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController(text: '90');
        return AlertDialog(
          title: const Text('Duración (seg)'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Ej: 120'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)), child: const Text('Iniciar')),
          ],
        );
      },
    );

    if (seg == null || seg <= 0) return;

    setState(() {
      _simulating = true;
      _elapsed    = 0;
      _total      = seg;
      oz  .clearSamples();
      cond.clearSamples();
      ph  .clearSamples();
    });

    final rnd = Random();
    _simTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      _elapsed++;

      oz  .addSample(_make(_elapsed, rnd.nextDouble()));          // 0-1 ppm
      cond.addSample(_make(_elapsed, rnd.nextDouble()*2000));     // 0-2000 µS
      ph  .addSample(_make(_elapsed, rnd.nextDouble()*13 + 1));   // 1-14 pH

      setState(() {});
      if (_elapsed >= _total) {
        t.cancel();
        await _finSim();
      }
    });
  }

  Sample _make(int s, double y) => Sample(
    numSample: 0,
    selectedMinutes: s ~/ 60,
    selectedSeconds: s % 60,
    y: y,
  );

  Future<void> _finSim() async {
    setState(() => _simulating = false);

    final nuevo = widget.record.copyWith(
      fechaHora            : DateTime.now(),
      muestreoOzone       : oz  .deepCopy(),
      muestreoConductivity: cond.deepCopy(),
      muestreoPh          : ph  .deepCopy(),
    );
    await context.read<RecordService>().saveRecord(nuevo, sync:false);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Simulación guardada')));
    }
  }

  /* ───────────── UI ───────────── */

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
              fechaHora    : Text(DateFormat.yMd().add_jm().format(widget.record.fechaHora)),
            ),

            /* ───────── Botón SIMULAR centrado ───────── */
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon : const Icon(Icons.play_arrow),
                label: const Text('Simular'),
                style: btnStyle,
                onPressed: _simulating ? null : _pedirYArrancarSim,
              ),
            ),

            if (_simulating) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _elapsed / max(_total, 1),
                backgroundColor: Colors.grey.shade300,
              ),
            ],

            /* ───────── Gráficas ───────── */
            const SizedBox(height: 24),
            Creando_OzoneChart(muestreo: oz),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Creando_ConductivityChart(muestreo: cond)),
                const SizedBox(width: 20),
                Expanded(child: Creando_PhChart(muestreo: ph)),
              ],
            ),

            /* ───────── Botones de descarga centrados ───────── */
            const SizedBox(height: 32),
            Center(
              child: Wrap(
                spacing: 20,
                children: [
                  ElevatedButton(
                    style: btnStyle,
                    onPressed: () => saveToTxt(
                      context,
                      Text(widget.record.contaminante),
                      Text('${widget.record.concentracion} ppm'),
                      Text(DateFormat.yMd().add_jm().format(widget.record.fechaHora)),
                      oz,
                      ph,
                      cond,
                    ),
                    child: const Text('Guardar txt'),
                  ),
                  ElevatedButton(
                    style: btnStyle,
                    onPressed: () => saveToCsv(
                      context,
                      Text(widget.record.contaminante),
                      Text('${widget.record.concentracion} ppm'),
                      Text(DateFormat.yMd().add_jm().format(widget.record.fechaHora)),
                      oz,
                      ph,
                      cond,
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
