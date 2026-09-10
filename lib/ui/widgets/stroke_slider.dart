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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SizedBox(
      width: isMobile ? 80 : 110,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: Slider(
          value: strokeWidth,
          min: 1.0,
          max: 20.0,
          activeColor: const Color(0xFF00FFA3),
          inactiveColor: Colors.white24,
          onChanged: onChanged,
        ),
      ),
    );
  }
}