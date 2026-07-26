/// Phase 4 — Hotspot User Detail Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../../domain/models/hotspot_models.dart';
import '../../domain/services/hotspot_service.dart';
import '../../providers/hotspot_providers.dart';
import '../../routing/app_router.dart';

/// Detailed view for a single hotspot user.
///
/// Receives [HotspotUser] via route `extra` parameter.
class HotspotUserDetailScreen extends ConsumerWidget {
  const HotspotUserDetailScreen({
    super.key,
    required this.userId,
    required this.user,
  });

  final String userId;
  final HotspotUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lookup matching active session for this user.
    final hotspotAsync = ref.watch(activeHotspotProvider);
    final activeSession = hotspotAsync.valueOrNull?.activeSessions
        .where((a) => a.user == user.name)
        .firstOrNull;

    // Decode expiry from comment.
    final expiry = HotspotService.decodeExpiry(user);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          IconButton(
            key: const Key('hotspot_detail_edit_button'),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push(
              AppRoutes.editHotspotUser(user.id),
              extra: user,
            ),
          ),
          PopupMenuButton<_DetailAction>(
            key: const Key('hotspot_detail_overflow'),
            onSelected: (action) =>
                _handleAction(context, ref, action),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                key: const Key('hotspot_detail_toggle_disabled'),
                value: user.disabled
                    ? _DetailAction.enable
                    : _DetailAction.disable,
                child: Text(user.disabled ? 'Enable User' : 'Disable User'),
              ),
              const PopupMenuItem(
                key: Key('hotspot_detail_reset_counters'),
                value: _DetailAction.resetCounters,
                child: Text('Reset Counters'),
              ),
              const PopupMenuItem(
                key: Key('hotspot_detail_delete'),
                value: _DetailAction.delete,
                child: Text(
                  'Delete User',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          _StatusCard(user: user, activeSession: activeSession),
          const SizedBox(height: 16),

          // Details card
          _DetailCard(user: user),
          const SizedBox(height: 16),

          // Active session card (if online)
          if (activeSession != null) ...[
            _ActiveSessionCard(session: activeSession),
            const SizedBox(height: 16),
          ],

          // Expiry card (if applicable)
          if (expiry != null) ...[
            _ExpiryCard(expiry: expiry),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _DetailAction action,
  ) async {
    switch (action) {
      case _DetailAction.enable:
        await _toggleEnabled(context, ref, disabled: false);
      case _DetailAction.disable:
        await _toggleEnabled(context, ref, disabled: true);
      case _DetailAction.resetCounters:
        await _confirmResetCounters(context, ref);
      case _DetailAction.delete:
        await _confirmDelete(context, ref);
    }
  }

  Future<void> _toggleEnabled(
    BuildContext context,
    WidgetRef ref, {
    required bool disabled,
  }) async {
    try {
      if (disabled) {
        await ref.read(hotspotActionsProvider.notifier).disableUser(userId);
      } else {
        await ref.read(hotspotActionsProvider.notifier).enableUser(userId);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              disabled ? 'User disabled.' : 'User enabled.',
            ),
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  Future<void> _confirmResetCounters(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Counters'),
        content: Text(
          'Reset all counters (uptime, bytes) for "${user.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('reset_counters_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(hotspotActionsProvider.notifier)
          .resetCounters(userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Counters reset.')),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Permanently delete "${user.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('delete_user_confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(hotspotActionsProvider.notifier).deleteUser(userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User "${user.name}" deleted.')),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.replaceAll(RegExp(r'=password=[^\s,]+'), '=password=***'),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-cards
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.user, required this.activeSession});

  final HotspotUser user;
  final HotspotActive? activeSession;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: user.disabled
                  ? Colors.grey.shade200
                  : activeSession != null
                      ? Colors.green.shade100
                      : Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                user.disabled
                    ? Icons.person_off
                    : activeSession != null
                        ? Icons.wifi
                        : Icons.person,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _StatusChip(
                        label: user.disabled ? 'Disabled' : 'Enabled',
                        color: user.disabled ? Colors.orange : Colors.green,
                      ),
                      if (activeSession != null)
                        const _StatusChip(
                          label: 'ACTIVE',
                          color: Colors.green,
                        ),
                      if (user.isExpired)
                        const _StatusChip(
                          label: 'EXPIRED',
                          color: Colors.red,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.user});

  final HotspotUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(),
            _Row('Profile', user.profile),
            _Row('Server', user.server),
            if (user.password.isNotEmpty)
              _Row('Password', user.password),
            if (user.macAddress != null)
              _Row('MAC Address', user.macAddress!),
            if (user.ipAddress != null)
              _Row('IP Address', user.ipAddress!),
            if (user.limitUptime != null)
              _Row('Limit Uptime', user.limitUptime!),
            if (user.limitBytesTotal != null)
              _Row(
                'Limit (bytes)',
                RouterosFormat.bytes(user.limitBytesTotal!),
              ),
            if (user.bytesIn != null)
              _Row('Bytes In', RouterosFormat.bytes(user.bytesIn!)),
            if (user.bytesOut != null)
              _Row('Bytes Out', RouterosFormat.bytes(user.bytesOut!)),
            if (user.comment != null && user.comment!.isNotEmpty)
              _Row('Comment', user.comment!),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({required this.session});

  final HotspotActive session;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Session',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(),
            _Row('IP Address', session.address),
            _Row('MAC Address', session.macAddress),
            if (session.uptime != null) _Row('Uptime', session.uptime!),
            if (session.bytesIn != null)
              _Row('Bytes In', RouterosFormat.bytes(session.bytesIn!)),
            if (session.bytesOut != null)
              _Row('Bytes Out', RouterosFormat.bytes(session.bytesOut!)),
            if (session.loginBy != null)
              _Row('Login By', session.loginBy!),
          ],
        ),
      ),
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({required this.expiry});

  final HotspotExpiry expiry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: expiry.isExpired ? Colors.red.shade50 : Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expiry',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(),
            _Row('Expires', expiry.displayText),
            _Row('Status', expiry.isExpired ? 'Expired' : 'Active'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

enum _DetailAction { enable, disable, resetCounters, delete }
