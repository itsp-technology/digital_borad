import 'dart:ui';

class CurveMath {
  /// Computes the midpoint between two coordinates to anchor quadratic Bézier curves
  static Offset computeMidpoint(Offset p1, Offset p2) {
    return Offset((p1.dx + p2.dx) / 2.0, (p1.dy + p2.dy) / 2.0);
  }
}