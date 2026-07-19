import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design/theme.dart';
import 'firebase_options.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Sem Firebase (plataforma não configurada/offline no boot): o app segue
    // no modo local (LocalAuth + PersistentEventStore).
  }
  runApp(const ProviderScope(child: MenthicApp()));
}

class MenthicApp extends StatelessWidget {
  const MenthicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Menthic',
      debugShowCheckedModeBanner: false,
      theme: menthicTheme(),
      routerConfig: menthicRouter,
    );
  }
}
