import 'package:flutter/material.dart';
import 'fonts.dart';
import 'tokens.dart';
import 'theme.dart';
import 'neumorphic.dart';

/// Título "bolha" — aproximação da tipografia do protótipo.
class DisplayTitle extends StatelessWidget {
  final String text;
  final double size;
  const DisplayTitle(this.text, {super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: displayTitleStyle(size));
  }
}

/// Rótulo mint + campo afundado (NeuInset) com TextField sem borda.
class PillField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  const PillField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            label,
            style: fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: MColors.mintDeep,
            ),
          ),
        ),
        NeuInset(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: nunito(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pílula branca "Continuar com o Google" (logo extraído do SVG).
class GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const GoogleButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return NeuButton(
      onTap: onTap,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/img/google_g.png', width: 24, height: 24),
          const SizedBox(width: 12),
          Text(
            'Continuar com o Google',
            style: nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
