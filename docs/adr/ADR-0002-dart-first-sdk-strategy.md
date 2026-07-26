# ADR-0002 — Dart-first SDK strategy

## Status
ACCEPTED

## Date
2026-07-26

## Context
DevKuroTik requires reusable domain and protocol logic packaged as SDKs. The SDK packages (mikrotik_sdk, voucher_sdk, routeros_script_sdk, monitoring_sdk) contain business rules, protocol handling, and domain models that must:
- Be testable with plain `dart test` without requiring Flutter widgets or device SDKs
- Remain portable to non-Flutter environments (CLI tools, test harnesses, future platforms)
- Not import `package:flutter` or depend on widget lifecycle
- Be independently verifiable in CI without Android/iOS simulators

The Flutter application (`devkurotik_app`) is the sole consumer of these packages and is the only layer that may import Flutter-specific APIs.

## Decision
All SDK packages under `packages/` will be authored as **pure Dart packages**, not Flutter packages.

- SDK `pubspec.yaml` files will use `sdk: ^3.12.2` (Dart constraint only), not `flutter.sdk`.
- SDK packages will **not** import `package:flutter`.
- SDK packages will run tests with `dart test`, not `flutter test`.
- Only `apps/devkurotik_app` will import and depend on the Flutter SDK.

## Rationale
- ARCHITECTURE.md mandates: "SDKs do not depend on Flutter UI."
- Pure Dart packages can be tested headlessly in CI without Flutter toolchain overhead.
- Decoupling from Flutter prevents breaking SDK tests when Flutter upgrades change widget APIs.
- Enables future reuse in Dart server-side or CLI contexts (test harnesses, migration tools).
- Validated by AUDIT_REPORT.md finding that Mikhmon legacy code tightly coupled protocol logic with presentation — DevKuroTik must not repeat this error.

## Consequences
**Positive:**
- SDK tests run fast and headlessly on any CI environment with only Dart installed.
- No Flutter version constraints on SDK package tests.
- Protocol logic can be validated independently of UI frameworks.
- Strict dependency boundary between business logic and presentation layer.

**Negative:**
- Cannot use Flutter utilities (e.g., `compute`, `FlutterError`) inside SDKs.
- Any SDK that eventually needs Flutter integration must be refactored or wrapped.

## Alternatives Considered
- **Flutter packages for all SDKs** → Rejected. Violates ARCHITECTURE.md SDK boundary rules. Couples protocol logic to Flutter upgrade cycles.
- **Shared Flutter plugin pattern** → Rejected. Unnecessary complexity at this stage. SDKs have no platform channel needs in Phase 1–7 scope.

## References
- ARCHITECTURE.md — Section 5 (SDK Boundaries): "SDKs do not depend on Flutter UI"
- ROADMAP_V1.md — SDK architecture section
- PHASE_0.md — Task 4 (Reserve package workspace boundaries)
- AUDIT_REPORT.md — Architecture deficiency findings in Mikhmon legacy
