import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/muestreo.dart';
import '../models/sample.dart';

class EditingSamples extends StatefulWidget {
  final Muestreo           muestreo;          // contiene maxDuration
  final Function(Muestreo)? onSamplesUpdated;

  const EditingSamples({
    super.key,
    required this.muestreo,
    this.onSamplesUpdated,
  });

  @override
  State<EditingSamples> createState() => _EditingSamplesState();
}

class _EditingSamplesState extends State<EditingSamples> {
  final _formKey = GlobalKey<FormState>();

  /* ╭──── helpers límites ────╮ */
  int? get _maxSeconds => widget.muestreo.maxDuration?.inSeconds;
  bool _exceed(int sec) => _maxSeconds != null && sec > _maxSeconds!;
  void _warn() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
        content: Text('La muestra excede el tiempo máximo permitido')),
  );

  void _ordenarYNotificar() {
    widget.muestreo.sortByTime();
    widget.muestreo.renum();
    widget.onSamplesUpdated?.call(widget.muestreo.deepCopy());
  }

  /* ╭──── CRUD ────╮ */
  Sample _nextSample() {
    // primer punto
    if (widget.muestreo.isEmpty) {
      return Sample(
        numSample       : 1,
        selectedMinutes : 0,
        selectedSeconds : 5,
        y               : 0.0,
      );
    }

    // a partir del último
    final last = widget.muestreo.last;
    var m   = last.selectedMinutes;
    var sec = last.selectedSeconds + 5;
    if (sec >= 60) {
      m  += sec ~/ 60;
      sec = sec % 60;
    }
    return Sample(
      numSample       : last.numSample + 1,
      selectedMinutes : m,
      selectedSeconds : sec,
      y               : 0.0,
    );
  }

  void _addSample() {
    final s = _nextSample();
    final total = s.totalSeconds;
    if (_exceed(total)) {
      _warn();
      return;
    }
    setState(() {
      widget.muestreo.addSample(s);
      _ordenarYNotificar();
    });
  }

  void _updateSample(int index, Sample upd) {
    final total = upd.totalSeconds;
    if (_exceed(total)) {
      _warn();
      return;
    }
    setState(() {
      widget.muestreo.updateSample(index, upd);
      _ordenarYNotificar();
    });
  }

  void _removeSample(int index) {
    setState(() {
      widget.muestreo.removeSample(index);
      _ordenarYNotificar();
    });
  }

  /* ╭──── UI ────╮ */
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.builder(
            shrinkWrap : true,
            physics    : const NeverScrollableScrollPhysics(),
            itemCount  : widget.muestreo.count,
            itemBuilder: (_, i) => _sampleCard(widget.muestreo[i], i),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: _addSample, child: const Text('Add Sample')),
        ],
      ),
    ),
  );

  Widget _sampleCard(Sample s, int idx) => Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sample ${s.numSample} – ${s.formattedTime}'),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeSample(idx),
              ),
            ],
          ),
          Row(children: [
            _timeField(
              label   : 'Min',
              initial : s.selectedMinutes,
              onChange: (v) => _updateSample(
                idx,
                s.copyWith(selectedMinutes: v),
              ),
            ),
            const SizedBox(width: 16),
            _timeField(
              label   : 'Seg',
              initial : s.selectedSeconds,
              limit   : 2,
              onChange: (v) => _updateSample(
                idx,
                s.copyWith(selectedSeconds: v.clamp(0, 59)),
              ),
            ),
          ]),
        ],
      ),
    ),
  );

  Widget _timeField({
    required String label,
    required int    initial,
    required void Function(int) onChange,
    int?   limit,
  }) =>
      Expanded(
        child: TextFormField(
          initialValue: initial.toString(),
          decoration  : InputDecoration(labelText: label),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (limit != null) LengthLimitingTextInputFormatter(limit),
          ],
          onChanged: (v) => onChange(int.tryParse(v) ?? 0),
        ),
      );
}
