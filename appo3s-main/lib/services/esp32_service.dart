import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/record.dart';
import 'api_config.dart'; // para _syncToBackend (opcional)

/// Servicio que consulta cada [interval] segundos el JSON del ESP32
/// y mantiene un _buffer_ circular de [maxSamples] mediciones por tipo.
///
///  GET  http://<ip-esp32>/data  ⟶
///  {
///    "o3":   0.34,      // ppm
///    "cond": 420.0,     // µS/cm
///    "ph":   7.15,
///    "timestamp": "2025-06-18T12:34:56Z"
///  }
class Esp32Service extends ChangeNotifier {
  Esp32Service({
    required this.esp32Ip,
    this.interval   = const Duration(seconds: 2),
    this.maxSamples = 300,
    this.syncToBackend = false,
  });

  // ── Configuración ──────────────────────────────────────────────────
  final String   esp32Ip;            // IP o mDNS del micro
  final Duration interval;           // periodo de polling
  final int      maxSamples;         // “ventana” circular
  final bool     syncToBackend;      // POST a /records

  // ── Estado / buffers ──────────────────────────────────────────────
  final Map<String, List<Record>> buffer = {
    'o3'  : <Record>[],
    'cond': <Record>[],
    'ph'  : <Record>[],
  };

  bool    espOnline    = false;      // para mostrar en UI
  String? lastError;                 // último error (debug)
  DateTime? lastSuccess;

  Timer? _ticker;

  // ── API pública ───────────────────────────────────────────────────
  void startPolling() {
    _ticker?.cancel();
    _fetchOnce();                                   // primer intento inmediato
    _ticker = Timer.periodic(interval, (_) => _fetchOnce());
  }

  void stopPolling() => _ticker?.cancel();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── HELPERS internos ──────────────────────────────────────────────
  Future<void> _fetchOnce() async {
    try {
      final uri = Uri.parse('http://$esp32Ip/data');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      final Map<String, dynamic> j = jsonDecode(res.body);

      // Validación mínima
      for (final k in ['o3', 'cond', 'ph', 'timestamp']) {
        if (!j.containsKey(k)) throw 'Campo $k ausente';
      }

      _add('o3',   j['o3'],   j['timestamp']);
      _add('cond', j['cond'], j['timestamp']);
      _add('ph',   j['ph'],   j['timestamp']);

      espOnline   = true;
      lastError   = null;
      lastSuccess = DateTime.now();
      notifyListeners();

      if (syncToBackend) await _syncLastToBackend();
    } catch (e) {
      espOnline = false;
      lastError = e.toString();
      debugPrint('❌ ESP32 fetch error: $lastError');
      notifyListeners();
    }
  }

  void _add(String key, num? value, String ts) {
    if (value == null) return;                       // descarta nulos
    final list = buffer[key]!;
    list.add(
      Record(
        tipo: key,
        contaminante: key,
        concentracion: value.toDouble(),
        fechaHora: DateTime.tryParse(ts) ?? DateTime.now(),
      ),
    );
    if (list.length > maxSamples) list.removeAt(0);  // ventana circular
  }

  /// Envía la última muestra de cada tipo al backend REST (opcional).
  Future<void> _syncLastToBackend() async {
    try {
      final latestO3 = buffer['o3']!.isNotEmpty ? buffer['o3']!.last : null;
      if (latestO3 == null) return;

      await http.post(
        Uri.parse('$baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(latestO3.toJson()),
      );
    } catch (e) {
      debugPrint('⚠️  No se pudo sincronizar con backend: $e');
    }
  }
}
