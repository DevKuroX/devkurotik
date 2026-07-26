/// Phase 5 — Voucher Template Screen.
///
/// Allows the user to preview and select a voucher rendering template.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/voucher_models.dart';
import '../../providers/voucher_providers.dart';

/// Screen for selecting and previewing voucher templates.
class VoucherTemplateScreen extends ConsumerWidget {
  const VoucherTemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTemplate = ref.watch(voucherTemplateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Voucher Template')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Select a template for printed vouchers',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...VoucherTemplate.values.map(
            (template) => _TemplateCard(
              key: Key('template_card_${template.name}'),
              template: template,
              isSelected: template == currentTemplate,
              onTap: () =>
                  ref.read(voucherTemplateProvider.notifier).setTemplate(template),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    super.key,
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final VoucherTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    template.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _TemplatePreview(template: template),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({required this.template});

  final VoucherTemplate template;

  @override
  Widget build(BuildContext context) {
    switch (template) {
      case VoucherTemplate.default220:
        return _DefaultPreview();
      case VoucherTemplate.thermal180:
        return _ThermalPreview();
      case VoucherTemplate.small160:
        return _SmallPreview();
    }
  }
}

class _DefaultPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Router Name', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('Profile', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 8),
          Text('Username: XXXXX', style: Theme.of(context).textTheme.bodySmall),
          Text('Password: XXXXX', style: Theme.of(context).textTheme.bodySmall),
          Text('Validity: 1H', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Container(width: 40, height: 40, color: Colors.grey.shade300, child: const Icon(Icons.qr_code, size: 32)),
          const SizedBox(height: 4),
          Text('Generated: 2026-07-26', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ThermalPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Router | Profile', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 6),
          Text('User: XXXXX  Pass: XXXXX', style: Theme.of(context).textTheme.bodySmall),
          Text('Valid: 1H  2026-07-26 10:30', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Container(width: 32, height: 32, color: Colors.grey.shade300, child: const Icon(Icons.qr_code, size: 24)),
        ],
      ),
    );
  }
}

class _SmallPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('[Profile] User:X Pass:X', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
