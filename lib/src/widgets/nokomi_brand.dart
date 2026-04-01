import 'package:flutter/material.dart';

class NokomiBrand extends StatelessWidget {
  const NokomiBrand({
    super.key,
    this.compact = false,
    this.showText = true,
  });

  final bool compact;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 42.0 : 50.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF16493F), Color(0xFF3DB69B)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332D8B73),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _NokomiLogoPainter(),
          ),
        ),
        if (showText) ...[
          SizedBox(width: compact ? 10 : 14),
          Text(
            'Nokomi',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFE8EAED),
              fontSize: compact ? 24 : 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _NokomiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()..color = const Color(0x66FFFFFF);
    final pagePaint = Paint()..color = const Color(0x44FFFFFF);
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.28, size.width * 0.28,
          size.height * 0.5),
      Radius.circular(size.width * 0.05),
    );
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.24, size.height * 0.24, size.width * 0.24,
          size.height * 0.54),
      Radius.circular(size.width * 0.05),
    );
    canvas.drawRRect(leftRect, pagePaint);
    canvas.drawRRect(rightRect, framePaint);

    final divider = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = size.width * 0.03;
    canvas.drawLine(
      Offset(size.width * 0.37, size.height * 0.24),
      Offset(size.width * 0.37, size.height * 0.78),
      divider,
    );

    final path = Path()
      ..moveTo(size.width * 0.56, size.height * 0.18)
      ..lineTo(size.width * 0.56, size.height * 0.72)
      ..moveTo(size.width * 0.56, size.height * 0.18)
      ..lineTo(size.width * 0.8, size.height * 0.56)
      ..moveTo(size.width * 0.8, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height * 0.72);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
