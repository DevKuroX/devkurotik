# ARCHITECTURE.md
> High-level architecture contract for DevKuroTik.

---

## Purpose
Provide a stable, repository-level description of the DevKuroTik architecture without changing or extending the canonical specification.

## Scope
This document covers:
- high-level architecture
- SDK boundaries
- repository structure
- package relationships
- phase ownership
- data flow
- security principles

## Audience
- maintainers
- implementers
- reviewers
- AI agents
- auditors

## Last Updated
2026-07-25

---

## 1. Architectural Summary

DevKuroTik is a **complete rewrite of Mikhmon**.

It is designed as:
- mobile-first
- Flutter-based
- Android-first, iOS-ready
- offline-first
- multi-router capable
- SDK-driven
- security-focused

The architecture is fixed by the canonical specification and must not be changed casually.

---

## 2. High-Level Architecture

```text
Flutter App
   |
Riverpod State Layer
   |
SDK Layer
   |
MikroTik RouterOS API
```

Expanded view:

```text
Flutter
   |
Riverpod
   |
Domain / SDK Layer
   |
Local Storage + Secure Storage + RouterOS API
```

### Primary Layers
1. **Presentation Layer** — Flutter UI
2. **State Layer** — Riverpod
3. **Domain / SDK Layer** — package-based business and protocol logic
4. **Persistence Layer** — Drift/SQLite + secure storage
5. **RouterOS Integration Layer** — MikroTik binary API access

---

## 3. Approved Technology Baseline

The architecture assumes the following fixed baseline:
- Flutter 3.x
- Dart bundled with pinned Flutter release
- Riverpod 2.x
- Drift + SQLite
- `go_router`
- `flutter_secure_storage`
- `fl_chart`
- `pdf` + `printing`
- `qr_flutter`
- `flutter_local_notifications`
- `local_auth`

No alternative technology stack may be introduced unless the project owner explicitly changes the source-of-truth documents.

---

## 4. Repository Structure

Planned structure:

```text
devkurotik/
├── apps/
│   └── devkurotik_app/
├── packages/
│   ├── mikrotik_sdk/
│   ├── voucher_sdk/
│   ├── routeros_script_sdk/
│   ├── monitoring_sdk/
│   ├── hotspot_sdk/        # optional retained split
│   ├── system_sdk/         # optional retained split
│   ├── report_sdk/         # optional retained split
│   ├── ppp_sdk/            # optional retained split
│   └── queue_sdk/          # optional retained split
├── docs/
├── tools/
└── .github/
```

### Repository Principle
- UI belongs in `apps/`
- reusable logic belongs in `packages/`
- governance and architecture docs belong in documentation
- fixtures and automation belong in `tools/`

---

## 5. SDK Boundaries

### `mikrotik_sdk`
Responsibilities:
- RouterOS binary protocol transport
- connection lifecycle
- authentication
- command execution
- retries/timeouts
- standardized errors
- secret-safe logging

Must not own:
- UI
- app-specific persistence
- hotspot business rules

### `voucher_sdk`
Responsibilities:
- bulk generation orchestration
- voucher payload assembly
- Quick Print compatibility logic
- voucher domain models
- QR payload rules

Must not own:
- raw transport
- app UI
- unapproved external QR behavior

### `routeros_script_sdk`
Responsibilities:
- `on-login` metadata parsing
- `OnLoginScriptGenerator`
- `/system/script` record parsing
- Quick Print encoding/decoding
- compatibility fixtures and serialization rules

Must not own:
- UI
- app routing
- direct credential storage

### `monitoring_sdk`
Responsibilities:
- dashboard-oriented resource retrieval
- traffic abstractions
- health-check models
- monitoring formatting helpers

Must not own:
- widget code
- app navigation
- voucher/business-record logic

---

## 6. Package Relationships

High-level package dependency direction:

```text
devkurotik_app
   ↓
Riverpod + feature modules
   ↓
Domain SDKs
   ↓
mikrotik_sdk / persistence services
   ↓
MikroTik RouterOS
```

### Relationship Rules
- app features consume SDKs
- SDKs do not depend on Flutter UI
- high-risk compatibility logic remains isolated
- transport logic remains below business modules

---

## 7. Phase Ownership by Architectural Area

| Phase | Primary Architectural Area |
|---|---|
| Phase 0 | repository, tooling, governance, structure |
| Phase 1 | `mikrotik_sdk`, transport, auth, errors |
| Phase 2 | router persistence, secure storage, active-router state |
| Phase 3 | dashboard presentation + monitoring consumption |
| Phase 4 | hotspot domain and user workflows |
| Phase 5 | voucher domain, generation, print flows |
| Phase 6 | `routeros_script_sdk`, parser/generator compatibility |
| Phase 7 | PPP + Queue domain scope |
| Phase 8 | security controls across layers |
| Phase 9 | optional premium isolation |
| Phase 10 | release validation, telemetry, beta controls |

---

## 8. Data Flow

### Operational Flow
```text
User Action
   ↓
Flutter UI
   ↓
Riverpod State Management
   ↓
Feature / Domain SDK
   ↓
MikroTik SDK or Local Persistence
   ↓
RouterOS / SQLite / Secure Storage
```

### Offline-First Principle
- local state and cache live in approved local persistence layers
- credentials live in secure storage
- router interactions use approved SDK boundaries
- optional premium sync features must not contaminate core offline-first behavior

---

## 9. Security Principles

Architecture must preserve the following principles:
1. No default credentials
2. No plaintext credential storage in local DB
3. No plaintext credential leakage in logs, telemetry, or crash reports
4. Input validation before RouterOS command execution
5. Destructive actions require confirmation and auditability
6. External services must not receive voucher credential payloads
7. Security hardening is mandatory before beta

These principles come directly from the audit and security specification.

---

## 10. Architecture Stability Rule

This architecture is considered stable.

Contributors and AI agents must not:
- redesign state management
- replace routing
- replace persistence model
- collapse SDK boundaries for convenience
- move premium features into the critical path
- alter the project from a rewrite into a migration/port

---

## 11. Implementation Rule

The architecture must be implemented through the canonical phase documents.

If any contributor believes the architecture must change, implementation must stop and the project owner must explicitly authorize a specification update.

---

## References
- `README.md`
- `CLAUDE.md`
- `AGENTS.md`
- `RULES.md`
- `CONTRIBUTING.md`
- `docs/GOVERNANCE.md`
- `ROADMAP_V1.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `PHASE_0.md` ... `PHASE_10.md`
- `SDK_DESIGN.md`
- `MIGRATION_BLUEPRINT.md`
- `SECURITY_REPORT.md`
