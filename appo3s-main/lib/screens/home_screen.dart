import 'package:flutter/material.dart';
import 'historial_registros.dart';
import 'creando_registros.dart';

import '../services/esp32_por_cable_web.dart'
    if (dart.library.ffi) '../services/esp32_por_cable_win.dart';

import '../services/esp32_por_wifi.dart';
import '../services/esp32_manager.dart';

import '../services/server_renamed.dart';

import 'package:http/http.dart' as http;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSelected = true; // true = Wi-Fi, false = Serial
  bool _isConnected = false;
  late final ESP32WifiService _wifiService;
  late final ConnectionManager _connectionManager;
  bool developer_mode = false; // Variable para modo desarrollador
  String ipEncontrada='0.0.0.0';
  bool checked=false;
  @override
@override
void initState() {
  super.initState();
  Mongo mongo=   new Mongo();
   mongo.iniciar_mongo(); // Conectar a MongoDB al iniciar


  _wifiService = ESP32WifiService(ipAddress: '0.0.0.0');
  _connectionManager = ConnectionManager(
    wifiService: _wifiService,
    serialService: ESP32SerialService(),
  );

  // Ejecutar luego del primer frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _autoBuscarESP32();
    checked= check_mode(_isConnected, developer_mode);
  });



  
}


 Future<bool> _autoBuscarESP32() async {
  bool result = false;
  try {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      final mensaje = 'No hay conexión WiFi activa';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      return false;
    }

    final ipLocal = await _obtenerIpLocal();
    print('IP local obtenida: $ipLocal');

    if (!mounted) return false;
    if (ipLocal == null) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      final mensaje = (connectivity == ConnectivityResult.wifi)
          ? 'Conectado a WiFi pero sin IP (¿problema de DHCP?)'
          : 'No hay conexión WiFi activa';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      return false;
    }

    final subnet = _extraerSubnet(ipLocal);
    if (subnet.isEmpty) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('IP inválida detectada: $ipLocal')),
      );
      return false;
    }

    _mostrarDialogo('Buscando ESP32 en la red...');

    final ipEncontrada = await buscarIpESP32Extendido(subnet);

    if (!mounted) return false;
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (ipEncontrada != null) {
      print('ESP32 encontrado en $ipEncontrada');
      _wifiService.ipAddress = ipEncontrada;
      result = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ESP32 encontrado en $ipEncontrada')),
      );

      if (_isSelected) {
        final ok = await _connectionManager.switchConnection(ConnectionType.wifi);
        setState(() => _isConnected = ok);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Conexión Wi-Fi con ESP32 establecida'
                : 'Fallo al conectar por Wi-Fi'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el ESP32 en la red.')),
      );
      result = false;
    }
  } catch (e) {
    print('Error en _autoBuscarESP32: $e');
    result = false;
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al buscar ESP32: $e')),
    );
  }

  return result;
}



Future<String?> _obtenerIpLocal() async {
  try {
    // 1. Verificar si hay internet realmente
    print ('verificando wifi');
    final tieneInternet = await _verificarConexionReal();
    print('Tiene conexión a internet: $tieneInternet');
    if (!tieneInternet) {
      print('No hay conexión real a internet.');
      return null;
    }

    // 2. Listar interfaces de red
    List<NetworkInterface> interfaces = [];
    try {
      interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      ).timeout(const Duration(seconds: 3), onTimeout: () => []);
    } catch (e) {
      print('Error al listar interfaces de red: $e');
      return null;
    }

    if (interfaces.isEmpty) {
      print('No se encontraron interfaces de red.');
      return null;
    }

    // 3. Mostrar interfaces encontradas
    for (var interface in interfaces) {
      print('Interfaz: ${interface.name}');
      for (var addr in interface.addresses) {
        print('  → Dirección: ${addr.address} (${addr.type}, loopback: ${addr.isLoopback})');
        if (addr.type == InternetAddressType.IPv4 &&
            !addr.isLoopback &&
            addr.address != '0.0.0.0') {
          print('✅ IP local válida encontrada: ${addr.address}');
          return addr.address;
        }
      }
    }

    print('⚠️ No se encontró una dirección IPv4 válida.');
    return null;
  } catch (e) {
    print('❌ Error crítico en _obtenerIpLocal: $e');
    return null;
  }
}


Future<bool> _verificarConexionReal() async {
  try {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      final mensaje = 'No hay conexión WiFi activa';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      return false;
    }

    final result = await InternetAddress.lookup('google.com').timeout(
      const Duration(seconds: 3),
    );
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (e) {
    print('Error al verificar conexión real');
    return false;
  }
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

  void _mostrarDialogo(String mensaje) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Expanded(child: Text(mensaje)),
        ],
      ),
    ),
  );
}

