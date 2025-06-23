// home_screen.dart
import 'package:flutter/material.dart';
import 'historial_registros.dart';
import 'creando_registros.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menú principal')),
      body: Center(
        child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Primer botón expandido
    SizedBox(
      width: 300, // Ancho fijo
  height: 300, // Alto fijo (igual que el ancho)
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: ElevatedButton(
                style: ElevatedButton.styleFrom(
        fixedSize: const Size(160, 160), // Ancho y alto iguales (cuadrado)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Bordes ligeramente redondeados
        ),
      ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistorialRegistros()),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Evita que el Column ocupe todo el espacio
            children: [
              const Icon(Icons.description, size: 80),
              const SizedBox(height: 8),
              Text('Historial de registros'),
            ],
          ),
        ),
      ),
    ),
    
    const SizedBox(width: 100), // Espacio entre botones
    
    // Segundo botón expandido
    SizedBox(
      width: 300, // Ancho fijo
  height: 300, // Alto fijo (igual que el ancho)
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: ElevatedButton(
               style: ElevatedButton.styleFrom(
        fixedSize: const Size(160, 160), // Ancho y alto iguales (cuadrado)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Bordes ligeramente redondeados
        ),
      ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreandoRegistros()),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics, size: 80),
              const SizedBox(height: 8),
              Text('Iniciar registro'),
            ],
          ),
        ),
      ),
    ),
  ],
),
      ),
    );
  }
}
