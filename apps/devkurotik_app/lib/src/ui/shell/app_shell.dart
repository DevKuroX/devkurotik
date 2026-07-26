/// AppShell — persistent bottom navigation shell.
///
/// Wraps all top-level screens in a BottomNavigationBar.
/// Phase 3: Dashboard + Overview + Router Management tabs.
/// Phase 4: Added Hotspot tab.
/// Phase 5: Added Voucher tab (index 2; Overview→3, Routers→4).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';

/// Shell widget providing bottom tab navigation.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFromLocation(location),
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        destinations: const [
          NavigationDestination(
            key: Key('nav_dashboard'),
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            key: Key('nav_hotspot'),
            icon: Icon(Icons.wifi_outlined),
            selectedIcon: Icon(Icons.wifi),
            label: 'Hotspot',
          ),
          NavigationDestination(
            key: Key('nav_voucher'),
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Vouchers',
          ),
          NavigationDestination(
            key: Key('nav_overview'),
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Overview',
          ),
          NavigationDestination(
            key: Key('nav_routers'),
            icon: Icon(Icons.router_outlined),
            selectedIcon: Icon(Icons.router),
            label: 'Routers',
          ),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith(AppRoutes.hotspot)) return 1;
    if (location.startsWith(AppRoutes.voucher)) return 2;
    if (location.startsWith(AppRoutes.multiRouter)) return 3;
    if (location.startsWith(AppRoutes.routerList)) return 4;
    return 0; // dashboard (default)
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.hotspot);
      case 2:
        context.go(AppRoutes.voucher);
      case 3:
        context.go(AppRoutes.multiRouter);
      case 4:
        context.go(AppRoutes.routerList);
    }
  }
}
