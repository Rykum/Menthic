import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers.dart';
import '../../design/design.dart';
import 'local_auth.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) async {
      if (s == AnimationStatus.completed && mounted) {
        final logged = await ref.read(localAuthProvider).isLoggedIn();
        if (!mounted) return;
        if (!logged) {
          context.goNamed('login');
          return;
        }
        final onboarded = await ref.read(priorsRepoProvider).onboarded();
        if (!mounted) return;
        context.goNamed(onboarded ? 'hoje' : 'onboarding');
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenthicScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: MSpace.xl),
          const DisplayTitle('Menthic', size: 60),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => NeuInset(
              radius: MRadius.blob,
              padding: const EdgeInsets.all(48),
              color: MColors.mint,
              child: Text(
                '${(_c.value * 100).round()}%',
                style: displayTitleStyle(40),
              ),
            ),
          ),
          const Text(
            'By Munhoz',
            style: TextStyle(
              color: MColors.neutralGray,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
