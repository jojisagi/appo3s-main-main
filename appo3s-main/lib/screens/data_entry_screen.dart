import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/record.dart';
import '../services/record_service.dart';

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});
  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String contaminante = '';
  double concentracion = 0;
  DateTime fecha = DateTime.now();
  TimeOfDay hora = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar datos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
              const SizedBox(height: 20),
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
                child: Text(
                  'Fecha: ${fecha.toLocal().toString().split(' ')[0]}',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: hora,
                  );
                  if (t != null) setState(() => hora = t);
                },
                child: Text(
                  'Hora: ${hora.format(context)}',
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final fechaHora = DateTime(
                      fecha.year,
                      fecha.month,
                      fecha.day,
                      hora.hour,
                      hora.minute,
                    );
                    Provider.of<RecordService>(context, listen: false).addRecord(
                      Record(
                        contaminante: contaminante,
                        concentracion: concentracion,
                        fechaHora: fechaHora, tipo: '',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Registro guardado exitosamente'),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
