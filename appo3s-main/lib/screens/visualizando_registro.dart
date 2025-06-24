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
final Record record;                     // ← único parámetro
const VisualizandoRegistros({
Key? key,
required this.record,
}) : super(key: key);

@override
State<VisualizandoRegistros> createState() =>
_VisualizandoRegistrosState();
}

class _VisualizandoRegistrosState extends State<VisualizandoRegistros> {
/* ────────── copias locales (no alteran el record original) ────────── */
  late Muestreo oz;
  late Muestreo cond;
  late Muestreo ph;

/* ────────── control de demo ────────── */
  Timer? _simTimer;
  bool   _simulating = false;
  int    _elapsed    = 0;   // seg transcurridos
  int    _total      = 0;   // seg objetivo

  @override
  void initState() {
    super.initState();
    // Se clonan para que la demo no afecte el registro almacenado
    oz   = widget.record.muestreo_ozone.deepCopy();
    cond = widget.record.muestreo_conductivity.deepCopy();
    ph   = widget.record.muestreo_ph.deepCopy();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  /* ───────────────── DEMO / SIMULACIÓN ───────────────── */

  Future<void> _pedirYArrancarSim() async {
    if (_simulating) return;

    final segundos = await _dialogPedirSegundos();
    if (segundos == null || segundos <= 0) return;

    setState(() {
      _simulating = true;
      _elapsed    = 0;
      _total      = segundos;

      // “Reiniciamos” las listas para que la animación empiece en vacío
      oz  .clearSamples();
      cond.clearSamples();
      ph  .clearSamples();
    });

    final rnd = Random();

    _simTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      _elapsed++;

      // Generamos tres lecturas sintéticas
      oz  .addSample(_makeSample(_elapsed, rnd.nextDouble()       ));    // 0-1   ppm
      cond.addSample(_makeSample(_elapsed, rnd.nextDouble()*2000 ));    // 0-2000 µS
      ph  .addSample(_makeSample(_elapsed, rnd.nextDouble()*13 + 1));   // 1-14   pH

      setState(() {});                          // fuerza repaint

      if (_elapsed >= _total) {
        t.cancel();
        await _finalizarDemo();
      }
    });
  }

  Future<int?> _dialogPedirSegundos() => showDialog<int>(
    context: context,
    builder: (_) {
      final ctrl = TextEditingController(text: '90');
      return AlertDialog(
        title: const Text('Duración de la simulación (seg)'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Ej.: 120'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(ctrl.text)),
            child: const Text('Iniciar'),
          ),
        ],
      );
    },
  );

  Sample _makeSample(int sec, double y) => Sample(
    numSample       : 0,
    selectedMinutes : sec ~/ 60,
    selectedSeconds : sec % 60,
    y               : y,
  );

  Future<void> _finalizarDemo() async {
    setState(() => _simulating = false);

    // Creamos un nuevo Record con los muestreos recién generados
    final nuevo = widget.record.copyWith(
      fechaHora            : DateTime.now(),
      muestreo_ozone       : oz.deepCopy(),
      muestreo_conductivity: cond.deepCopy(),
      muestreo_ph          : ph.deepCopy(),
    );

    // Guardamos (POST) — RecordService maneja reintentos
    await context.read<RecordService>().addRecord(nuevo);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulación finalizada y guardada')),
      );
    }
  }

  /* ──────────────────── UI ──────────────────── */

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registro')),
    floatingActionButton: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
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
        const SizedBox(width: 12),
        ElevatedButton(
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
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon : const Icon(Icons.play_arrow),
          label: const Text('Simular'),
          onPressed: _simulating ? null : _pedirYArrancarSim,
        ),
      ],
    ),
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
          if (_simulating) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _elapsed / max(_total, 1),          // evita ÷0
              backgroundColor: Colors.grey.shade300,
            ),
          ],
          const SizedBox(height: 20),
          Creando_OzoneChart(muestreo: oz),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Creando_ConductivityChart(muestreo: cond)),
              const SizedBox(width: 20),
              Expanded(child: Creando_PhChart(muestreo: ph)),
            ],
          ),
        ],
      ),
    ),
  );
}
