import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalibrationService extends ChangeNotifier {
  static const _kO3   = 'cal_offset_o3';
  static const _kPh   = 'cal_offset_ph';
  static const _kCond = 'cal_offset_cond';

  double _o3   = 0, _ph = 0, _cond = 0;

  double get o3Offset   => _o3;
  double get phOffset   => _ph;
  double get condOffset => _cond;

  CalibrationService() { _load(); }

  Future<void> setOffsets({double? o3, double? ph, double? cond}) async {
    final prefs = await SharedPreferences.getInstance();
    if (o3   != null) { _o3   = o3;   await prefs.setDouble(_kO3,   o3); }
    if (ph   != null) { _ph   = ph;   await prefs.setDouble(_kPh,   ph); }
    if (cond != null) { _cond = cond; await prefs.setDouble(_kCond, cond); }
    notifyListeners();
  }

  /* ──────────────────── private ──────────────────── */
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _o3   = p.getDouble(_kO3)   ?? 0;
    _ph   = p.getDouble(_kPh)   ?? 0;
    _cond = p.getDouble(_kCond) ?? 0;
    notifyListeners();
  }
}
