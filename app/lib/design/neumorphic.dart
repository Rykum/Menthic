import 'package:flutter/material.dart';
import 'tokens.dart';

/// Superfície em relevo: sombra clara em cima-esquerda, escura embaixo-direita.
class NeuButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsets padding;
  final Color? color;
  const NeuButton({
    super.key,
    required this.child,
    this.onTap,
    this.radius = MRadius.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? MColors.mint,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: MColors.highlight,
              offset: Offset(-4, -4),
              blurRadius: MBlur.neu,
            ),
            BoxShadow(
              color: MColors.shadowDark,
              offset: Offset(5, 6),
              blurRadius: MBlur.neu + 2,
            ),
          ],
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}

/// Superfície afundada: inner-shadow desenhada por CustomPainter
/// (Flutter não tem BoxShadow interno nativo).
class NeuInset extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? color;
  const NeuInset({
    super.key,
    required this.child,
    this.radius = MRadius.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InsetPainter(base: color ?? MColors.mintDeep, radius: radius),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _InsetPainter extends CustomPainter {
  final Color base;
  final double radius;
  _InsetPainter({required this.base, required this.radius});

  void _innerShadow(
    Canvas c,
    RRect rrect,
    Color color,
    Offset offset,
    double blur,
  ) {
    c.save();
    c.clipRRect(rrect);
    final bounds = rrect.outerRect.inflate(blur * 3 + offset.distance);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds)
      ..addRRect(rrect.shift(offset));
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    c.drawPath(path, paint);
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = base);
    // Sombra escura vinda de cima-esquerda (afunda o topo).
    _innerShadow(
      canvas,
      rrect,
      MColors.shadowDark,
      const Offset(4, 4),
      MBlur.neu,
    );
    // Luz vinda de baixo-direita.
    _innerShadow(
      canvas,
      rrect,
      MColors.highlight.withValues(alpha: 0.6),
      const Offset(-3, -3),
      MBlur.neu,
    );
  }

  @override
  bool shouldRepaint(_InsetPainter old) =>
      old.base != base || old.radius != radius;
}
