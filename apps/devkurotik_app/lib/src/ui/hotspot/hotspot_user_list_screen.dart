/// Phase 4 — Hotspot User List Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/hotspot_models.dart';
import '../../providers/hotspot_providers.dart';
import '../../providers/router_providers.dart';
import '../../routing/app_router.dart';

/// Hotspot user list with search, filter, and bulk actions.
class HotspotUserListScreen extends ConsumerStatefulWidget {
  const HotspotUserListScreen({super.key});

  @override
  ConsumerState<HotspotUserListScreen> createState() =>
      _HotspotUserListScreenState();
}

class _HotspotUserListScreenState
    extends ConsumerState<HotspotUserListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeRouter = ref.watch(activeRouterProvider);
    final users = ref.watch(filteredHotspotUsersProvider);
    final hotspotAsync = ref.watch(activeHotspotProvider);
    final filter = ref.watch(hotspotFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeRouter?.name ?? 'Hotspot Users',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Filter icon
          IconButton(
            key: const Key('hotspot_filter_button'),
            icon: Badge(
              isLabelVisible: filter != HotspotUserFilter.all,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Filter',
          ),
          // Overflow menu — bulk actions
          PopupMenuButton<_BulkAction>(
            key: const Key('hotspot_overflow_menu'),
            onSelected: (action) => _handleBulkAction(context, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _BulkAction.deleteByComment,
                child: Text('Delete by comment'),
              ),
              const PopupMenuItem(
                value: _BulkAction.deleteExpired,
                child: Text('Delete expired users'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              key: const Key('hotspot_search_field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(hotspotSearchProvider.notifier)
                              .clearQuery();
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
              onChanged: (q) =>
                  ref.read(hotspotSearchProvider.notifier).setQuery(q),
            ),
          ),
        ),
      ),
      body: hotspotAsync.when(
        loading: () => _buildLoading(),
        error: (err, _) => _buildError(context, err.toString()),
        data: (data) {
          if (activeRouter == null) return _buildEmptyState(context);
          if (data == null) return _buildEmptyState(context);
          if (users.isEmpty) return _buildEmptyUsers(context, filter);
          return _buildUserList(context, users, data);
        },
      ),
      floatingActionButton: activeRouter != null
          ? FloatingActionButton(
              key: const Key('add_hotspot_user_fab'),
              onPressed: () => context.push(AppRoutes.addHotspotUser),
              tooltip: 'Add user',
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Widget _buildLoading() {
    return const Center(
      key: Key('hotspot_loading'),
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    final sanitized = error.replaceAll(
      RegExp(r'=password=[^\s,]+'),
      '=password=***',
    );
    return Center(
      key: const Key('hotspot_error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load hotspot data',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              sanitized,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('hotspot_retry_button'),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () =>
                  ref.read(activeHotspotProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      key: const Key('hotspot_empty_no_router'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.router_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No active router selected.'),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('hotspot_go_to_routers'),
            onPressed: () => context.go(AppRoutes.routerList),
            child: const Text('Go to Routers'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUsers(
    BuildContext context,
    HotspotUserFilter filter,
  ) {
    final label = switch (filter) {
      HotspotUserFilter.byProfile => 'No users for this profile.',
      HotspotUserFilter.byComment => 'No users for this comment.',
      HotspotUserFilter.expired => 'No expired users.',
      HotspotUserFilter.all => 'No hotspot users found.',
    };
    return Center(
      key: const Key('hotspot_empty_users'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(label),
          const SizedBox(height: 8),
          if (filter != HotspotUserFilter.all)
            TextButton(
              key: const Key('hotspot_clear_filter'),
              onPressed: () {
                ref.read(hotspotFilterProvider.notifier).reset();
                ref.read(hotspotProfileFilterProvider.notifier).clear();
                ref.read(hotspotCommentFilterProvider.notifier).clear();
              },
              child: const Text('Clear filter'),
            ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<HotspotUser> users,
    HotspotData data,
  ) {
    // Build active user ID set for quick lookup.
    final activeIds = {for (final a in data.activeSessions) a.user};

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(activeHotspotProvider.notifier).refresh(),
      child: ListView.builder(
        key: const Key('hotspot_user_list'),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isActive = activeIds.contains(user.name);
          return _UserTile(
            user: user,
            isActive: isActive,
            onTap: () => context.push(
              AppRoutes.hotspotUserDetailPath(user.id),
              extra: user,
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => const _FilterSheet(),
    );
  }

  Future<void> _handleBulkAction(
    BuildContext context,
    _BulkAction action,
  ) async {
    switch (action) {
      case _BulkAction.deleteByComment:
        await _showDeleteByCommentDialog(context);
      case _BulkAction.deleteExpired:
        await _confirmBulkDeleteExpired(context);
    }
  }

  Future<void> _showDeleteByCommentDialog(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete by Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the comment prefix to delete:'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('bulk_delete_comment_field'),
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Comment prefix',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('bulk_delete_comment_confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final comment = controller.text.trim();
    if (comment.isEmpty) return;

    try {
      final removed = await ref
          .read(hotspotActionsProvider.notifier)
          .bulkDeleteByComment(comment);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $removed user(s).')),
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

  Future<void> _confirmBulkDeleteExpired(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expired Users'),
        content: const Text(
          'This will permanently delete all expired users (limit-uptime=1s). '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('bulk_delete_expired_confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete All Expired'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final removed = await ref
          .read(hotspotActionsProvider.notifier)
          .bulkDeleteExpired();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $removed expired user(s).')),
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

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isActive,
    required this.onTap,
  });

  final HotspotUser user;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      key: Key('user_tile_${user.id}'),
      leading: CircleAvatar(
        backgroundColor: user.disabled
            ? Colors.grey.shade300
            : isActive
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
        child: Icon(
          user.disabled
              ? Icons.person_off
              : isActive
                  ? Icons.person
                  : Icons.person_outline,
          color: user.disabled
              ? Colors.grey
              : isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        user.name,
        style: user.disabled
            ? const TextStyle(color: Colors.grey)
            : null,
      ),
      subtitle: Text(
        user.profile +
            (isActive ? ' • Active' : '') +
            (user.disabled ? ' • Disabled' : '') +
            (user.isExpired ? ' • Expired' : ''),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: user.comment != null && user.comment!.isNotEmpty
          ? const Icon(Icons.comment, size: 14, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(hotspotFilterProvider);
    final hotspotAsync = ref.watch(activeHotspotProvider);
    final profiles = hotspotAsync.valueOrNull?.profiles ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Users',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  key: const Key('filter_all'),
                  label: const Text('All'),
                  selected: filter == HotspotUserFilter.all,
                  onSelected: (_) {
                    ref.read(hotspotFilterProvider.notifier).setFilter(
                          HotspotUserFilter.all,
                        );
                    Navigator.of(context).pop();
                  },
                ),
                FilterChip(
                  key: const Key('filter_expired'),
                  label: const Text('Expired'),
                  selected: filter == HotspotUserFilter.expired,
                  onSelected: (_) {
                    ref.read(hotspotFilterProvider.notifier).setFilter(
                          HotspotUserFilter.expired,
                        );
                    Navigator.of(context).pop();
                  },
                ),
                FilterChip(
                  key: const Key('filter_disabled'),
                  label: const Text('Disabled'),
                  selected: filter == HotspotUserFilter.byComment &&
                      ref.read(hotspotCommentFilterProvider) == '__disabled__',
                  onSelected: (_) {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            if (profiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'By Profile',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: profiles
                    .map(
                      (p) => FilterChip(
                        key: Key('filter_profile_${p.name}'),
                        label: Text(p.name),
                        selected: filter == HotspotUserFilter.byProfile &&
                            ref.read(hotspotProfileFilterProvider) == p.name,
                        onSelected: (_) {
                          ref
                              .read(hotspotProfileFilterProvider.notifier)
                              .setProfile(p.name);
                          ref
                              .read(hotspotFilterProvider.notifier)
                              .setFilter(HotspotUserFilter.byProfile);
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _BulkAction { deleteByComment, deleteExpired }
