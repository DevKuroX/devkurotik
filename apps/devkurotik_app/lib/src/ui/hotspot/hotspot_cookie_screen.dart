/// Phase 4 — Hotspot Cookie List Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/hotspot_models.dart';
import '../../providers/hotspot_providers.dart';

/// Screen listing hotspot cookies for the active router.
class HotspotCookieScreen extends ConsumerWidget {
  const HotspotCookieScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cookiesAsync = ref.watch(hotspotCookieProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotspot Cookies'),
        actions: [
          IconButton(
            key: const Key('cookies_refresh_button'),
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(hotspotCookieProvider.notifier).refresh(),
          ),
        ],
      ),
      body: cookiesAsync.when(
        loading: () => const Center(
          key: Key('cookies_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          key: const Key('cookies_error'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Failed to load cookies.'),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const Key('cookies_retry_button'),
                onPressed: () =>
                    ref.read(hotspotCookieProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (cookies) {
          if (cookies.isEmpty) {
            return const Center(
              key: Key('cookies_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cookie_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No cookies found.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(hotspotCookieProvider.notifier).refresh(),
            child: ListView.builder(
              key: const Key('cookies_list'),
              itemCount: cookies.length,
              itemBuilder: (context, index) {
                final cookie = cookies[index];
                return _CookieTile(cookie: cookie);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CookieTile extends ConsumerWidget {
  const _CookieTile({required this.cookie});

  final HotspotCookie cookie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: Key('cookie_tile_${cookie.id}'),
      leading: const Icon(Icons.cookie),
      title: Text(cookie.user),
      subtitle: Text(
        cookie.macAddress +
            (cookie.expiresIn != null ? ' · expires ${cookie.expiresIn}' : ''),
      ),
      trailing: IconButton(
        key: Key('delete_cookie_${cookie.id}'),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        tooltip: 'Remove',
        onPressed: () => _confirmRemove(context, ref),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Cookie'),
        content: Text(
          'Remove cookie for "${cookie.user}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('remove_cookie_confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(hotspotActionsProvider.notifier).removeCookie(cookie.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cookie for "${cookie.user}" removed.')),
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
