// screens/historial_registros.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/record.dart';
import '../services/record_service.dart';
import 'visualizando_registro.dart';

// Lanza backend sólo en desktop
import '../utils/backend_launcher_io.dart'
if (dart.library.html) '../utils/backend_launcher_stub.dart';

class HistorialRegistros extends StatefulWidget {
  const HistorialRegistros({super.key});
  @override
  State<HistorialRegistros> createState() => _HistorialRegistrosState();
}

class _HistorialRegistrosState extends State<HistorialRegistros> {
  DateTime? _selectedDate;
  String    _search = '';
  bool      _loading = true;
  String?   _error;
  Timer?    _poller;

  /* ───────── init & fetch ───────── */
  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    if (!kIsWeb) await BackendLauncher.launchIfNeeded();
    await _fetch();
    _poller = Timer.periodic(
      const Duration(seconds: 15),
          (_) => context.read<RecordService>().fetchAll(),
    );
  }

  Future<void> _fetch() async {
    try {
      await context.read<RecordService>().fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  /* ───────── helpers ───────── */

  Map<String, List<Record>> _group(List<Record> rs) {
    final map = <String, List<Record>>{};
    for (final r in rs) {
      final k = DateFormat('yyyy-MM-dd').format(r.fechaHora);
      map.putIfAbsent(k, () => []).add(r);
    }
    return map;
  }

  List<Record> _applyFilters(RecordService srv) {
    var list = _selectedDate == null
        ? srv.records
        : srv.byDate(_selectedDate!);

    if (_search.isNotEmpty) {
      list = list
          .where((r) =>
          r.contaminante.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    final srv      = context.watch<RecordService>();
    final filtered = _applyFilters(srv);
    final grouped  = _group(filtered);
    final days     = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SizedBox(
          height: 36,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar contaminante…',
              filled  : true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide : BorderSide.none,
              ),
            ),
            onChanged: (txt) => setState(() => _search = txt),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 12, right: 4, bottom: 4, top: 6),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon : const Icon(Icons.filter_alt_outlined),
                    label: Text(_selectedDate == null
                        ? 'Filtrar fecha'
                        : DateFormat.yMd().format(_selectedDate!)),

                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate : DateTime(2020),
                        lastDate  : DateTime(2100),
                      );
                      if (d != null) setState(() => _selectedDate = d);
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Recargar',
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    setState(() => _loading = true);
                    await _fetch();
                  },
                )
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error',
          style: const TextStyle(color: Colors.red)))
          : RefreshIndicator(
        onRefresh: _fetch,
        child: days.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Sin registros')),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: days.length,
          itemBuilder: (ctx, i) {
            final day  = days[i];
            final list = grouped[day]!;
            return ExpansionTile(
              initiallyExpanded: i == 0,
              tilePadding: const EdgeInsets.symmetric(
                  horizontal: 4),
              title: Text(
                DateFormat.yMMMMd()
                    .format(DateTime.parse(day)),
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              children: [
                ...list.map((r) => Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VisualizandoRegistros(
                                fechaHora: Text(
                                    '${DateFormat.yMd().format(r.fechaHora)} – ${DateFormat.jm().format(r.fechaHora)}'),
                                contaminante:
                                Text(r.contaminante),
                                concentracion: Text(
                                    '${r.concentracion.toStringAsFixed(2)} ppm'),
                                muestreo_ozone:
                                r.muestreo_ozone,
                                muestreo_ph  : r.muestreo_ph,
                                muestreo_conductivity:
                                r.muestreo_conductivity,
                              ),
                        ),
                      );
                    },
                    leading: const Icon(
                        Icons.analytics_outlined),
                    title: Text(r.contaminante),
                    subtitle: Text(DateFormat.jm()
                        .format(r.fechaHora)),
                    trailing: Text(
                        '${r.concentracion.toStringAsFixed(2)} ppm'),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }
}
