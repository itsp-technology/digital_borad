import 'dart:ui';

class StrokePoint {
  final Offset offset;
  final double pressure;

  const StrokePoint({
    required this.offset,
    this.pressure = 0.5,
  });
}