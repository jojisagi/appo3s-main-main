import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/record.dart';
import 'api_config.dart';   // ← para baseUrl cuando syncToBackend = true

/// Servicio que consulta cada [interval] el JSON expuesto por tu ESP32.
///
///  GET http://<IP>/data  =>
///  {
///    "o3"       : 0.34,          // ppm
///    "cond"     : 420.0,         // µS/cm
///    "ph"       : 7.15,
///    "timestamp": "2025-06-18T12:34:56Z"
///  }
class Esp32Service extends ChangeNotifier {
  Esp32Service({
    required this.esp32Ip,
    this.interval      = const Duration(seconds: 2),
    this.maxSamples    = 300,
    this.syncToBackend = false,
  });

  // ───────────────────────── config ─────────────────────────
  final String   esp32Ip;            // IP o mDNS del micro
  final Duration interval;           // periodo de polling
  final int      maxSamples;         // ventana circular
  final bool     syncToBackend;      // POST a /records (opcional)

  // ───────────── buffers (histórico en memoria) ─────────────
  final Map<String, List<Record>> buffer = {
    'o3'  : <Record>[],
    'cond': <Record>[],
    'ph'  : <Record>[],
  };

  bool        espOnline    = false;     // útil para mostrar en UI
  String?     lastError;                // último error
  DateTime?   lastSuccess;              // último fetch OK
  Timer?      _ticker;

  // ───────────────────── API pública ───────────────────────
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

  // ─────────────────── lógica interna ──────────────────────
  Future<void> _fetchOnce() async {
    try {
      final uri  = Uri.parse('http://$esp32Ip/data');
      final res  = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      final Map<String, dynamic> j = jsonDecode(res.body);

      // Validación rápida
      for (final k in ['o3', 'cond', 'ph', 'timestamp']) {
        if (!j.containsKey(k)) throw 'Campo "$k" ausente';
      }

      _add('o3'  , j['o3']  , j['timestamp']);
      _add('cond', j['cond'], j['timestamp']);
      _add('ph'  , j['ph']  , j['timestamp']);

      espOnline   = true;
      lastError   = null;
      lastSuccess = DateTime.now();
      notifyListeners();

      if (syncToBackend) _syncLastToBackend();
    } catch (e, st) {
      espOnline = false;
      lastError = e.toString();
      debugPrint('❌ ESP32 fetch error: $e\n$st');
      notifyListeners();
    }
  }

  void _add(String key, num? value, String ts) {
    if (value == null) return;
    final list = buffer[key]!;
    list.add(
      Record(
       
        contaminante  : key,
        concentracion : value.toDouble(),
        fechaHora     : DateTime.tryParse(ts) ?? DateTime.now(),
      ),
    );
    if (list.length > maxSamples) list.removeAt(0);   // mantiene la “ventana”
  }

  Future<void> _syncLastToBackend() async {
    try {
      final latest = buffer.entries
          .expand((e) => e.value)
          .fold<Record?>(null, (p, c) => p == null || c.fechaHora.isAfter(p.fechaHora) ? c : p);

      if (latest == null) return;

      await http.post(
        Uri.parse('$baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(latest.toJson()),
      );
    } catch (e) {
      debugPrint('⚠️  Sincronización backend falló: $e');
    }
  }
}
