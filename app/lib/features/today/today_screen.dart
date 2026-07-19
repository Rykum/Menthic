import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/design.dart';
import '../auth/local_auth.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenthicScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DisplayTitle('Menthic'),
            const SizedBox(height: MSpace.lg),
            GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bem-vindo 👋', style: displayTitleStyle(26)),
                  const SizedBox(height: MSpace.lg),
                  NeuButton(
                    onTap: () async {
                      await ref.read(localAuthProvider).signOut();
                      if (context.mounted) context.goNamed('login');
                    },
                    child: Text('Sair', style: displayTitleStyle(24)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
