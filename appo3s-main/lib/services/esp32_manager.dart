import '../services/esp32_por_cable.dart';
import '../services/esp32_por_wifi.dart';

import 'dart:async';
import 'package:flutter_libserialport/flutter_libserialport.dart';
enum ConnectionType { wifi, serial }

class ConnectionManager {
  final ESP32WifiService wifiService;
  final ESP32SerialService serialService;
  ConnectionType currentType = ConnectionType.wifi;

  ConnectionManager({
    required this.wifiService,
    required this.serialService,
  });

  Future<bool> switchConnection(ConnectionType type) async {
    currentType = type;
    if (type == ConnectionType.wifi) {
      serialService.desconectar();
      return await wifiService.verificarConexion();
    } else {
      return await _connectToSerial();
    }
  }

  Future<bool> _connectToSerial() async {
    final ports = SerialPort.availablePorts;
    for (var port in ports) {
      if (port.contains('COM') || port.contains('ttyUSB')) {
        if (await serialService.conectar(port)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<String> getData() async {
    if (currentType == ConnectionType.wifi) {
      return await wifiService.obtenerDatos();
    } else {
      // Para serial, usamos el stream
      final completer = Completer<String>();
      final subscription = serialService.dataStream.listen((data) {
        if (!completer.isCompleted) {
          completer.complete(data.toString());
        }
      });
      
      // Enviamos comando para solicitar datos
      serialService.enviarComando('GET_DATA');
      
      return completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          subscription.cancel();
          throw TimeoutException('No se recibieron datos del ESP32');
        },
      );
    }
  }
}