// lib/screens/historial_registros.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/record.dart';
import '../services/record_service.dart';
import 'visualizando_registro.dart';

// Sólo arranca backend en desktop
import '../utils/backend_launcher_io.dart'
if (dart.library.html) '../utils/backend_launcher_stub.dart';

class HistorialRegistros extends StatefulWidget {
  const HistorialRegistros({super.key});

  @override
  State<HistorialRegistros> createState() => _HistorialRegistrosState();
}

class _HistorialRegistrosState extends State<HistorialRegistros> {
/* ────────── estado interno ────────── */
  DateTime? _selectedDate;
  String    _search      = '';
  bool      _loading     = true;
  String?   _error;

  /*  demo de simulación  */
  Timer? _poller, _simTimer;
  bool   _simulating = false;
  int    _elapsedSec = 0, _totalSec = 0;

/* ────────── ciclo de vida ────────── */
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

  @override
  void dispose() {
    _poller?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }

/* ────────── descarga desde Mongo ────────── */
  Future<void> _fetch() async {
    try {
      await context.read<RecordService>()
          .fetchAll()
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      _error = 'El servidor tardó demasiado en responder.';
    } catch (e) {
      _error = 'Error inesperado: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

/* ────────── filtros y agrupado ────────── */
  List<Record> _applyFilters(RecordService srv) {
    var list = _selectedDate == null
        ? srv.records
        : srv.byDate(_selectedDate!);

    if (_search.isNotEmpty) {
      list = list.where((r) =>
          r.contaminante.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  Map<String, List<Record>> _group(List<Record> rs) {
    final map = <String, List<Record>>{};
    for (final r in rs) {
      final k = DateFormat('yyyy-MM-dd').format(r.fechaHora);
      map.putIfAbsent(k, () => []).add(r);
    }
    return map;
  }


/* ────────── UI ────────── */
  @override
  Widget build(BuildContext context) {
    final srv      = context.watch<RecordService>();
    final filtered = _applyFilters(srv);
    final grouped  = _group(filtered);
    final days     = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: _buildAppBar(),

      body: Column(
        children: [
          if (_simulating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(
                value: _elapsedSec / max(_totalSec, 1),
                backgroundColor: Colors.grey.shade300,
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorPane(error: _error!, onRetry: () async {
              setState(() => _loading = true);
              await _fetch();
            })
                : _RegistroList(days: days, grouped: grouped),
          ),
        ],
      ),
    );
  }

/* ── App-bar con buscador y filtro ── */
  PreferredSizeWidget _buildAppBar() => AppBar(
    centerTitle: true,
    title: SizedBox(
      height: 36,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar contaminante…',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (txt) => setState(() => _search = txt),
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(38),
      child: Padding(
        padding:
        const EdgeInsets.only(left: 12, right: 4, bottom: 4, top: 6),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.filter_alt_outlined,
                    color: Colors.white),
                label: Text(
                  _selectedDate == null
                      ? 'Filtrar fecha'
                      : DateFormat.yMd().format(_selectedDate!),
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
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
            ),
          ],
        ),
      ),
    ),
  );
}

/* ────────── widgets auxiliares ────────── */

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off, color: Colors.red, size: 80),
        const SizedBox(height: 16),
        const Text('No se pudo conectar con el servidor.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          onPressed: onRetry,
        ),
      ],
    ),
  );
}

class _RegistroList extends StatelessWidget {
  const _RegistroList({required this.days, required this.grouped});
  final List<String> days;
  final Map<String, List<Record>> grouped;

  @override
  Widget build(BuildContext context) {
    final fetch = context
        .findAncestorStateOfType<_HistorialRegistrosState>()!._fetch;

    return RefreshIndicator(
      onRefresh: fetch,
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
        itemBuilder: (_, i) {
          final day = days[i];
          final list = grouped[day]!;
          return ExpansionTile(
            initiallyExpanded: i == 0,
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(
              DateFormat.yMMMMd().format(DateTime.parse(day)),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: list.map((r) {
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: Text(r.contaminante),
                  subtitle: Text(DateFormat.jm().format(r.fechaHora)),
                  trailing:
                  Text('${r.concentracion.toStringAsFixed(2)} ppm'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          VisualizandoRegistros(record: r),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
