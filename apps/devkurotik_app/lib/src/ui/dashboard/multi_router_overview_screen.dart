/// MultiRouterOverviewScreen — Phase 3 multi-router dashboard.
///
/// Shows a compact summary card for each saved router.
/// Useful for monitoring multiple routers at a glance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/dashboard_data.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/router_providers.dart';
import 'widgets/router_summary_card.dart';

/// Screen showing all saved routers in a compact list with live metrics.
class MultiRouterOverviewScreen extends ConsumerWidget {
  const MultiRouterOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerList = ref.watch(routerListProvider);
    final multiAsync = ref.watch(multiRouterDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Routers'),
        actions: [
          IconButton(
            key: const Key('multi_refresh_button'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh all',
            onPressed: () => ref
                .read(multiRouterDashboardProvider.notifier)
                .refreshAll(),
          ),
        ],
      ),
      body: routerList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Error loading routers: $err',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        data: (routers) {
          if (routers.isEmpty) {
            return _buildEmptyState(context);
          }
          return multiAsync.when(
            loading: () => _buildLoadingList(context, routers.length),
            error: (err, _) => _buildErrorState(context, err, ref),
            data: (dataList) => _buildOverviewList(context, ref, dataList),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // States
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.router_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No routers saved',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Add a router in Router Management.'),
        ],
      ),
    );
  }

  Widget _buildLoadingList(BuildContext context, int count) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (context, i) => const _SkeletonCard(),
    );
  }

  Widget _buildErrorState(BuildContext context, Object err, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Failed to load dashboard data',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('multi_retry_button'),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () =>
                ref.read(multiRouterDashboardProvider.notifier).refreshAll(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewList(
    BuildContext context,
    WidgetRef ref,
    List<DashboardData> dataList,
  ) {
    if (dataList.isEmpty) {
      return _buildEmptyState(context);
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(multiRouterDashboardProvider.notifier).refreshAll(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: dataList.length,
        itemBuilder: (context, index) {
          final data = dataList[index];
          return RouterSummaryCard(
            key: Key('summary_card_${data.routerId}'),
            data: data,
            compact: true,
          );
        },
      ),
    );
  }
}

// ─── Skeleton card for loading placeholder ──────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(28, 28),
                const SizedBox(width: 12),
                Expanded(child: _box(16, double.infinity)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _box(12, double.infinity)),
                const SizedBox(width: 8),
                Expanded(child: _box(12, double.infinity)),
                const SizedBox(width: 8),
                Expanded(child: _box(12, double.infinity)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(double height, double width) => Container(
        height: height,
        width: width == double.infinity ? null : width,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
