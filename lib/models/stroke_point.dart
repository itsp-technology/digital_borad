import 'dart:ui';

class StrokePoint {
  final Offset offset;
  final double pressure;

  const StrokePoint({
    required this.offset,
    this.pressure = 0.5,
  });

  Map<String, dynamic> toMap() => {
        'x': offset.dx,
        'y': offset.dy,
        'p': pressure,
      };

  factory StrokePoint.fromMap(Map<String, dynamic> map) => StrokePoint(
        offset: Offset(
          (map['x'] as num).toDouble(),
          (map['y'] as num).toDouble(),
        ),
        pressure: (map['p'] as num?)?.toDouble() ?? 0.5,
      );
}