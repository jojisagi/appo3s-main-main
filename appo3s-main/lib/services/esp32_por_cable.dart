import 'dart:convert';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialService {
  final void Function(double)? onTemperatura;
  SerialPort? _port;
  SerialPortReader? _reader;

  double ultimaTemperatura=0; // ← Aquí se guarda la última temperatura recibida

  SerialService({this.onTemperatura});

  void iniciar() {
    final ports = SerialPort.availablePorts;
    if (ports.isEmpty) {
      print("No hay puertos disponibles.");
      return;
    }

    final portName = ports.firstWhere((p) => p.contains("COM"), orElse: () => ports.first);
    _port = SerialPort(portName);

    final config = SerialPortConfig()
      ..baudRate = 9600
      ..bits = 8
      ..stopBits = 1
      ..parity = SerialPortParity.none;

    _port!.config = config;

    if (!_port!.openReadWrite()) {
      print("No se pudo abrir el puerto $portName");
      return;
    }

    _reader = SerialPortReader(_port!);
    _reader!.stream.listen((data) {
      final linea = utf8.decode(data).trim();
      try {
        final double temp = double.parse(linea);
        ultimaTemperatura = temp; // ← Se guarda la temperatura actual
        print("Temperatura recibida: $temp");
        onTemperatura?.call(temp); // ← Notifica si hay callback
      } catch (_) {
        print("Dato inválido: $linea");
      }
    });
  }

  void detener() {
    _reader?.close();
    _port?.close();
    _reader = null;
    _port = null;
  }
}
