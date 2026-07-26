# DEPENDENCY_AUDIT.md
> DevKuroTik v0.8.0 — Dependency Security Audit
> Date: 2026-07-26
> Status: READ-ONLY assessment. No code was modified.

---

## 1. Scope

This audit covers all dependencies declared in:
- `apps/devkurotik_app/pubspec.yaml`
- `packages/mikrotik_sdk/pubspec.yaml`
- `packages/voucher_sdk/pubspec.yaml` (stub)
- `packages/monitoring_sdk/pubspec.yaml` (stub)
- `packages/routeros_script_sdk/pubspec.yaml` (stub)

---

## 2. DevKuroTik App — Runtime Dependencies

### State Management & Navigation

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `flutter_riverpod` | ^2.6.1 | Remi Rousselet | No known CVEs; widely used | ✅ |
| `riverpod_annotation` | ^2.6.1 | Remi Rousselet | Code generation only | ✅ |
| `go_router` | ^15.1.2 | Flutter team | No known CVEs | ✅ |

### Local Persistence

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `drift` | ^2.26.1 | Simon Binder | Type-safe ORM, parameterized queries — no SQL injection | ✅ |
| `sqlite3_flutter_libs` | ^0.5.28 | moor_ffi team | Bundled SQLite — check upstream SQLite CVEs | ⚠️ Review |
| `path_provider` | ^2.1.5 | Flutter team | File system access — paths only, no credential exposure | ✅ |
| `path` | ^1.9.0 | Dart team | Path manipulation utilities | ✅ |

**SQLite note:** The bundled SQLite version in `sqlite3_flutter_libs` tracks upstream SQLite releases. SQLite has had memory corruption CVEs in specific versions. Should be verified against current SQLite CVE list.

### Secure Storage & Authentication

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `flutter_secure_storage` | ^9.2.4 | Julian Steenbakker | Android Keystore + iOS Keychain; actively maintained | ✅ |
| `local_auth` | ^2.3.0 | Flutter team | Biometric APIs; well-audited; currently unused | ⚠️ Installed, inactive |

### UI / Data Visualization

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `fl_chart` | ^0.71.0 | imaNNeo | Pure Dart/Flutter charts; no network access | ✅ |

### PDF / Print

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `pdf` | ^3.11.3 | David PHAM-VAN | No network access; pure PDF generation | ✅ |
| `printing` | ^5.14.3 | David PHAM-VAN | Interfaces with OS print subsystem; no credential exposure | ✅ |

### QR Code

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `qr_flutter` | ^4.1.0 | Luke Freeman | Pure Dart QR generation; fully local (no Google Chart API) | ✅ Note |

**Note:** This is a critical improvement over Mikhmon, which sent all voucher credentials to `chart.googleapis.com` (HIGH-04 in legacy security report). DevKuroTik generates QR codes locally — no external services receive credentials.

### Notifications & System

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `flutter_local_notifications` | ^18.0.1 | MaikuB | Local notifications; no network transmission | ✅ |

### 🔴 UNAUDITED — Bluetooth/Thermal Print

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `flutter_thermal_printer` | ^2.0.1 | thipanith | **Third-party; Bluetooth + Wi-Fi socket access; not security-audited** | ⚠️ REVIEW REQUIRED |

**`flutter_thermal_printer` risk assessment:**
- Publisher: small open-source maintainer (`thipanith` on pub.dev)
- Permissions requested: `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`; Wi-Fi socket access
- Security implications: Package runs in same Dart isolate as the app, with access to all in-scope variables including any in-memory credentials
- CVE status: Not tracked on NVD; pub.dev advisory database not consulted
- **Required action:** Manual code review before Phase 8 completion

### File Sharing

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `share_plus` | ^9.x (inferred) | FlutterCommunity | OS share sheet; no additional privilege | ✅ |

---

## 3. DevKuroTik App — Dev Dependencies

| Package | Purpose | Notes |
|---|---|---|
| `flutter_test` | Widget/unit testing | Framework only |
| `flutter_lints` | Lint rules | Analysis only |
| `riverpod_generator` | Code generation | Build-time only |
| `build_runner` | Code generation | Build-time only |
| `drift_dev` | Schema generation | Build-time only |

No dev dependencies have production runtime security implications.

---

## 4. mikrotik_sdk — Runtime Dependencies

| Package | Version | Publisher | Security Notes | Status |
|---|---|---|---|---|
| `crypto` | ^3.0.7 | Dart team | MD5 for pre-v6.43 challenge-response; SHA-1 available if needed | ✅ |
| `logging` | ^1.3.0 | Dart team | No network transmission; consumer configures sinks | ✅ |

