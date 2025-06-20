import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/muestreo.dart';
import '../models/sample.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/muestreo.dart';
import '../models/sample.dart';

class EditingSamples extends StatefulWidget {
  final Muestreo muestreo;
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

  void _addSample() {
    setState(() {
      final newSample = _createNewSample();
      widget.muestreo.addSample(newSample);
      _updateAndNotify();
    });
  }

  Sample _createNewSample() {
    if (widget.muestreo.isEmpty) {
      return Sample(
        numSample: 1,
        selectedMinutes: 0,
        selectedSeconds: 30,
        y: 0.0,
      );
    } else {
      final lastSample = widget.muestreo.getSample(widget.muestreo.count - 1);
      var newMinutes = lastSample.selectedMinutes;
      var newSeconds = lastSample.selectedSeconds + 30;
      
      if (newSeconds >= 60) {
        newMinutes += newSeconds ~/ 60;
        newSeconds = newSeconds % 60;
      }
      
      return Sample(
        numSample: widget.muestreo.count + 1,
        selectedMinutes: newMinutes,
        selectedSeconds: newSeconds,
        y: lastSample.y ?? 0.0,
      );
    }
  }

  void _updateAndNotify() {
    _sortAndRenumberSamples();
    _notifyParent();
  }

  void _sortAndRenumberSamples() {
    final samples = widget.muestreo.samples.toList();
    samples.sort((a, b) {
      final aTotal = a.selectedMinutes * 60 + a.selectedSeconds;
      final bTotal = b.selectedMinutes * 60 + b.selectedSeconds;
      return aTotal.compareTo(bTotal);
    });
    
    widget.muestreo.clearSamples();
    for (int i = 0; i < samples.length; i++) {
      widget.muestreo.addSample(samples[i].copyWith(numSample: i + 1));
    }
  }

  void _removeSample(int index) {
    setState(() {
      widget.muestreo.removeSample(index);
      _updateAndNotify();
    });
  }

  void _updateSample(int index, Sample updatedSample) {
    setState(() {
      widget.muestreo.updateSample(index, updatedSample);
      _updateAndNotify();
    });
  }

  void _notifyParent() {
    widget.onSamplesUpdated?.call(widget.muestreo.deepCopy());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.muestreo.count,
                itemBuilder: (context, index) {
                  final sample = widget.muestreo.getSample(index);
                  return _buildSampleCard(sample, index);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addSample,
                child: const Text('Add Sample'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSampleCard(Sample sample, int index) {
    return Card(
      key: ValueKey(sample.numSample),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sample ${sample.numSample} - ${sample.formattedTime}'),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeSample(index),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: sample.selectedMinutes.toString(),
                    decoration: const InputDecoration(labelText: 'Minutes'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final minutes = int.tryParse(value) ?? 0;
                      _updateSample(
                        index,
                        sample.copyWith(selectedMinutes: minutes),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: sample.selectedSeconds.toString(),
                    decoration: const InputDecoration(labelText: 'Seconds'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (value) {
                      final seconds = int.tryParse(value) ?? 0;
                      _updateSample(
                        index,
                        sample.copyWith(selectedSeconds: seconds),
                      );
                    },
                  ),
                ),
              ],
            ),
            /*TextFormField(
              initialValue: sample.y?.toString() ?? '0',
              decoration: const InputDecoration(labelText: 'Value (Y)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final y = double.tryParse(value) ?? 0.0;
                _updateSample(index, sample.copyWith(y: y));
              },
            ),*/
          ],
        ),
      ),
    );
  }
}