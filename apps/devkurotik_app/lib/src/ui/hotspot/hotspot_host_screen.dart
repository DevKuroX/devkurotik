/// Phase 4 — Hotspot Host List Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/hotspot_models.dart';
import '../../providers/hotspot_providers.dart';

/// Screen listing hotspot hosts for the active router.
class HotspotHostScreen extends ConsumerStatefulWidget {
  const HotspotHostScreen({super.key});

  @override
  ConsumerState<HotspotHostScreen> createState() => _HotspotHostScreenState();
}

class _HotspotHostScreenState extends ConsumerState<HotspotHostScreen> {
  HostFilter _filter = HostFilter.all;

  @override
  Widget build(BuildContext context) {
    final hostsAsync = ref.watch(hotspotHostProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotspot Hosts'),
        actions: [
          PopupMenuButton<HostFilter>(
            key: const Key('hosts_filter_menu'),
            initialValue: _filter,
            onSelected: (f) {
              setState(() => _filter = f);
              ref.read(hotspotHostProvider.notifier).refresh(filter: f);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: HostFilter.all,
                child: Text('All'),
              ),
              PopupMenuItem(
                value: HostFilter.authorized,
                child: Text('Authorized'),
              ),
              PopupMenuItem(
                value: HostFilter.bypassed,
                child: Text('Bypassed'),
              ),
            ],
          ),
          IconButton(
            key: const Key('hosts_refresh_button'),
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(hotspotHostProvider.notifier).refresh(filter: _filter),
          ),
        ],
      ),
      body: hostsAsync.when(
        loading: () => const Center(
          key: Key('hosts_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          key: const Key('hosts_error'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Failed to load hosts.'),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const Key('hosts_retry_button'),
                onPressed: () => ref
                    .read(hotspotHostProvider.notifier)
                    .refresh(filter: _filter),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (hosts) {
          if (hosts.isEmpty) {
            return const Center(
              key: Key('hosts_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.device_hub, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hosts found.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(hotspotHostProvider.notifier).refresh(filter: _filter),
            child: ListView.builder(
              key: const Key('hosts_list'),
              itemCount: hosts.length,
              itemBuilder: (context, index) {
                final host = hosts[index];
                return _HostTile(host: host);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HostTile extends ConsumerWidget {
  const _HostTile({required this.host});

  final HotspotHost host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: Key('host_tile_${host.id}'),
      leading: CircleAvatar(
        backgroundColor: host.authorized
            ? Colors.green.shade100
            : Colors.grey.shade200,
        child: Icon(
          host.authorized ? Icons.check_circle : Icons.device_unknown,
          color: host.authorized ? Colors.green : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(host.macAddress),
      subtitle: Text(
        host.address +
            (host.authorized ? ' · Authorized' : '') +
            (host.bypassed ? ' · Bypassed' : '') +
            (host.server != null ? ' · ${host.server}' : ''),
      ),
      trailing: IconButton(
        key: Key('delete_host_${host.id}'),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        tooltip: 'Remove',
        onPressed: () => _confirmRemove(context, ref),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Host'),
        content: Text('Remove host "${host.macAddress}" (${host.address})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('remove_host_confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(hotspotActionsProvider.notifier).removeHost(host.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Host "${host.macAddress}" removed.'),
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