**MD5 note:** MD5 is used per the RouterOS API specification for pre-v6.43 authentication challenge-response. This is a protocol requirement, not a design choice. Modern RouterOS versions (v6.43+) use plaintext password exchange. Neither constitutes a hash-based authentication scheme that needs upgrading — they are protocol-level constructs.

---

## 5. Stub Packages (no runtime dependencies)

| Package | Status |
|---|---|
| `voucher_sdk` | Stub — no runtime deps |
| `monitoring_sdk` | Stub — no runtime deps |
| `routeros_script_sdk` | Stub — no runtime deps |

---

## 6. License Summary

| Package | License | Commercial Use | Concerns |
|---|---|---|---|
| All Flutter/Dart team packages | BSD-3-Clause | ✅ Yes | None |
| `drift` | MIT | ✅ Yes | None |
| `fl_chart` | MIT | ✅ Yes | None |
| `pdf` + `printing` | Apache-2.0 | ✅ Yes | None |
| `qr_flutter` | BSD-3-Clause | ✅ Yes | None |
| `flutter_secure_storage` | BSD-3-Clause | ✅ Yes | None |
| `flutter_thermal_printer` | MIT (unverified) | Verify | Review required |
| `riverpod` family | MIT | ✅ Yes | None |
| `crypto` | BSD-3-Clause | ✅ Yes | None |
| `share_plus` | BSD-3-Clause | ✅ Yes | None |

All major dependencies use permissive licenses compatible with commercial distribution. Verify `flutter_thermal_printer` license terms explicitly.

---

## 7. Known CVE Status

| Package | CVE Status | Last Checked |
|---|---|---|
| `flutter_secure_storage` | No known CVEs | 2026-07-26 |
| `drift` | No known CVEs | 2026-07-26 |
| `sqlite3_flutter_libs` | Depends on bundled SQLite version | Need to verify upstream |
| `crypto` | No known CVEs | 2026-07-26 |
| `flutter_thermal_printer` | Not tracked on NVD | Not checked |
| All other packages | No known CVEs | 2026-07-26 |

---

## 8. Dependency Audit Findings

### 🟡 DA-01 — `flutter_thermal_printer` Not Security Audited

**Severity:** Medium
**Package:** `flutter_thermal_printer ^2.0.1`
**Issue:** This third-party package receives Bluetooth and Wi-Fi socket permissions and executes in the same Dart isolate as the application. It has not been reviewed for malicious behavior, excessive data collection, or security vulnerabilities.
**Required action:** Perform a code review of the package source before Phase 8 completion. Specifically review: network connection targets, file system access patterns, any credential-adjacent code paths.

### 🟡 DA-02 — `sqlite3_flutter_libs` Bundled SQLite Version Not Verified

**Severity:** Low
**Package:** `sqlite3_flutter_libs ^0.5.28`
**Issue:** SQLite has had several memory corruption CVEs historically. The bundled SQLite version was not verified against the NVD CVE database.
**Required action:** Run `sqlite3_flutter_libs` version check and compare bundled SQLite version against known CVEs. Update if needed.

### 🟡 DA-03 — No Automated Dependency Vulnerability Scanning in CI

**Severity:** Low
**Issue:** No CI step runs `dart pub outdated`, `flutter pub audit`, or third-party SBOM tools (e.g., Trivy, OWASP Dependency-Check) against the dependency tree.
**Required action:** Add `dart pub outdated` to CI pipeline as a non-blocking informational step. Consider `flutter pub audit` when it supports pub.dev advisory database lookups.

### ✅ DA-04 — No Google Chart API Usage (Positive Finding)

The legacy Mikhmon vulnerability HIGH-04 (hotspot credentials sent to `chart.googleapis.com`) does NOT exist in DevKuroTik. `qr_flutter` generates all QR codes locally. No external service receives any credential.

### ✅ DA-05 — All Major Dependencies are Pinned via pubspec.lock

`pubspec.lock` is committed, preventing uncontrolled auto-upgrades. Dependencies can only change on explicit `flutter pub upgrade`.

---

## 9. Recommended Actions for Phase 8

| Priority | Action | Package(s) |
|---|---|---|
| 🟠 Medium | Manual security review of source code | `flutter_thermal_printer` |
| 🟡 Low | Verify bundled SQLite version vs. CVE list | `sqlite3_flutter_libs` |
| 🟡 Low | Add CI step: `dart pub outdated` | All packages |
| 🟡 Low | Generate and store SBOM (Software Bill of Materials) | All packages |
| 🟡 Low | Verify `flutter_thermal_printer` license | `flutter_thermal_printer` |
| 🟢 Info | Consider `dart pub audit` when available | All packages |

---

*DEPENDENCY_AUDIT.md — Phase 8 Pre-Assessment | DevKuroTik v0.8.0*
