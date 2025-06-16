import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/record.dart';
import '../services/record_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sample.dart';
class Editing_samples extends StatefulWidget {
  const Editing_samples({super.key});
  @override
  State<Editing_samples> createState() => _Editing_samplesState();
}

class _Editing_samplesState extends State<Editing_samples> {
  final _formKey = GlobalKey<FormState>();
  List<Sample> samples = [
    Sample(numSample: 1, selectedMinutes: 0, selectedSeconds: 30),
    Sample(numSample: 2, selectedMinutes: 1, selectedSeconds: 0),
    Sample(numSample: 3, selectedMinutes: 1, selectedSeconds: 30),
    Sample(numSample: 4, selectedMinutes: 2, selectedSeconds: 0),
    Sample(numSample: 5, selectedMinutes: 2, selectedSeconds: 30),
    Sample(numSample: 6, selectedMinutes: 3, selectedSeconds: 0),
  ];

  // Helper method to sort samples by duration
  void _sortSamples() {
    setState(() {
      samples.sort((a, b) {
        final aDuration = a.duration;
        final bDuration = b.duration;
        return aDuration.compareTo(bDuration);
      });
      
      // Update sample numbers after sorting
      for (int i = 0; i < samples.length; i++) {
        samples[i] = samples[i].copyWith(numSample: i + 1);
      }
    });
  }

  void _addSample() {
    setState(() {
      samples.add(Sample(
        numSample: samples.length + 1,
        selectedMinutes: 0,
        selectedSeconds: 0,
      ));
      _sortSamples(); // Sort after adding
    });
  }

  void _removeSample(int index) {
    setState(() {
      samples.removeAt(index);
      _sortSamples(); // Sort after removing
    });
  }

  void _updateSample(int index, Sample updatedSample) {
    setState(() {
      samples[index] = updatedSample;
      _sortSamples(); // Sort after updating
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
              itemCount: samples.length,
              itemBuilder: (context, index) {
                final sample = samples[index];
                return _buildSampleCard(sample, index);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addSample,
              child: const Text('Add Sample'),
            ),
            const SizedBox(height: 16), // Espacio adicional al final
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