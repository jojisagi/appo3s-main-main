import 'dart:convert'; // para jsonDecode
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class ESP32WifiService {
  String ipAddress;
  final int port;

  ESP32WifiService({required this.ipAddress, this.port = 80});

  Future<bool> verificarConexion() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.wifi) return false;

      final response = await http.get(
        Uri.parse('http://$ipAddress:$port/status'),
      ).timeout(const Duration(seconds: 2));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> obtenerDatos() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress:$port/data'),
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        print('Datos obtenidos: ${response.body}');
        return jsonDecode(response.body);
      }

      throw Exception('Error en la respuesta del ESP32');
    } catch (e) {
      throw Exception('Error al obtener datos: $e');
    }
  }
}
