import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design/theme.dart';
import 'router.dart';

void main() => runApp(const ProviderScope(child: MenthicApp()));

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
