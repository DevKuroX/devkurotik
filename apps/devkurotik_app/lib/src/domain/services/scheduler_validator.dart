/// Phase 6 — SchedulerValidator.
///
/// Validates the scheduler linkage behavior required by PHASE_6.md Task 8.
///
/// Rules:
///   1. Modes remove / notice / removeRecord / noticeRecord → scheduler REQUIRED.
///   2. Mode none → scheduler MUST NOT exist (or must be removed).
///   3. Scheduler interval MUST match "00:02:XX" format (XX = 10..59).
///   4. Scheduler comment MUST equal "Monitor Profile `<profileName>`".
///   5. Scheduler disabled MUST be false.
library;

import '../models/profile_models.dart';

/// Validates scheduler state against Phase 6 requirements.
class SchedulerValidator {
  const SchedulerValidator();

  /// Validates that the scheduler entry (if any) is consistent with the
  /// given expiry mode and profile name.
  ///
  /// Returns a [SchedulerValidationResult] with any violations.
  SchedulerValidationResult validate({
    required ExpiryMode mode,
    required String profileName,
    required SchedulerState state,
  }) {
    final violations = <String>[];

    switch (mode) {
      case ExpiryMode.none:
        // No scheduler expected — both exists and disabled are violations
        if (state == SchedulerState.exists || state == SchedulerState.disabled) {
          violations.add(
            'Expiry mode is "none" but a scheduler exists for profile '
            '"$profileName". Remove it.',
          );
        }

      case ExpiryMode.remove:
      case ExpiryMode.notice:
      case ExpiryMode.removeRecord:
      case ExpiryMode.noticeRecord:
        // Scheduler required
        if (state == SchedulerState.missing) {
          violations.add(
            'Expiry mode "${mode.displayName}" requires a background sweep '
            'scheduler for profile "$profileName". Create it.',
          );
        }
        if (state == SchedulerState.disabled) {
          violations.add(
            'Background sweep scheduler for profile "$profileName" is '
            'disabled. Enable it.',
          );
        }
    }

    return SchedulerValidationResult(violations: violations);
  }

  /// Validates the interval string conforms to the canonical format.
  ///
  /// Must match "00:02:XX" where XX is 10..59.
  bool isValidInterval(String interval) {
    final re = RegExp(r'^00:02:[1-5]\d$');
    return re.hasMatch(interval);
  }

  /// Validates the scheduler comment conforms to the canonical format.
  ///
  /// Must equal "Monitor Profile `<profileName>`".
  bool isValidComment(String comment, String profileName) {
    return comment == 'Monitor Profile $profileName';
  }
}

/// State of the scheduler associated with a profile.
enum SchedulerState {
  /// Scheduler exists and is enabled.
  exists,

  /// Scheduler exists but is disabled.
  disabled,

  /// No scheduler found.
  missing,
}

/// Result of a scheduler validation.
class SchedulerValidationResult {
  const SchedulerValidationResult({required this.violations});

  final List<String> violations;

  bool get isValid => violations.isEmpty;

  @override
  String toString() => isValid
      ? 'SchedulerValidationResult(valid)'
      : 'SchedulerValidationResult(violations: $violations)';
}
