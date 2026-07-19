import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menthic/design/tokens.dart';

void main() {
  test('paleta fiel ao protótipo', () {
    expect(MColors.mint, const Color(0xFF7BCCD1));
    expect(MColors.cyanLight, const Color(0xFFA2F7FD));
    expect(MColors.mintDeep, const Color(0xFF6CB7BC));
    expect(MColors.highlight, const Color(0xFFDCFDFF));
    expect(MColors.blueAccent, const Color(0xFF42C8ED));
    expect(MColors.neutralGray, const Color(0xFF9F9C9C));
  });

  test('raio do card = 22 (protótipo)', () {
    expect(MRadius.card, 22.0);
  });
}
