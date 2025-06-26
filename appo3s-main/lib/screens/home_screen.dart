import 'package:flutter/material.dart';
import 'historial_registros.dart';
import 'creando_registros.dart';

import '../services/esp32_por_cable.dart';
import '../services/esp32_por_wifi.dart';
import '../services/esp32_manager.dart';

import 'package:http/http.dart' as http;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSelected = false;
  bool _isConnected = false;
  late final ESP32WifiService _wifiService;
  late final ConnectionManager _connectionManager;

  @override
  void initState() {
    super.initState();
    
    _wifiService = ESP32WifiService(ipAddress: '0.0.0.0');
    _connectionManager = ConnectionManager(
      wifiService: _wifiService,
      serialService: ESP32SerialService(),
    );
    _autoBuscarESP32();
  }

  Future<void> _autoBuscarESP32() async {
    final ipLocal = await _obtenerIpLocal();
    print ('IP local obtenida: $ipLocal');
    if (ipLocal == null) return;

    final subnet = _extraerSubnet(ipLocal);

    final ipEncontrada = await buscarIpESP32Simple(subnet);
    if (ipEncontrada != null) {
      _wifiService.ipAddress = ipEncontrada;
      if (_isSelected) {
        final ok = await _connectionManager.switchConnection(ConnectionType.wifi);
        setState(() => _isConnected = ok);
      }
    }
  }

  Future<String?> _obtenerIpLocal() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result != ConnectivityResult.wifi) return null;

      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String _extraerSubnet(String ip) {
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return '';
  }

  void mensaje_escafold(BuildContext context, bool isSelected) async {
    final tipo = isSelected ? ConnectionType.wifi : ConnectionType.serial;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Estableciendo conexión...')),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    final conectado = await _connectionManager.switchConnection(tipo);
    if (context.mounted) Navigator.of(context).pop();

    setState(() {
      _isConnected = conectado;
      _isSelected = isSelected;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSelected
              ? (conectado ? 'Wi-Fi conectado correctamente' : 'Fallo en conexión Wi-Fi')
              : (conectado ? 'Cable conectado correctamente' : 'Fallo en conexión por cable'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú principal'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                Icon(_isSelected ? Icons.wifi : Icons.cable, size: 24),
                const SizedBox(width: 4),
                Text(_isSelected ? 'Wi-Fi' : 'Cable',
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
                Switch(
                  value: _isSelected,
                  onChanged: (bool value) => mensaje_escafold(context, value),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Historial
            SizedBox(
              width: 160,
              height: 160,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialRegistros())),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description, size: 80),
                    SizedBox(height: 8),
                    Text('Historial de registros'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 40),
            // Iniciar
            SizedBox(
              width: 160,
              height: 160,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreandoRegistros())),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, size: 80),
                    SizedBox(height: 8),
                    Text('Iniciar registro'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Future<String?> buscarIpESP32Simple(String subnet) async {
  print('🔍 Iniciando escaneo en subnet: $subnet');

  for (int i = 1; i < 255; i++) {
    final ip = '$subnet.$i';
    
    try {
      final response = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(milliseconds: 300));

      if (response.statusCode == 200 && response.body.trim() == "OK") {
        print('✅ ESP32 encontrado en $ip');
        return ip;
      } else {
        print('⚠️  $ip respondió pero no es ESP32');
      }
    } catch (e) {
      print('❌ Sin respuesta de $ip');
    }
  }

  print('🚫 No se encontró el ESP32 en la red.');
  return null;
}

