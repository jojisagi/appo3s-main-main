// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/record_service.dart';
import 'services/esp32_service.dart';
import 'services/calibration_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    /// Multi-provider:  ⓐ Calibración  ⓑ Backend registros  ⓒ ESP32 polling
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalibrationService()),
        ChangeNotifierProvider(create: (_) => RecordService()..fetchAll()),
        /// El servicio que lee el micro arranca en segundo plano
        ChangeNotifierProvider(
          create: (_) => Esp32Service(
            esp32Ip: '192.168.1.55',   // ← tu IP o mDNS
            syncToBackend: true,       // guardar últimas muestras en Mongo
          )..startPolling(),
        ),
      ],
      child: const AppO3Sense(),
    ),
  );
}


class AppO3Sense extends StatelessWidget {
  const AppO3Sense({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medición de Ozono',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B6FB8),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 4,
          backgroundColor: Color(0xFF3B6FB8),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
