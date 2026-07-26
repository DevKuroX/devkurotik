import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/routing/app_router.dart';

void main() {
  runApp(const ProviderScope(child: DevKuroTikApp()));
}

class DevKuroTikApp extends StatelessWidget {
  const DevKuroTikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DevKuroTik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
