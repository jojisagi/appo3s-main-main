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
    print('[ESP32SerialService] Iniciando conexión al puerto: $portName');

    final success = await compute(testSerialPort, portName);
    if (!success) {
      print('[ESP32SerialService] Test del puerto $portName falló. No se pudo conectar.');
      _connected = false;
      return false;
    }
    print('[ESP32SerialService] Test del puerto $portName exitoso. Procediendo a abrir y configurar.');

    try {
      _port = SerialPort(portName);
      final config = SerialPortConfig()
        ..baudRate = 115200
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;

      if (!_port!.openReadWrite()) {
        print('[ESP32SerialService] No se pudo abrir el puerto $portName.');
        throw Exception('No se pudo abrir el puerto');
      }
      _port!.config = config;
      print('[ESP32SerialService] Puerto $portName abierto y configurado.');

      _reader = SerialPortReader(_port!);

      final completer = Completer<bool>();
      late StreamSubscription<List<int>> subscription;

      subscription = _reader!.stream.listen((data) {
        try {
          final strData = utf8.decode(data).trim();
          print('[ESP32SerialService] Datos recibidos: "$strData"');
          final value = double.parse(strData);
          _dataController.add(value);
          _connected = true;
          if (!completer.isCompleted) completer.complete(true);
          subscription.cancel();
        } catch (e) {
          print('[ESP32SerialService] Error al procesar datos: $e');
        }
      }, onError: (error) {
        print('[ESP32SerialService] Error en stream: $error');
      }, onDone: () {
        print('[ESP32SerialService] Stream cerrado.');
      });

      final result = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('[ESP32SerialService] Timeout esperando datos en puerto $portName.');
          subscription.cancel();
          desconectar();
          return false;
        },
      );

      if (result) {
        print('[ESP32SerialService] Conexión establecida con éxito en $portName.');
      }
      return result;
    } catch (e, st) {
      print('[ESP32SerialService] Error durante la conexión: $e');
      print(st);
      desconectar();
      return false;
    }
  }

  Future<void> enviarComando(String comando) async {
    if (_port == null || !_port!.isOpen) {
      print('[ESP32SerialService] No se puede enviar comando, puerto no abierto.');
      return;
    }
    print('[ESP32SerialService] Enviando comando: $comando');
    _port!.write(utf8.encode('$comando\n'));
  }

  void desconectar() {
    print('[ESP32SerialService] Desconectando puerto.');
    _reader?.close();
    _port?.close();
    _connected = false;
  }

  void dispose() {
    print('[ESP32SerialService] Dispose llamado.');
    desconectar();
    _dataController.close();
  }

  static bool testSerialPort(String portName) {
    print('[ESP32SerialService] Probando puerto $portName...');
    try {
      final port = SerialPort(portName);
      final config = SerialPortConfig()
        ..baudRate = 115200
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;

      if (!port.openReadWrite()) {
        print('[ESP32SerialService] No se pudo abrir el puerto $portName en el test.');
        return false;
      }
      port.config = config;
      port.close();
      print('[ESP32SerialService] Puerto $portName funciona correctamente.');
      return true;
    } catch (e) {
      print('[ESP32SerialService] Excepción en testSerialPort: $e');
      return false;
    }
  }
}

/// Esta función también solo existe en Windows/Linux/macOS
List<String> obtenerPuertosDisponibles() {
  final ports = SerialPort.availablePorts;
  print('[ESP32SerialService] Puertos disponibles encontrados: $ports');
  return ports;
}
