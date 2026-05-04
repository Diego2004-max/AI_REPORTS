import 'package:flutter/material.dart';
import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/app/theme/app_spacing.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: AppShadows.float,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.52, size * 0.52),
          painter: _BarChartPainter(),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 34;
    final h = size.height / 34;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.white.withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromLTRBR(2 * w, 18 * h, 9 * w, 32 * h, const Radius.circular(2)),
      paint,
    );

    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromLTRBR(13.5 * w, 10 * h, 20.5 * w, 32 * h, const Radius.circular(2)),
      paint,
    );

    paint.color = Colors.white.withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromLTRBR(25 * w, 2 * h, 32 * w, 32 * h, const Radius.circular(2)),
      paint,
    );

    paint.color = AppColors.success;
    canvas.drawCircle(Offset(29 * w, 3 * h), 3.5 * w, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
