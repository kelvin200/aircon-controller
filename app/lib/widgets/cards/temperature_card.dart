import 'package:flutter/material.dart';
import '../../models.dart';
import '../panel.dart';

/// Temperature card: large monospaced value with a set-point slider.
class TemperatureCard extends StatelessWidget {
  final SystemStatus status;
  final Color tempColor;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const TemperatureCard({
    super.key,
    required this.status,
    required this.tempColor,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final s = status;
    return Panel(
      title: 'Temperature',
      child: Column(
        children: [
          Center(
            child: Text(
              '${s.setTemp.toStringAsFixed(1)}°',
              key: const Key('set-temp'),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w600,
                color: tempColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Slider(
            key: const Key('status-temp-slider'),
            min: 18,
            max: 25,
            divisions: 7,
            value: (s.setTemp.clamp(18, 25) as double),
            activeColor: tempColor,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}
