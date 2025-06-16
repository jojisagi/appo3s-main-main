import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/record.dart';

const _baseUrl = 'http://localhost:8080';    // backend local

class RecordService extends ChangeNotifier {
  final List<Record> _records = [];
  List<Record> get records => _records;

  Future<void> fetchAll() async {
    final r = await http.get(Uri.parse('$_baseUrl/records'));
    if (r.statusCode == 200) {
      _records
        ..clear()
        ..addAll((json.decode(r.body) as List)
            .map((e) => Record.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    }
  }

  Future<void> addRecord(Record record) async {
    _records.add(record);
    notifyListeners();                               // pinta de inmediato
    await http.post(Uri.parse('$_baseUrl/records'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(record.toJson()));
  }

  List<Record> byDate(DateTime d) => _records
      .where((e) =>
  e.fechaHora.year == d.year &&
      e.fechaHora.month == d.month &&
      e.fechaHora.day == d.day)
      .toList();
}
