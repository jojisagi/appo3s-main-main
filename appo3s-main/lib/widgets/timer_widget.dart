import 'package:flutter/material.dart';
import 'package:appo3s/models/muestreo.dart';

class TimerWidget extends StatefulWidget {
  final Muestreo muestreo;
  
  const TimerWidget({super.key, required this.muestreo});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Duration _currentDuration = Duration.zero;
  final TextEditingController _maxDurationController = TextEditingController();
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(hours: 24),
    )..addListener(() {
        setState(() {
          _currentDuration = _controller.duration! * _controller.value;
        });
      });

    // Inicializar con el valor existente si hay
    if (widget.muestreo.maxDuration != null) {
      _maxDurationController.text = 
          "${widget.muestreo.maxDuration!.inMinutes}:${widget.muestreo.maxDuration!.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _maxDurationController.dispose();
    super.dispose();
  }

  void _setMaxDuration() {
    final parts = _maxDurationController.text.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      final newDuration = Duration(minutes: minutes, seconds: seconds);

      setState(() {
        widget.muestreo.maxDuration = newDuration;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duración máxima establecida a ${_formatDuration(newDuration)}')));
    }
  }

  void _startTimer() {
    if (widget.muestreo.maxDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero establece un tiempo máximo')));
      return;
    }

    setState(() {
      _controller.duration = widget.muestreo.maxDuration;
      _controller.forward(from: 0);
      _isTimerRunning = true;
    });
  }

  void _stopTimer() {
    setState(() {
      _controller.stop();
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    setState(() {
      _controller.reset();
      _currentDuration = Duration.zero;
      _isTimerRunning = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

@override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(8),  // Reducido de 10
    decoration: BoxDecoration(
      color: Colors.grey[200],
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,  // Añadido para hacer la columna más compacta
      children: [
        const Text(
          'CONTROL DE TIEMPO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),  // Reducido de 12
        ),
        const SizedBox(height: 6),  // Reducido de 8
        
        // Selector de tiempo máximo
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _maxDurationController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo máximo (mm:ss)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),  // Reducido
                  isDense: true,  // Añadido para hacer el campo más compacto
                ),
                keyboardType: TextInputType.datetime,
              ),
            ),
            const SizedBox(width: 6),  // Reducido de 8
            ElevatedButton(
              onPressed: _setMaxDuration,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),  // Reducido
                minimumSize: Size.zero,  // Añadido para hacer el botón más pequeño
              ),
              child: const Text('SET', style: TextStyle(fontSize: 12)),  // Tamaño de texto reducido
            ),
          ],
        ),
        const SizedBox(height: 6),  // Reducido de 8

        // Display del temporizador
        Container(
          padding: const EdgeInsets.all(12),  // Reducido de 16
          child: Center(
            child: Text(
              _formatDuration(_currentDuration),
              style: const TextStyle(
                fontSize: 28,  // Reducido de 32
                fontWeight: FontWeight.bold,
                fontFamily: 'RobotoMono'
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),  // Reducido de 8
        
        if (widget.muestreo.maxDuration != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),  // Reducido
            child: Text(
              'Límite: ${_formatDuration(widget.muestreo.maxDuration!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),  // Tamaño reducido
              textAlign: TextAlign.center,
            ),
          ),

        // Controles del timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isTimerRunning ? _stopTimer : _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTimerRunning ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),  // Reducido
                minimumSize: Size.zero,  // Añadido para hacer el botón más pequeño
              ),
              child: Text(
                _isTimerRunning ? 'DETENER' : 'INICIAR',
                style: const TextStyle(color: Colors.white, fontSize: 12),  // Tamaño reducido
              ),
            ),
            const SizedBox(width: 12),  // Reducido de 16
            OutlinedButton(
              onPressed: _resetTimer,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),  // Reducido
                minimumSize: Size.zero,  // Añadido para hacer el botón más pequeño
              ),
              child: const Text('REINICIAR', style: TextStyle(fontSize: 12)),  // Tamaño reducido
            ),
          ],
        ),
      ],
    ),
  );
 }
}