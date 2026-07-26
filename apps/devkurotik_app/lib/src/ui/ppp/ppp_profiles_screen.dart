/// Phase 7 — PPP Profiles Screen.
///
/// Listing only — per FEATURE_MATRIX.md Module 12 (Medium priority,
/// not implemented in Mikhmon source).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/ppp_models.dart';
import '../../providers/ppp_providers.dart';

/// Screen listing all PPP profiles (read-only).
class PppProfilesScreen extends ConsumerWidget {
  const PppProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pppAsync = ref.watch(activePppProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PPP Profiles'),
        actions: [
          IconButton(
            key: const Key('ppp_profiles_refresh'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(activePppProvider.notifier).refresh(),
          ),
        ],
      ),
      body: pppAsync.when(
        loading: () => const Center(
          key: Key('ppp_profiles_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => _buildError(context, ref, err.toString()),
        data: (data) {
          final profiles = data?.profiles ?? [];
          if (profiles.isEmpty) {
            return const Center(
              key: Key('ppp_profiles_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No PPP profiles found.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(activePppProvider.notifier).refresh(),
            child: ListView.builder(
              key: const Key('ppp_profiles_list'),
              itemCount: profiles.length,
              itemBuilder: (ctx, i) =>
                  _PppProfileTile(profile: profiles[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      key: const Key('ppp_profiles_error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load PPP profiles.'),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('ppp_profiles_retry'),
            onPressed: () => ref.read(activePppProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PppProfileTile extends StatelessWidget {
  const _PppProfileTile({required this.profile});

  final PppProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('ppp_profile_tile_${profile.id}'),
      leading: const CircleAvatar(
        backgroundColor: Colors.deepOrange,
        child: Icon(Icons.tune, color: Colors.white, size: 20),
      ),
      title: Text(profile.name),
      subtitle: Text(
        [
          if (profile.rateLimit != null) profile.rateLimit!,
          if (profile.localAddress != null) 'local: ${profile.localAddress}',
          if (profile.remoteAddress != null) 'remote: ${profile.remoteAddress}',
        ].join(' · '),
      ),
      trailing: profile.onlyOne
          ? const Tooltip(
              message: 'Only-one session allowed',
              child: Icon(Icons.person, size: 18, color: Colors.indigo),
            )
          : null,
      onTap: () => _showDetail(context),
    );
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
              profile.name,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const Divider(),
            if (profile.rateLimit != null)
              _Row('Rate Limit', profile.rateLimit!),
            if (profile.localAddress != null)
              _Row('Local Address', profile.localAddress!),
            if (profile.remoteAddress != null)
              _Row('Remote Address', profile.remoteAddress!),
            if (profile.sessionTimeout != null)
              _Row('Session Timeout', profile.sessionTimeout!),
            if (profile.idleTimeout != null)
              _Row('Idle Timeout', profile.idleTimeout!),
            _Row('Only One', profile.onlyOne ? 'yes' : 'no'),
            if (profile.comment != null)
              _Row('Comment', profile.comment!),
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
            width: 120,
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
