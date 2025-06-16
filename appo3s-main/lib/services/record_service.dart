import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/record.dart';
import 'api_config.dart';

class RecordService extends ChangeNotifier {
  final List<Record> _records = [];
  List<Record> get records => _records;

  Future<void> fetchAll() async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/records'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        _records
          ..clear()
          ..addAll((json.decode(r.body) as List)
              .map((e) => Record.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      } else {
        throw Exception('Error: ${r.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener registros: $e');
    }
  }

  Future<void> addRecord(Record record) async {
    _records.add(record);
    notifyListeners(); // muestra en UI de inmediato

    try {
      await http.post(
        Uri.parse('$baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(record.toJson()),
      );
    } catch (e) {
      print('❌ Error al enviar registro: $e');
    }
  }

  List<Record> byDate(DateTime d) => _records
      .where((e) =>
  e.fechaHora.year == d.year &&
      e.fechaHora.month == d.month &&
      e.fechaHora.day == d.day)
      .toList();
}