Future<void> _handleSwitchChange(bool value) async {
  // Cambiar inmediatamente el estado visual del switch
  setState(() {
    _isSelected = value;
    check_mode(_isConnected, developer_mode); 
  });

  // Mostrar indicador de carga
  final dialogContext = context;



      
  showDialog(
    context: dialogContext,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Cambiando conexión...'),
        ],
      ),
    ),
  );
  


  bool connectionResult = false;
  
  try {
    if (value) {
      // Modo Wi-Fi - buscar ESP32
      
      if (developer_mode==false){
          connectionResult = await _autoBuscarESP32();
      }else{
          connectionResult=true;
      }
     // 
    } else {
      // Modo Serial - verificar conexión por cable
      if (developer_mode==false){
      connectionResult = await _connectionManager.switchConnection(ConnectionType.serial);}
      else{
        connectionResult=true;
        }
      //connectionResult=true;
    }
  } catch (e) {
    print('Error al cambiar conexión: $e');
    connectionResult = false;
  }

  // Cerrar el diálogo solo si el widget todavía está montado
  if (mounted) {
    Navigator.of(dialogContext, rootNavigator: true).pop();
    
    setState(() {
      _isConnected = connectionResult;
    });

    // Mostrar feedback al usuario
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(
        content: Text(
          connectionResult
              ? 'Conectado por ${value ? 'Wi-Fi' : 'Cable'}'
              : 'Error al conectar por ${value ? 'Wi-Fi' : 'Cable'}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

bool check_mode(bool conecte , bool devele) {
  bool x=false;
  if (devele) {
    x = true; // Modo desarrollador, siempre activo
  } else {
    x = conecte; // Depende del estado del switch
  }

  checked = x; // Actualizar la variable global

  return x;
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
                  onChanged: _handleSwitchChange, // Usar el nuevo método

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
              child:
               ElevatedButton(
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
              child: 
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Opcional: Cambiar estilo si está deshabilitado
                  backgroundColor: checked
                      ? null 
                      : Colors.grey[300],
                ),
                onPressed: checked
                    ? () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const CreandoRegistros()),
                      ) 
                    : null, // Si es false, el botón se deshabilita
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

Future<String?> buscarIpESP32Extendido(String subnet) async {
  print('🔍 Iniciando escaneo extendido rápido en subnet: $subnet');

  final parts = subnet.split('.');
  if (parts.length != 3) {
    print('❌ Subnet inválido: $subnet');
    return null;
  }

  final base1 = int.tryParse(parts[0]) ?? 0;
  final base2 = int.tryParse(parts[1]) ?? 0;
  final thirdOctet = int.tryParse(parts[2]) ?? 0;

  // Lista de direcciones comunes donde suele estar el ESP32
  final commonAddresses = [1, 2, 100, 101, 123, 200, 254];

  // Primero buscamos en las direcciones comunes (más rápidamente)
  for (final i in commonAddresses) {
    final ip = '$subnet.$i';
    if (await _verificarIpRapido(ip)) {
      print('✅ ESP32 encontrado rápidamente en $ip');
      return ip;
    }
  }

  // Si no lo encontramos, buscamos en el resto del rango
  final futures = <Future<String?>>[];
  
  for (int offset = -3; offset <= 3; offset++) {
    final currentThird = thirdOctet + offset;
    if (currentThird < 0 || currentThird > 255) continue;

    final currentSubnet = '$base1.$base2.$currentThird';
    print('🌐 Explorando subnet: $currentSubnet');

    // Buscamos en paralelo en grupos de 10 direcciones
    for (int group = 1; group < 255; group += 10) {
      final groupEnd = (group + 10).clamp(1, 255);
      
      for (int i = group; i < groupEnd; i++) {
        final ip = '$currentSubnet.$i';
        futures.add(_verificarIpConTimeout(ip));
      }

      // Esperamos resultados del grupo actual
      final results = await Future.wait(futures);
      for (final result in results) {
        if (result != null) {
          print('✅ ESP32 encontrado en ${result}');
          return result;
        }
      }
      futures.clear();
    }
  }

  print('🚫 No se encontró el ESP32 en las subnets exploradas.');
  return null;
}

Future<bool> _verificarIpRapido(String ip) async {
  try {
    final response = await http
        .get(Uri.parse('http://$ip/status'))
        .timeout(const Duration(milliseconds: 100)); // Tiempo más corto

    return response.statusCode == 200 && response.body.trim() == "OK";
  } catch (e) {
    return false;
  }
}

Future<String?> _verificarIpConTimeout(String ip) async {
  try {
    final response = await http
        .get(Uri.parse('http://$ip/status'))
        .timeout(const Duration(milliseconds: 150)); // Tiempo intermedio

    if (response.statusCode == 200 && response.body.trim() == "OK") {
      return ip;
    }
  } catch (e) {
    // Ignorar errores de timeout
  }
  return null;
}