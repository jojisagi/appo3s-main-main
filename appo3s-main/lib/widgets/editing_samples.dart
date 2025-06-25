// lib/widgets/editing_samples.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/muestreo.dart';
import '../models/sample.dart';

class EditingSamples extends StatefulWidget {
  final Muestreo  muestreo;
  final int?      maxSeconds;                  // ⏱  límite opcional
  final Function(Muestreo)? onSamplesUpdated;

  const EditingSamples({
    super.key,
    required this.muestreo,
    this.maxSeconds,
    this.onSamplesUpdated,
  });

  @override
  State<EditingSamples> createState() => _EditingSamplesState();
}

class _EditingSamplesState extends State<EditingSamples> {
  final _formKey = GlobalKey<FormState>();

  /* ───────── helpers ───────── */
  bool _excede(int sec) =>
      widget.maxSeconds != null && sec > widget.maxSeconds!;
  void _warn() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
        content: Text('La muestra excede el tiempo máximo permitido')),
  );

  void _ordenarNotify() {
    widget.muestreo.sortByTime();
    widget.muestreo.renum();
    widget.onSamplesUpdated?.call(widget.muestreo.deepCopy());
  }

  /* ───────── CRUD ───────── */
  Sample _nextSample() {
    if (widget.muestreo.isEmpty) {
      return Sample(numSample: 1, selectedMinutes: 0, selectedSeconds: 5);
    }
    final last = widget.muestreo.last;
    var m = last.selectedMinutes;
    var s = last.selectedSeconds + 5;
    if (s >= 60) {
      m += s ~/ 60;
      s %= 60;
    }
    return Sample(
      numSample: widget.muestreo.count + 1,
      selectedMinutes: m,
      selectedSeconds: s,
    );
  }

  void _add() {
    final n = _nextSample();
    final tot = n.selectedMinutes * 60 + n.selectedSeconds;
    if (_excede(tot)) return _warn();
    setState(() {
      widget.muestreo.addSample(n);
      _ordenarNotify();
    });
  }

  void _rem(int idx) =>
      setState(() => {widget.muestreo.removeSample(idx), _ordenarNotify()});

  void _upd(int idx, Sample s) {
    final tot = s.selectedMinutes * 60 + s.selectedSeconds;
    if (_excede(tot)) return _warn();
    setState(() {
      widget.muestreo.updateSample(idx, s);
      _ordenarNotify();
    });
  }

  /* ── añade cierre exacto si falta ── */
  @override
  void dispose() {
    final lim = widget.maxSeconds;
    if (lim != null && widget.muestreo.isNotEmpty) {
      final last = widget.muestreo.last;
      final lastSec = last.selectedMinutes * 60 + last.selectedSeconds;
      if (lastSec < lim) {
        widget.muestreo.addSample(Sample(
          numSample: widget.muestreo.count + 1,
          selectedMinutes: lim ~/ 60,
          selectedSeconds: lim % 60,
        ));
        _ordenarNotify();
      }
    }
    super.dispose();
  }

  /* ───────── UI ───────── */
  @override
  Widget build(BuildContext ctx) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Form(
      key: _formKey,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.muestreo.count,
          itemBuilder: (_, i) => _card(widget.muestreo[i], i),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _add, child: const Text('Añadir muestra')),
      ]),
    ),
  );

  Widget _card(Sample s, int idx) => Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Muestra ${s.numSample} – ${s.formattedTime}'),
          IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _rem(idx)),
        ]),
        Row(children: [
          _tf(
              init: s.selectedMinutes,
              lbl: 'Min',
              onCh: (v) =>
                  _upd(idx, s.copyWith(selectedMinutes: v))),
          const SizedBox(width: 12),
          _tf(
              init: s.selectedSeconds,
              lbl: 'Seg',
              limit2: true,
              onCh: (v) =>
                  _upd(idx, s.copyWith(selectedSeconds: v))),
        ]),
      ]),
    ),
  );

  Widget _tf(
      {required int init,
        required String lbl,
        bool limit2 = false,
        required Function(int) onCh}) =>
      Expanded(
        child: TextFormField(
          initialValue: init.toString(),
          decoration: InputDecoration(labelText: lbl),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (limit2) LengthLimitingTextInputFormatter(2),
          ],
          onChanged: (txt) => onCh(int.tryParse(txt) ?? 0),
        ),
      );
}
