/// Phase 6 — Profile providers.
///
/// Riverpod providers for hotspot user profile management.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/router_repository.dart';
import '../domain/models/profile_models.dart';
import '../domain/services/metadata_encoder.dart';
import '../domain/services/on_login_script_generator.dart';
import '../domain/services/profile_service.dart';
import '../domain/services/scheduler_validator.dart';
import 'router_providers.dart';

// ---------------------------------------------------------------------------
// Service providers
// ---------------------------------------------------------------------------

/// Provides a shared [ProfileService] instance.
final profileServiceProvider = Provider<ProfileService>(
  (ref) => const ProfileService(),
);

/// Provides the canonical [OnLoginScriptGenerator].
final scriptGeneratorProvider = Provider<OnLoginScriptGenerator>(
  (ref) => const OnLoginScriptGenerator(),
);

/// Provides the [MetadataEncoder].
final metadataEncoderProvider = Provider<MetadataEncoder>(
  (ref) => const MetadataEncoder(),
);

/// Provides the [SchedulerValidator].
final schedulerValidatorProvider = Provider<SchedulerValidator>(
  (ref) => const SchedulerValidator(),
);

// ---------------------------------------------------------------------------
// Profile list provider (per router)
// ---------------------------------------------------------------------------

/// Fetches and caches the profile list for the given router ID.
///
/// Family arg: routerId (String)
final profileProvider = AsyncNotifierProviderFamily<
    ProfileNotifier, List<HotspotProfile>, String>(
  ProfileNotifier.new,
);

/// Notifier for [profileProvider].
class ProfileNotifier
    extends FamilyAsyncNotifier<List<HotspotProfile>, String> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  ProfileService get _service => ref.read(profileServiceProvider);

  @override
  Future<List<HotspotProfile>> build(String arg) async {
    return _fetch(arg);
  }

  Future<List<HotspotProfile>> _fetch(String routerId) async {
    final routers = await ref.read(routerListProvider.future);
    final router = routers.where((r) => r.id == routerId).firstOrNull;
    if (router == null) return [];
    final password = await _repo.getPassword(routerId);
    if (password == null) return [];
    return _service.listProfiles(router, password);
  }

  /// Refreshes the profile list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

// ---------------------------------------------------------------------------
// Active router profile provider
// ---------------------------------------------------------------------------

/// Profile list for the currently active router.
final activeProfileProvider = AsyncNotifierProvider<
    ActiveProfileNotifier, List<HotspotProfile>>(
  ActiveProfileNotifier.new,
);

/// Notifier for [activeProfileProvider].
class ActiveProfileNotifier
    extends AsyncNotifier<List<HotspotProfile>> {
  @override
  Future<List<HotspotProfile>> build() async {
    final active = ref.watch(activeRouterProvider);
    if (active == null) return [];
    return ref.watch(profileProvider(active.id).future);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final active = ref.read(activeRouterProvider);
      if (active == null) return [];
      await ref.read(profileProvider(active.id).notifier).refresh();
      return ref.read(profileProvider(active.id).future);
    });
  }
}

// ---------------------------------------------------------------------------
// Profile actions provider (per router)
// ---------------------------------------------------------------------------

/// Handles profile create / update / delete operations.
///
/// Family arg: routerId (String)
final profileActionsProvider =
    NotifierProviderFamily<ProfileActionsNotifier, void, String>(
  ProfileActionsNotifier.new,
);

/// Notifier for [profileActionsProvider].
class ProfileActionsNotifier extends FamilyNotifier<void, String> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  ProfileService get _service => ref.read(profileServiceProvider);

  @override
  void build(String arg) {}

  Future<void> _requireRouter(
    Future<void> Function(dynamic router, String password) action,
  ) async {
    final routers = await ref.read(routerListProvider.future);
    final router = routers.where((r) => r.id == arg).firstOrNull;
    if (router == null) throw StateError('Router $arg not found.');
    final password = await _repo.getPassword(arg);
    if (password == null) {
      throw StateError('No credentials found for router $arg.');
    }
    await action(router, password);
  }

  /// Adds a new profile with generated scripts.
  Future<void> addProfile(
    ProfileScriptParams params, {
    String? addressPool,
    String? rateLimit,
    int sharedUsers = 1,
    String? parentQueue,
  }) async {
    await _requireRouter((router, password) => _service.addProfile(
          router,
          password,
          params,
          addressPool: addressPool,
          rateLimit: rateLimit,
          sharedUsers: sharedUsers,
          parentQueue: parentQueue,
        ));
    ref.invalidate(profileProvider(arg));
  }

  /// Updates an existing profile's on-login script + scheduler.
  Future<void> updateProfile(
    String profileId,
    ProfileScriptParams params, {
    String? addressPool,
    String? rateLimit,
    int sharedUsers = 1,
    String? parentQueue,
  }) async {
    await _requireRouter((router, password) => _service.updateProfile(
          router,
          password,
          profileId,
          params,
          addressPool: addressPool,
          rateLimit: rateLimit,
          sharedUsers: sharedUsers,
          parentQueue: parentQueue,
        ));
    ref.invalidate(profileProvider(arg));
  }

  /// Deletes a profile and its associated scheduler.
  Future<void> deleteProfile(String profileId, String profileName) async {
    await _requireRouter((router, password) =>
        _service.deleteProfile(router, password, profileId, profileName));
    ref.invalidate(profileProvider(arg));
  }
}
