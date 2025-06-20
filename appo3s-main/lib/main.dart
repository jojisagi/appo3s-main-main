import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/record_service.dart';
import 'services/esp32_service.dart';

// ── import condicional: usa dart:io sólo donde existe ──
import 'utils/server_launcher_io.dart'
if (dart.library.html) 'utils/server_launcher_stub.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En macOS/Windows/Linux levanta (o reinicia) el backend.
  if (!kIsWeb) await ServerLauncher.launchIfNeeded();

  runApp(const AppO3Sense());
}

class AppO3Sense extends StatelessWidget {
  const AppO3Sense({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ─── MongoDB CRUD ───
        ChangeNotifierProvider(create: (_) => RecordService()..fetchAll()),

        // ─── ESP32 tiempo-real ───
        ChangeNotifierProvider(
          create: (_) => Esp32Service(
            esp32Ip: '192.168.1.55', // ← pon aquí la IP de tu módulo
            syncToBackend: true,     // sube muestras al backend
          )..startPolling(),
        ),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
