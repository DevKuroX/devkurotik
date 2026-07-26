/// Phase 4 — Active Sessions Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../../domain/models/hotspot_models.dart';
import '../../providers/hotspot_providers.dart';

/// Screen listing all active hotspot sessions for the active router.
class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotspotAsync = ref.watch(activeHotspotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions'),
        actions: [
          IconButton(
            key: const Key('sessions_refresh_button'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(activeHotspotProvider.notifier).refresh(),
          ),
        ],
      ),
      body: hotspotAsync.when(
        loading: () => const Center(
          key: Key('sessions_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => _buildError(context, ref, err.toString()),
        data: (data) {
          if (data == null || data.activeSessions.isEmpty) {
            return const Center(
              key: Key('sessions_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active sessions.'),
                ],
              ),
            );
          }
          return _buildSessionList(context, ref, data.activeSessions);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      key: const Key('sessions_error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load sessions.'),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('sessions_retry_button'),
            onPressed: () =>
                ref.read(activeHotspotProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    WidgetRef ref,
    List<HotspotActive> sessions,
  ) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(activeHotspotProvider.notifier).refresh(),
      child: ListView.builder(
        key: const Key('sessions_list'),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _SessionTile(session: session);
        },
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final HotspotActive session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: Key('session_tile_${session.id}'),
      leading: const CircleAvatar(
        backgroundColor: Colors.green,
        child: Icon(Icons.wifi, color: Colors.white, size: 20),
      ),
      title: Text(session.user),
      subtitle: Text(
        '${session.address} · ${session.macAddress}'
        '${session.uptime != null ? ' · ${session.uptime}' : ''}',
      ),
      trailing: IconButton(
        key: Key('disconnect_session_${session.id}'),
        icon: const Icon(Icons.logout, color: Colors.red),
        tooltip: 'Disconnect',
        onPressed: () => _confirmDisconnect(context, ref),
      ),
      isThreeLine: false,
      onTap: () => _showDetail(context, session),
    );
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Session'),
        content: Text(
          'Disconnect "${session.user}" (${session.address})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('disconnect_confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(hotspotActionsProvider.notifier)
          .disconnectSession(session.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session "${session.user}" disconnected.'),
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

  void _showDetail(BuildContext context, HotspotActive session) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.user,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const Divider(),
            _Row('IP Address', session.address),
            _Row('MAC Address', session.macAddress),
            _Row('Server', session.server),
            if (session.uptime != null)
              _Row('Uptime', session.uptime!),
            if (session.loginBy != null)
              _Row('Login By', session.loginBy!),
            if (session.bytesIn != null)
              _Row('Bytes In', RouterosFormat.bytes(session.bytesIn!)),
            if (session.bytesOut != null)
              _Row('Bytes Out', RouterosFormat.bytes(session.bytesOut!)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
