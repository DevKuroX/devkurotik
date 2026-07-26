# ADR-0003 — Offline-first local storage with Drift + SQLite and flutter_secure_storage

## Status
ACCEPTED

## Date
2026-07-26

## Context
DevKuroTik is designed as an offline-first application. Users may operate in environments with intermittent or no internet connectivity. The application must:
- Store router connection profiles and user preferences locally and persistently
- Store credentials securely (API credentials must never appear in plaintext in the local database)
- Cache router state, monitoring data, and hotspot data for offline display
- Provide queryable, typed local persistence suitable for complex relational data (users, profiles, sessions, voucher records)

The approved technology baseline from ROADMAP_V1.md mandates:
- **Drift** for local relational database (SQLite via drift)
- **flutter_secure_storage** for credential storage
- No alternative persistence frameworks

## Decision
We will use:
1. **Drift + SQLite** (`drift` + `sqlite3_flutter_libs`) for all structured local persistence except credentials.
2. **flutter_secure_storage** for all router credentials, API keys, and sensitive authentication material.

Credentials must never be stored in the Drift database. All router API credentials are stored exclusively in the platform keychain via `flutter_secure_storage`.

## Rationale
- Mandated by ROADMAP_V1.md approved technology baseline.
- SECURITY_REPORT.md finding: legacy Mikhmon stored credentials without adequate protection. DevKuroTik must eliminate this.
- Drift provides type-safe, migration-aware SQLite access with code generation, suitable for structured data.
- flutter_secure_storage uses platform-native keychains (Android Keystore, iOS Keychain) — credentials are encrypted at rest without custom encryption logic.
- Offline-first requirement means local state must be complete and queryable without a server connection.

## Consequences
**Positive:**
- Credentials are encrypted at rest by the platform OS, not by application-level code.
- Structured data is type-safe and migration-safe via Drift schema versioning.
- Application works fully offline for all cached data.
- Security audit requirement (no plaintext credentials) is architecturally enforced.

**Negative:**
- Drift requires code generation (`build_runner`) — adds build step complexity.
- flutter_secure_storage has platform-specific edge cases (e.g., Android backup behavior, iOS iCloud sync) that require configuration.
- Schema migrations must be managed carefully across app versions.

## Alternatives Considered
- **Hive / Isar** → Rejected. Not in the approved technology baseline. Introducing unapproved persistence would violate RULES.md Rule 3.
- **SharedPreferences for credentials** → Rejected. SharedPreferences is not encrypted; storing credentials there would violate SECURITY_REPORT.md requirements and ARCHITECTURE.md Section 9.
- **Remote-first with cloud sync** → Rejected. Violates offline-first principle. Optional premium cloud sync (Phase 9) must not contaminate the core offline model.
- **SQLCipher for full DB encryption** → Not required for Phase 0. Credentials are not stored in the DB. Can be revisited in Phase 8 security hardening if risk assessment requires it.

## References
- ROADMAP_V1.md — Approved technology baseline
- ARCHITECTURE.md — Section 9 (Security Principles): "No plaintext credential storage in local DB"
- SECURITY_REPORT.md — Credential storage findings
- PHASE_0.md — Task 2 (Pin the approved technical baseline)
- PHASE_2.md — Router persistence implementation (Phase 2 scope)
- PHASE_8.md — Security hardening (credential review gate)
