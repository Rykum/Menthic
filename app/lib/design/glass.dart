import 'dart:ui';
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Card de vidro fosco: blur do fundo + fill translúcido + borda clara + sombra.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MSpace.lg),
    this.radius = MRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: MColors.shadowDark,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: MBlur.glass, sigmaY: MBlur.glass),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: MColors.glassFill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: MColors.glassBorder, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
