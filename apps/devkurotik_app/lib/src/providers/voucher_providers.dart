/// Phase 5 — Voucher Riverpod providers.
///
/// Provider dependency graph:
///   appDatabaseProvider     (Phase 2)
///   routerRepositoryProvider (Phase 2)
///   activeRouterProvider    (Phase 2)
///   voucherRepositoryProvider  (Phase 5 — new)
///   voucherServiceProvider     (Phase 5 — new)
///   voucherRenderServiceProvider (Phase 5 — new)
///   quickPrintServiceProvider  (Phase 5 — new)
///   printServiceProvider       (Phase 5 — new)
///   voucherBatchListProvider   (Phase 5 — new, per-router family)
///   lastVoucherBatchProvider   (Phase 5 — new, active router)
///   voucherGenerationParamsProvider (Phase 5 — new, form state)
///   voucherActionsProvider     (Phase 5 — new, write actions)
///   quickPrintListProvider     (Phase 5 — new, per-router family)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/router_repository.dart';
import '../data/repositories/voucher_repository.dart';
import '../domain/models/router_model.dart';
import '../domain/models/voucher_models.dart' show generateBatchCode, VoucherBatch, VoucherGenerationParams, VoucherTemplate, QuickPrintPackage;
import '../domain/services/print_service.dart';
import '../domain/services/quick_print_service.dart';
import '../domain/services/voucher_generator_service.dart';
import '../domain/services/voucher_render_service.dart';
import 'router_providers.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

/// Singleton [VoucherRepository].
final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  return VoucherRepository(db: ref.watch(appDatabaseProvider));
});

/// Singleton [VoucherGeneratorService].
final voucherGeneratorServiceProvider = Provider<VoucherGeneratorService>(
  (ref) => const VoucherGeneratorService(),
);

/// Singleton [VoucherRenderService].
final voucherRenderServiceProvider = Provider<VoucherRenderService>(
  (ref) => const VoucherRenderService(),
);

/// Singleton [QuickPrintService].
final quickPrintServiceProvider = Provider<QuickPrintService>(
  (ref) => const QuickPrintService(),
);

/// Singleton [PrintService].
final printServiceProvider = Provider<PrintService>(
  (ref) => const PrintService(),
);

// ---------------------------------------------------------------------------
// Batch list per router
// ---------------------------------------------------------------------------

/// Family provider: voucher batch history for a specific router id.
///
/// arg = routerId (String).
final voucherBatchListProvider = AsyncNotifierProviderFamily<
  VoucherBatchListNotifier,
  List<VoucherBatch>,
  String
>(VoucherBatchListNotifier.new);

class VoucherBatchListNotifier
    extends FamilyAsyncNotifier<List<VoucherBatch>, String> {
  VoucherRepository get _repo => ref.read(voucherRepositoryProvider);

  @override
  Future<List<VoucherBatch>> build(String arg) {
    return _repo.listBatches(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.listBatches(arg));
  }
}

// ---------------------------------------------------------------------------
// Last batch for active router
// ---------------------------------------------------------------------------

/// Last generated voucher batch for the currently active router.
final lastVoucherBatchProvider =
    AsyncNotifierProvider<LastVoucherBatchNotifier, VoucherBatch?>(
  LastVoucherBatchNotifier.new,
);

class LastVoucherBatchNotifier extends AsyncNotifier<VoucherBatch?> {
  VoucherRepository get _repo => ref.read(voucherRepositoryProvider);

  @override
  Future<VoucherBatch?> build() async {
    final active = ref.watch(activeRouterProvider);
    if (active == null) return null;
    return _repo.getLastBatch(active.id);
  }

  Future<void> refresh() async {
    final active = ref.read(activeRouterProvider);
    if (active == null) {
      state = const AsyncData(null);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getLastBatch(active.id));
  }
}

// ---------------------------------------------------------------------------
// Generation params form state
// ---------------------------------------------------------------------------

