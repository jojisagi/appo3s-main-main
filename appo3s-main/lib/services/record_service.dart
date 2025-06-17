//record_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/record.dart';
import 'api_config.dart';

class RecordService extends ChangeNotifier {
  final List<Record> _records = [];
  List<Record> get records => List.unmodifiable(_records);

  /* ──────────────── DESCARGAR TODOS ──────────────── */
  Future<void> fetchAll() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/records'))
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      _records
        ..clear()
        ..addAll((jsonDecode(res.body) as List)
            .map((e) => Record.fromJson(e as Map<String, dynamic>)));

      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchAll → $e');
      rethrow;
    }
  }

  /* ───────────── INSERTAR Y SINCRONIZAR ───────────── */
  Future<void> addRecord(Record r) async {
    _records.add(r);
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(r.toJson()),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw 'POST ${res.statusCode}';
      }
      await fetchAll();
    } catch (e) {
      _records.remove(r);
      notifyListeners();
      debugPrint('❌ addRecord → $e');
    }
  }

  /* ───────────── FILTROS DE AYUDA ───────────── */
  List<Record> byDate(DateTime d) => _records.where((r) =>
  r.fechaHora.year == d.year &&
      r.fechaHora.month == d.month &&
      r.fechaHora.day == d.day).toList();

  /// NUEVO ▸ filtra por tipo/contaminante (pH, cond, O3…)
  List<Record> byType(String t) =>
      _records.where((r) => r.tipo == t).toList();
}