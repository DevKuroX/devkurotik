/// Router list screen — main Phase 2 entry point.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/router_model.dart';
import '../../providers/router_providers.dart';
import '../../routing/app_router.dart';
import 'widgets/router_list_tile.dart';
import 'widgets/health_status_badge.dart';
import 'widgets/router_group_filter.dart';
import 'delete_confirmation_dialog.dart';

/// Screen displaying all saved routers with group filter and health status.
class RouterListScreen extends ConsumerStatefulWidget {
  const RouterListScreen({super.key});

  @override
  ConsumerState<RouterListScreen> createState() => _RouterListScreenState();
}

class _RouterListScreenState extends ConsumerState<RouterListScreen> {
  RouterGroup? _groupFilter;

  @override
  Widget build(BuildContext context) {
    final routerListAsync = ref.watch(routerListProvider);
    final activeRouter = ref.watch(activeRouterProvider);
    final healthMap = ref.watch(routerHealthProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routers'),
        actions: [
          IconButton(
            key: const Key('refresh_health_btn'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Check health',
            onPressed: () async {
              final routers = ref.read(routerListProvider).valueOrNull ?? [];
              if (routers.isNotEmpty) {
                await ref
                    .read(routerHealthProvider.notifier)
                    .checkAll(routers);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_router_fab'),
        onPressed: () => context.push(AppRoutes.addRouter),
        tooltip: 'Add Router',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          RouterGroupFilter(
            selected: _groupFilter,
            onChanged: (g) => setState(() => _groupFilter = g),
          ),
          Expanded(
            child: routerListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  key: const Key('router_list_error'),
                  'Error loading routers: $e',
                ),
              ),
              data: (routers) {
                final filtered = _groupFilter == null
                    ? routers
                    : routers
                        .where((r) => r.group == _groupFilter)
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    key: Key('router_list_empty'),
                    child: Text('No routers saved.\nTap + to add one.'),
                  );
                }

                return ListView.builder(
                  key: const Key('router_list_view'),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final router = filtered[index];
                    final health = healthMap[router.id];
                    final isActive = activeRouter?.id == router.id;

                    return RouterListTile(
                      router: router,
                      isActive: isActive,
                      healthBadge: HealthStatusBadge(result: health),
                      onTap: () => _selectRouter(router),
                      onEdit: () => context.push(
                        AppRoutes.editRouterPath(router.id),
                      ),
                      onDelete: () => _confirmDelete(router),
                      onCheckHealth: () => ref
                          .read(routerHealthProvider.notifier)
                          .checkRouter(router),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRouter(RouterModel router) async {
    await ref.read(activeRouterProvider.notifier).selectRouter(router);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Active router: ${router.name}')),
      );
    }
  }

  Future<void> _confirmDelete(RouterModel router) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(routerName: router.name),
    );
    if (confirmed == true) {
      await ref.read(routerListProvider.notifier).deleteRouter(router.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Router "${router.name}" deleted.')),
        );
      }
    }
  }
}
