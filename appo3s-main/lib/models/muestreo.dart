import 'package:flutter/services.dart';
import 'package:appo3s/models/sample.dart';

class Muestreo {
   Duration? maxDuration;
  
   List<Sample> _samples = [
    
  ]; // Lista privada

  // Constructor opcional para inicializar con muestras existentes
  Muestreo() {
  
  }

 void llenarMuestras() {
    _samples = [
      Sample(numSample: 1, selectedMinutes: 0, selectedSeconds: 0),
    Sample(numSample: 2, selectedMinutes: 0, selectedSeconds: 30),
    Sample(numSample: 3, selectedMinutes: 1, selectedSeconds: 0),
    Sample(numSample: 4, selectedMinutes: 1, selectedSeconds: 30),
    Sample(numSample: 5, selectedMinutes: 2, selectedSeconds: 0),
    Sample(numSample: 6, selectedMinutes: 2, selectedSeconds: 30),
    Sample(numSample: 7, selectedMinutes: 3, selectedSeconds: 0),

      
    ];

    _samples[3].y = 5;
  }


  // Getter para acceder a las muestras (solo lectura)
  List<Sample> get samples => List.unmodifiable(_samples);

  // Añadir una nueva muestra
  void addSample(Sample sample) {
    _samples.add(sample);
  }

  // Modificar una muestra existente
  void updateSample(int index, Sample newSample) {
    if (index >= 0 && index < _samples.length) {
      _samples[index] = newSample;
    } else {
      throw RangeError('Índice fuera de rango');
    }
  }

  // Eliminar una muestra
  void removeSample(int index) {
    if (index >= 0 && index < _samples.length) {
      _samples.removeAt(index);
    } else {
      throw RangeError('Índice fuera de rango');
    }
  }

  // Eliminar por muestra (comparando objetos)
  void removeSampleByObject(Sample sample) {
    _samples.remove(sample);
  }

  // Obtener una muestra específica
  Sample getSample(int index) {
    if (index >= 0 && index < _samples.length) {
      return _samples[index];
    }
    throw RangeError('Índice fuera de rango');
  }

  // Limpiar todas las muestras
  void clearSamples() {
    _samples.clear();
  }

  // Número de muestras
  int get count => _samples.length;

  // Verificar si está vacío
  bool get isEmpty => _samples.isEmpty;
  bool get isNotEmpty => _samples.isNotEmpty;
}