/// Form state for voucher generation parameters.
///
/// Holds user's current form input before generation.
final voucherGenerationParamsProvider =
    NotifierProvider<VoucherGenerationParamsNotifier, VoucherGenerationParams?>(
  VoucherGenerationParamsNotifier.new,
);

class VoucherGenerationParamsNotifier
    extends Notifier<VoucherGenerationParams?> {
  @override
  VoucherGenerationParams? build() => null;

  void setParams(VoucherGenerationParams params) {
    state = params;
  }

  void clearParams() {
    state = null;
  }
}

// ---------------------------------------------------------------------------
// Quick Print list per router
// ---------------------------------------------------------------------------

/// Quick Print packages from the router.
///
/// arg = routerId (String).
final quickPrintListProvider = AsyncNotifierProviderFamily<
  QuickPrintListNotifier,
  List<QuickPrintPackage>,
  String
>(QuickPrintListNotifier.new);

class QuickPrintListNotifier
    extends FamilyAsyncNotifier<List<QuickPrintPackage>, String> {
  RouterRepository get _routerRepo => ref.read(routerRepositoryProvider);
  QuickPrintService get _service => ref.read(quickPrintServiceProvider);

  @override
  Future<List<QuickPrintPackage>> build(String arg) async {
    final routers = await ref.read(routerListProvider.future);
    final router = routers.where((r) => r.id == arg).firstOrNull;
    if (router == null) return [];
    final password = await _routerRepo.getPassword(arg);
    if (password == null) return [];
    return _service.listPackages(router: router, password: password);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
  }
}

// ---------------------------------------------------------------------------
// Selected template state
// ---------------------------------------------------------------------------

/// Currently selected voucher template.
final voucherTemplateProvider =
    NotifierProvider<VoucherTemplateNotifier, VoucherTemplate>(
  VoucherTemplateNotifier.new,
);

class VoucherTemplateNotifier extends Notifier<VoucherTemplate> {
  @override
  VoucherTemplate build() => VoucherTemplate.default220;

  void setTemplate(VoucherTemplate t) {
    state = t;
  }
}

// ---------------------------------------------------------------------------
// Voucher actions notifier
// ---------------------------------------------------------------------------

/// Performs write operations: generate batch, push to router, save, print.
///
/// Failure recovery: [lastRenderedPdf] holds the most recently generated PDF
/// so the user can retry print without re-generating.
final voucherActionsProvider =
    AsyncNotifierProvider<VoucherActionsNotifier, void>(
  VoucherActionsNotifier.new,
);

class VoucherActionsNotifier extends AsyncNotifier<void> {
  RouterRepository get _routerRepo => ref.read(routerRepositoryProvider);
  VoucherRepository get _voucherRepo => ref.read(voucherRepositoryProvider);
  VoucherGeneratorService get _genService =>
      ref.read(voucherGeneratorServiceProvider);
  VoucherRenderService get _renderService =>
      ref.read(voucherRenderServiceProvider);
  PrintService get _printService => ref.read(printServiceProvider);

  @override
  Future<void> build() async {}

  RouterModel _requireActiveRouter() {
    final active = ref.read(activeRouterProvider);
    if (active == null) throw StateError('No active router selected.');
    return active;
  }

  Future<String> _requirePassword(String routerId) async {
    final pwd = await _routerRepo.getPassword(routerId);
    if (pwd == null) throw StateError('No credentials for router $routerId.');
    return pwd;
  }

  // ---------------------------------------------------------------------------
  // Generate + push to router + save locally
  // ---------------------------------------------------------------------------

