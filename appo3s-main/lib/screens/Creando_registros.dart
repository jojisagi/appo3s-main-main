// lib/screens/creando_registros.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/muestreo.dart';
import '../models/record.dart';
import '../services/record_service.dart';
import '../widgets/creando_conductivity_chart.dart';
import '../widgets/creando_ozone_chart.dart';
import '../widgets/creando_ph_chart.dart';
import '../widgets/editing_samples.dart';
import '../widgets/record_form.dart';
import '../widgets/timer_widget.dart';

import '../services/esp32_por_cable_web.dart'
    if (dart.library.ffi) '../services/esp32_por_cable_win.dart';

import '../services/esp32_por_wifi.dart';
import '../services/esp32_manager.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/esp32_wifi_dns.dart';

class CreandoRegistros extends StatefulWidget {
  final Record? original;
  final ConnectionManager connectionManager;

  const CreandoRegistros({
    super.key,
    this.original,
    required this.connectionManager,
  });

  @override
  State<CreandoRegistros> createState() => _CreandoRegistrosState();
}



class _CreandoRegistrosState extends State<CreandoRegistros> {
/* ───────────────────────── 1. ESTADO PRINCIPAL ───────────────────────── */
  late Record   _record;           // único «source of truth»
  late Muestreo _ozone;
  late Muestreo _ph;
  late Muestreo _conductivity;
  final Muestreo _timePattern = Muestreo(); // pauta mm:ss del Timer

  bool     _patternSet  = false;
  bool     _started     = false;
  bool     _formEnabled = false;
  Duration _elapsed     = Duration.zero;
  Timer?   _ticker;
  final    _rnd = Random();

/* ───────────────────────── 2. INIT / DISPOSE ───────────────────────── */
  @override
  void initState() {
    super.initState();

    // ① Registro existente  o  ② esqueleto “vacío” (no se insertará aún)
    _record = widget.original ??
        Record(
          contaminante         : 'O₃',           // marcador temporal
          concentracion        : 0,
          fechaHora            : DateTime.now(),
          muestreoOzone        : Muestreo(),
          muestreoPh           : Muestreo(),
          muestreoConductivity : Muestreo(),
        );

    // Los buffers NO deben apuntar al mismo objeto
    _ozone        = _record.muestreoOzone.deepCopy();
    _ph           = _record.muestreoPh.deepCopy();
    _conductivity = _record.muestreoConductivity.deepCopy();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

/* ───────────────────────── 3. CALLBACKS PATRÓN ───────────────────────── */
  void _onSetPattern(Muestreo nuevo) {
    _patternSet  = true;
    _started     = false;
    _formEnabled = false;
    _elapsed     = Duration.zero;
    _ticker?.cancel();

    _timePattern.inicializar_con_otro_muestreo(nuevo);
    _ozone       .inicializar_con_otro_muestreo(nuevo);
    _ph          .inicializar_con_otro_muestreo(nuevo);
    _conductivity.inicializar_con_otro_muestreo(nuevo);

    setState(() {});
  }

/* ───────────────────────── 4. START / INJECT ───────────────────────── */
  void _onStart() {
    if (!_patternSet || _timePattern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes definir al menos una muestra')),
      );
      return;
    }
    if (_started) return;

    _started = true;
    _ticker  = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      _injectMockValuesIfNeeded();
      if (mounted) setState(() {}); // actualiza cronómetro
    });
  }

 Future<void> _injectMockValuesIfNeeded() async {
  if (_timePattern.index_actual >= _timePattern.count) {
    _ticker?.cancel();
    _started     = false;
    _formEnabled = true;

    _record = _record.copyWith(
      muestreoOzone        : _ozone.deepCopy(),
      muestreoPh           : _ph.deepCopy(),
      muestreoConductivity : _conductivity.deepCopy(),
      fechaHora            : DateTime.now(),
    );

    if (widget.original != null) {
      context.read<RecordService>().saveRecord(_record);
    }

    setState(() {});
    return;
  }

  final smp = _timePattern[_timePattern.index_actual];
  if (_elapsed.inSeconds < smp.totalSeconds) return;

  // 🛑 Pausa el timer mientras intenta leer los datos
  _ticker?.cancel();

  final m = smp.selectedMinutes;
  final sec = smp.selectedSeconds;

  while (true) {
    try {
      print('⏱️ Intentando inyectar datos en $m:$sec...');
      final data = await _datazo();

      // Si hay al menos un valor válido, considera que fue exitoso
      final bool valid = data.isNotEmpty &&
          (data['Ozono'] != null || data['pH'] != null || data['Conductividad'] != null);

      if (valid) {
        _ozone       .actualizarMuestras_time(m, sec, data['Ozono'] ?? 0.0);
        _ph          .actualizarMuestras_time(m, sec, data['pH'] ?? 0.0);
        _conductivity.actualizarMuestras_time(m, sec, data['Conductividad'] ?? 0.0);

        _timePattern.index_actual++;
        break; // ✅ Sal del while
      } else {
        print('❌ Datos inválidos, reintentando en 1 segundo...');
      }
    } catch (e) {
      print('❌ Error al obtener datos: $e');
    }

    // Esperar 1 segundo antes de reintentar
    await Future.delayed(const Duration(seconds: 1));
  }

  // ▶️ Reanudar el timer
  _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
    _elapsed += const Duration(seconds: 1);
    _injectMockValuesIfNeeded();
    if (mounted) setState(() {});
  });

  if (mounted) setState(() {});
}



