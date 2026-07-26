/// Phase 6 — SchedulerValidator tests.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/profile_models.dart';
import 'package:devkurotik_app/src/domain/services/scheduler_validator.dart';

void main() {
  const validator = SchedulerValidator();

  group('SchedulerValidator.validate', () {
    test('none + missing scheduler → valid', () {
      final result = validator.validate(
        mode: ExpiryMode.none,
        profileName: 'daily',
        state: SchedulerState.missing,
      );
      expect(result.isValid, isTrue);
    });

    test('none + scheduler exists → violation', () {
      final result = validator.validate(
        mode: ExpiryMode.none,
        profileName: 'daily',
        state: SchedulerState.exists,
      );
      expect(result.isValid, isFalse);
      expect(result.violations, isNotEmpty);
      expect(result.violations.first, contains('none'));
    });

    test('none + scheduler disabled → violation (should not exist)', () {
      final result = validator.validate(
        mode: ExpiryMode.none,
        profileName: 'daily',
        state: SchedulerState.disabled,
      );
      // disabled is still "exists" category for none mode — violation
      expect(result.isValid, isFalse);
    });

    test('remove + scheduler exists → valid', () {
      final result = validator.validate(
        mode: ExpiryMode.remove,
        profileName: 'daily',
        state: SchedulerState.exists,
      );
      expect(result.isValid, isTrue);
    });

    test('remove + scheduler missing → violation', () {
      final result = validator.validate(
        mode: ExpiryMode.remove,
        profileName: 'daily',
        state: SchedulerState.missing,
      );
      expect(result.isValid, isFalse);
      expect(result.violations.first, contains('Remove'));
    });

    test('remove + scheduler disabled → violation', () {
      final result = validator.validate(
        mode: ExpiryMode.remove,
        profileName: 'daily',
        state: SchedulerState.disabled,
      );
      expect(result.isValid, isFalse);
      expect(result.violations.first, contains('disabled'));
    });

    test('notice + scheduler exists → valid', () {
      final result = validator.validate(
        mode: ExpiryMode.notice,
        profileName: 'daily',
        state: SchedulerState.exists,
      );
      expect(result.isValid, isTrue);
    });

    test('notice + scheduler missing → violation', () {
      final result = validator.validate(
        mode: ExpiryMode.notice,
        profileName: 'daily',
        state: SchedulerState.missing,
      );
      expect(result.isValid, isFalse);
    });

    test('removeRecord + scheduler exists → valid', () {
      final result = validator.validate(
        mode: ExpiryMode.removeRecord,
        profileName: 'daily',
        state: SchedulerState.exists,
      );
      expect(result.isValid, isTrue);
    });

    test('noticeRecord + scheduler missing → violation', () {
      final result = validator.validate(
        mode: ExpiryMode.noticeRecord,
        profileName: 'premium',
        state: SchedulerState.missing,
      );
      expect(result.isValid, isFalse);
    });

    test('all expiry modes with existing scheduler → valid', () {
      for (final mode in [
        ExpiryMode.remove,
        ExpiryMode.notice,
        ExpiryMode.removeRecord,
        ExpiryMode.noticeRecord,
      ]) {
        final result = validator.validate(
          mode: mode,
          profileName: 'daily',
          state: SchedulerState.exists,
        );
        expect(result.isValid, isTrue,
            reason: 'Mode ${mode.displayName} with existing scheduler must be valid');
      }
    });
  });

  group('SchedulerValidator.isValidInterval', () {
    test('valid intervals', () {
      expect(validator.isValidInterval('00:02:10'), isTrue);
      expect(validator.isValidInterval('00:02:30'), isTrue);
      expect(validator.isValidInterval('00:02:59'), isTrue);
    });

    test('invalid intervals', () {
      expect(validator.isValidInterval('00:05:00'), isFalse);
      expect(validator.isValidInterval('00:02:05'), isFalse);
      expect(validator.isValidInterval('00:02:60'), isFalse);
      expect(validator.isValidInterval('00:02:9'), isFalse);
      expect(validator.isValidInterval('invalid'), isFalse);
    });
  });

  group('SchedulerValidator.isValidComment', () {
    test('correct comment format', () {
      expect(
        validator.isValidComment('Monitor Profile daily', 'daily'),
        isTrue,
      );
      expect(
        validator.isValidComment('Monitor Profile weekly', 'weekly'),
        isTrue,
      );
    });

    test('incorrect comment format', () {
      expect(
        validator.isValidComment('monitor daily', 'daily'),
        isFalse,
      );
      expect(
        validator.isValidComment('Monitor Profile daily', 'weekly'),
        isFalse,
      );
      expect(
        validator.isValidComment('', 'daily'),
        isFalse,
      );
    });
  });

  group('SchedulerValidationResult', () {
    test('empty violations → isValid=true', () {
      const result = SchedulerValidationResult(violations: []);
      expect(result.isValid, isTrue);
    });

    test('non-empty violations → isValid=false', () {
      const result = SchedulerValidationResult(violations: ['Violation 1']);
      expect(result.isValid, isFalse);
    });
  });
}
