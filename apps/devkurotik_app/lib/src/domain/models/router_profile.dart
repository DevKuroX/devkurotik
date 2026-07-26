/// RouterProfile — transient view model associating a RouterModel with
/// a detected RouterInfo snapshot.
///
/// ## Storage policy
///
/// [routerInfo] is NOT persisted to Drift.  It is session-scoped memory state
/// only.  The Drift schema (v1) is unchanged — no new columns are added.
///
/// ## Role
///
/// [RouterProfile] is a read-only view model constructed by the presentation
/// layer.  It wraps a persisted [RouterModel] and optionally enriches it with
/// live capability data from [CapabilityDetector].  Downstream phases (Phase 3+)
/// consume [RouterProfile] in preference to raw [RouterModel] where version-
/// aware branching is required.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import 'router_model.dart';

export 'package:mikrotik_sdk/mikrotik_sdk.dart'
    show RouterInfo, RouterVersion, CapabilityMatrix;

/// Transient view model: a persisted router + its optional live identity info.
///
/// Construct via [RouterProfile.withInfo] or [RouterProfile.withoutInfo].
final class RouterProfile {
  const RouterProfile._({
    required this.router,
    required this.routerInfo,
    required this.lastDetectedAt,
  });

  // ---------------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------------

  /// Create a profile with a populated [RouterInfo].
  factory RouterProfile.withInfo({
    required RouterModel router,
    required RouterInfo routerInfo,
  }) =>
      RouterProfile._(
        router: router,
        routerInfo: routerInfo,
        lastDetectedAt: routerInfo.detectedAt,
      );

  /// Create a profile without capability info (detection not yet run or failed).
  factory RouterProfile.withoutInfo(RouterModel router) => RouterProfile._(
        router: router,
        routerInfo: null,
        lastDetectedAt: null,
      );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// The base persisted router entity.
  final RouterModel router;

  /// Live capability snapshot, or `null` if detection has not been run or
  /// has failed for this session.
  ///
  /// Never persisted to Drift — resets to null on app restart.
  final RouterInfo? routerInfo;

  /// When [routerInfo] was last populated.  Null if no detection has run.
  final DateTime? lastDetectedAt;

  // ---------------------------------------------------------------------------
  // Derived properties
  // ---------------------------------------------------------------------------

  /// True if a [RouterInfo] snapshot is available.
  bool get hasInfo => routerInfo != null;

  /// True if [routerInfo] is available and its version is not [RouterVersion.unknown].
  bool get isVersionKnown => hasInfo && !routerInfo!.version.isUnknown;

  /// Human-readable capability warnings for this router version.
  ///
  /// Returns an empty list if [routerInfo] is null, the version is unknown,
  /// or no variances are documented for this version.
  List<String> get capabilityWarnings {
    if (!hasInfo) return const [];
    final note = CapabilityMatrix.varianceNote(routerInfo!.version);
    return note != null ? [note] : const [];
  }

  // ---------------------------------------------------------------------------
  // Object overrides
  // ---------------------------------------------------------------------------

  @override
  String toString() => 'RouterProfile('
      'router: ${router.name}, '
      'hasInfo: $hasInfo, '
      'version: ${routerInfo?.version ?? 'unknown'}'
      ')';
}
