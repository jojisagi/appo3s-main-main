import 'package:flutter/material.dart';
import 'Historial_registros.dart';
import 'Creando_registros.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menú principal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  Historial_registros()),
              ),
              child: const Text('    Historial de registros  '),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  CreandoRegistros()),
              ),
              child: const Text('Iniciar proceso de registro'),
            ),
          ],
        ),
      ),
    );
  }
}
