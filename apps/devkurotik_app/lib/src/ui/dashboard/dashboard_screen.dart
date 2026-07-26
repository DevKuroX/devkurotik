/// DashboardScreen — Phase 3 single-router dashboard.
///
/// Bound to the active router from Phase 2 [activeRouterProvider].
/// Supports pull-to-refresh, loading state, empty state, error state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/dashboard_data.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/router_providers.dart';
import 'widgets/router_summary_card.dart';

/// Main dashboard screen for the currently active router.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final activeRouter = ref.watch(activeRouterProvider);

    if (activeRouter == null) {
      return _buildEmptyState(context);
    }

    final dashAsync = ref.watch(dashboardProvider(activeRouter.id));
    final refreshSettings = ref.watch(dashboardRefreshSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(activeRouter.name),
        actions: [
          if (refreshSettings.autoRefresh)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Auto-refresh every '
                    '${refreshSettings.interval!.inSeconds}s',
                child: const Icon(Icons.sync, size: 18),
              ),
            ),
          IconButton(
            key: const Key('dashboard_refresh_button'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _doRefresh(activeRouter.id),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Refresh settings',
            onPressed: () => _showRefreshSettings(context),
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => _buildLoadingState(context),
        error: (err, _) => _buildErrorState(context, err, activeRouter.id),
        data: (data) => _buildDataState(context, data, activeRouter.id),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // States
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.router_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.secondary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No router selected',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Router Management and select an active router.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('go_to_routers_button'),
              icon: const Icon(Icons.list),
              label: const Text('Manage Routers'),
              onPressed: () {
                // Navigate to router list via go_router.
                // Using context.go would require go_router import here;
                // emit via callback or use navigator if not using go_router directly.
                Navigator.of(context).pushNamed('/routers');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting to router…'),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    String routerId,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_wifi_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to reach router',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _sanitizeError(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('dashboard_retry_button'),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => _doRefresh(routerId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataState(
    BuildContext context,
    DashboardData data,
    String routerId,
  ) {
    return RefreshIndicator(
      onRefresh: () => _doRefresh(routerId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          RouterSummaryCard(
            key: Key('summary_card_${data.routerId}'),
            data: data,
          ),
          _buildInterfaceList(context, data),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interface list section
  // ---------------------------------------------------------------------------

  Widget _buildInterfaceList(BuildContext context, DashboardData data) {
    if (data.interfaces.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cable,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Interfaces (${data.runningInterfaceCount}/'
                  '${data.totalInterfaceCount} up)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...data.interfaces.map((iface) => _InterfaceRow(iface: iface)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _doRefresh(String routerId) async {
    await ref.read(dashboardProvider(routerId).notifier).refresh();
  }

  void _showRefreshSettings(BuildContext context) {
    final settings = ref.read(dashboardRefreshSettingsProvider);
    final notifier = ref.read(dashboardRefreshSettingsProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _RefreshSettingsSheet(
        settings: settings,
        notifier: notifier,
      ),
    );
  }

  /// Sanitize error messages to avoid credential leakage.
  String _sanitizeError(Object error) {
    final raw = error.toString();
    // Strip stack trace if present.
    final idx = raw.indexOf('\n');
    final msg = idx > 0 ? raw.substring(0, idx) : raw;
    // Remove any password-looking content.
    return msg.replaceAll(RegExp(r'=password=[^\s,)]+'), '=password=***');
  }
}

// ─── Interface row ───────────────────────────────────────────────────────────

class _InterfaceRow extends StatelessWidget {
  const _InterfaceRow({required this.iface});

  final InterfaceSummary iface;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            iface.running ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: iface.running ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              iface.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (iface.type != null)
            Text(
              iface.type!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(102),
                  ),
            ),
        ],
      ),
    );
  }
}

// ─── Refresh settings bottom sheet ──────────────────────────────────────────

class _RefreshSettingsSheet extends StatelessWidget {
  const _RefreshSettingsSheet({
    required this.settings,
    required this.notifier,
  });

  final DashboardRefreshSettings settings;
  final DashboardRefreshSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auto-Refresh Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _option(context, 'Manual only', null),
          _option(context, 'Every 15 seconds', const Duration(seconds: 15)),
          _option(context, 'Every 30 seconds', const Duration(seconds: 30)),
          _option(context, 'Every 60 seconds', const Duration(seconds: 60)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, String label, Duration? interval) {
    final isSelected = settings.interval == interval;
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        if (interval == null) {
          notifier.disableAutoRefresh();
        } else {
          notifier.setInterval(interval);
        }
        Navigator.of(context).pop();
      },
    );
  }
}
