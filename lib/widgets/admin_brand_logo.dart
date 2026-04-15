import 'package:flutter/material.dart';
import '../infrastructure/theme.dart';

/// A reusable Rockstar admin brand logo widget.
///
/// This widget draws a simple six-pointed star mark and pairs it with the
/// "ROCKSTAR" wordmark and an optional "ADMIN PANEL" subtitle.
class AdminBrandLogo extends StatelessWidget {
  final bool showSubtitle;

  const AdminBrandLogo({super.key, this.showSubtitle = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AdminColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: const CustomPaint(painter: _RockstarMarkPainter()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ROCKSTAR',
                style: TextStyle(
                    fontFamily: 'Epilogue',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white)),
            if (showSubtitle) ...[
              const SizedBox(height: 2),
              const Text('ADMIN PANEL',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AdminColors.textMuted,
                      fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ],
    );
  }
}

class _RockstarMarkPainter extends CustomPainter {
  const _RockstarMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AdminColors.accent;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    // ignore: unused_local_variable
    final angle = 60.0 * (3.1415926535897932 / 180.0);
    final dx = radius * 0.8660254037844386; // cos(30°)
    final dy = radius * 0.5;

    final path1 = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx - dx, center.dy + dy)
      ..lineTo(center.dx + dx, center.dy + dy)
      ..close();

    final path2 = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - dx, center.dy - dy)
      ..lineTo(center.dx + dx, center.dy - dy)
      ..close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
