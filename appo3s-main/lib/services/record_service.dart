//record_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/record.dart';
import 'api_config.dart';

class RecordService extends ChangeNotifier {
  final List<Record> _records = [];
  List<Record> get records => _records;

  // ─────────────────────────  GET ALL  ──────────────────────────
  Future<void> fetchAll() async {
    try {
      final uri = Uri.parse('$baseUrl/records');
      final res  = await http.get(uri).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      final data = jsonDecode(res.body) as List;
      _records
        ..clear()
        ..addAll(data.map((e) => Record.fromJson(e as Map<String, dynamic>)));

      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchAll → $e');
      rethrow;                              // deja que la UI lo gestione
    }
  }

  // ────────────────────────  INSERT & SYNC  ─────────────────────
  Future<void> addRecord(Record record) async {
    _records.add(record);
    notifyListeners();                       // pinta al instante

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toJson()),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw 'POST ${res.statusCode}';
      }
      await fetchAll();                      // refresca con la BD real
    } catch (e) {
      _records.remove(record);               // revierte
      notifyListeners();
      debugPrint('❌ addRecord → $e');
    }
  }

  // ────────────────────────  FILTRO POR FECHA  ──────────────────
  List<Record> byDate(DateTime d) =>
      _records.where((r) =>
      r.fechaHora.year  == d.year &&
          r.fechaHora.month == d.month &&
          r.fechaHora.day   == d.day).toList();
}
