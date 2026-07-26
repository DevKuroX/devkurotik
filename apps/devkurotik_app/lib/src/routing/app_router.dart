/// go_router routing configuration for Phase 2.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/router_management/router_list_screen.dart';
import '../ui/router_management/add_router_screen.dart';
import '../ui/router_management/edit_router_screen.dart';

/// Route name constants.
class AppRoutes {
  AppRoutes._();

  static const routerList = '/routers';
  static const addRouter = '/routers/add';
  static const editRouter = '/routers/edit/:id';

  static String editRouterPath(String id) => '/routers/edit/$id';
}

/// App router instance.
final appRouter = GoRouter(
  initialLocation: AppRoutes.routerList,
  routes: [
    GoRoute(
      path: AppRoutes.routerList,
      name: 'router-list',
      builder: (BuildContext context, GoRouterState state) =>
          const RouterListScreen(),
    ),
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
