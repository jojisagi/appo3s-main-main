import 'package:flutter/material.dart';
import 'package:appo3s/models/muestreo.dart';
import 'package:flutter/services.dart';
class TimerWidget extends StatefulWidget {
  final Muestreo muestreo;
  
  const TimerWidget({super.key, required this.muestreo});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Duration _currentDuration = Duration.zero;
  bool _isTimerRunning = false;
  
  // Controladores para minutos y segundos
  final TextEditingController _minutesController = TextEditingController(text: '0');
  final TextEditingController _secondsController = TextEditingController(text: '30');

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
      _minutesController.text = widget.muestreo.maxDuration!.inMinutes.toString();
      _secondsController.text = widget.muestreo.maxDuration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _setMaxDuration() {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    final newDuration = Duration(minutes: minutes, seconds: seconds);

    setState(() {
      widget.muestreo.maxDuration = newDuration;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duración máxima establecida a ${_formatDuration(newDuration)}')));
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CONTROL DE TIEMPO',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: 6),
          
          // Selector de tiempo máximo (estilo similar a EditingSamples)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minutesController,
                  decoration: const InputDecoration(
                    labelText: 'Minutos',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _secondsController,
                  decoration: const InputDecoration(
                    labelText: 'Segundos',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _setMaxDuration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  minimumSize: Size.zero,
                ),
                child: const Text('SET', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Display del temporizador
          Container(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                _formatDuration(_currentDuration),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono'
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          
          if (widget.muestreo.maxDuration != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Límite: ${_formatDuration(widget.muestreo.maxDuration!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  _isTimerRunning ? 'DETENER' : 'INICIAR',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _resetTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'RESET',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}