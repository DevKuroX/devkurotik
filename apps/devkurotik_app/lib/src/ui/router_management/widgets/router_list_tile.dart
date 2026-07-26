/// Router list tile widget.
library;

import 'package:flutter/material.dart';

import '../../../domain/models/router_model.dart';

/// A single router entry in the list, with action callbacks.
class RouterListTile extends StatelessWidget {
  const RouterListTile({
    super.key,
    required this.router,
    required this.isActive,
    required this.healthBadge,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onCheckHealth,
  });

  final RouterModel router;
  final bool isActive;
  final Widget healthBadge;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCheckHealth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isActive
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        key: Key('router_tile_${router.id}'),
        leading: CircleAvatar(
          backgroundColor: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.router,
            color: isActive
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                router.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            healthBadge,
          ],
        ),
        subtitle: Text(
          '${router.host}:${router.port}  •  ${router.username}  •  ${router.group.label}',
          style: theme.textTheme.bodySmall,
        ),
        onTap: onTap,
        trailing: PopupMenuButton<_RouterAction>(
          key: Key('router_menu_${router.id}'),
          onSelected: (action) {
            switch (action) {
              case _RouterAction.edit:
                onEdit();
              case _RouterAction.delete:
                onDelete();
              case _RouterAction.checkHealth:
                onCheckHealth();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: _RouterAction.checkHealth,
              child: ListTile(
                leading: Icon(Icons.health_and_safety),
                title: Text('Check health'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _RouterAction.edit,
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _RouterAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RouterAction { edit, delete, checkHealth }
