import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers.dart';
import '../../design/design.dart';
import 'archetype.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String? _periodo;
  int? _adiar;

  Future<void> _finish(int subestima) async {
    final priors = archetypePriors(
      periodo: _periodo!,
      adiar: _adiar!,
      subestima: subestima,
    );
    final repo = ref.read(priorsRepoProvider);
    await repo.save(priors);
    await repo.setOnboarded();
    if (mounted) context.goNamed('hoje');
  }

  Widget _option(String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: MSpace.sm),
    child: NeuButton(
      onTap: onTap,
      child: Text(
        label,
        style: fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: MColors.highlight,
        ),
      ),
    ),
  );

  Widget _scale(void Function(int) onPick) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 1; i <= 5; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MSpace.xs),
          child: NeuButton(
            onTap: () => onPick(i),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Text(
              '$i',
              style: fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: MColors.highlight,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _question(String text) => Padding(
    padding: const EdgeInsets.only(bottom: MSpace.md),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: MColors.mintDeep,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      Column(
        children: [
          _question('Você rende melhor de manhã, à tarde ou à noite?'),
          _option(
            'manhã',
            () => setState(() {
              _periodo = 'manha';
              _step = 1;
            }),
          ),
          _option(
            'tarde',
            () => setState(() {
              _periodo = 'tarde';
              _step = 1;
            }),
          ),
          _option(
            'noite',
            () => setState(() {
              _periodo = 'noite';
              _step = 1;
            }),
          ),
        ],
      ),
      Column(
        children: [
          _question('Costuma adiar tarefas chatas?\n(1 nunca … 5 sempre)'),
          _scale(
            (v) => setState(() {
              _adiar = v;
              _step = 2;
            }),
          ),
        ],
      ),
      Column(
        children: [
          _question(
            'Ao planejar, você subestima quanto as coisas demoram?\n'
            '(1 nunca … 5 sempre)',
          ),
          _scale(_finish),
        ],
      ),
    ];

    return MenthicScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: MSpace.md),
            const DisplayTitle('Menthic', size: 44),
            const SizedBox(height: MSpace.sm),
            Text('${_step + 1} de 3', style: displayTitleStyle(20)),
            const SizedBox(height: MSpace.md),
            GlassCard(child: steps[_step]),
            const SizedBox(height: MSpace.md),
          ],
        ),
      ),
    );
  }
}
