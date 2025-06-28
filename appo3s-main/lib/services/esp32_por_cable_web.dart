// lib/services/esp32_por_cable_web.dart

import 'dart:async';

class ESP32SerialService {
  Stream<double> get dataStream => const Stream.empty();
  bool get isConnected => false;

  Future<bool> conectar(String portName) async => false;
  Future<void> enviarComando(String comando) async {}
  void desconectar() {}
  void dispose() {}
}

/// en web, no hay puertos reales
List<String> obtenerPuertosDisponibles() => [];
