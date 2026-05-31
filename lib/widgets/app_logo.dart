import 'package:flutter/material.dart';

/// 牛马记账 Logo - 牛头轮廓 + ¥ 符号
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool rounded;

  const AppLogo({super.key, this.size = 80, this.showText = false, this.rounded = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: rounded ? BorderRadius.circular(size * 0.22) : null,
            shape: rounded ? BoxShape.rectangle : BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _NiuMaLogoPainter(),
            size: Size(size, size),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.15),
          Text(
            '牛马记账',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _NiuMaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // === 牛头轮廓 ===
    final headPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 牛头主体 - 椭圆形脸
    final headPath = Path();
    final headRect = Rect.fromCenter(
      center: Offset(cx, cy + h * 0.05),
      width: w * 0.42,
      height: h * 0.44,
    );
    headPath.addOval(headRect);
    canvas.drawPath(headPath, headPaint);

    // 左牛角
    final leftHornPath = Path();
    leftHornPath.moveTo(cx - w * 0.14, cy - h * 0.15);
    leftHornPath.quadraticBezierTo(
      cx - w * 0.28, cy - h * 0.32,
      cx - w * 0.22, cy - h * 0.38,
    );
    canvas.drawPath(leftHornPath, headPaint);

    // 右牛角
    final rightHornPath = Path();
    rightHornPath.moveTo(cx + w * 0.14, cy - h * 0.15);
    rightHornPath.quadraticBezierTo(
      cx + w * 0.28, cy - h * 0.32,
      cx + w * 0.22, cy - h * 0.38,
    );
    canvas.drawPath(rightHornPath, headPaint);

    // 左耳
    final leftEarPath = Path();
    leftEarPath.moveTo(cx - w * 0.18, cy - h * 0.1);
    leftEarPath.quadraticBezierTo(
      cx - w * 0.32, cy - h * 0.08,
      cx - w * 0.28, cy + h * 0.02,
    );
    canvas.drawPath(leftEarPath, headPaint);

    // 右耳
    final rightEarPath = Path();
    rightEarPath.moveTo(cx + w * 0.18, cy - h * 0.1);
    rightEarPath.quadraticBezierTo(
      cx + w * 0.32, cy - h * 0.08,
      cx + w * 0.28, cy + h * 0.02,
    );
    canvas.drawPath(rightEarPath, headPaint);

    // === ¥ 符号（在牛脸中央）===
    final yuanPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round;

    final yTop = cy - h * 0.02;
    final yBottom = cy + h * 0.18;
    final yMid = cy + h * 0.06;

    // Y 的两条斜线
    canvas.drawLine(
      Offset(cx - w * 0.08, yTop - h * 0.06),
      Offset(cx, yMid),
      yuanPaint,
    );
    canvas.drawLine(
      Offset(cx + w * 0.08, yTop - h * 0.06),
      Offset(cx, yMid),
      yuanPaint,
    );

    // 竖线
    canvas.drawLine(Offset(cx, yMid), Offset(cx, yBottom), yuanPaint);

    // 两条横线
    canvas.drawLine(
      Offset(cx - w * 0.06, yMid + h * 0.02),
      Offset(cx + w * 0.06, yMid + h * 0.02),
      yuanPaint,
    );
    canvas.drawLine(
      Offset(cx - w * 0.06, yMid + h * 0.06),
      Offset(cx + w * 0.06, yMid + h * 0.06),
      yuanPaint,
    );

    // === 装饰：小圆点（鼻孔）===
    final nosePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx - w * 0.05, cy + h * 0.22), w * 0.018, nosePaint);
    canvas.drawCircle(Offset(cx + w * 0.05, cy + h * 0.22), w * 0.018, nosePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}