// lib/services/esp32_por_cable_win.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter/foundation.dart';

class ESP32SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  final StreamController<double> _dataController = StreamController.broadcast();
  bool _connected = false;

  Stream<double> get dataStream => _dataController.stream;
  bool get isConnected => _connected;

  Future<bool> conectar(String portName) async {
    final success = await compute(testSerialPort, portName);
    if (!success) {
      _connected = false;
      return false;
    }
    try {
      _port = SerialPort(portName);
      final config = SerialPortConfig()
        ..baudRate = 115200
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;

      if (!_port!.openReadWrite()) throw Exception('No se pudo abrir el puerto');
      _port!.config = config;
      _reader = SerialPortReader(_port!);

      final completer = Completer<bool>();
      late StreamSubscription<List<int>> subscription;

      subscription = _reader!.stream.listen((data) {
        try {
          final strData = utf8.decode(data).trim();
          final value = double.parse(strData);
          _dataController.add(value);
          _connected = true;
          if (!completer.isCompleted) completer.complete(true);
          subscription.cancel();
        } catch (_) {}
      });

      return await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          subscription.cancel();
          desconectar();
          return false;
        },
      );
    } catch (_) {
      desconectar();
      return false;
    }
  }

  Future<void> enviarComando(String comando) async {
    if (_port == null || !_port!.isOpen) return;
    _port!.write(utf8.encode('$comando\n'));
  }

  void desconectar() {
    _reader?.close();
    _port?.close();
    _connected = false;
  }

  void dispose() {
    desconectar();
    _dataController.close();
  }

  static bool testSerialPort(String portName) {
    try {
      final port = SerialPort(portName);
      final config = SerialPortConfig()
        ..baudRate = 115200
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;

      if (!port.openReadWrite()) return false;
      port.config = config;
      port.close();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Esta función también solo existe en Windows/Linux/macOS
List<String> obtenerPuertosDisponibles() {
  return SerialPort.availablePorts;
}
