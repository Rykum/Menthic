import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/design.dart';
import 'local_auth.dart';

class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});
  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirm = TextEditingController();
  final _fone = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _confirm.dispose();
    _fone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(localAuthProvider)
          .signUp(
            email: _email.text,
            password: _senha.text,
            confirm: _confirm.text,
            phone: _fone.text,
          );
      if (mounted) context.goNamed('hoje');
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenthicScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: MSpace.md),
            const DisplayTitle('Menthic'),
            const SizedBox(height: MSpace.md),
            GlassCard(
              child: Column(
                children: [
                  PillField(label: 'email:', controller: _email),
                  const SizedBox(height: MSpace.sm),
                  PillField(label: 'senha:', controller: _senha, obscure: true),
                  const SizedBox(height: MSpace.sm),
                  PillField(
                    label: 'Confirmar Senha:',
                    controller: _confirm,
                    obscure: true,
                  ),
                  const SizedBox(height: MSpace.sm),
                  PillField(
                    label: 'Telefone:',
                    controller: _fone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: MSpace.md),
                  Text('ou', style: displayTitleStyle(22)),
                  const SizedBox(height: MSpace.sm),
                  GoogleButton(
                    onTap: () async {
                      await ref.read(localAuthProvider).signInWithGoogle();
                      if (context.mounted) context.goNamed('hoje');
                    },
                  ),
                  const SizedBox(height: MSpace.lg),
                  NeuButton(
                    onTap: _submit,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 28,
                    ),
                    child: Text('Cadastar', style: displayTitleStyle(34)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            NeuButton(
              onTap: () => context.goNamed('login'),
              color: MColors.cyanLight,
              child: Text(
                'já possuo conta',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: MColors.mintDeep,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: MSpace.md),
            const Text(
              'By Munhoz',
              style: TextStyle(
                color: MColors.neutralGray,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
