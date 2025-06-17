import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/record.dart';
import 'api_config.dart';

class RecordService extends ChangeNotifier {
  final List<Record> _records = [];
  List<Record> get records => _records;

  /// ───── Descarga todos los registros ─────
  Future<void> fetchAll() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/records'))
          .timeout(const Duration(seconds: 20));          // timeout 20 s

      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      final List data = jsonDecode(res.body);
      _records
        ..clear()
        ..addAll(data.map((e) => Record.fromJson(e)));

      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchAll → $e');
      rethrow;
    }
  }

  /// ───── Inserta y sincroniza ─────
  Future<void> addRecord(Record record) async {
    _records.add(record);            // pinta al instante
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toJson()),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw 'POST ${res.statusCode}';
      }

      await fetchAll();              // refresca con la DB real
    } catch (e) {
      _records.remove(record);       // revierte si falló
      notifyListeners();
      debugPrint('❌ addRecord → $e');
    }
  }

  /// ───── Filtro por fecha ─────
  List<Record> byDate(DateTime d) => _records.where((r) {
    final f = r.fechaHora;
    return f.year == d.year && f.month == d.month && f.day == d.day;
  }).toList();
}
