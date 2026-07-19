import 'package:flutter/material.dart';

/// Paleta exata extraída dos protótipos SVG. Nenhum widget usa hex direto.
abstract final class MColors {
  static const mint = Color(0xFF7BCCD1);
  static const cyanLight = Color(0xFFA2F7FD);
  static const mintDeep = Color(0xFF6CB7BC);
  static const highlight = Color(0xFFDCFDFF);
  static const blueAccent = Color(0xFF42C8ED);
  static const neutralGray = Color(0xFF9F9C9C);

  /// Sombra escura do neumorphism (derivada do mintDeep, mais fechada).
  static const shadowDark = Color(0x33456B6E);

  /// Fill do vidro: cyanLight a 20% (fill-opacity="0.2" no SVG).
  static Color get glassFill => cyanLight.withValues(alpha: 0.20);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.35);
}

abstract final class MRadius {
  static const pill = 36.5; // rx dos botões-pílula no SVG
  static const card = 22.0; // rx do card de vidro no SVG
  static const blob = 999.0;
}

abstract final class MSpace {
  static const xs = 6.0;
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 28.0;
  static const xl = 40.0;
}

abstract final class MBlur {
  static const glass = 18.0; // sigma do BackdropFilter do card
  static const neu = 8.0; // blur das sombras neumórficas
}
