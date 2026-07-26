/// Phase 7 — PPP Secret List Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/ppp_models.dart';
import '../../providers/ppp_providers.dart';
import '../../routing/app_router.dart';

/// Screen listing all PPP secrets with search and filter support.
class PppSecretListScreen extends ConsumerWidget {
  const PppSecretListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secrets = ref.watch(filteredPppSecretsProvider);
    final pppAsync = ref.watch(activePppProvider);
    final search = ref.watch(pppSearchProvider);
    final filter = ref.watch(pppServiceFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PPP Secrets'),
        actions: [
          IconButton(
            key: const Key('ppp_secrets_refresh'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(activePppProvider.notifier).refresh(),
          ),
          PopupMenuButton<PppServiceType>(
            key: const Key('ppp_service_filter_menu'),
            tooltip: 'Filter by service',
            icon: Icon(
              Icons.filter_list,
              color: filter != PppServiceType.any
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onSelected: (type) =>
                ref.read(pppServiceFilterProvider.notifier).setFilter(type),
            itemBuilder: (_) => PppServiceType.values
                .map(
                  (t) => PopupMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        if (filter == t)
                          const Icon(Icons.check, size: 16)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Text(t.displayName),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              key: const Key('ppp_search_field'),
              decoration: InputDecoration(
                hintText: 'Search by username or profile…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            ref.read(pppSearchProvider.notifier).clearQuery(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
                filled: true,
              ),
              onChanged: (v) =>
                  ref.read(pppSearchProvider.notifier).setQuery(v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('ppp_add_secret_fab'),
        tooltip: 'Add PPP Secret',
        onPressed: () => context.push(AppRoutes.addPppSecret),
        child: const Icon(Icons.add),
      ),
      body: pppAsync.when(
        loading: () => const Center(
          key: Key('ppp_secrets_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => _buildError(context, ref, err.toString()),
        data: (_) {
          if (secrets.isEmpty) {
            return Center(
              key: const Key('ppp_secrets_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.vpn_key_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    search.isNotEmpty || filter != PppServiceType.any
                        ? 'No secrets match the filter.'
                        : 'No PPP secrets found.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(activePppProvider.notifier).refresh(),
            child: ListView.builder(
              key: const Key('ppp_secrets_list'),
              itemCount: secrets.length,
              itemBuilder: (ctx, i) =>
                  _SecretTile(secret: secrets[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      key: const Key('ppp_secrets_error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load PPP secrets.'),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('ppp_secrets_retry'),
            onPressed: () => ref.read(activePppProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SecretTile extends ConsumerWidget {
  const _SecretTile({required this.secret});

  final PppSecret secret;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: Key('secret_tile_${secret.id}'),
      leading: CircleAvatar(
        backgroundColor: secret.disabled
            ? Colors.grey.shade200
            : Colors.indigo.shade50,
        child: Icon(
          Icons.vpn_key_outlined,
          color: secret.disabled ? Colors.grey : Colors.indigo,
          size: 20,
        ),
      ),
      title: Text(
        secret.name,
        style: TextStyle(
          color: secret.disabled ? Colors.grey : null,
          decoration: secret.disabled ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${secret.service.displayName} · ${secret.profile}'
        '${secret.comment != null ? ' · ${secret.comment}' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (secret.disabled)
            const Icon(Icons.pause_circle_outline,
                color: Colors.orange, size: 18),
          PopupMenuButton<_SecretAction>(
            key: Key('secret_menu_${secret.id}'),
            onSelected: (action) =>
                _onAction(context, ref, action),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _SecretAction.edit,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: secret.disabled
                    ? _SecretAction.enable
                    : _SecretAction.disable,
                child: Row(
                  children: [
                    Icon(secret.disabled
                        ? Icons.play_arrow_outlined
                        : Icons.pause_outlined),
                    const SizedBox(width: 8),
                    Text(secret.disabled ? 'Enable' : 'Disable'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _SecretAction.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => context.push(
        AppRoutes.editPppSecretPath(secret.id),
        extra: secret,
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _SecretAction action,
  ) async {
    switch (action) {
      case _SecretAction.edit:
        if (context.mounted) {
          context.push(AppRoutes.editPppSecretPath(secret.id), extra: secret);
        }
      case _SecretAction.enable:
        try {
          await ref.read(pppActionsProvider.notifier).enableSecret(secret.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${secret.name}" enabled.')),
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
      case _SecretAction.disable:
        try {
          await ref.read(pppActionsProvider.notifier).disableSecret(secret.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${secret.name}" disabled.')),
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
      case _SecretAction.delete:
        await _confirmDelete(context, ref);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Secret'),
        content: Text(
          'Delete PPP secret "${secret.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('ppp_delete_confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(pppActionsProvider.notifier).deleteSecret(secret.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${secret.name}" deleted.')),
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

enum _SecretAction { edit, enable, disable, delete }
