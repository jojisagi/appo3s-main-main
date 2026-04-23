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
import '../services/esp32_wifi_dns.dart';
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
  bool developer_mode = false;
  String ipEncontrada='0.0.0.0';
  String ipActual_ESP32='0.0.0.0';
  bool checked=false;
  final TextEditingController _ipController = TextEditingController(text: '10.74.22.231');

  // Control para diálogo abierto
  bool _dialogoAbierto = false;

  // Flag para cancelar búsqueda
  bool _cancelarBusqueda = false;

  @override
  void initState() {
    super.initState();
    Mongo mongo = Mongo();
   mongo.iniciar_mongo(); // Conectar a MongoDB al iniciar

    _wifiService = ESP32WifiService(ipAddress: '10.74.22.200');
    _wifiService.verificarConexion().then((ok) {
      print("Verificacion manual en initState: $ok");
    });
    _connectionManager = ConnectionManager(
      wifiService: _wifiService,
      serialService: ESP32SerialService(),
    );

    // Ejecutar luego del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _autoBuscarESP32();
      if (_dialogoAbierto) _cerrarDialogo();
      setState(() {
        checked = check_mode(_isConnected, developer_mode);
      });
    });
  }

  void _mostrarDialogoConCancelar(String mensaje) {
    if (_dialogoAbierto) return;
    _dialogoAbierto = true;

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
        actions: [
          TextButton(
            onPressed: () {
              cancelarBusqueda();
              if (mounted && Navigator.canPop(context)) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ).then((_) {
      _dialogoAbierto = false;
    });
  }

  void _mostrarDialogo(String mensaje) {
    if (_dialogoAbierto) return;
    _dialogoAbierto = true;

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
    ).then((_) {
      _dialogoAbierto = false;
    });
  }

  void _cerrarDialogo() {
    if (_dialogoAbierto && mounted && Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogoAbierto = false;
    }
  }

  void cancelarBusqueda() {
    print('Busqueda cancelada por usuario.');
    _cancelarBusqueda = true;
  }

  Future<bool> _autoBuscarESP32() async {
    _cancelarBusqueda = false;
    bool result = false;
    print('[HOME] _autoBuscarESP32 iniciado');
    try {
      final connectivity = await Connectivity().checkConnectivity();
      print('[HOME] Estado de conectividad: $connectivity');

      if (!connectivity.contains(ConnectivityResult.wifi)) {
        print('[HOME] No hay WiFi activo — abortando búsqueda');
        _cerrarDialogo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay conexión WiFi activa')),
          );
          _isConnected = false;
        }
        return false;
      }

      // 1) Intentar primero con la IP que ya tenemos (más rápido)
      final ipActual = _wifiService.ipAddress;
      print('[HOME] Paso 1: verificando HTTP en IP actual ($ipActual)...');
      _mostrarDialogo('Verificando ESP32 en $ipActual...');
      final httpActual = await _verificarIpRapido(ipActual);
      print('[HOME] HTTP en $ipActual: $httpActual');
      if (httpActual) {
        _cerrarDialogo();
        print('[HOME] ESP32 confirmado en $ipActual por HTTP');
        _isConnected = true;
        result = true;
        _ipController.text = ipActual;
        setState(() { check_mode(_isConnected, developer_mode); });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ESP32 conectado en $ipActual')),
          );
        }
        return true;
      }
      _cerrarDialogo();

      // 2) Intentar UDP broadcast
      print('[HOME] Paso 2: intentando UDP broadcast...');
      _mostrarDialogoConCancelar('Buscando ESP32 con broadcast UDP...');
      final ipBroadcast = await discoverESP32();
      print('[HOME] discoverESP32 terminó — resultado: $ipBroadcast');

      if (_cancelarBusqueda) {
        print('[HOME] Búsqueda cancelada por usuario');
        _cerrarDialogo();
        return false;
      }
      _cerrarDialogo();

      if (ipBroadcast != null) {
        print('[HOME] ESP32 encontrado por UDP en $ipBroadcast');
        _isConnected = true;
        _wifiService.ipAddress = ipBroadcast;
        _ipController.text = ipBroadcast;
        result = true;
        setState(() { check_mode(_isConnected, developer_mode); });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ESP32 encontrado en $ipBroadcast (UDP)')),
          );
        }
        return true;
      }

      print('[HOME] Paso 3: UDP falló — ESP32 no encontrado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ESP32 no encontrado')),
        );
      }
    } catch (e, stack) {
      print('[HOME] ERROR en _autoBuscarESP32: $e');
      print('[HOME] Stack: $stack');
      _cerrarDialogo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar ESP32: $e')),
        );
      }
      result = false;
    }
    print('[HOME] _autoBuscarESP32 terminó — resultado: $result');
    return result;
  }

  Future<String?> _obtenerIpLocal() async {
    try {
      print('verificando wifi');
      final tieneInternet = await _verificarConexionReal();
      print('Tiene conexión a internet: $tieneInternet');
      if (!tieneInternet) {
        print('No hay conexión real a internet.');
        return null;
      }

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
      if (!connectivity.contains(ConnectivityResult.wifi)) {
        _cerrarDialogo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay conexión WiFi activa')),
          );
        }
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

  Future<void> _handleSwitchChange(bool value) async {
    setState(() {
      _isSelected = value;
      check_mode(_isConnected, developer_mode);
    });

    final dialogContext = context;

    if (_dialogoAbierto) _cerrarDialogo();

    

    bool connectionResult = false;

    try {
      if (_isSelected) {
        if (!developer_mode) {
          _mostrarDialogo('Buscando Esp32 por WiFi...');
          connectionResult = await _autoBuscarESP32();
          _isConnected = connectionResult;
          if (_dialogoAbierto) _cerrarDialogo();
          if(connectionResult)
          _connectionManager.switchConnection(ConnectionType.wifi);

        } else {
          connectionResult = true;
          
        }
      } else {
        if (!developer_mode) {
          _mostrarDialogo('Buscando Esp32 por cable Serial...');
          connectionResult = await _connectionManager.switchConnection(ConnectionType.serial);
          _isConnected=connectionResult;
          if (_dialogoAbierto) _cerrarDialogo();
        } else {
          connectionResult = true;
          _isConnected=connectionResult;
        }
      }
    } catch (e) {
      print('Error al cambiar conexión: $e');
      connectionResult = false;

    }

     setState(() {
        _isConnected = connectionResult;

      });

    if (mounted) {
      _cerrarDialogo();

     
    
    if(!_isSelected){
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



          setState(() {

      check_mode(_isConnected, developer_mode);
    });


    }
  }

bool check_mode(bool conecte , bool devele) {
    bool x = false;
    if (devele) {
      x = true; // Modo desarrollador, siempre activo
      setState(() {
        _isConnected = true; // Forzar conexión en modo desarrollador
      });
    } else {
      x = conecte; // Depende del estado del switch
      


    }
    setState(() {
      checked = x;
      
    });
    return x;
  }


  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _conectarConIp(String ip) async {
    final ipTrimmed = ip.trim();
    if (ipTrimmed.isEmpty) return;
    print('[HOME] Conectando manualmente a IP: $ipTrimmed');
    _wifiService.ipAddress = ipTrimmed;
    if (_dialogoAbierto) _cerrarDialogo();
    _mostrarDialogo('Conectando a $ipTrimmed...');
    final ok = await _verificarIpRapido(ipTrimmed);
    _cerrarDialogo();
    print('[HOME] Resultado conexión manual a $ipTrimmed: $ok');
    setState(() {
      _isConnected = ok;
      check_mode(ok, developer_mode);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Conectado a $ipTrimmed' : 'No se pudo conectar a $ipTrimmed')),
      );
    }
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
                    color: checked ? Colors.green : Colors.red,
                  ),
                ),
                const Icon(Icons.wifi, size: 24),
                const SizedBox(width: 4),
                const Text('Wi-Fi', style: TextStyle(fontSize: 16, color: Colors.white)),

                 IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh),
               onPressed: () {
        _handleSwitchChange(_isSelected); // Simula cambio
              },
            ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialRegistros())),
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
                SizedBox(
                  width: 160,
                  height: 160,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: checked ? null : Colors.grey[300],
                    ),
                    onPressed: checked
                        ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreandoRegistros(connectionManager: _connectionManager, developer_mode: developer_mode)))
                        : null,
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
            const SizedBox(height: 32),
            SizedBox(
              width: 360,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP del ESP32',
                        hintText: '192.168.x.x',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.router),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: _conectarConIp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('Conectar'),
                    onPressed: () => _conectarConIp(_ipController.text),
                  ),
                ],
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

  // --------------------------
  // Primera etapa: misma red local, en paralelo
  // --------------------------
  const concurrency = 20; // puedes ajustar
  final ipsLocal = List.generate(256, (i) => '$subnet.${255 - i}');

  for (int i = 0; i < ipsLocal.length; i += concurrency) {
    if (_cancelarBusquedaGlobal) return null;

    final lote = ipsLocal.skip(i).take(concurrency);
    final results = await Future.wait(
      lote.map((ip) async {
        if (_cancelarBusquedaGlobal) return null;
        final ok = await _verificarIpRapido(ip);
        if (ok) return ip;
        return null;
      }),
    );

    for (final result in results) {
      if (result != null) {
        print('✅ ESP32 encontrado rápidamente en $result');
        return result;
      }
    }
  }

  // --------------------------
  // Segunda etapa: subnets adyacentes
  // --------------------------
  final futures = <Future<String?>>[];

  for (int offset = -3; offset <= 3; offset++) {
    final currentThird = thirdOctet + offset;
    if (currentThird < 0 || currentThird > 255) continue;

    final currentSubnet = '$base1.$base2.$currentThird';
    print('🌐 Explorando subnet: $currentSubnet');

    for (int group = 1; group < 255; group += 10) {
      final groupEnd = (group + 10).clamp(1, 255);

      for (int i = group; i < groupEnd; i++) {
        if (_cancelarBusquedaGlobal) return null;
        final ip = '$currentSubnet.$i';
        print('🌐 Probar IP: $ip');
        futures.add(_verificarIpConTimeout(ip));
      }

      final results = await Future.wait(futures);
      for (final result in results) {
        if (result != null) {
          print('✅ ESP32 encontrado en $result');
          return result;
        }
      }
      futures.clear();
    }
  }

  print('🚫 No se encontró el ESP32 en las subnets exploradas.');
  return null;
}


bool _cancelarBusquedaGlobal = false; // Variable global para cancelar búsqueda

Future<bool> _verificarIpRapido(String ip) async {
  try {
    final response = await http
        .get(Uri.parse('http://$ip/status'))
        .timeout(const Duration(seconds: 2));

    return response.statusCode == 200 && response.body.trim() == "OK";
  } catch (e) {
    return false;
  }
}

Future<String?> _verificarIpConTimeout(String ip) async {
  try {
    final response = await http
        .get(Uri.parse('http://$ip/status'))
        .timeout(const Duration(milliseconds: 400));

    if (response.statusCode == 200 && response.body.trim() == "OK") {
      return ip;
    }
  } catch (e) {
    // Ignorar errores
  }
  return null;
}