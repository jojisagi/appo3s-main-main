import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/record.dart';

/// Servicio que consulta cada [n] segundos el endpoint JSON que expone tu ESP32
/// ────────────────────────────────────────────────────────────────────────────
/// GET  http://<IP-ESP32>/data  ⇒
/// {
///   "o3":   0.34,         // ppm
///   "cond": 420.0,        // μS/cm
///   "ph":   7.15,
///   "timestamp": "2025-06-18T12:34:56Z"
/// }
class Esp32Service extends ChangeNotifier {
  Esp32Service({required this.esp32Ip});

  /// IP o hostname del microcontrolador
  final String esp32Ip;

  /// Historial en memoria (máx 300 registros por tipo)
  final Map<String, List<Record>> buffer = {
    'o3':   <Record>[],
    'cond': <Record>[],
    'ph':   <Record>[],
  };

  Timer? _ticker;

  /// Comienza el polling continuo
  ///
  /// * [period] intervalo entre peticiones (por defecto 2 s)
  void startPolling({Duration period = const Duration(seconds: 2)}) {
    _ticker?.cancel();
    _ticker = Timer.periodic(period, (_) => _fetchOnce());
  }

  /// Detiene el polling
  void stopPolling() => _ticker?.cancel();

  /* ────────────────────────────── PRIVATE ────────────────────────────── */

  Future<void> _fetchOnce() async {
    try {
      final uri = Uri.parse('http://$esp32Ip/data');
      final res  = await http.get(uri).timeout(const Duration(seconds: 3));

      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      _add('o3',   json['o3']   as num, json['timestamp'] as String);
      _add('cond', json['cond'] as num, json['timestamp'] as String);
      _add('ph',   json['ph']   as num, json['timestamp'] as String);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ ESP32 fetch error: $e');
    }
  }

  void _add(String key, num value, String ts) {
    final list = buffer[key]!;
    list.add(
      Record(
        tipo: key,
        concentracion: value.toDouble(),
        fechaHora: DateTime.parse(ts),
        contaminante: key,          // no importa para las gráficas
      ),
    );
    if (list.length > 300) list.removeAt(0);   // mantiene la ventana
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
