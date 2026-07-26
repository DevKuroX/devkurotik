/// Phase 7 — Simple Queue Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/queue_models.dart';
import '../../providers/queue_providers.dart';

/// Screen listing all simple queues with filter and search support.
class SimpleQueueScreen extends ConsumerWidget {
  const SimpleQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queues = ref.watch(filteredSimpleQueuesProvider);
    final queueAsync = ref.watch(activeSimpleQueueProvider);
    final search = ref.watch(queueSearchProvider);
    final filter = ref.watch(queueFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Queues'),
        actions: [
          IconButton(
            key: const Key('queue_refresh'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(activeSimpleQueueProvider.notifier).refresh(),
          ),
          PopupMenuButton<SimpleQueueFilter>(
            key: const Key('queue_filter_menu'),
            tooltip: 'Filter',
            icon: Icon(
              Icons.filter_list,
              color: filter != SimpleQueueFilter.all
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onSelected: (f) =>
                ref.read(queueFilterProvider.notifier).setFilter(f),
            itemBuilder: (_) => [
              _filterItem(SimpleQueueFilter.all, 'All', filter),
              _filterItem(SimpleQueueFilter.enabled, 'Enabled', filter),
              _filterItem(SimpleQueueFilter.disabled, 'Disabled', filter),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              key: const Key('queue_search_field'),
              decoration: InputDecoration(
                hintText: 'Search by name or target…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            ref.read(queueSearchProvider.notifier).clearQuery(),
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
                  ref.read(queueSearchProvider.notifier).setQuery(v),
            ),
          ),
        ),
      ),
      body: queueAsync.when(
        loading: () => const Center(
          key: Key('queue_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => _buildError(context, ref, err.toString()),
        data: (_) {
          if (queues.isEmpty) {
            return Center(
              key: const Key('queue_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.queue_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    search.isNotEmpty || filter != SimpleQueueFilter.all
                        ? 'No queues match the filter.'
                        : 'No simple queues found.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(activeSimpleQueueProvider.notifier).refresh(),
            child: ListView.builder(
              key: const Key('queue_list'),
              itemCount: queues.length,
              itemBuilder: (ctx, i) =>
                  _QueueTile(queue: queues[i]),
            ),
          );
        },
      ),
    );
  }

  PopupMenuItem<SimpleQueueFilter> _filterItem(
    SimpleQueueFilter value,
    String label,
    SimpleQueueFilter current,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (current == value)
            const Icon(Icons.check, size: 16)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      key: const Key('queue_error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load queues.'),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('queue_retry'),
            onPressed: () =>
                ref.read(activeSimpleQueueProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile({required this.queue});

  final SimpleQueue queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: Key('queue_tile_${queue.id}'),
      leading: CircleAvatar(
        backgroundColor:
            queue.disabled ? Colors.grey.shade200 : Colors.teal.shade50,
        child: Icon(
          Icons.queue,
          color: queue.disabled ? Colors.grey : Colors.teal,
          size: 20,
        ),
      ),
      title: Text(
        queue.name,
        style: TextStyle(
          color: queue.disabled ? Colors.grey : null,
          decoration: queue.disabled ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        [
          if (queue.target != null) queue.target!,
          if (queue.maxLimit != null) queue.maxLimit!,
        ].join(' · '),
      ),
      trailing: PopupMenuButton<_QueueAction>(
        key: Key('queue_menu_${queue.id}'),
        onSelected: (action) => _onAction(context, ref, action),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: _QueueAction.delete,
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
      onTap: () => _showDetail(context),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _QueueAction action,
  ) async {
    if (action == _QueueAction.delete) {
      await _confirmDelete(context, ref);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Queue'),
        content: Text(
          'Delete queue "${queue.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('queue_delete_confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(queueActionsProvider.notifier).removeQueue(queue.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Queue "${queue.name}" deleted.')),
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
              queue.name,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const Divider(),
            if (queue.target != null) _Row('Target', queue.target!),
            if (queue.maxLimit != null) _Row('Max Limit', queue.maxLimit!),
            if (queue.limitAt != null) _Row('Limit At', queue.limitAt!),
            if (queue.parent != null) _Row('Parent', queue.parent!),
            if (queue.priority != null)
              _Row('Priority', queue.priority!.toString()),
            _Row('Disabled', queue.disabled ? 'yes' : 'no'),
            if (queue.bytes != null) _Row('Bytes', queue.bytes!),
            if (queue.dropped != null) _Row('Dropped', queue.dropped!),
            if (queue.comment != null) _Row('Comment', queue.comment!),
          ],
        ),
      ),
    );
  }
}

enum _QueueAction { delete }

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
