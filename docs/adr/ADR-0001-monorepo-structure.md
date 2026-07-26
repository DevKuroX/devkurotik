# ADR-0001 — Monorepo with apps/ and packages/ workspace structure

## Status
ACCEPTED

## Date
2026-07-26

## Context
DevKuroTik is designed as a multi-package project from the outset. The architecture mandates four SDK packages (mikrotik_sdk, voucher_sdk, routeros_script_sdk, monitoring_sdk) plus the Flutter application. Each SDK has distinct responsibilities, must be independently testable, and must not depend on Flutter UI. The Flutter application consumes the SDKs.

The project requires:
- Clear separation between UI code and reusable domain/protocol logic
- Independent CI validation per package
- Enforceable package dependency direction (app → SDKs, not SDK → SDK except where approved)
- Scalability to add optional packages (hotspot_sdk, ppp_sdk, queue_sdk, system_sdk, report_sdk) without restructuring

## Decision
We will use a Dart/Flutter monorepo structure organized as:

```
devkurotik/
├── apps/
│   └── devkurotik_app/        # Flutter application
├── packages/
│   ├── mikrotik_sdk/          # RouterOS transport
│   ├── voucher_sdk/           # Voucher domain
│   ├── routeros_script_sdk/   # Script parsing/generation
│   └── monitoring_sdk/        # Dashboard resource models
├── docs/
│   └── adr/
├── tools/
└── .github/
    └── workflows/
```

Each package is a standalone Dart package with its own `pubspec.yaml`, `lib/`, and `test/` directories.

## Rationale
- Mandated by ROADMAP_V1.md and ARCHITECTURE.md without negotiation.
- SDK boundaries must be preserved to prevent business logic from leaking into transport layer and vice versa.
- Independent packages enable independent testing in CI, per PHASE_0.md Task 4.
- Monorepo avoids multi-repo coordination overhead while retaining clear package boundaries.
- pub.dev workspace support (Dart 3.x) allows local path dependencies without publishing.

## Consequences
**Positive:**
- SDK boundaries are structurally enforced by package imports.
- Each SDK can be tested independently in CI.
- Optional packages can be added to `packages/` without affecting existing structure.
- Dependency direction is auditable (pubspec.yaml imports only go downward).

**Negative:**
- Slightly more setup overhead for tooling (multiple `pub get` calls, CI matrix).
- Cross-package refactoring requires coordinated changes.

## Alternatives Considered
- **Single Flutter package (everything in apps/)** → Rejected. Collapses SDK boundaries. Transport logic would be coupled to Flutter, violating ARCHITECTURE.md.
- **Multi-repo (separate git repos per package)** → Rejected. Excessive coordination overhead for a solo/small team project at this stage. Violates simplicity goals of Phase 0.
- **Melos for workspace management** → Deferred. Melos adds convenience scripts but is not required for Phase 0. Can be added in a later phase if needed without changing structure.

## References
- ROADMAP_V1.md — Section 4 (Repository Structure)
- ARCHITECTURE.md — Section 4 (Repository Structure), Section 5 (SDK Boundaries)
- PHASE_0.md — Task 1 (Initialize canonical repository structure), Task 4 (Reserve package workspace boundaries)
