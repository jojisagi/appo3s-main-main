import 'package:flutter/services.dart';
import 'package:appo3s/models/sample.dart';

class Muestreo {
   Duration? maxDuration;
  int index_actual = 0; // Índice para el número de muestra
   List<Sample> _samples = [
    
  ]; // Lista privada

  // Constructor opcional para inicializar con muestras existentes
Muestreo({this.maxDuration, List<Sample>? samples})
      : _samples = samples ?? [];

  // Añade estos métodos:
factory Muestreo.fromJson(Map<String, dynamic> json) {
    return Muestreo(
      maxDuration: json['maxDuration'] != null
          ? Duration(microseconds: json['maxDuration'] as int)
          : null,
    ).._samples = (json['samples'] as List?)
          ?.map((e) => Sample.fromJson(e as Map<String, dynamic>))
          .toList() ??
        []
      ..index_actual = json['index_actual'] as int? ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDuration': maxDuration?.inMicroseconds,
      'index_actual': index_actual,
      'samples': _samples.map((sample) => sample.toJson()).toList(),
    };
  }



  //*************** */
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

    _samples[3].y = -5;
  }

   Muestreo deepCopy() {
    final nuevo = Muestreo();
    for (final sample in samples) {
      nuevo.addSample(sample.copy());
    }
    return nuevo;
  }

  void inicializar_con_otro_muestreo(Muestreo otro) {
    clearSamples();
    for (final sample in otro.samples) {
      addSample(sample.copy());
    }
  }

 /*void inicializar_con_otro_muestreo(Muestreo otroMuestreo) {
    // Inicializa este muestreo con los datos de otro muestreo
    for (int i = 0; i < otroMuestreo._samples.length; i++) {
      _samples.add(Sample(
        numSample: otroMuestreo._samples[i].numSample,
        selectedMinutes: otroMuestreo._samples[i].selectedMinutes,
        selectedSeconds: otroMuestreo._samples[i].selectedSeconds,
        y: otroMuestreo._samples[i].y,
      )); 
    }


  }
*/
  void actualizarMuestras_index(double y) {
    // Actualiza las muestras con los valores actuales
    _samples [index_actual].y = y;
    index_actual++;
  }

    void actualizarMuestras_time(int minutes, int seconds, double y) {
    // Actualiza las muestras con los valores actuales
  for (int i = 0; i < _samples.length; i++) {
      if (_samples[i].selectedMinutes == minutes && _samples[i].selectedSeconds == seconds) {
        _samples [index_actual].y = y;
        index_actual++;
        return; // Salir del bucle una vez que se actualiza la muestra
      }

    }

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