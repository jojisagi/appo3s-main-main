// lib/services/record_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/record.dart';
import 'api_config.dart';     // ← baseUrl

class RecordService extends ChangeNotifier {
  /* ───── cache in-memory ───── */
  final List<Record> _records = [];
  List<Record> get records => List.unmodifiable(_records);

  List<Record> byDate(DateTime d) => _records
      .where((r) =>
  r.fechaHora.year  == d.year  &&
      r.fechaHora.month == d.month &&
      r.fechaHora.day   == d.day)
      .toList();

  /* ───── descarga completa ───── */
  Future<void> fetchAll() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/records'))
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';

      final data = jsonDecode(res.body) as List<dynamic>;
      _records
        ..clear()
        ..addAll(data.map((e) {
          final map = e as Map<String, dynamic>;
          // Mongo suele mandar el _id dentro del propio objeto
          final id  = (map['_id'] ?? '').toString();
          return Record.fromJson(map, id: id);
        }));

      notifyListeners();
    } catch (e, st) {
      debugPrint('❌ fetchAll → $e\n$st');
      rethrow;
    }
  }

  /* ───── up-sert (create / update) ───── */
  Future<void> saveRecord(Record rec, {bool sync = true}) async {
    /// 1) actualiza cache inmediatamente
    final idx = _records.indexWhere((e) => e.id == rec.id);
    if (idx == -1) {
      _records.add(rec);        // nuevo
    } else {
      _records[idx] = rec;      // edición local
    }
    notifyListeners();

    if (!sync) return;          // modo offline / demo

    try {
      if (rec.id.isEmpty) {
        /* ---------- CREATE ---------- */
        final res = await http.post(
          Uri.parse('$baseUrl/records'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(rec.toJson()),
        );

        if (res.statusCode != 200 && res.statusCode != 201) {
          throw 'POST ${res.statusCode}';
        }

        // el backend responde con el documento insertado (+ _id)
        final inserted   = jsonDecode(res.body) as Map<String, dynamic>;
        final newId      = (inserted['_id'] ?? '').toString();
        final savedRec   = rec.copyWith(id: newId);

        // Reemplaza la versión sin id por la definitiva
        _records.remove(rec);
        _records.add(savedRec);
        notifyListeners();
      } else {
        /* ---------- UPDATE ---------- */
        final res = await http.put(
          Uri.parse('$baseUrl/records/${rec.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(rec.toJson()),
        );

        if (res.statusCode != 200) throw 'PUT ${res.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ saveRecord → $e');
      // opcional: revertir cambios en la cache si falló
    }
  }
}
