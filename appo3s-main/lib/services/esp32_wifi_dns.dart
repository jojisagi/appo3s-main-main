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
