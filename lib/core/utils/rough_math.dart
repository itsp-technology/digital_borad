import 'dart:math' as math;
import 'dart:ui';

class RoughMath {
  static final math.Random _rng = math.Random();

  static double _roughness(double roughness) => (roughness * 1.5);

  /// Generates a hand-drawn looking line with subtle curved jitter
  static Path roughLine(Offset start, Offset end, {double roughness = 1.0}) {
    final path = Path()..moveTo(start.dx, start.dy);
    final distance = (end - start).distance;
    final r = _roughness(roughness);

    if (distance < 10) {
      path.lineTo(end.dx, end.dy);
      return path;
    }

    // First slight bow curve
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final normal = Offset(-(end.dy - start.dy), end.dx - start.dx);
    final normLen = normal.distance;
    final unitNormal = normLen > 0 ? Offset(normal.dx / normLen, normal.dy / normLen) : Offset.zero;

    final jitter1 = (_rng.nextDouble() - 0.5) * r * 3.0;
    final ctrl1 = mid + unitNormal * jitter1;
    path.quadraticBezierTo(ctrl1.dx, ctrl1.dy, end.dx, end.dy);

    // Second slight sketch pass for authentic hand-drawn feel
    final jitter2 = (_rng.nextDouble() - 0.5) * r * 2.5;
    final ctrl2 = mid - unitNormal * jitter2;
    path.moveTo(start.dx + (_rng.nextDouble() - 0.5) * r, start.dy + (_rng.nextDouble() - 0.5) * r);
    path.quadraticBezierTo(ctrl2.dx, ctrl2.dy, end.dx, end.dy);

    return path;
  }

  /// Generates a hand-drawn rectangle with overlapping sketch corners
  static Path roughRect(Rect rect, {double roughness = 1.0}) {
    final path = Path();
    final p1 = rect.topLeft;
    final p2 = rect.topRight;
    final p3 = rect.bottomRight;
    final p4 = rect.bottomLeft;

    path.addPath(roughLine(p1, p2, roughness: roughness), Offset.zero);
    path.addPath(roughLine(p2, p3, roughness: roughness), Offset.zero);
    path.addPath(roughLine(p3, p4, roughness: roughness), Offset.zero);
    path.addPath(roughLine(p4, p1, roughness: roughness), Offset.zero);
    return path;
  }

  /// Generates an Excalidraw-style ellipse/circle
  static Path roughEllipse(Rect rect, {double roughness = 1.0}) {
    final path = Path();
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final rx = rect.width / 2.0;
    final ry = rect.height / 2.0;
    const steps = 36;
    final r = _roughness(roughness);

    for (int pass = 0; pass < 2; pass++) {
      for (int i = 0; i <= steps; i++) {
        final theta = (i / steps) * 2 * math.pi;
        final wobble = (_rng.nextDouble() - 0.5) * r * 1.5;
        final x = cx + (rx + wobble) * math.cos(theta);
        final y = cy + (ry + wobble) * math.sin(theta);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }
    return path;
  }

  /// Generates an Excalidraw-style arrow
  static Path roughArrow(Offset start, Offset end, {double roughness = 1.0}) {
    final path = roughLine(start, end, roughness: roughness);
    const double arrowLen = 18.0;
    const double angle = 26 * math.pi / 180;
    final double dir = math.atan2(end.dy - start.dy, end.dx - start.dx);

    final a1 = Offset(
      end.dx - arrowLen * math.cos(dir - angle),
      end.dy - arrowLen * math.sin(dir - angle),
    );
    final a2 = Offset(
      end.dx - arrowLen * math.cos(dir + angle),
      end.dy - arrowLen * math.sin(dir + angle),
    );

    path.addPath(roughLine(end, a1, roughness: roughness), Offset.zero);
    path.addPath(roughLine(end, a2, roughness: roughness), Offset.zero);
    return path;
  }
}