/// Phase 7 — PPP Dashboard Screen.
///
/// Entry point for PPP management: counts and navigation to
/// secrets, active sessions, and profiles.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/ppp_providers.dart';
import '../../routing/app_router.dart';

/// Dashboard screen for PPP management.
class PppDashboardScreen extends ConsumerWidget {
  const PppDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pppAsync = ref.watch(activePppProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PPP'),
        actions: [
          IconButton(
            key: const Key('ppp_dashboard_refresh'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(activePppProvider.notifier).refresh(),
          ),
        ],
      ),
      body: pppAsync.when(
        loading: () => const Center(
          key: Key('ppp_dashboard_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => _buildError(context, ref, err.toString()),
        data: (data) {
          final secrets = data?.secrets.length ?? 0;
          final active = data?.activeSessions.length ?? 0;
          final profiles = data?.profiles.length ?? 0;

          return ListView(
            key: const Key('ppp_dashboard_list'),
            padding: const EdgeInsets.all(16),
            children: [
              _DashboardCard(
                key: const Key('ppp_secrets_card'),
                icon: Icons.vpn_key_outlined,
                color: Colors.indigo,
                title: 'Secrets',
                subtitle: '$secrets user${secrets == 1 ? '' : 's'}',
                onTap: () => context.push(AppRoutes.pppSecrets),
              ),
              const SizedBox(height: 12),
              _DashboardCard(
                key: const Key('ppp_sessions_card'),
                icon: Icons.link,
                color: Colors.green,
                title: 'Active Sessions',
                subtitle: '$active session${active == 1 ? '' : 's'}',
                onTap: () => context.push(AppRoutes.pppActiveSessions),
              ),
              const SizedBox(height: 12),
              _DashboardCard(
                key: const Key('ppp_profiles_card'),
                icon: Icons.tune,
                color: Colors.deepOrange,
                title: 'Profiles',
                subtitle: '$profiles profile${profiles == 1 ? '' : 's'}',
                onTap: () => context.push(AppRoutes.pppProfiles),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      key: const Key('ppp_dashboard_error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load PPP data.'),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('ppp_dashboard_retry'),
            onPressed: () => ref.read(activePppProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
