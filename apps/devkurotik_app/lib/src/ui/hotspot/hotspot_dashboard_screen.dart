/// Phase 4 — Hotspot Dashboard Screen.
///
/// Overview of hotspot metrics for the active router, with navigation
/// to user list, active sessions, cookies, and hosts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/hotspot_providers.dart';
import '../../providers/router_providers.dart';
import '../../routing/app_router.dart';

/// Top-level hotspot screen showing summary stats and navigation tiles.
class HotspotDashboardScreen extends ConsumerWidget {
  const HotspotDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRouter = ref.watch(activeRouterProvider);
    final hotspotAsync = ref.watch(activeHotspotProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeRouter != null
              ? '${activeRouter.name} — Hotspot'
              : 'Hotspot',
        ),
        actions: [
          IconButton(
            key: const Key('hotspot_dashboard_refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(activeHotspotProvider.notifier).refresh(),
          ),
        ],
      ),
      body: hotspotAsync.when(
        loading: () => const Center(
          key: Key('hotspot_dashboard_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => _buildError(context, ref, err.toString()),
        data: (data) {
          if (activeRouter == null) {
            return _buildNoRouter(context);
          }
          if (data == null) {
            return _buildNoRouter(context);
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(activeHotspotProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        key: const Key('stat_total_users'),
                        label: 'Total Users',
                        value: '${data.totalUsers}',
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        key: const Key('stat_active_users'),
                        label: 'Active',
                        value: '${data.activeUsers}',
                        icon: Icons.wifi,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        key: const Key('stat_disabled_users'),
                        label: 'Disabled',
                        value: '${data.disabledUsers}',
                        icon: Icons.person_off,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        key: const Key('stat_expired_users'),
                        label: 'Expired',
                        value: '${data.expiredUsers}',
                        icon: Icons.timer_off,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Navigation tiles
                Text(
                  'Manage',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                _NavTile(
                  key: const Key('nav_user_list'),
                  icon: Icons.people,
                  title: 'Users',
                  subtitle: '${data.totalUsers} total',
                  onTap: () => context.push(AppRoutes.hotspotUsers),
                ),
                _NavTile(
                  key: const Key('nav_active_sessions'),
                  icon: Icons.wifi,
                  title: 'Active Sessions',
                  subtitle: '${data.activeUsers} online',
                  onTap: () => context.push(AppRoutes.hotspotSessions),
                ),
                _NavTile(
                  key: const Key('nav_cookies'),
                  icon: Icons.cookie,
                  title: 'Cookies',
                  onTap: () => context.push(AppRoutes.hotspotCookies),
                ),
                _NavTile(
                  key: const Key('nav_hosts'),
                  icon: Icons.device_hub,
                  title: 'Hosts',
                  onTap: () => context.push(AppRoutes.hotspotHosts),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: activeRouter != null
          ? FloatingActionButton(
              key: const Key('hotspot_add_user_fab'),
              onPressed: () => context.push(AppRoutes.addHotspotUser),
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Widget _buildNoRouter(BuildContext context) {
    return Center(
      key: const Key('hotspot_no_router'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.router_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No active router selected.'),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('hotspot_go_to_routers'),
            onPressed: () => context.go(AppRoutes.routerList),
            child: const Text('Go to Routers'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    final sanitized =
        error.replaceAll(RegExp(r'=password=[^\s,]+'), '=password=***');
    return Center(
      key: const Key('hotspot_dashboard_error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Failed to load hotspot data.'),
            const SizedBox(height: 8),
            Text(
              sanitized,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('hotspot_dashboard_retry'),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () =>
                  ref.read(activeHotspotProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
