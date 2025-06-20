import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/record.dart';
import '../services/record_service.dart';
import '../models/muestreo.dart';

class RecordForm extends StatefulWidget {

  Muestreo muestreo_ozone;
  Muestreo muestreo_ph ;
  Muestreo muestreo_conductivity;

  RecordForm({
    super.key,
    required this.muestreo_ozone,
    required this.muestreo_ph,
    required this.muestreo_conductivity,
  });

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
              validator: (v) =>
              v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Concentración (ppm)'),
              keyboardType: TextInputType.number,
              onSaved: (v) => concentracion = double.tryParse(v ?? '0') ?? 0,
              validator: (v) =>
              v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: fecha,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => fecha = d);
              },
              label: Text('Fecha: ${fecha.toIso8601String().split('T').first}'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.access_time),
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: hora,
                );
                if (t != null) setState(() => hora = t);
              },
              label: Text('Hora: ${hora.format(context)}'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
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
                    muestreo_ozone: widget.muestreo_ozone,
                    muestreo_ph: widget.muestreo_ph, 
                    muestreo_conductivity: widget.muestreo_conductivity,
                  ),
                );
                Navigator.pop(context); // cierra el formulario
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
