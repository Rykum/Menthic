import 'package:flutter/material.dart';
import 'fonts.dart';
import 'tokens.dart';

ThemeData menthicTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MColors.mint,
      primary: MColors.mint,
      surface: MColors.cyanLight,
    ),
    scaffoldBackgroundColor: MColors.cyanLight,
  );
  return base.copyWith(textTheme: base.textTheme.apply(fontFamily: 'Nunito'));
}

/// Estilo do título "bolha" (Fredoka), aproximação da tipografia do protótipo.
TextStyle displayTitleStyle(double size) => fredoka(
  fontSize: size,
  fontWeight: FontWeight.w700,
  color: MColors.mint,
  shadows: const [
    Shadow(color: MColors.mintDeep, offset: Offset(1, 2), blurRadius: 2),
    Shadow(color: MColors.highlight, offset: Offset(-1, -1), blurRadius: 1),
  ],
);
