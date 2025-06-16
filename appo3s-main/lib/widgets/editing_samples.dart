import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/muestreo.dart';
import '../models/sample.dart';

class EditingSamples extends StatefulWidget {
  final Muestreo muestreo;
  
  const EditingSamples({super.key, required this.muestreo});

  @override
  State<EditingSamples> createState() => _EditingSamplesState();
}

class _EditingSamplesState extends State<EditingSamples> {
  final _formKey = GlobalKey<FormState>();

  void _addSample() {
    setState(() {
      if (widget.muestreo.isEmpty) {
        // First sample: 0 minutes, 30 seconds
        widget.muestreo.addSample(Sample(
          numSample: 1,
          selectedMinutes: 0,
          selectedSeconds: 30,
        ));
      } else {
        // Get the last sample's time
        final lastSample = widget.muestreo.getSample(widget.muestreo.count - 1);
        var newMinutes = lastSample.selectedMinutes;
        var newSeconds = lastSample.selectedSeconds + 30;
        
        // Handle seconds overflow
        if (newSeconds >= 60) {
          newMinutes += newSeconds ~/ 60;
          newSeconds = newSeconds % 60;
        }
        
        widget.muestreo.addSample(Sample(
          numSample: widget.muestreo.count + 1,
          selectedMinutes: newMinutes,
          selectedSeconds: newSeconds,
        ));
      }
      _sortAndRenumberSamples();
    });
  }

  void _sortAndRenumberSamples() {
    setState(() {
      // Get current samples and sort them by duration
      final samples = widget.muestreo.samples.toList();
      samples.sort((a, b) {
        final aTotal = a.selectedMinutes * 60 + a.selectedSeconds;
        final bTotal = b.selectedMinutes * 60 + b.selectedSeconds;
        return aTotal.compareTo(bTotal);
      });
      
      // Update the muestreo with sorted and renumbered samples
      widget.muestreo.clearSamples();
      for (int i = 0; i < samples.length; i++) {
        widget.muestreo.addSample(samples[i].copyWith(numSample: i + 1));
      }
    });
  }

  void _removeSample(int index) {
    setState(() {
      widget.muestreo.removeSample(index);
      _sortAndRenumberSamples();
    });
  }

  void _updateSample(int index, Sample updatedSample) {
    setState(() {
      widget.muestreo.updateSample(index, updatedSample);
      _sortAndRenumberSamples();
    });
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
              const SizedBox(height: 16),
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
            if (sample.y != null)
              TextFormField(
                initialValue: sample.y.toString(),
                decoration: const InputDecoration(labelText: 'Y Value'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final y = double.tryParse(value);
                  _updateSample(index, sample.copyWith(y: y));
                },
              ),
          ],
        ),
      ),
    );
  }
}