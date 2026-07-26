# DEPENDENCY_POLICY.md
> DevKuroTik approved dependency list and evaluation policy.

---

## Purpose
Define the approved dependency baseline, criteria for adding or updating dependencies, and the upgrade cadence for the DevKuroTik project.

## Last Updated
2026-07-26

---

## 1. Approved Dependency Baseline

The following packages are approved by the canonical specification (ROADMAP_V1.md). No substitutes are permitted without project owner approval.

### Flutter App (`apps/devkurotik_app`)

| Package | Version Constraint | Purpose |
|---|---|---|
| `flutter_riverpod` | `^2.6.1` | State management |
| `riverpod_annotation` | `^2.6.1` | Riverpod code generation annotations |
| `go_router` | `^15.1.2` | Navigation / routing |
| `drift` | `^2.26.1` | Local relational database (SQLite) |
| `sqlite3_flutter_libs` | `^0.5.28` | SQLite native binaries for Flutter |
| `path_provider` | `^2.1.5` | Platform paths for database file |
| `path` | `^1.9.0` | Path manipulation |
| `flutter_secure_storage` | `^9.2.4` | Secure credential storage |
| `fl_chart` | `^0.71.0` | Charts (dashboard) |
| `pdf` | `^3.11.3` | PDF generation (vouchers) |
| `printing` | `^5.14.3` | Print/share integration |
| `qr_flutter` | `^4.1.0` | QR code rendering |
| `flutter_local_notifications` | `^18.0.1` | Local notifications |
| `local_auth` | `^2.3.0` | Biometric authentication |
| `cupertino_icons` | `^1.0.8` | iOS-style icons |

### Dev Dependencies (App)

| Package | Version Constraint | Purpose |
|---|---|---|
| `build_runner` | `^2.4.14` | Code generation runner |
| `drift_dev` | `^2.26.1` | Drift schema code generation |
| `riverpod_generator` | `^2.6.5` | Riverpod provider code generation |
| `flutter_lints` | `^6.0.0` | Lint rules |
| `custom_lint` | `^0.7.5` | Custom lint runner |
| `riverpod_lint` | `^2.6.5` | Riverpod-specific lint rules |

### SDK Packages (`packages/*`)

| Package | Version Constraint | Purpose |
|---|---|---|
| `test` | `^1.25.15` | Dart test framework |
| `lints` | `^5.1.1` | Recommended Dart lint rules |

---

## 2. Evaluation Criteria for New Dependencies

Any dependency not in the approved baseline requires project owner approval. Evaluation criteria:

| Criterion | Requirement |
|---|---|
| pub.dev popularity | ≥ 100 likes on pub.dev |
| Maintenance | Published within the last 2 years; actively maintained |
| Null safety | Must support sound null safety (Dart 3.x) |
| Platform support | Must support Android and iOS (for app-level packages) |
| License | Must be MIT, BSD, or Apache 2.0 |
| Transitive deps | Must not introduce conflicting transitive dependencies |
| Security | Must not require insecure permissions beyond what the app needs |
| Alignment | Must align with the approved architecture (no alternatives to approved packages) |

---

## 3. Prohibited Substitutions

The following substitutions are explicitly prohibited:

| Instead of... | Do NOT use... |
|---|---|
| `flutter_riverpod` | `flutter_bloc`, `provider`, `mobx`, `getx` |
| `drift` | `hive`, `isar`, `sqflite` (direct), `objectbox` |
| `go_router` | `auto_route`, `beamer`, manual `Navigator` for app routing |
| `flutter_secure_storage` | `shared_preferences` for credentials |

---

## 4. Version Update Cadence

| Category | Update Frequency |
|---|---|
| Security patches | Immediate upon discovery |
| Minor versions | At phase boundaries (after phase completion) |
| Major versions | Requires explicit owner decision and migration plan |
| Flutter SDK | Pin until a phase explicitly requires upgrade |
| Dart SDK | Follows Flutter SDK |

### Update Process
1. Check `flutter pub outdated` / `dart pub outdated` at the start of each phase.
2. Apply patch/minor updates if they do not break tests.
3. Document breaking changes in the phase completion report.
4. Major version upgrades require a separate evaluation.

---

## 5. Rejection Criteria

Reject a dependency if:

- It is a substitute for an already-approved package.
- It requires permissions not justified by the feature it enables.
- Its last publish was > 2 years ago.
- It has open critical security issues.
- It introduces a transitive dependency conflict with the approved baseline.
- It is not null-safe (Dart 3.x compatible).
- It requires native code that is not supported on both Android and iOS.

---

## References
- ROADMAP_V1.md — Approved technology baseline
- ARCHITECTURE.md — Section 3 (Approved Technology Baseline)
- RULES.md — Rule 3 (No undocumented dependencies)
- PHASE_0.md — Task 10 (Define dependency management policy)
