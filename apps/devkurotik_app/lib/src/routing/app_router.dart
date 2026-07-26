/// go_router routing configuration for Phase 2 + Phase 3 + Phase 4 + Phase 5 + Phase 7.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/models/hotspot_models.dart';
import '../domain/models/ppp_models.dart';
import '../domain/models/voucher_models.dart';
import '../ui/router_management/router_list_screen.dart';
import '../ui/router_management/add_router_screen.dart';
import '../ui/router_management/edit_router_screen.dart';
import '../ui/dashboard/dashboard_screen.dart';
import '../ui/dashboard/multi_router_overview_screen.dart';
import '../ui/shell/app_shell.dart';
import '../ui/hotspot/hotspot_dashboard_screen.dart';
import '../ui/hotspot/hotspot_user_list_screen.dart';
import '../ui/hotspot/hotspot_user_detail_screen.dart';
import '../ui/hotspot/add_hotspot_user_screen.dart';
import '../ui/hotspot/edit_hotspot_user_screen.dart';
import '../ui/hotspot/active_sessions_screen.dart';
import '../ui/hotspot/hotspot_cookie_screen.dart';
import '../ui/hotspot/hotspot_host_screen.dart';
import '../ui/voucher/voucher_dashboard_screen.dart';
import '../ui/voucher/generate_voucher_screen.dart';
import '../ui/voucher/voucher_preview_screen.dart';
import '../ui/voucher/voucher_history_screen.dart';
import '../ui/voucher/quick_print_screen.dart';
import '../ui/voucher/voucher_template_screen.dart';
import '../ui/ppp/ppp_dashboard_screen.dart';
import '../ui/ppp/ppp_secret_list_screen.dart';
import '../ui/ppp/add_ppp_secret_screen.dart';
import '../ui/ppp/edit_ppp_secret_screen.dart';
import '../ui/ppp/ppp_active_sessions_screen.dart';
import '../ui/ppp/ppp_profiles_screen.dart';
import '../ui/queue/simple_queue_screen.dart';

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

  // ── Phase 4 — Hotspot ──────────────────────────────────────────────────────
  static const hotspot = '/hotspot';
  static const hotspotUsers = '/hotspot/users';
  static const hotspotUserDetail = '/hotspot/users/:userId';
  static const addHotspotUser = '/hotspot/users/add';
  static const editHotspotUserPath = '/hotspot/users/:userId/edit';
  static const hotspotSessions = '/hotspot/sessions';
  static const hotspotCookies = '/hotspot/cookies';
  static const hotspotHosts = '/hotspot/hosts';

  static String hotspotUserDetailPath(String userId) =>
      '/hotspot/users/$userId';

  static String editHotspotUser(String userId) =>
      '/hotspot/users/$userId/edit';

  // ── Phase 5 — Voucher ──────────────────────────────────────────────────────
  static const voucher = '/voucher';
  static const generateVoucher = '/voucher/generate';
  static const voucherPreview = '/voucher/preview';
  static const voucherHistory = '/voucher/history';
  static const quickPrint = '/voucher/quick-print';
  static const voucherTemplate = '/voucher/template';

  // ── Phase 7 — PPP ─────────────────────────────────────────────────────────
  static const ppp = '/ppp';
  static const pppSecrets = '/ppp/secrets';
  static const addPppSecret = '/ppp/secrets/add';
  static const editPppSecret = '/ppp/secrets/:secretId/edit';
  static const pppActiveSessions = '/ppp/sessions';
  static const pppProfiles = '/ppp/profiles';

  static String editPppSecretPath(String secretId) =>
      '/ppp/secrets/$secretId/edit';

  // ── Phase 7 — Queue ───────────────────────────────────────────────────────
  static const queue = '/queue';
  static const simpleQueues = '/queue/simple';
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
        // ── Hotspot dashboard (Phase 4) ─────────────────────────────────────
        GoRoute(
          path: AppRoutes.hotspot,
          name: 'hotspot',
          builder: (BuildContext context, GoRouterState state) =>
              const HotspotDashboardScreen(),
        ),
        // ── Voucher dashboard (Phase 5) ─────────────────────────────────────
        GoRoute(
          path: AppRoutes.voucher,
          name: 'voucher',
          builder: (BuildContext context, GoRouterState state) =>
              const VoucherDashboardScreen(),
        ),
        // ── PPP dashboard (Phase 7) ─────────────────────────────────────────
        GoRoute(
          path: AppRoutes.ppp,
          name: 'ppp',
          builder: (BuildContext context, GoRouterState state) =>
              const PppDashboardScreen(),
        ),
        // ── Queue dashboard (Phase 7) ───────────────────────────────────────
        GoRoute(
          path: AppRoutes.queue,
          name: 'queue',
          builder: (BuildContext context, GoRouterState state) =>
              const SimpleQueueScreen(),
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
    // ── Hotspot sub-routes (outside shell — full screen flows) ───────────────
    GoRoute(
      path: AppRoutes.hotspotUsers,
      name: 'hotspot-users',
      builder: (BuildContext context, GoRouterState state) =>
          const HotspotUserListScreen(),
    ),
    GoRoute(
      path: AppRoutes.addHotspotUser,
      name: 'add-hotspot-user',
      builder: (BuildContext context, GoRouterState state) =>
          const AddHotspotUserScreen(),
    ),
    GoRoute(
      path: AppRoutes.hotspotUserDetail,
      name: 'hotspot-user-detail',
      builder: (BuildContext context, GoRouterState state) {
        final userId = state.pathParameters['userId']!;
        final user = state.extra as HotspotUser?;
        if (user == null) {
          // Fallback: navigate back to user list if no user passed.
          return const HotspotUserListScreen();
        }
        return HotspotUserDetailScreen(userId: userId, user: user);
      },
    ),
    GoRoute(
      path: AppRoutes.editHotspotUserPath,
      name: 'edit-hotspot-user',
      builder: (BuildContext context, GoRouterState state) {
        final userId = state.pathParameters['userId']!;
        final user = state.extra as HotspotUser?;
        if (user == null) {
          return const HotspotUserListScreen();
        }
        return EditHotspotUserScreen(userId: userId, user: user);
      },
    ),
    GoRoute(
      path: AppRoutes.hotspotSessions,
      name: 'hotspot-sessions',
      builder: (BuildContext context, GoRouterState state) =>
          const ActiveSessionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.hotspotCookies,
      name: 'hotspot-cookies',
      builder: (BuildContext context, GoRouterState state) =>
          const HotspotCookieScreen(),
    ),
    GoRoute(
      path: AppRoutes.hotspotHosts,
      name: 'hotspot-hosts',
      builder: (BuildContext context, GoRouterState state) =>
          const HotspotHostScreen(),
    ),
    // ── Voucher sub-routes (outside shell) ───────────────────────────────────
    GoRoute(
      path: AppRoutes.generateVoucher,
      name: 'generate-voucher',
      builder: (BuildContext context, GoRouterState state) =>
          const GenerateVoucherScreen(),
    ),
    GoRoute(
      path: AppRoutes.voucherPreview,
      name: 'voucher-preview',
      builder: (BuildContext context, GoRouterState state) {
        final batch = state.extra as VoucherBatch?;
        if (batch == null) {
          return const VoucherDashboardScreen();
        }
        return VoucherPreviewScreen(batch: batch);
      },
    ),
    GoRoute(
      path: AppRoutes.voucherHistory,
      name: 'voucher-history',
      builder: (BuildContext context, GoRouterState state) =>
          const VoucherHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.quickPrint,
      name: 'quick-print',
      builder: (BuildContext context, GoRouterState state) =>
          const QuickPrintScreen(),
    ),
    GoRoute(
      path: AppRoutes.voucherTemplate,
      name: 'voucher-template',
      builder: (BuildContext context, GoRouterState state) =>
          const VoucherTemplateScreen(),
    ),
    // ── PPP sub-routes (Phase 7) ──────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.pppSecrets,
      name: 'ppp-secrets',
      builder: (BuildContext context, GoRouterState state) =>
          const PppSecretListScreen(),
    ),
    GoRoute(
      path: AppRoutes.addPppSecret,
      name: 'add-ppp-secret',
      builder: (BuildContext context, GoRouterState state) =>
          const AddPppSecretScreen(),
    ),
    GoRoute(
      path: AppRoutes.editPppSecret,
      name: 'edit-ppp-secret',
      builder: (BuildContext context, GoRouterState state) {
        final secretId = state.pathParameters['secretId']!;
        final secret = state.extra as PppSecret?;
        if (secret == null) {
          return const PppSecretListScreen();
        }
        return EditPppSecretScreen(secretId: secretId, secret: secret);
      },
    ),
    GoRoute(
      path: AppRoutes.pppActiveSessions,
      name: 'ppp-sessions',
      builder: (BuildContext context, GoRouterState state) =>
          const PppActiveSessionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.pppProfiles,
      name: 'ppp-profiles',
      builder: (BuildContext context, GoRouterState state) =>
          const PppProfilesScreen(),
    ),
    // ── Queue sub-routes (Phase 7) ────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.simpleQueues,
      name: 'simple-queues',
      builder: (BuildContext context, GoRouterState state) =>
          const SimpleQueueScreen(),
    ),
  ],
);
