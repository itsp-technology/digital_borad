import 'package:flutter/material.dart';

class StrokeSlider extends StatelessWidget {
  final double strokeWidth;
  final ValueChanged<double> onChanged;

  const StrokeSlider({
    super.key,
    required this.strokeWidth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Slider(
        value: strokeWidth,
        min: 1.0,
        max: 20.0,
        activeColor: Colors.white,
        inactiveColor: Colors.white24,
        onChanged: onChanged,
      ),
    );
  }
}