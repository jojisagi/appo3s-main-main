// lib/widgets/timer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/muestreo.dart';

class TimerWidget extends StatefulWidget {
  final Muestreo     muestreo;
  final VoidCallback? onStart;          // ← callback externo

  const TimerWidget({
    super.key,
    required this.muestreo,
    this.onStart,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration _currentDuration = Duration.zero;
  bool     _isTimerRunning   = false;

  /* ────────── inputs “mm:ss” ────────── */
  final _minutesCtrl = TextEditingController(text: '0');
  final _secondsCtrl = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync   : this,
      duration: const Duration(hours: 24),
    )..addListener(() {
      setState(() {
        _currentDuration = _controller.duration! * _controller.value;
      });
    });

    // Si ya hay una duración máxima, muéstrala en los campos
    final maxDur = widget.muestreo.maxDuration;
    if (maxDur != null) {
      _minutesCtrl.text = maxDur.inMinutes.toString();
      _secondsCtrl.text =
          maxDur.inSeconds.remainder(60).toString().padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _minutesCtrl.dispose();
    _secondsCtrl.dispose();
    super.dispose();
  }

  /* ─────────────────── acciones ─────────────────── */

  void _setMaxDuration() {
    final m = int.tryParse(_minutesCtrl.text) ?? 0;
    final s = int.tryParse(_secondsCtrl.text) ?? 0;
    final dur = Duration(minutes: m, seconds: s);

    if (dur.inSeconds == 0) {
      _msg('La duración no puede ser 0 s');
      return;
    }

    setState(() => widget.muestreo.maxDuration = dur);
    _msg('Duración máxima: ${_fmt(dur)}');
  }

  void _startTimer() {
    final maxDur = widget.muestreo.maxDuration;
    if (maxDur == null) {
      _msg('Primero establece un tiempo máximo');
      return;
    }

    setState(() {
      _controller
        ..duration = maxDur
        ..forward(from: 0);
      _isTimerRunning = true;
    });

    // 🔔 avisa al padre para arrancar la simulación
    widget.onStart?.call();
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
      _isTimerRunning  = false;
    });
  }

  /* ─────────────────── helpers ─────────────────── */

  void _msg(String txt) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  /* ─────────────────── UI ─────────────────── */

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('CONTROL DE TIEMPO',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 6),

        /* —— selector mm:ss —— */
        Row(children: [
          _numField(_minutesCtrl, 'Min'),
          const SizedBox(width: 8),
          _numField(_secondsCtrl, 'Seg', limit: 2),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _setMaxDuration,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12)),
            child: const Text('SET', style: TextStyle(fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 8),

        /* —— display —— */
        Center(
          child: Text(_fmt(_currentDuration),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'RobotoMono',
              )),
        ),
        if (widget.muestreo.maxDuration != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                'Límite: ${_fmt(widget.muestreo.maxDuration!)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ),
        const SizedBox(height: 6),

        /* —— botones —— */
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ctrlBtn(
            _isTimerRunning ? 'DETENER' : 'INICIAR',
            _isTimerRunning ? _stopTimer : _startTimer,
            _isTimerRunning ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 12),
          _ctrlBtn('RESET', _resetTimer, Colors.blue),
        ]),
      ],
    ),
  );

  /* —— widgets auxiliares —— */

  Widget _numField(TextEditingController c, String lbl, {int? limit}) => Expanded(
    child: TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: lbl,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        if (limit != null) LengthLimitingTextInputFormatter(limit),
      ],
    ),
  );

  Widget _ctrlBtn(String txt, VoidCallback fn, Color c) => ElevatedButton(
    onPressed: fn,
    style: ElevatedButton.styleFrom(
      backgroundColor: c,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    child: Text(txt,
        style: const TextStyle(color: Colors.white, fontSize: 12)),
  );
}
