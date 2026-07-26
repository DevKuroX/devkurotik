/// go_router routing configuration for Phase 2 + Phase 3.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/router_management/router_list_screen.dart';
import '../ui/router_management/add_router_screen.dart';
import '../ui/router_management/edit_router_screen.dart';
import '../ui/dashboard/dashboard_screen.dart';
import '../ui/dashboard/multi_router_overview_screen.dart';
import '../ui/shell/app_shell.dart';

/// Route name constants.
class AppRoutes {
  AppRoutes._();

  // ── Phase 2 — Router management ────────────────────────────────────────────
  static const routerList = '/routers';
  static const addRouter = '/routers/add';
  static const editRouter = '/routers/edit/:id';

  static String editRouterPath(String id) => '/routers/edit/$id';

  // ── Phase 3 — Dashboard ────────────────────────────────────────────────────
  static const dashboard = '/dashboard';
  static const multiRouter = '/overview';
}

/// App router instance.
final appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  routes: [
    // ── Shell (tab navigation) ────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        // ── Dashboard (Phase 3) ─────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.dashboard,
          name: 'dashboard',
          builder: (BuildContext context, GoRouterState state) =>
              const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.multiRouter,
          name: 'multi-router',
          builder: (BuildContext context, GoRouterState state) =>
              const MultiRouterOverviewScreen(),
        ),
        // ── Router management (Phase 2) ─────────────────────────────────────
        GoRoute(
          path: AppRoutes.routerList,
          name: 'router-list',
          builder: (BuildContext context, GoRouterState state) =>
              const RouterListScreen(),
        ),
      ],
    ),
    // ── Modal routes (outside shell) ─────────────────────────────────────────
    GoRoute(
      path: AppRoutes.addRouter,
      name: 'add-router',
      builder: (BuildContext context, GoRouterState state) =>
          const AddRouterScreen(),
    ),
    GoRoute(
      path: AppRoutes.editRouter,
      name: 'edit-router',
      builder: (BuildContext context, GoRouterState state) {
        final routerId = state.pathParameters['id']!;
        return EditRouterScreen(routerId: routerId);
      },
    ),
  ],
);