  /// Generate a batch, push to router, save to SQLite.
  ///
  /// Steps:
  /// 1. Generate credentials locally.
  /// 2. Save batch to SQLite FIRST (failure recovery guarantee).
  /// 3. Push to router.
  /// 4. Refresh batch list provider.
  Future<VoucherBatch> generateAndPush(VoucherGenerationParams params) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);

    state = const AsyncLoading();
    try {
      // 1. Generate locally.
      final vouchers = _genService.generate(params);
      final now = DateTime.now();
      final batchCode = generateBatchCode(now: now);

      final batch = VoucherBatch(
        id: _uuid(),
        routerId: router.id,
        batchCode: batchCode,
        profileName: params.profileName,
        quantity: params.quantity,
        mode: params.mode,
        charSet: params.charSet,
        prefix: params.prefix,
        usernameLength: params.usernameLength,
        passwordLength: params.passwordLength,
        limitUptime: params.limitUptime,
        comment: params.comment,
        generatedAt: now,
        vouchers: vouchers,
      );

      // 2. Save BEFORE pushing to router (failure recovery).
      await _voucherRepo.saveBatch(batch);

      // 3. Push to router.
      await _genService.pushToRouter(
        router: router,
        password: password,
        vouchers: vouchers,
        params: params,
      );

      // 4. Refresh batch list.
      ref.read(voucherBatchListProvider(router.id).notifier).refresh();
      ref.read(lastVoucherBatchProvider.notifier).refresh();

      state = const AsyncData(null);
      return batch;
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // One-touch: generate 1 voucher + immediately print/share
  // ---------------------------------------------------------------------------

  /// Generate a single voucher and immediately share the PDF.
  Future<void> oneTouchGenerateAndPrint(
    VoucherGenerationParams params, {
    required String routerName,
    String? validity,
    VoucherTemplate template = VoucherTemplate.default220,
  }) async {
    // Force quantity = 1 for one-touch flow.
    final singleParams = params.copyWith(quantity: 1);
    final batch = await generateAndPush(singleParams);
    if (batch.vouchers.isEmpty) return;

    final pdfResult = await _renderService.renderSingleVoucher(
      voucher: batch.vouchers.first,
      routerName: routerName,
      profileName: batch.profileName,
      routerHost: params.routerHost,
      validity: validity,
      template: template,
    );

    await _printService.printOrShare(pdfResult.bytes, pdfResult.filename);
  }

  // ---------------------------------------------------------------------------
  // Print retry (failure recovery)
  // ---------------------------------------------------------------------------

  /// Re-render and share the last batch PDF.
  ///
  /// Called when printing failed after generation — no re-generation needed.
  Future<void> retryPrintLastBatch({
    required VoucherBatch batch,
    required String routerName,
    required String routerHost,
    String? validity,
    VoucherTemplate template = VoucherTemplate.default220,
  }) async {
    final pdfResult = await _renderService.renderBatch(
      batch: batch,
      routerName: routerName,
      routerHost: routerHost,
      validity: validity,
      template: template,
    );
    await _printService.printOrShare(pdfResult.bytes, pdfResult.filename);
  }

  // ---------------------------------------------------------------------------
  // Delete batch
  // ---------------------------------------------------------------------------

  Future<void> deleteBatch(String batchId, String routerId) async {
    state = const AsyncLoading();
    try {
      await _voucherRepo.deleteBatch(batchId);
      ref.read(voucherBatchListProvider(routerId).notifier).refresh();
      ref.read(lastVoucherBatchProvider.notifier).refresh();
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Quick Print
  // ---------------------------------------------------------------------------

  QuickPrintService get _qpService => ref.read(quickPrintServiceProvider);

  Future<void> deleteQuickPrintPackage(
    String routerId,
    String scriptId,
  ) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(routerId);
    await _qpService.deletePackage(
      router: router,
      password: password,
      scriptId: scriptId,
    );
    ref.read(quickPrintListProvider(routerId).notifier).refresh();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _uuid() {
    // Simple UUID v4 without package dependency.
    final r = (DateTime.now().millisecondsSinceEpoch ^ 0xDEADBEEF).toRadixString(16);
    return '${r.padLeft(8, '0')}-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
        .replaceAllMapped(
          RegExp('[xy]'),
          (m) {
            final c = m.group(0);
            // ignore: prefer_const_declarations
            final v = (DateTime.now().microsecondsSinceEpoch & 0xF);
            return c == 'x' ? v.toRadixString(16) : (v & 0x3 | 0x8).toRadixString(16);
          },
        );
  }
}
