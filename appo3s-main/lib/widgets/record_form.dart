import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/record.dart';
import '../services/record_service.dart';

class RecordForm extends StatefulWidget {
  const RecordForm({super.key});
  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final _formKey = GlobalKey<FormState>();
  String contaminante = '';
  double concentracion = 0;
  DateTime fecha = DateTime.now();
  TimeOfDay hora = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Contaminante'),
              onSaved: (v) => contaminante = v ?? '',
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            TextFormField(
              decoration:
              const InputDecoration(labelText: 'Concentración (ppm)'),
              keyboardType: TextInputType.number,
              onSaved: (v) => concentracion = double.parse(v ?? '0'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: fecha,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => fecha = d);
              },
              child: Text('Fecha: ${fecha.toIso8601String().split('T').first}'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final t =
                await showTimePicker(context: context, initialTime: hora);
                if (t != null) setState(() => hora = t);
              },
              child: Text('Hora: ${hora.format(context)}'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                _formKey.currentState?.save();
                final fechaHora = DateTime(
                  fecha.year,
                  fecha.month,
                  fecha.day,
                  hora.hour,
                  hora.minute,
                );
                context.read<RecordService>().addRecord(
                  Record(
                    contaminante: contaminante,
                    concentracion: concentracion,
                    fechaHora: fechaHora,
                  ),
                );
                Navigator.pop(context); // cierra el sheet
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
