// lib/widgets/record_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/muestreo.dart';
import '../models/record.dart';
import '../services/record_service.dart';

class RecordForm extends StatefulWidget {
  final Muestreo muestreoOzone;
  final Muestreo muestreoPh;
  final Muestreo muestreoConductivity;
  final Muestreo muestreotemp;

  const RecordForm({
    super.key,
    required this.muestreoOzone,
    required this.muestreoPh,
    required this.muestreoConductivity,
    required this.muestreotemp,
  });

  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final _formKey = GlobalKey<FormState>();

  String    _contaminante  = '';
  double    _concentracion = 0;
  DateTime  _fecha         = DateTime.now();
  TimeOfDay _hora          = TimeOfDay.now();
    // Control para diálogo abierto
  bool _dialogoAbierto = false;

    void _mostrarDialogo(String mensaje) {
    if (_dialogoAbierto) return;
    _dialogoAbierto = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(mensaje)),
          ],
        ),
      ),
    ).then((_) {
      _dialogoAbierto = false;
    });
  }

  void _cerrarDialogo() {
    if (_dialogoAbierto && mounted && Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogoAbierto = false;
    }
  }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /* ─── contaminante ─── */
          TextFormField(
            decoration:
            const InputDecoration(labelText: 'Contaminante'),
            onSaved: (v) => _contaminante = v?.trim() ?? '',
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          ),

          /* ─── concentración ─── */
          TextFormField(
            decoration:
            const InputDecoration(labelText: 'Concentración (ppm)'),
            keyboardType: TextInputType.number,
            onSaved: (v) =>
            _concentracion = double.tryParse(v ?? '') ?? 0,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Campo requerido';
              }
              final d = double.tryParse(v);
              if (d == null) return 'Ingrese un número válido';
              if (d <= 0) return 'Debe ser un valor positivo';
              return null;
            },
          ),
          const SizedBox(height: 16),

          /* ─── selector FECHA ─── */
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              'Fecha: ${_fecha.toIso8601String().split('T').first}',
            ),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _fecha,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _fecha = d);
            },
          ),
          const SizedBox(height: 8),

          /* ─── selector HORA ─── */
          ElevatedButton.icon(
            icon: const Icon(Icons.access_time),
            label: Text('Hora: ${_hora.format(context)}'),
            onPressed: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _hora,
              );
              if (t != null) setState(() => _hora = t);
            },
          ),
          const SizedBox(height: 24),

          /* ─── GUARDAR ─── */
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              _formKey.currentState!.save();

              final fechaHora = DateTime(
                _fecha.year,
                _fecha.month,
                _fecha.day,
                _hora.hour,
                _hora.minute,
              );

              final nuevo = Record(
                contaminante        : _contaminante,
                concentracion       : _concentracion,
                fechaHora           : fechaHora,
                muestreoOzone       : widget.muestreoOzone.deepCopy(),
                muestreoPh          : widget.muestreoPh.deepCopy(),
                muestreoConductivity: widget.muestreoConductivity.deepCopy(),
               muestreoTemperatura: widget.muestreotemp.deepCopy(),
              );

              _mostrarDialogo('Guardando en base de datos...');
              // up-sert: crea o actualiza sin duplicar
              await context.read<RecordService>().saveRecord(nuevo);
                  

                  
              if (mounted) {
                _cerrarDialogo();               // cierra el diálogo de carga
                Navigator.pop(context);                 // cierra el modal
                
              
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Registro guardado exitosamente'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
                


              
            },
          ),
        ],
      ),
    ),
  );
}
