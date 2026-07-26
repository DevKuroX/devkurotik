/// Phase 5 — Quick Print Screen.
///
/// Shows Quick Print packages from the router, allows one-touch
/// generate + print using a saved configuration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/voucher_models.dart';
import '../../providers/router_providers.dart';
import '../../providers/voucher_providers.dart';
import '../../routing/app_router.dart';

/// Quick Print packages list screen.
class QuickPrintScreen extends ConsumerWidget {
  const QuickPrintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRouter = ref.watch(activeRouterProvider);

    if (activeRouter == null) {
      return const Scaffold(
        body: Center(child: Text('No router selected.')),
      );
    }

    final packagesAsync = ref.watch(quickPrintListProvider(activeRouter.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Print'),
        actions: [
          IconButton(
            key: const Key('refresh_qp_btn'),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(quickPrintListProvider(activeRouter.id).notifier)
                .refresh(),
          ),
        ],
      ),
      body: packagesAsync.when(
        data: (packages) => packages.isEmpty
            ? const _NoPackagesYet()
            : _PackageList(
                packages: packages,
                routerId: activeRouter.id,
                router: activeRouter,
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NoPackagesYet extends StatelessWidget {
  const _NoPackagesYet();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.print_outlined, size: 48),
          SizedBox(height: 8),
          Text('No Quick Print packages found.'),
          SizedBox(height: 4),
          Text(
            'Create packages on the router using /system/script\n'
            'with comment "QuickPrintMikhmon".',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PackageList extends ConsumerWidget {
  const _PackageList({
    required this.packages,
    required this.routerId,
    required this.router,
  });

  final List<QuickPrintPackage> packages;
  final String routerId;
  final dynamic router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        return _QuickPrintTile(
          key: Key('qp_${pkg.scriptId}'),
          pkg: pkg,
          routerId: routerId,
          router: router,
        );
      },
    );
  }
}

class _QuickPrintTile extends ConsumerWidget {
  const _QuickPrintTile({
    super.key,
    required this.pkg,
    required this.routerId,
    required this.router,
  });

  final QuickPrintPackage pkg;
  final String routerId;
  final dynamic router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text(pkg.name),
        subtitle: Text(
          '${pkg.profile} | ${pkg.mode.name} | len:${pkg.usernameLength} '
          '| ${pkg.charSet.label}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // One-touch generate+print button
            IconButton(
              key: Key('qp_run_${pkg.scriptId}'),
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Generate + Print',
              onPressed: () => _onRun(context, ref),
            ),
          ],
        ),
        onLongPress: () => _showDeleteDialog(context, ref),
      ),
    );
  }

  Future<void> _onRun(BuildContext context, WidgetRef ref) async {
    final params = VoucherGenerationParams(
      routerId: routerId,
      routerHost: pkg.server.isNotEmpty ? pkg.server : router.host as String,
      profileName: pkg.profile,
      quantity: 1,
      mode: pkg.mode,
      charSet: pkg.charSet,
      usernameLength: pkg.usernameLength,
      passwordLength: pkg.usernameLength,
      prefix: pkg.prefix,
      limitUptime: pkg.limitUptime.isEmpty ? null : pkg.limitUptime,
      comment: pkg.comment,
    );

    try {
      final batch = await ref
          .read(voucherActionsProvider.notifier)
          .generateAndPush(params);

      if (!context.mounted) return;
      context.push(AppRoutes.voucherPreview, extra: batch);
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete package?'),
        content: Text('Delete "${pkg.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref
          .read(voucherActionsProvider.notifier)
          .deleteQuickPrintPackage(routerId, pkg.scriptId);
    }
  }
}
