import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/design.dart';
import 'local_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ref.read(localAuthProvider).signIn(_email.text, _senha.text);
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
                  const SizedBox(height: MSpace.md),
                  PillField(label: 'senha:', controller: _senha, obscure: true),
                  const SizedBox(height: MSpace.sm),
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
                    radius: MRadius.blob,
                    padding: const EdgeInsets.all(56),
                    child: Text('Entrar', style: displayTitleStyle(34)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            NeuButton(
              onTap: () => context.goNamed('cadastro'),
              color: MColors.cyanLight,
              child: Text(
                'Não possuo conta',
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
