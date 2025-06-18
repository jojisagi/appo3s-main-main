// home_screen.dart
import 'package:flutter/material.dart';
import 'historial_registros.dart';
import 'creando_registros.dart';
import 'graphs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menú principal')),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shrinkWrap: true,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialRegistros()),
              ),
              child: const Text('Historial de registros'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreandoRegistros()),
              ),
              child: const Text('Ingresar registro manualmente'),
            ),
            const Divider(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GraphsScreen()),
              ),
              child: const Text('Gráficas en tiempo real'),
            ),
          ],
        ),
      ),
    );
  }
}
