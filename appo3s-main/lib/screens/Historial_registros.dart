import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/record.dart';
import '../services/record_service.dart';
import '../screens/visualizando_registro.dart';

// ------------ import condicional: sólo desktop arranca backend -------------
import '../utils/backend_launcher_io.dart'
if (dart.library.html) '../utils/backend_launcher_stub.dart';

class HistorialRegistros extends StatefulWidget {
  const HistorialRegistros({super.key});

  @override
  State<HistorialRegistros> createState() => _HistorialRegistrosState();
}

class _HistorialRegistrosState extends State<HistorialRegistros> {
  DateTime? selectedDate;
  bool _loading = true;
  String? _error;
  Timer? _poller;

  // ───────────── INIT ─────────────
  @override
  void initState() {
    super.initState();
    _initAndFetch();          // 👈
  }

  Future<void> _initAndFetch() async {
    // 1) Arranca backend si procede (sólo desktop)
    if (!kIsWeb) await BackendLauncher.launchIfNeeded();

    // 2) Descarga registros
    await _fetch();

    // 3) Refresco automático cada 15 s
    _poller = Timer.periodic(
      const Duration(seconds: 15),
          (_) => context.read<RecordService>().fetchAll(),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  // ───────────── DESCARGA ─────────────
  Future<void> _fetch() async {
    try {
      await context.read<RecordService>().fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) {
    final rs        = context.watch<RecordService>();
    final registros = selectedDate == null ? rs.records : rs.byDate(selectedDate!);

    // Agrupamos por día (YYYY-MM-DD)
    final mapa = <String, List<Record>>{};
    for (final r in registros) {
      final clave = DateFormat('yyyy-MM-dd').format(r.fechaHora);
      mapa.putIfAbsent(clave, () => []).add(r);
    }
    final dias = mapa.keys.toList()..sort((a, b) => b.compareTo(a)); // Desc.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de registros'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
          child: Text('Error: $_error',
              style: const TextStyle(color: Colors.red)))
          : Column(
        children: [
          // ── Barra de filtro y recarga manual ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: Text(selectedDate == null
                        ? 'Filtrar por fecha'
                        : DateFormat.yMd().format(selectedDate!)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        setState(() => selectedDate = d);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() => _loading = true);
                    _fetch();
                  },
                ),
              ],
            ),
          ),

          // ── Lista agrupada ──
          Expanded(
            child: dias.isEmpty
                ? const Center(child: Text('Sin registros'))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: dias.length,
              itemBuilder: (_, index) {
                final dia   = dias[index];
                final lista = mapa[dia]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        DateFormat.yMMMMd()
                            .format(DateTime.parse(dia)),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    ...lista.map(
                          (r) => Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    VisualizandoRegistros(
                                      fechaHora: Text(
                                        '${DateFormat.yMd().format(r.fechaHora)} - '
                                            '${DateFormat.jm().format(r.fechaHora)}',
                                      ),
                                      contaminante: Text(r.contaminante),
                                      concentracion: Text(
                                        '${r.concentracion.toStringAsFixed(2)} ppm',
                                      ),
                                      muestreo_ozone: r.muestreo_ozone,
                                      muestreo_ph: r.muestreo_ph,
                                      muestreo_conductivity:
                                      r.muestreo_conductivity,
                                    ),
                              ),
                            ),
                            child: ListTile(
                              title: Text(r.contaminante),
                              subtitle:
                              Text(DateFormat.jm().format(r.fechaHora)),
                              trailing:
                              Text('${r.concentracion} ppm'),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
