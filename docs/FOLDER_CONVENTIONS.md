# FOLDER_CONVENTIONS.md
> DevKuroTik folder structure conventions and enforcement rules.

---

## Purpose
Document the canonical folder structure for the DevKuroTik monorepo and define rules for maintaining it.

## Last Updated
2026-07-26

---

## 1. Top-Level Structure

```
devkurotik/                         ← repository root
├── apps/
│   └── devkurotik_app/             ← Flutter application
├── packages/
│   ├── mikrotik_sdk/               ← RouterOS transport SDK
│   ├── voucher_sdk/                ← Voucher domain SDK
│   ├── routeros_script_sdk/        ← Script parsing/generation SDK
│   └── monitoring_sdk/             ← Dashboard resource SDK
├── docs/
│   ├── adr/                        ← Architecture Decision Records
│   ├── ENGINEERING_STANDARDS.md
│   ├── TESTING_STANDARDS.md
│   ├── DEPENDENCY_POLICY.md
│   ├── GIT_CONVENTIONS.md
│   ├── FOLDER_CONVENTIONS.md       ← this file
│   └── GOVERNANCE.md
├── tools/
│   └── fixtures/                   ← Test fixtures (Phase 6 regression data)
├── .github/
│   └── workflows/
│       └── ci.yml
├── audit/                          ← Audit and specification documents
├── analysis_options.yaml           ← Root shared lint configuration
├── README.md
├── CLAUDE.md
├── AGENTS.md
├── RULES.md
├── CONTRIBUTING.md
└── ARCHITECTURE.md
```

---

## 2. Application Folder Structure

```
apps/devkurotik_app/
├── lib/
│   ├── main.dart                   ← app entry point
│   ├── app/
│   │   ├── app.dart                ← DevKuroTikApp widget (Phase 1+)
│   │   └── router.dart             ← go_router configuration (Phase 2+)
│   ├── features/                   ← feature modules (Phase 2+)
│   │   ├── router_management/
│   │   ├── dashboard/
│   │   ├── hotspot/
│   │   ├── voucher/
│   │   ├── ppp/
│   │   └── settings/
│   └── shared/                     ← shared UI components, extensions, utils
│       ├── widgets/
│       ├── theme/
│       └── extensions/
├── test/
│   └── widget_test.dart
├── integration_test/               ← created Phase 4+
├── android/
├── ios/
├── pubspec.yaml
└── analysis_options.yaml
```

### Feature Module Structure
Each feature module follows:
```
features/<feature>/
├── data/           ← repositories, data sources, DTOs
├── domain/         ← models, use cases, interfaces
├── presentation/   ← widgets, screens, providers
└── <feature>_module.dart
```

---

## 3. SDK Package Structure

```
packages/<sdk_name>/
├── lib/
│   ├── <sdk_name>.dart             ← public library barrel
│   └── src/                        ← internal implementation (Phase 1+)
│       ├── models/
│       ├── exceptions/
│       └── ...
├── test/
│   └── <sdk_name>_test.dart
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 4. Docs Folder Structure

```
docs/
├── adr/
│   ├── ADR-TEMPLATE.md
│   ├── ADR-0001-monorepo-structure.md
│   ├── ADR-0002-dart-first-sdk-strategy.md
│   ├── ADR-0003-offline-first-local-storage.md
│   └── ADR-0004-android-first-ios-ready.md
├── ENGINEERING_STANDARDS.md
├── TESTING_STANDARDS.md
├── DEPENDENCY_POLICY.md
├── GIT_CONVENTIONS.md
├── FOLDER_CONVENTIONS.md
└── GOVERNANCE.md
```

ADR numbering: sequential, zero-padded to 4 digits (`ADR-0005-...`).

---

## 5. Tools Folder Structure

```
tools/
└── fixtures/                       ← Phase 6 regression fixtures
    ├── on_login_scripts/           ← input/expected output pairs
    └── quick_print/                ← Quick Print encoding fixtures
```

The `tools/` directory is for automation, scripts, and test fixtures only. No application code belongs here.

---

## 6. Enforcement Rules

1. **UI belongs in `apps/`** — no widget code in `packages/`.
2. **Reusable logic belongs in `packages/`** — no business logic in `apps/lib/` that should be in an SDK.
3. **Governance docs belong in `docs/`** — no governance markdown scattered at root except the approved root-level contract docs.
4. **Fixtures belong in `tools/`** — no test fixtures scattered in package test directories (exception: simple inline test data is acceptable).
5. **Generated files must not be committed** — `*.g.dart`, `*.freezed.dart`, `build/` are in `.gitignore`.
6. **No new top-level directories** — only `apps/`, `packages/`, `docs/`, `tools/`, `.github/`, `audit/` are approved at repository root.

---

## 7. Frozen Structure

This structure is frozen as of Phase 0. Changes to the top-level structure require:
- An ADR documenting the reason.
- Project owner explicit approval.
- Update to this document.

---

## References
- ARCHITECTURE.md — Section 4 (Repository Structure)
- ADR-0001 — Monorepo structure decision
- PHASE_0.md — Task 1, Task 4, Task 8
