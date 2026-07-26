/// Phase 5 — Voucher Dashboard Screen.
///
/// Entry point for the Voucher tab. Shows:
/// - Summary stats (last batch)
/// - Quick actions (Generate, Quick Print, History)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/router_providers.dart';
import '../../providers/voucher_providers.dart';
import '../../routing/app_router.dart';

/// Voucher dashboard — Phase 5 entry screen.
class VoucherDashboardScreen extends ConsumerWidget {
  const VoucherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRouter = ref.watch(activeRouterProvider);
    final lastBatchAsync = ref.watch(lastVoucherBatchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vouchers'),
        actions: [
          if (activeRouter != null)
            IconButton(
              key: const Key('voucher_history_btn'),
              icon: const Icon(Icons.history),
              tooltip: 'History',
              onPressed: () => context.push(AppRoutes.voucherHistory),
            ),
        ],
      ),
      body: activeRouter == null
          ? const _NoRouterSelected()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Router info card
                  _RouterInfoCard(router: activeRouter),
                  const SizedBox(height: 16),
                  // Last batch summary
                  lastBatchAsync.when(
                    data: (batch) => batch != null
                        ? _LastBatchCard(batch: batch)
                        : const _NoBatchYet(),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                  ),
                  const SizedBox(height: 16),
                  // Quick actions
                  const _QuickActionsSection(),
                ],
              ),
            ),
      floatingActionButton: activeRouter == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('generate_voucher_fab'),
              onPressed: () => context.push(AppRoutes.generateVoucher),
              icon: const Icon(Icons.add_card),
              label: const Text('Generate'),
            ),
    );
  }
}

class _NoRouterSelected extends StatelessWidget {
  const _NoRouterSelected();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.router_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No router selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Select a router from the Routers tab first.'),
        ],
      ),
    );
  }
}

class _RouterInfoCard extends StatelessWidget {
  const _RouterInfoCard({required this.router});

  final dynamic router;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.router),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    router.name as String,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    router.host as String,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _LastBatchCard extends StatelessWidget {
  const _LastBatchCard({required this.batch});

  final dynamic batch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Last Batch',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const Divider(),
            _InfoRow(label: 'Batch', value: batch.batchCode as String),
            _InfoRow(label: 'Profile', value: batch.profileName as String),
            _InfoRow(
              label: 'Count',
              value: (batch.quantity as int).toString(),
            ),
            _InfoRow(label: 'Mode', value: (batch.mode as Object).toString().split('.').last),
          ],
        ),
      ),
    );
  }
}

class _NoBatchYet extends StatelessWidget {
  const _NoBatchYet();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 12),
            const Text('No vouchers generated yet.'),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                key: const Key('generate_action_btn'),
                icon: Icons.add_card,
                label: 'Generate',
                onTap: () => context.push(AppRoutes.generateVoucher),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                key: const Key('quick_print_action_btn'),
                icon: Icons.print,
                label: 'Quick Print',
                onTap: () => context.push(AppRoutes.quickPrint),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                key: const Key('history_action_btn'),
                icon: Icons.history,
                label: 'History',
                onTap: () => context.push(AppRoutes.voucherHistory),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
