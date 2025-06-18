import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/record_service.dart';
import 'screens/home_screen.dart';

// ── import condicional ─────────────────────────────────────────
//   • En entornos con dart:io se usará server_launcher_io.dart
//   • En Web se caerá al stub que no hace nada
import 'utils/server_launcher_io.dart'
if (dart.library.html) 'utils/server_launcher_stub.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo intentamos levantar el backend fuera de Web.
  if (!kIsWeb) await ServerLauncher.launchIfNeeded();

  runApp(
    ChangeNotifierProvider(
      create: (_) => RecordService()..fetchAll(),
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
