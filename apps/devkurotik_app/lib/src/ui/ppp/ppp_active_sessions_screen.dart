/// Phase 7 — PPP Active Sessions Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/ppp_models.dart';
import '../../providers/ppp_providers.dart';

/// Screen listing all active PPP sessions with disconnect support.
class PppActiveSessionsScreen extends ConsumerWidget {
  const PppActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pppAsync = ref.watch(activePppProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PPP Active Sessions'),
        actions: [
          IconButton(
            key: const Key('ppp_sessions_refresh'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(activePppProvider.notifier).refresh(),
          ),
        ],
      ),
      body: pppAsync.when(
        loading: () => const Center(
          key: Key('ppp_sessions_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => _buildError(context, ref, err.toString()),
        data: (data) {
          final sessions = data?.activeSessions ?? [];
          if (sessions.isEmpty) {
            return const Center(
              key: Key('ppp_sessions_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active PPP sessions.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(activePppProvider.notifier).refresh(),
            child: ListView.builder(
              key: const Key('ppp_sessions_list'),
              itemCount: sessions.length,
              itemBuilder: (ctx, i) =>
                  _PppSessionTile(session: sessions[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      key: const Key('ppp_sessions_error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load PPP sessions.'),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('ppp_sessions_retry'),
            onPressed: () => ref.read(activePppProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PppSessionTile extends ConsumerWidget {
  const _PppSessionTile({required this.session});

  final PppActive session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: Key('ppp_session_tile_${session.id}'),
      leading: const CircleAvatar(
        backgroundColor: Colors.green,
        child: Icon(Icons.link, color: Colors.white, size: 20),
      ),
      title: Text(session.name),
      subtitle: Text(
        '${session.service} · ${session.address}'
        '${session.uptime != null ? ' · ${session.uptime}' : ''}',
      ),
      trailing: IconButton(
        key: Key('ppp_disconnect_${session.id}'),
        icon: const Icon(Icons.logout, color: Colors.red),
        tooltip: 'Disconnect',
        onPressed: () => _confirmDisconnect(context, ref),
      ),
      onTap: () => _showDetail(context),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect PPP Session'),
        content: Text(
          'Disconnect "${session.name}" (${session.address})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('ppp_disconnect_confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(pppActionsProvider.notifier)
          .disconnectSession(session.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session "${session.name}" disconnected.')),
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

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.name,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const Divider(),
            _Row('Service', session.service),
            _Row('IP Address', session.address),
            if (session.uptime != null) _Row('Uptime', session.uptime!),
            if (session.callerId != null)
              _Row('Caller ID', session.callerId!),
            if (session.encoding != null)
              _Row('Encoding', session.encoding!),
            if (session.sessionId != null)
              _Row('Session ID', session.sessionId!),
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
            width: 100,
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
