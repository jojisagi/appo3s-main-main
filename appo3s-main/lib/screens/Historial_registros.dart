import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/record_service.dart';

class HistorialRegistros extends StatefulWidget {
  const HistorialRegistros({super.key});

  @override
  State<HistorialRegistros> createState() => _HistorialRegistrosState();
}

class _HistorialRegistrosState extends State<HistorialRegistros> {
  DateTime? selectedDate;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();                     // descarga al abrir la pantalla
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
  Widget build(BuildContext context) {
    final rs = context.watch<RecordService>();
    final registros =
    selectedDate == null ? rs.records : rs.byDate(selectedDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de registros'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error: $_error',
            style: const TextStyle(color: Colors.red)),
      )
          : Column(
        children: [
          // ─── Filtro + Recarga ───────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: Text(
                      selectedDate == null
                          ? 'Filtrar por fecha'
                          : DateFormat.yMd().format(selectedDate!),
                    ),
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
                  tooltip: 'Recargar',
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _fetch();
                  },
                ),
              ],
            ),
          ),
          // ─── Lista ──────────────────────────────
          Expanded(
            child: registros.isEmpty
                ? const Center(child: Text('Sin registros'))
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: registros.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = registros[i];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.contaminante,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${r.concentracion} ppm',
                              style:
                              const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMd()
                              .add_jm()
                              .format(r.fechaHora),
                          style: TextStyle(
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
