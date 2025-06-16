import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/record_service.dart';


class Historial_registros extends StatefulWidget {
   Historial_registros({super.key});
  @override
  State<Historial_registros> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<Historial_registros> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final rs = context.watch<RecordService>();
    final records =
    selectedDate == null ? rs.records : rs.byDate(selectedDate!);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar registro')),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => selectedDate = d);
                  },
                  child: Text(
                    selectedDate == null
                        ? 'Filtrar por fecha'
                        : DateFormat.yMd().format(selectedDate!),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(records[i].contaminante),
                subtitle: Text(
                  '${records[i].concentracion} ppm — '
                      '${DateFormat.yMd().add_jm().format(records[i].fechaHora)}',
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }
}
