import 'dart:convert';
import 'dart:async';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter/foundation.dart';


class ESP32SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<List<int>>? _serialSubscription;
  bool _connected = false;

  final StreamController<String> _dataController = StreamController.broadcast();
  Stream<String> get dataStream => _dataController.stream;
  bool get isConnected => _connected;

  Completer<bool>? _statusCompleter;
  Completer<List<double>>? _dataCompleter;

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
      _serialSubscription = _reader!.stream.listen(_onSerialData);

      _statusCompleter = Completer<bool>();
      await enviarComando('STATUS');

      final statusResult = await _statusCompleter!.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('[ESP32SerialService] Timeout esperando respuesta STATUS');
          _statusCompleter = null;
          return false;
        },
      );

      if (!statusResult) {
        desconectar();
        return false;
      }

      _connected = true;
      print('[ESP32SerialService] STATUS OK recibido');
      return true;

    } catch (e) {
      print('[ESP32SerialService] Error durante la conexión: $e');
      desconectar();
      return false;
    }
  }

  void _onSerialData(List<int> data) {
    final strData = utf8.decode(data).trim();
    print('[ESP32SerialService] Datos recibidos: "$strData"');

    if (_statusCompleter != null && strData == 'OK') {
      _statusCompleter!.complete(true);
      _statusCompleter = null;
      return;
    }

    if (_dataCompleter != null && strData.contains(',')) {
      final cleanData = strData.endsWith(',') ? strData.substring(0, strData.length - 1) : strData;
      final values = cleanData.split(',').map((v) => double.tryParse(v) ?? 0.0).toList();
      if (values.length == 4) {
        _dataCompleter!.complete(values);
        _dataCompleter = null;
        return;
      }
    }

    _dataController.add(strData);
  }

  Future<void> enviarComando(String comando) async {
    if (_port == null || !_port!.isOpen) {
      print('[ESP32SerialService] No se puede enviar comando, puerto no abierto.');
      return;
    }
    print('[ESP32SerialService] Enviando comando: $comando');
    _port!.write(utf8.encode('$comando\r\n'));
  }

  Future<Map<String, double?>> getData() async {
    if (_port == null || !_port!.isOpen) {
      print('[ESP32SerialService] No se puede obtener datos, puerto no abierto.');
      return {
        "Temperatura": null,
        "pH": null,
        "Conductividad": null,
        "Ozono": null,
      };
    }

    _dataCompleter = Completer<List<double>>();
    await enviarComando('GET_DATA');

    try {
      final values = await _dataCompleter!.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('[ESP32SerialService] Timeout esperando datos');
          _dataCompleter = null;
          return <double>[];

              

        },
      );

      if (values == null || values.length != 4) {
        return {
          "Temperatura": null,
          "pH": null,
          "Conductividad": null,
          "Ozono": null,
        };
      }

      return {
        "Temperatura": values[0],
        "pH": values[1],
        "Conductividad": values[2],
        "Ozono": values[3],
      };
    } catch (e) {
      print('[ESP32SerialService] Error al obtener datos: $e');
      _dataCompleter = null;
      return {
        "Temperatura": null,
        "pH": null,
        "Conductividad": null,
        "Ozono": null,
      };
    }
  }

  void desconectar() {
    print('[ESP32SerialService] Desconectando puerto.');
    _serialSubscription?.cancel();
    _serialSubscription = null;
    _reader?.close();
    _port?.close();
    _connected = false;
  }

  void dispose() {
    print('[ESP32SerialService] Dispose llamado.');
    _dataController.close();
    desconectar();
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
