/// RouterSummaryCard — Phase 3 dashboard widget.
///
/// Displays a single router's monitoring snapshot in a Material card.
/// Used by both the single-router dashboard and multi-router overview.
library;

import 'package:flutter/material.dart';
import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../../../domain/models/dashboard_data.dart';
import '../../../domain/services/router_resource_formatter.dart';

/// A card displaying key router metrics from a [DashboardData] snapshot.
class RouterSummaryCard extends StatelessWidget {
  const RouterSummaryCard({
    super.key,
    required this.data,
    this.onTap,
    this.compact = false,
  });

  /// The dashboard data to display.
  final DashboardData data;

  /// Optional tap callback (e.g. navigate to detail).
  final VoidCallback? onTap;

  /// Compact mode: shows fewer rows (for multi-router list).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, colorScheme),
              const Divider(height: 20),
              if (compact) _buildCompactBody(context) else _buildFullBody(context),
              if (!compact && data.routerInfo != null) ...[
                const Divider(height: 20),
                _buildCapabilityBadges(context, data.routerInfo!),
              ],
              if (!data.isLive) ...[
                const SizedBox(height: 8),
                _buildCachedBanner(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.router, color: colorScheme.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.routerName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                data.identity != data.routerName
                    ? '${data.routerHost}  •  ${data.identity}'
                    : data.routerHost,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _OnlineBadge(
          key: Key('online_badge_${data.routerId}'),
        ),
      ],
    );
  }

  // ─── Compact body (for multi-router list) ───────────────────────────────────

  Widget _buildCompactBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricChip(
            icon: Icons.memory,
            label: 'CPU',
            value: RouterResourceFormatter.cpu(data.cpuLoad),
          ),
        ),
        Expanded(
          child: _MetricChip(
            icon: Icons.storage,
            label: 'MEM',
            value: RouterResourceFormatter.memoryPercent(
              freeBytes: data.freeMemory,
              totalBytes: data.totalMemory,
            ),
          ),
        ),
        Expanded(
          child: _MetricChip(
            icon: Icons.timer,
            label: 'UP',
            value: RouterResourceFormatter.uptime(data.uptime),
          ),
        ),
      ],
    );
  }

  // ─── Full body ──────────────────────────────────────────────────────────────

  Widget _buildFullBody(BuildContext context) {
    final now = DateTime.now();
    return Column(
      children: [
        _DetailRow(
          icon: Icons.developer_board,
          label: 'RouterOS',
          value: RouterResourceFormatter.versionShort(data.version),
        ),
        _DetailRow(
          icon: Icons.dns,
          label: 'Board',
          value: data.board.isEmpty ? '—' : data.board,
        ),
        _DetailRow(
          icon: Icons.memory,
          label: 'CPU',
          value: RouterResourceFormatter.cpu(data.cpuLoad),
        ),
        _DetailRow(
          icon: Icons.storage,
          label: 'Memory',
          value: RouterResourceFormatter.memory(
            freeBytes: data.freeMemory,
            totalBytes: data.totalMemory,
          ),
        ),
        _DetailRow(
          icon: Icons.timer,
          label: 'Uptime',
          value: RouterResourceFormatter.uptime(data.uptime),
        ),
        _DetailRow(
          icon: Icons.cable,
          label: 'Interfaces',
          value: '${data.runningInterfaceCount}/${data.totalInterfaceCount} up',
        ),
        _DetailRow(
          icon: Icons.access_time,
          label: 'Last seen',
          value: RouterResourceFormatter.lastSeen(data.fetchedAt, now: now),
        ),
      ],
    );
  }

  // ─── Capability badges ──────────────────────────────────────────────────────

  Widget _buildCapabilityBadges(BuildContext context, RouterInfo info) {
    final badges = <_CapabilityBadge>[];
    if (CapabilityMatrix.supportsHotspot(info.version)) {
      badges.add(const _CapabilityBadge('Hotspot'));
    }
    if (CapabilityMatrix.supportsPppoe(info.version)) {
      badges.add(const _CapabilityBadge('PPPoE'));
    }
    if (CapabilityMatrix.supportsApiSsl(info.version)) {
      badges.add(const _CapabilityBadge('API SSL'));
    }
    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capabilities',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: badges,
        ),
      ],
    );
  }

  // ─── Cached banner ──────────────────────────────────────────────────────────

  Widget _buildCachedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cached, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            'Showing cached data',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.amber.shade800,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Private helper widgets ──────────────────────────────────────────────────

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.green.shade600),
          const SizedBox(width: 4),
          Text(
            'ONLINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _CapabilityBadge extends StatelessWidget {
  const _CapabilityBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 11),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      backgroundColor:
          Theme.of(context).colorScheme.primaryContainer.withAlpha(128),
    );
  }
}
