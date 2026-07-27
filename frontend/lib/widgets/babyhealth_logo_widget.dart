import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// BabyHealth brand logo: a rounded badge with the brand gradient
/// (teal → coral) containing a white heart with a heartbeat (ECG) line.
///
/// Matches the marketing landing logo. [size] controls the badge side length.
class BabyHealthLogoWidget extends StatelessWidget {
  final double size;

  const BabyHealthLogoWidget({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48.0; // design space is 48x48
    final radius = 12 * s;

    // Badge with brand gradient.
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final badgePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primary, // #4B9B9B
          AppTheme.auroraTeal, // #73D2D2
          AppTheme.accent, // #DF7B5E
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      badgePaint,
    );

    // Heart (white).
    final heart = Path()
      ..moveTo(24 * s, 36.5 * s)
      ..cubicTo(10 * s, 27 * s, 7 * s, 17.5 * s, 14.5 * s, 13.5 * s)
      ..cubicTo(19 * s, 11 * s, 22.5 * s, 13.5 * s, 24 * s, 16.5 * s)
      ..cubicTo(25.5 * s, 13.5 * s, 29 * s, 11 * s, 33.5 * s, 13.5 * s)
      ..cubicTo(41 * s, 17.5 * s, 38 * s, 27 * s, 24 * s, 36.5 * s)
      ..close();
    canvas.drawPath(heart, Paint()..color = Colors.white);

    // Heartbeat / ECG line (teal-dark).
    final ecg = Path()
      ..moveTo(13 * s, 24.5 * s)
      ..lineTo(18 * s, 24.5 * s)
      ..lineTo(19.8 * s, 19.9 * s)
      ..lineTo(22.2 * s, 28.1 * s)
      ..lineTo(24 * s, 22.1 * s)
      ..lineTo(25.2 * s, 24.5 * s)
      ..lineTo(35 * s, 24.5 * s);
    canvas.drawPath(
      ecg,
      Paint()
        ..color = AppTheme.primaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
