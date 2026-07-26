/// Phase 6 — Profile provider unit tests.
///
/// Tests Riverpod providers: service providers, scriptGeneratorProvider,
/// metadataEncoderProvider, schedulerValidatorProvider.
/// Profile list and actions providers tested via fake notifiers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/profile_models.dart';
import 'package:devkurotik_app/src/domain/services/on_login_script_generator.dart';
import 'package:devkurotik_app/src/domain/services/metadata_encoder.dart';
import 'package:devkurotik_app/src/domain/services/scheduler_validator.dart';
import 'package:devkurotik_app/src/providers/profile_providers.dart';

// ---------------------------------------------------------------------------
// Fake notifiers
// ---------------------------------------------------------------------------

class _FakeProfileNotifier extends ActiveProfileNotifier {
  _FakeProfileNotifier(this._profiles);
  final List<HotspotProfile> _profiles;

  @override
  Future<List<HotspotProfile>> build() async => _profiles;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<HotspotProfile> _fakeProfiles() {
  const gen = OnLoginScriptGenerator();
  final dailyScript = gen
      .generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ))
      .onLogin;

  final weeklyScript = gen
      .generate(const ProfileScriptParams(
        profileName: 'weekly',
        mode: ExpiryMode.notice,
        validity: '7d',
        price: '20000',
        sellingPrice: '20000',
      ))
      .onLogin;

  final freeScript = gen
      .generate(const ProfileScriptParams(
        profileName: 'free',
        mode: ExpiryMode.none,
        validity: '',
        price: '0',
        sellingPrice: '0',
      ))
      .onLogin;

  return [
    HotspotProfile.fromApiMap({
      '.id': '*1',
      'name': 'daily',
      'on-login': dailyScript,
    }),
    HotspotProfile.fromApiMap({
      '.id': '*2',
      'name': 'weekly',
      'on-login': weeklyScript,
    }),
    HotspotProfile.fromApiMap({
      '.id': '*3',
      'name': 'free',
      'on-login': freeScript,
    }),
  ];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('profileServiceProvider', () {
    test('provides a ProfileService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(profileServiceProvider);
      expect(service, isNotNull);
    });
  });

  group('scriptGeneratorProvider', () {
    test('provides OnLoginScriptGenerator instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final generator = container.read(scriptGeneratorProvider);
      expect(generator, isA<OnLoginScriptGenerator>());
    });

    test('generator produces correct output for remove mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final generator = container.read(scriptGeneratorProvider);
      final result = generator.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      expect(result.onLogin, startsWith(':put (",rem,'));
      expect(result.requiresScheduler, isTrue);
    });
  });

  group('metadataEncoderProvider', () {
    test('provides MetadataEncoder instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final enc = container.read(metadataEncoderProvider);
      expect(enc, isA<MetadataEncoder>());
    });

    test('encoder and generator are consistent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final generator = container.read(scriptGeneratorProvider);
      final enc = container.read(metadataEncoderProvider);

      final result = generator.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      expect(enc.hasValidPositions(result.onLogin), isTrue);
    });
  });

  group('schedulerValidatorProvider', () {
    test('provides SchedulerValidator instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sv = container.read(schedulerValidatorProvider);
      expect(sv, isA<SchedulerValidator>());
    });

    test('validates remove mode + existing scheduler → valid', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sv = container.read(schedulerValidatorProvider);
      final result = sv.validate(
        mode: ExpiryMode.remove,
        profileName: 'daily',
        state: SchedulerState.exists,
      );
      expect(result.isValid, isTrue);
    });
  });

  group('activeProfileProvider', () {
    test('returns empty list when no active router', () async {
      final container = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(() => _FakeProfileNotifier([])),
        ],
      );
      addTearDown(container.dispose);
      final profiles = await container.read(activeProfileProvider.future);
      expect(profiles, isEmpty);
    });

    test('returns profiles when data available', () async {
      final fakeProfiles = _fakeProfiles();
      final container = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(
            () => _FakeProfileNotifier(fakeProfiles),
          ),
        ],
      );
      addTearDown(container.dispose);
      final profiles = await container.read(activeProfileProvider.future);
      expect(profiles.length, 3);
    });

    test('profile with remove mode has metadata', () async {
      final fakeProfiles = _fakeProfiles();
      final container = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(
            () => _FakeProfileNotifier(fakeProfiles),
          ),
        ],
      );
      addTearDown(container.dispose);
      final profiles = await container.read(activeProfileProvider.future);
      final daily = profiles.firstWhere((p) => p.name == 'daily');
      expect(daily.metadata, isNotNull);
      expect(daily.metadata!.mode, ExpiryMode.remove);
    });

    test('profile with notice mode has metadata', () async {
      final fakeProfiles = _fakeProfiles();
      final container = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(
            () => _FakeProfileNotifier(fakeProfiles),
          ),
        ],
      );
      addTearDown(container.dispose);
      final profiles = await container.read(activeProfileProvider.future);
      final weekly = profiles.firstWhere((p) => p.name == 'weekly');
      expect(weekly.metadata!.mode, ExpiryMode.notice);
    });

    test('profile with none mode has metadata with mode=none', () async {
      final fakeProfiles = _fakeProfiles();
      final container = ProviderContainer(
        overrides: [
          activeProfileProvider.overrideWith(
            () => _FakeProfileNotifier(fakeProfiles),
          ),
        ],
      );
      addTearDown(container.dispose);
      final profiles = await container.read(activeProfileProvider.future);
      final free = profiles.firstWhere((p) => p.name == 'free');
      // Empty on-login → metadata with mode=none
      expect(free.metadata!.mode, ExpiryMode.none);
    });
  });
}
