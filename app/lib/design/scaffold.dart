import 'package:flutter/material.dart';
import 'tokens.dart';
import 'neumorphic.dart';

/// Base de toda tela: textura de fundo + blobs decorativos + conteúdo.
class MenthicScaffold extends StatelessWidget {
  final Widget child;
  final bool blobs;
  const MenthicScaffold({super.key, required this.child, this.blobs = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/textures/paper.jpg', fit: BoxFit.cover),
          if (blobs) const FloatingBlobs(),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// Círculos mint flutuantes; alguns são anéis com miolo afundado (protótipo).
class FloatingBlobs extends StatelessWidget {
  const FloatingBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        Widget ring(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MColors.mint.withValues(alpha: 0.25),
          ),
          child: Center(
            child: NeuInset(
              radius: MRadius.blob,
              padding: EdgeInsets.all(size * 0.14),
              color: MColors.mint,
              child: SizedBox(width: size * 0.5, height: size * 0.5),
            ),
          ),
        );
        Widget dot(double size, double opacity) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MColors.mint.withValues(alpha: opacity),
          ),
        );
        return Stack(
          children: [
            Positioned(left: w * 0.28, top: h * 0.06, child: dot(40, 0.5)),
            Positioned(left: w * 0.18, top: h * 0.58, child: ring(150)),
            Positioned(right: w * 0.10, top: h * 0.34, child: dot(120, 0.18)),
            Positioned(left: w * 0.08, bottom: h * 0.14, child: dot(120, 0.2)),
            Positioned(right: w * 0.12, bottom: h * 0.10, child: ring(150)),
          ],
        );
      },
    );
  }
}
