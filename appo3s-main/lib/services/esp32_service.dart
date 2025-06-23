import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';        // ← para context / Provider
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/record.dart';
import 'api_config.dart';                      // baseUrl para el backend
import 'calibration_service.dart';            // offsets de calibración

/// Servicio que interroga al ESP32 (`/data`) y mantiene un búfer en memoria
///
/// GET http://<ip>/data ⇒
/// ```json
/// {
///   "o3":   0.34,        // ppm
///   "cond": 420.0,       // µS/cm
///   "ph":   7.15,
///   "timestamp": "2025-06-18T12:34:56Z"
/// }
/// ```
class Esp32Service extends ChangeNotifier {
  Esp32Service({
    required this.esp32Ip,
    this.interval      = const Duration(seconds: 2),
    this.maxSamples    = 300,
    this.syncToBackend = false,
  });

  // ───────────── configuración ─────────────
  final String   esp32Ip;
  final Duration interval;
  final int      maxSamples;
  final bool     syncToBackend;

  // ─────────── estado / buffers ────────────
  final Map<String, List<Record>> buffer = {
    'o3'  : <Record>[],
    'cond': <Record>[],
    'ph'  : <Record>[],
  };

  bool        espOnline    = false;
  String?     lastError;
  DateTime?   lastSuccess;
  Timer?      _ticker;

  // Se obtiene en caliente con Provider cuando haga falta
  CalibrationService get _calSrv =>
      _calibrationKey.currentContext!.read<CalibrationService>();
  static final _calibrationKey = GlobalKey(); // se inyecta en arriba del árbol

  // ──────────── API pública ────────────────
  void startPolling() {
    _ticker?.cancel();
    _fetchOnce();                                      // primera llamada ahora
    _ticker = Timer.periodic(interval, (_) => _fetchOnce());
  }

  void stopPolling() => _ticker?.cancel();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ──────────── lógica interna ─────────────
  Future<void> _fetchOnce() async {
    try {
      final uri = Uri.parse('http://$esp32Ip/data');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      for (final k in ['o3', 'cond', 'ph', 'timestamp']) {
        if (!j.containsKey(k)) throw 'Campo "$k" ausente';
      }

      _add('o3',   j['o3'],   j['timestamp']);
      _add('cond', j['cond'], j['timestamp']);
      _add('ph',   j['ph'],   j['timestamp']);

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

  void _add(String tipo, num? rawValue, String ts) {
    if (rawValue == null) return;

    // Aplica calibración
    final corrected = rawValue.toDouble() - _calibrationOffset(tipo);

    final list = buffer[tipo]!;
    list.add(
      Record(
        contaminante : tipo,
        concentracion: corrected,
        fechaHora    : DateTime.tryParse(ts) ?? DateTime.now(),
      ),
    );
    if (list.length > maxSamples) list.removeAt(0);
  }

  double _calibrationOffset(String tipo) {
    switch (tipo) {
      case 'o3'  : return _calSrv.o3Offset;
      case 'ph'  : return _calSrv.phOffset;
      case 'cond': return _calSrv.condOffset;
      default    : return 0;
    }
  }

  Future<void> _syncLastToBackend() async {
    try {
      final latest = buffer.values
          .expand((l) => l)
          .reduce((a, b) => a.fechaHora.isAfter(b.fechaHora) ? a : b);

      await http.post(
        Uri.parse('$baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(latest.toJson()),
      );
    } catch (e) {
      debugPrint('⚠️ Sincronización backend falló: $e');
    }
  }
}