Future<Map<String, double?>> conversion_map(Future<Map<String, String?>> oldi) async {
  final oldMap = await oldi;
  final Map<String, double?> newMap = {};

  oldMap.forEach((key, value) {
    newMap[key] = value != null ? double.tryParse(value) : null;
  });

  return newMap;
}



Future<Map<String, double?>> _datazo() async {
  print("La conexion es de tipo: ${widget.connectionManager.currentType}");

if (widget.connectionManager.currentType == ConnectionType.wifi) {
    final ip = widget.connectionManager.wifiService.ipAddress;
    if (ip != null) {
      return  obtenerDatosNumericos(ip);
    } else {
      print("❌ Sin conexión WiFi");
      return {};
    }
  } else if (widget.connectionManager.currentType == ConnectionType.serial) {

    if (widget.connectionManager.serialService.isConnected) {
     await widget.connectionManager.serialService.enviarComando("GET_DATA");

    final datos = await widget.connectionManager.serialService.getData();  
      if (datos != null) {

         final Map<String, double?> datosConvertidos = datos.map((key, value) {
          return MapEntry(key, value?.toDouble());
        });

        return datosConvertidos;

       // return datos; // Éxito
      } else {
        print("❌ No se encontraron datos");
        return {};
      }

     
    
    } else {
      print("❌ Sin conexion x cable");
      return {};
    }
  }

  print("❌ Conexión no soportada");



return {};
}




/* ───────────────────────── 5. UI ───────────────────────── */
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.original == null
          ? 'Nuevo registro'
          : 'Editando registro'),
    ),
    body: _GraphsBody(
      key                 : ValueKey(_timePattern.hashCode),
      muestreoTime        : _timePattern,
      muestreoOzone       : _ozone,
      muestreoPh          : _ph,
      muestreoConductivity: _conductivity,
      onStart             : _onStart,
    ),
    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /* ---- SET PATRÓN ---- */
        FloatingActionButton.extended(
          heroTag : 'Set',
          icon    : const Icon(Icons.timer),
          label   : const Text('Set'),
          onPressed: () => showModalBottomSheet(
            context           : context,
            isScrollControlled: true,
            builder           : (_) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: EditingSamples(
                muestreo        : _timePattern.deepCopy(),
                onSamplesUpdated: _onSetPattern,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        /* ---- CAPTURAR ---- */
        FloatingActionButton.extended(
          heroTag : 'Record',
          icon    : const Icon(Icons.check),
          label   : const Text('Capturar'),
          backgroundColor: _formEnabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          onPressed: _formEnabled
              ? () => showModalBottomSheet(
            context           : context,
            isScrollControlled: true,
            builder           : (_) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child : RecordForm(
                muestreoOzone       : _ozone,
                muestreoPh          : _ph,
                muestreoConductivity: _conductivity,
              ),
            ),
          )
              : () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
              Text('Debes completar el muestreo primero.'),
            ),
          ),
        ),
      ],
    ),
  );
}

/* ──────────────────── cuerpo con gráficas ──────────────────── */
class _GraphsBody extends StatelessWidget {
  final Muestreo     muestreoTime;
  final Muestreo     muestreoOzone;
  final Muestreo     muestreoPh;
  final Muestreo     muestreoConductivity;
  final VoidCallback onStart;

  const _GraphsBody({
    super.key,
    required this.muestreoTime,
    required this.muestreoOzone,
    required this.muestreoPh,
    required this.muestreoConductivity,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TimerWidget(muestreo: muestreoTime, onStart: onStart),
        const SizedBox(height: 20),
        Creando_OzoneChart(
          key     : ValueKey(muestreoOzone.hashCode),
          muestreo: muestreoOzone,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Creando_ConductivityChart(
                key     : ValueKey(muestreoConductivity.hashCode),
                muestreo: muestreoConductivity,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Creando_PhChart(
                key     : ValueKey(muestreoPh.hashCode),
                muestreo: muestreoPh,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}