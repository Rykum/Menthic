import 'package:flutter/material.dart';

/// Fontes embutidas (assets/fonts, OFL) — mesmas assinaturas que os antigos
/// GoogleFonts.fredoka/nunito para o refactor ser só de import.
TextStyle fredoka({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  TextDecoration? decoration,
  List<Shadow>? shadows,
}) => TextStyle(
  fontFamily: 'Fredoka',
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  decoration: decoration,
  shadows: shadows,
);

TextStyle nunito({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  TextDecoration? decoration,
  List<Shadow>? shadows,
}) => TextStyle(
  fontFamily: 'Nunito',
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  decoration: decoration,
  shadows: shadows,
);
