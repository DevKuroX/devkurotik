/// Phase 5 — Voucher History Screen.
///
/// Shows all past voucher batches for the active router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/voucher_models.dart';
import '../../providers/router_providers.dart';
import '../../providers/voucher_providers.dart';
import '../../routing/app_router.dart';

/// Voucher history — list of past batches.
class VoucherHistoryScreen extends ConsumerWidget {
  const VoucherHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRouter = ref.watch(activeRouterProvider);

    if (activeRouter == null) {
      return const Scaffold(
        body: Center(child: Text('No router selected.')),
      );
    }

    final batchesAsync = ref.watch(voucherBatchListProvider(activeRouter.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Voucher History')),
      body: batchesAsync.when(
        data: (batches) => batches.isEmpty
            ? const _NoBatchesYet()
            : _BatchList(batches: batches, routerId: activeRouter.id),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NoBatchesYet extends StatelessWidget {
  const _NoBatchesYet();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48),
          SizedBox(height: 8),
          Text('No batches generated yet.'),
        ],
      ),
    );
  }
}

class _BatchList extends ConsumerWidget {
  const _BatchList({required this.batches, required this.routerId});

  final List<VoucherBatch> batches;
  final String routerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: batches.length,
      itemBuilder: (context, index) {
        final batch = batches[index];
        return _BatchTile(batch: batch, routerId: routerId);
      },
    );
  }
}

class _BatchTile extends ConsumerWidget {
  const _BatchTile({required this.batch, required this.routerId});

  final VoucherBatch batch;
  final String routerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRouter = ref.watch(activeRouterProvider);

    return Dismissible(
      key: Key('batch_${batch.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(context);
      },
      onDismissed: (_) async {
        await ref
            .read(voucherActionsProvider.notifier)
            .deleteBatch(batch.id, routerId);
      },
      child: ListTile(
        key: Key('batch_tile_${batch.id}'),
        leading: const Icon(Icons.receipt_long),
        title: Text(batch.batchCode),
        subtitle: Text(
          '${batch.quantity} × ${batch.profileName} — ${batch.mode.name}',
        ),
        trailing: Text(
          _formatDate(batch.generatedAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () => context.push(
          AppRoutes.voucherPreview,
          extra: batch,
        ),
        onLongPress: () => _showActions(context, ref, activeRouter),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete batch?'),
        content: Text('Delete "${batch.batchCode}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showActions(BuildContext context, WidgetRef ref, dynamic router) {
    if (router == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                final render = ref.read(voucherRenderServiceProvider);
                final print = ref.read(printServiceProvider);
                final pdf = await render.renderBatch(
                  batch: batch,
                  routerName: router.name as String,
                  routerHost: router.host as String,
                );
                await print.sharePdf(pdf.bytes, pdf.filename);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: () async {
                Navigator.pop(ctx);
                if (await _confirmDelete(context)) {
                  await ref
                      .read(voucherActionsProvider.notifier)
                      .deleteBatch(batch.id, routerId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
