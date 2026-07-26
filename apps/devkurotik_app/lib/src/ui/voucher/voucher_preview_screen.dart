/// Phase 5 — Voucher Preview Screen.
///
/// Shows generated vouchers with print/share actions.
/// Also handles failure recovery: if printing fails, user can retry.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/voucher_models.dart';
import '../../providers/router_providers.dart';
import '../../providers/voucher_providers.dart';

/// Shows a generated voucher batch with print/share options.
class VoucherPreviewScreen extends ConsumerWidget {
  const VoucherPreviewScreen({super.key, required this.batch});

  final VoucherBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(activeRouterProvider);
    final template = ref.watch(voucherTemplateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Vouchers — ${batch.batchCode}'),
        actions: [
          IconButton(
            key: const Key('template_btn'),
            icon: const Icon(Icons.view_list),
            tooltip: 'Select Template',
            onPressed: () => _showTemplateSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Batch summary bar
          _BatchSummaryBar(batch: batch),
          // Voucher list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: batch.vouchers.length,
              itemBuilder: (context, index) {
                final voucher = batch.vouchers[index];
                return _VoucherItemCard(
                  key: Key('voucher_$index'),
                  voucher: voucher,
                  index: index + 1,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _PrintBar(
        batch: batch,
        routerName: router?.name ?? '',
        routerHost: router?.host ?? '',
        template: template,
      ),
    );
  }

  void _showTemplateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _TemplateSheet(
        onSelected: (t) {
          ref.read(voucherTemplateProvider.notifier).setTemplate(t);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _BatchSummaryBar extends StatelessWidget {
  const _BatchSummaryBar({required this.batch});
  final VoucherBatch batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.batchCode,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '${batch.quantity} × ${batch.profileName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            batch.mode == VoucherMode.voucher ? 'Voucher Mode' : 'User+Pass Mode',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _VoucherItemCard extends StatelessWidget {
  const _VoucherItemCard({
    super.key,
    required this.voucher,
    required this.index,
  });

  final VoucherItem voucher;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              child: Text(
                '$index',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                  ),
                  if (!voucher.isVoucherMode)
                    Text(
                      voucher.password,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: Theme.of(context).colorScheme.outline,
                          ),
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

class _PrintBar extends ConsumerStatefulWidget {
  const _PrintBar({
    required this.batch,
    required this.routerName,
    required this.routerHost,
    required this.template,
  });

  final VoucherBatch batch;
  final String routerName;
  final String routerHost;
  final VoucherTemplate template;

  @override
  ConsumerState<_PrintBar> createState() => _PrintBarState();
}

class _PrintBarState extends ConsumerState<_PrintBar> {
  bool _printing = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('share_pdf_btn'),
                onPressed: _printing ? null : _onSharePdf,
                icon: const Icon(Icons.share),
                label: const Text('Share PDF'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('print_btn'),
                onPressed: _printing ? null : _onPrint,
                icon: const Icon(Icons.print),
                label: const Text('Print'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSharePdf() async {
    setState(() => _printing = true);
    try {
      final render = ref.read(voucherRenderServiceProvider);
      final print = ref.read(printServiceProvider);
      final pdf = await render.renderBatch(
        batch: widget.batch,
        routerName: widget.routerName,
        routerHost: widget.routerHost,
        template: widget.template,
      );
      await print.sharePdf(pdf.bytes, pdf.filename);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _onSharePdf,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _onPrint() async {
    setState(() => _printing = true);
    try {
      final render = ref.read(voucherRenderServiceProvider);
      final print = ref.read(printServiceProvider);
      final pdf = await render.renderBatch(
        batch: widget.batch,
        routerName: widget.routerName,
        routerHost: widget.routerHost,
        template: widget.template,
      );
      await print.printOrShare(pdf.bytes, pdf.filename);
    } on Exception catch (e) {
      if (!mounted) return;
      // Failure recovery: show retry option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print failed: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _onPrint,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }
}

class _TemplateSheet extends StatelessWidget {
  const _TemplateSheet({required this.onSelected});
  final ValueChanged<VoucherTemplate> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Template', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...VoucherTemplate.values.map(
            (t) => ListTile(
              key: Key('template_${t.name}'),
              leading: const Icon(Icons.description_outlined),
              title: Text(t.label),
              subtitle: Text('${t.widthMm.toInt()}mm wide'),
              onTap: () => onSelected(t),
            ),
          ),
        ],
      ),
    );
  }
}
