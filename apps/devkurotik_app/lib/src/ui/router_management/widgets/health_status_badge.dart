/// Health status badge widget.
library;

import 'package:flutter/material.dart';

import '../../../domain/models/router_model.dart';
import '../../../domain/services/router_health_service.dart';

/// Small badge showing the latest health status of a router.
class HealthStatusBadge extends StatelessWidget {
  const HealthStatusBadge({super.key, required this.result});

  final HealthCheckResult? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const SizedBox.shrink();
    }

    final (icon, color, tooltip) = switch (result!.status) {
      RouterHealthStatus.reachable => (
          Icons.check_circle,
          Colors.green,
          'Reachable${result!.latencyMs != null ? ' (${result!.latencyMs}ms)' : ''}',
        ),
      RouterHealthStatus.unreachable => (
          Icons.cancel,
          Colors.red,
          'Unreachable',
        ),
      RouterHealthStatus.authFailed => (
          Icons.lock,
          Colors.orange,
          'Auth failed',
        ),
      RouterHealthStatus.timeout => (
          Icons.timer_off,
          Colors.orange,
          'Timeout',
        ),
      RouterHealthStatus.unknown => (
          Icons.help_outline,
          Colors.grey,
          'Unknown',
        ),
    };

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 18),
    );
  }
}
