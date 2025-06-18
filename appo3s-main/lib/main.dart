//main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/record_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => RecordService()..fetchAll(), // Carga registros al iniciar
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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromARGB(255, 59, 111, 184),
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 4,
          backgroundColor: Color.fromARGB(255, 59, 111, 184),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
