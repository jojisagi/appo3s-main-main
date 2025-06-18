
import 'package:flutter/services.dart';

class Sample {
   int numSample;
   int selectedMinutes;
   int selectedSeconds;
   double? y;

  Sample({
    required this.numSample,
    required this.selectedMinutes,
    required this.selectedSeconds,
    this.y=0.0,
  });

  Duration get duration => Duration(
        minutes: selectedMinutes,
        seconds: selectedSeconds,
      );

  String get formattedTime =>
      '${selectedMinutes.toString().padLeft(2, '0')}:'
      '${selectedSeconds.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'num_sample': numSample,
        'minutes': selectedMinutes,
        'seconds': selectedSeconds,
        if (y != null) 'y': y,
      };

  factory Sample.fromJson(Map<String, dynamic> json) => Sample(
        numSample: json['num_sample'] as int,
        selectedMinutes: json['minutes'] as int,
        selectedSeconds: json['seconds'] as int,
        y: json['y']?.toDouble(),
      );

  Sample copyWith({
    int? numSample,
    int? selectedMinutes,
    int? selectedSeconds,
    double? y,
  }) {
    return Sample(
      numSample: numSample ?? this.numSample,
      selectedMinutes: selectedMinutes ?? this.selectedMinutes,
      selectedSeconds: selectedSeconds ?? this.selectedSeconds,
      y: y ?? this.y,
    );
  }
}