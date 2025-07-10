import 'dart:async';
import 'dart:io';

Future<String?> discoverESP32() async {
  final RawDatagramSocket socket =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final String message = "ESP32_DISCOVER";
  final InternetAddress broadcastAddress = InternetAddress("255.255.255.255");
  final int port = 4210;

  socket.broadcastEnabled = true;
  socket.send(message.codeUnits, broadcastAddress, port);

  final completer = Completer<String?>();
  Timer timeout = Timer(Duration(seconds: 3), () {
    completer.complete(null); // Timeout
    socket.close();
  });

  socket.listen((RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final Datagram? dg = socket.receive();
      if (dg != null) {
        final response = String.fromCharCodes(dg.data);
        if (response.startsWith("ESP32_RESPONSE:")) {
          timeout.cancel();
          socket.close();
          final ip = response.split(":")[1];
          completer.complete(ip);
        }
      }
    }
  });

  return completer.future;
}

  Future<String?> solicitarDatoESP32(String ip, String comando) async {
  final RawDatagramSocket socket =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

  final int port = 4210;

  socket.send(comando.codeUnits, InternetAddress(ip), port);

  final completer = Completer<String?>();
  Timer timeout = Timer(Duration(seconds: 2), () {
    completer.complete(null); // Timeout
    socket.close();
  });

  socket.listen((RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final dg = socket.receive();
      if (dg != null) {
        final respuesta = String.fromCharCodes(dg.data).trim();
        timeout.cancel();
        socket.close();
        completer.complete(respuesta);
      }
    }
  });

  return completer.future;
}

double? extraerValorNumerico(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(raw.trim());
  if (match != null) {
    return double.tryParse(match.group(0)!);
  }
  return null;
}

Future<Map<String, double?>> obtenerDatosNumericos(String ip) async {
  final respuesta = await solicitarDatoESP32(ip, "ESP32_DATA");
  print('Respuesta completa: $respuesta');

  if (respuesta == null) {
    return {
      "Temperatura": null,
      "pH": null,
      "Conductividad": null,
      "Ozono": null,
    };
  }

  // Separamos la respuesta por comas
  final partes = respuesta.split(',');

  // Ojo que puede venir una coma final, generar elemento vacío al final
  // Entonces verificamos que haya al menos 4 valores válidos
  if (partes.length < 4) {
    print('Respuesta con formato incorrecto: $respuesta');
    return {
      "Temperatura": null,
      "pH": null,
      "Conductividad": null,
      "Ozono": null,
    };
  }

  return {
    "Temperatura": extraerValorNumerico(partes[0]),
    "pH": extraerValorNumerico(partes[1]),
    "Conductividad": extraerValorNumerico(partes[2]),
    "Ozono": extraerValorNumerico(partes[3]),
  };
}
