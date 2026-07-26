import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: DevKuroTikApp()));
}

class DevKuroTikApp extends StatelessWidget {
  const DevKuroTikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevKuroTik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const _PlaceholderHome(),
    );
  }
}

/// Phase 0 placeholder — navigation and features implemented in later phases.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevKuroTik'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'DevKuroTik\nFoundation scaffold — Phase 0',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
