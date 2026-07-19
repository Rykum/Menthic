import 'package:go_router/go_router.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/cadastro_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/today/today_screen.dart';
import 'features/review/review_screen.dart';
import 'features/simulate/simulate_screen.dart';
import 'features/twin/twin_screen.dart';
import 'features/calibration/calibration_screen.dart';

final menthicRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/cadastro',
      name: 'cadastro',
      builder: (context, state) => const CadastroScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/hoje',
      name: 'hoje',
      builder: (context, state) => const TodayScreen(),
    ),
    GoRoute(
      path: '/revisao',
      name: 'revisao',
      builder: (context, state) => const ReviewScreen(),
    ),
    GoRoute(
      path: '/simular',
      name: 'simular',
      builder: (context, state) => const SimulateScreen(),
    ),
    GoRoute(
      path: '/twin',
      name: 'twin',
      builder: (context, state) => const TwinScreen(),
    ),
    GoRoute(
      path: '/calibracao',
      name: 'calibracao',
      builder: (context, state) => const CalibrationScreen(),
    ),
  ],
);
