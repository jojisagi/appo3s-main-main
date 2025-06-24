// lib/services/record_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/record.dart';
import 'api_config.dart';

class RecordService extends ChangeNotifier {
  /* ─────────── cache en memoria ─────────── */
  final List<Record> _records = [];

  List<Record> get records => List.unmodifiable(_records);

  /// Devuelve sólo los registros del día `d`
  List<Record> byDate(DateTime d) => _records
      .where((r) =>
  r.fechaHora.year  == d.year &&
      r.fechaHora.month == d.month &&
      r.fechaHora.day   == d.day)
      .toList();

  /* ─────────── DESCARGA COMPLETA ─────────── */
  Future<void> fetchAll() async {
    try {
      final uri = Uri.parse('$baseUrl/records');
      final res = await http.get(uri).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      final data = jsonDecode(res.body) as List;
      _records
        ..clear()
        ..addAll(data.map((e) => Record.fromJson(e as Map<String, dynamic>)));

      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchAll → $e');
      rethrow; // deja que la UI decida qué hacer
    }
  }

  /* ─────────── INSERTAR Y SINCRONIZAR ───────────
   * [sync] = true  → intenta guardar en el backend
   * [sync] = false → sólo lo añade de forma local (útil para simulaciones)
   */
  Future<void> addRecord(Record r, {bool sync = true}) async {
    _records.add(r);
    notifyListeners(); // pinta inmediatamente

    if (!sync) return; // modo simulación: no intenta POST

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(r.toJson()),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw 'POST ${res.statusCode}';
      }

      await fetchAll(); // refresca desde la BD real
    } catch (e) {
      _records.remove(r); // revierte si falló
      notifyListeners();
      debugPrint('❌ addRecord → $e');
    }
  }
}
