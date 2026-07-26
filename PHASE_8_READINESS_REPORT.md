# PHASE_8_READINESS_REPORT.md
> DevKuroTik v0.8.0 — Pre-Phase 8 Security Readiness Assessment
> Assessor: Claude Code (read-only static analysis)
> Assessment Date: 2026-07-26
> Milestone: release/v0.8-lts

---

## FINAL VERDICT

```
╔══════════════════════════════════════════════════════╗
║                                                      ║
║   VERDICT:  PROCEED WITH CONDITIONS                  ║
║                                                      ║
║   Security Score:  52 / 100                          ║
║   Phase 8 Blockers:  2 (C-1, C-2)                    ║
║   Pre-Phase 8 Immediate Actions:  1                  ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
```

**Phase 8 CAN proceed, but requires one immediate action before the first Phase 8 commit is written, and two issues are blockers that Phase 8 implementation must resolve as its highest-priority tasks.**

---

## 1. Security Score

### Scoring Breakdown

| Category | Weight | Score | Rationale |
|---|---|---|---|
| Credential storage | 20% | 80/100 | Keystore-backed correctly; iOS hardening missing; test credentials in git |
| Transport security | 20% | 5/100 | Zero TLS; all traffic plaintext; port 8729 exists but never used |
| Logging hygiene | 15% | 75/100 | 4-layer redaction; zero print() in production; raw error object risk |
| Input validation | 15% | 65/100 | Hotspot/PPP covered; queue missing; service-layer enforcement missing |
| Session/access control | 15% | 10/100 | No biometric gate, no idle timeout, no auto-lock, no route guards |
| Destructive action safety | 10% | 90/100 | All 11 current destructive actions guarded |
| Data at rest | 5% | 50/100 | Voucher credentials plaintext in SQLite |

**Weighted total: 52 / 100**

**Compared to Mikhmon's score of 18/100, DevKuroTik is already significantly more secure. However, two critical gaps (transport security and device access control) prevent a production-ready assessment.**

---

## 2. Risk Register

### Critical Findings

| ID | Finding | Location | Severity | CVSS (approx) |
|---|---|---|---|---|
| **C-1** | Live CHR admin password hardcoded in 13 committed test files | `packages/mikrotik_sdk/test/integration_*.dart` | 🔴 CRITICAL | 9.1 |
| **C-2** | No TLS/SSL transport — all RouterOS API traffic is plaintext TCP | `mikrotik_connection.dart`, `mikrotik_credentials.dart` | 🔴 CRITICAL | 8.1 |

### High Findings

| ID | Finding | Location | Severity |
|---|---|---|---|
| **H-1** | No app-level auto-lock, idle timeout, or biometric gate | `main.dart` (missing implementation) | 🟠 HIGH |

### Medium Findings

| ID | Finding | Location | Severity |
|---|---|---|---|
| **M-1** | Voucher `{name, password}` pairs stored as plaintext JSON in SQLite | `voucher_batch_table.dart:50` | 🟠 MEDIUM |
| **M-2** | No re-authentication when app returns from background | `main.dart` (missing lifecycle observer) | 🟠 MEDIUM |
| **M-3** | `local_auth ^2.3.0` installed but biometric gate never called | `pubspec.yaml:44`, no call sites in lib/ | 🟠 MEDIUM |

### Low Findings

| ID | Finding | Location | Severity |
|---|---|---|---|
| **L-1** | iOS `iOSOptions` not set — potential iCloud Keychain sync of router passwords | `router_providers.dart:30` | 🟡 LOW |
| **L-2** | Raw `error` objects passed unredacted to `_logger.warning()` | `mikrotik_logger.dart:67` | 🟡 LOW |
| **L-3** | IPv4 validation accepts invalid octets (e.g. `999.x.x.x`) | `ppp_models.dart:551` | 🟡 LOW |
| **L-4** | `callerId` field has no validation | `ppp_models.dart:523` | 🟡 LOW |
| **L-5** | UI widget directly accesses `flutter_secure_storage` | `generate_voucher_screen.dart:62` | 🟡 LOW |
| **L-6** | Router IP embedded in QR code URLs in PDF exports | `voucher_render_service.dart:386` | 🟡 LOW |
| **L-7** | Command-response timeout hardcoded at 10s | `mikrotik_connection.dart:269` | 🟡 LOW |

### Dependency Findings

| ID | Finding | Severity |
|---|---|---|
| **DA-01** | `flutter_thermal_printer ^2.0.1` not security audited | 🟡 MEDIUM |
| **DA-02** | `sqlite3_flutter_libs` bundled SQLite version not verified | 🟡 LOW |
| **DA-03** | No automated dependency vulnerability scanning in CI | 🟡 LOW |

---

## 3. Pre-Phase 8 Immediate Actions (Before First Commit)

These actions must be taken NOW — not as part of Phase 8 implementation — because C-1 represents a live credential exposure that is not mitigated by any planned Phase 8 work.

### 🔴 IMMEDIATE ACTION: Rotate CHR Credentials (C-1)

**The admin password `[REDACTED — rotated via SECURITY_HOTFIX_001]` for CHR v7 (54.147.121.92:8728) and CHR v6 (139.162.35.252:8728) is committed in git history across 13 test files.**

This is a violation of CLAUDE.md §12:
> *"Credentials must come from `chr.txt`/`chr6.txt` — never hardcoded in committed files."*

**Steps required immediately:**
1. Log into CHR v7 (AWS EC2) → change admin password
2. Log into CHR v6 (Linode) → change admin password
3. Update `chr.txt` and `chr6.txt` with new passwords
4. Do NOT rewrite git history if the repo is private — the routers are under your control and password rotation is faster
5. If the repo is or will be made public: use `git filter-repo` or BFG Repo Cleaner before any public exposure

**The CHR instances remain alive and operational. The risk is:**
- Anyone with repo access has had access to the CHR admin credentials
- Network-adjacent attackers who observed TCP traffic on port 8728 also have credentials

---

## 4. Phase 8 Blockers

Phase 8 implementation work is BLOCKED by or must resolve these two issues as first priority:

### Blocker 1 — C-1: Integration Test Credential Security

**Current state:** 13 integration test files contain `const _password = '[REDACTED — rotated via SECURITY_HOTFIX_001]'`.

**Required resolution:**
```dart
// WRONG (current — must fix):
const _password = '[REDACTED — rotated via SECURITY_HOTFIX_001]';

// CORRECT (Phase 8 target):
final _password = () {
  try {
    return File('/root/app/chr.txt')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('Password:'))
        .split(':')[1].trim();
  } catch (_) {
    return Platform.environment['CHR_PASSWORD'] ?? '';
  }
}();
```

All 13 integration test files must be updated. This is a non-negotiable prerequisite for any beta or production deployment.

**Estimated effort:** 2 hours

---

### Blocker 2 — C-2: TLS Transport Implementation

**Current state:** `useSsl = false` hardcoded. `SecureSocket` never used. All API traffic is plaintext TCP.

**Required resolution:**

In `mikrotik_connection.dart`, add a branch:
```dart
// Conceptual — for assessment purposes
if (_credentials.useSsl) {
  _socket = await SecureSocket.connect(
    host, _credentials.sslPort,
    onBadCertificate: (_) => true,  // self-signed cert tolerance for RouterOS
    timeout: _credentials.connectTimeout,
  );
} else {
  _socket = await Socket.connect(host, port, timeout: timeout);
}
```

This requires:
1. `MikrotikCredentials` to expose `useSsl` as configurable parameter
2. `MikrotikConnection` to branch on `useSsl`
3. Live integration tests on port 8729 against CHR v7 and CHR v6
4. Documentation of self-signed cert policy

**Note:** RouterOS uses self-signed certificates by default. The `onBadCertificate: (_) => true` policy is acceptable for a private network management tool where the user explicitly configures the router IP. Optional certificate pinning can be added as Phase 8 extension work.

**Estimated effort:** 1–2 days (SDK change + testing)

---

## 5. High-Risk Findings for Phase 8

### H-1 — App-Level Access Control (Biometric / Auto-Lock)

**Required for Phase 8 completion per PHASE_8.md §6 AC-5:**
> *"Local authentication and idle timeout policy are enforced where required by roadmap."*

**What must be built:**

1. **`AppLockNotifier`** (Riverpod notifier) — tracks locked/unlocked state
2. **`WidgetsBindingObserver`** in `main.dart` — detects lifecycle state changes
3. **Biometric gate** using `local_auth` — on launch and on resume after timeout
4. **`go_router` redirect** — bounces unauthenticated routes to lock screen
5. **Per-router `idle_to` configuration** — the Drift schema already has this column

**Settings required:**
- Global: biometric lock enabled/disabled
- Global: idle timeout duration (e.g., 1 min, 5 min, 15 min, never)
- Per-router: override idle_to from router config

**Estimated effort:** 3–5 days

---

## 6. Medium-Risk Findings for Phase 8

### M-1 — Voucher Credential Encryption

**These are hotspot product credentials — the commercial product of ISP operators.** On a rooted device or via ADB backup, an attacker can extract the entire historical voucher corpus.

**Recommended approach:**
1. Generate a per-device AES-256 key stored in `flutter_secure_storage`
2. Encrypt `voucherListJson` before writing to Drift
3. Decrypt on read

OR use `SQLCipher` via `drift_sqflite` with an encrypted database — broader protection but requires migration.

**Estimated effort:** 2–3 days (encryption approach); 3–5 days (SQLCipher migration)

### M-2 / M-3 — Session Lifecycle + local_auth

Covered by H-1 implementation (same feature).

---

## 7. Recommended Mitigations (Full Phase 8 Scope)

### Priority Order

| Priority | Finding | Mitigation | Effort |
|---|---|---|---|
| **P0 — Immediate** | C-1: CHR credentials in git | Rotate passwords, update test files to read from chr.txt | 2h |
| **P1 — Critical** | C-2: No TLS | Implement `SecureSocket` in `mikrotik_connection.dart` | 1–2d |
| **P2 — High** | H-1: No app lock | Implement biometric gate + auto-lock via `local_auth` + lifecycle | 3–5d |
| **P3 — Medium** | M-1: Voucher plaintext | Encrypt `voucherListJson` with Keystore-derived key | 2–3d |
| **P4 — Medium** | DA-01: Unaudited dep | Audit `flutter_thermal_printer` source code | 1d |
| **P5 — Low** | L-1: iOS Keychain | Set `iOSOptions` in `router_providers.dart` | 1h |
| **P6 — Low** | L-2: Error redaction | Sanitize `error` before `_logger.warning()` | 2h |
| **P7 — Low** | L-3/L-4: Validation gaps | Fix IPv4 octet check; add callerId validation | 2h |
| **P8 — Low** | 7.2: allowBackup | Verify/set `android:allowBackup="false"` | 1h |
| **P9 — Low** | 8.1: Screenshot | Set `FLAG_SECURE` on Android activity | 1h |
| **P10 — Low** | 8.3: Obfuscation | Verify `--obfuscate` in build scripts | 1h |
| **P11 — Low** | DA-02: SQLite CVE | Verify bundled SQLite version | 1h |
| **P12 — Low** | DA-03: CI scanning | Add `dart pub outdated` to CI | 2h |

---

## 8. Estimated Phase 8 Implementation Effort

| Work Stream | Days |
|---|---|
| TLS implementation (C-2) + integration tests | 2 |
| Biometric lock + auto-lock + route guards (H-1) | 4 |
| Voucher encryption at rest (M-1) | 2 |
| Credential test file remediation (C-1) | 0.5 |
| Input validation hardening (L-3, L-4) | 0.5 |
| Platform hardening (L-1, 7.2, 8.1, 8.3) | 1 |
| Logging fix (L-2) | 0.5 |
| Dependency audit + SBOM (DA-01, DA-02, DA-03) | 1.5 |
| Security regression tests | 2 |
| Release security checklist execution | 1 |
| Documentation (deliverables 11, 12, 13 from PHASE_8.md) | 1 |
| **Total estimate** | **~16 days (3.2 weeks)** |

This aligns with PHASE_8.md §11 "Realistic: 2 weeks" estimate, on the slightly longer end given the scope of biometric + TLS work.

---

## 9. What IS Correctly Implemented (Positive Findings)

These security properties are correctly implemented and do not require Phase 8 remediation:

| Property | Status | Evidence |
|---|---|---|
| Router passwords in Android Keystore | ✅ | `router_providers.dart`, `router_repository.dart` |
| No password column in Drift schema | ✅ | `router_table.dart` schema |
| Per-call credential retrieval (not cached in state) | ✅ | `getPassword()` call pattern in all service files |
| 4-layer credential redaction in SDK logs | ✅ | `mikrotik_logger.dart` |
| Zero `print()`/`debugPrint()` in production lib/ | ✅ | Full lib/ search |
| `MikrotikCredentials.toString()` redacts password | ✅ | `mikrotik_credentials.dart` |
| Auth failures not retried (no amplification) | ✅ | `retry_policy.dart:83` |
| All 11 destructive actions have confirmation dialogs | ✅ | All screens audited |
| Local QR generation (no Google Chart API) | ✅ | `qr_flutter` call sites |
| Temporary PDF files in app-private cache | ✅ | `print_service.dart` |
| No router admin credentials in PDF exports | ✅ | PDF render code |

**The credential isolation architecture is correctly designed and implemented.** Phase 8 strengthens existing controls and adds missing layers — it does not need to redesign what is already correct.

---

## 10. Assumptions and Limitations of This Assessment

This assessment is based on **static code analysis only**. The following could not be validated without runtime testing:

| Assumption | Confidence | Risk if Wrong |
|---|---|---|
| `flutter_secure_storage` correctly uses hardware Keystore on all tested devices | High | Key extraction on software-backed devices |
| No credential appears in `adb logcat` during normal operation | Medium | Should be verified on physical device |
| `android:allowBackup` default in the compiled manifest | Medium | Verify in generated `AndroidManifest.xml` |
| Temporary PDF files are cleaned up by OS lifecycle | Medium | Could accumulate in cache directory |
| `flutter_thermal_printer` does not exfiltrate data | Unknown | Supply-chain risk if malicious update |

---

## 11. Phase 8 Definition of Done Prerequisites

Phase 8 cannot be marked Done until all of the following are true:

| # | Requirement |
|---|---|
| 1 | C-1 resolved: CHR credentials rotated AND test files read from `chr.txt`/`chr6.txt` |
| 2 | C-2 resolved: TLS transport implemented and validated on CHR v7 + v6 |
| 3 | H-1 resolved: biometric gate, auto-lock, and idle timeout implemented |
| 4 | M-1 resolved: voucher credentials encrypted at rest |
| 5 | Security checklist (`SECURITY_CHECKLIST.md`) Section 1–9 all ✅ |
| 6 | Security regression tests (`SECURITY_CHECKLIST.md` Section 10) all ✅ |
| 7 | Release security checklist (`SECURITY_CHECKLIST.md` Part II) completed |
| 8 | Full test suite: 0 failures |
| 9 | `flutter analyze --fatal-infos`: No issues |
| 10 | CHR v7 + v6 live integration tests pass with new passwords |
| 11 | `PHASE_8_COMPLETION_REPORT.md` written and signed |

---

## 12. Comparison to Mikhmon Legacy (Security Progress)

| Category | Mikhmon v3 | DevKuroTik v0.8.0 | DevKuroTik after Phase 8 (target) |
|---|---|---|---|
| Credential storage | XOR cipher / hardcoded | Keystore | Keystore + iOS hardening |
| Transport | HTTP + cleartext API | Cleartext API | TLS API (port 8729) |
| Authentication | Default credentials | Per-user password | Biometric + idle lock |
| Logging | Credentials in HTML/logs | 4-layer redaction | Full redaction + runtime test |
| Input validation | None | Partial (forms) | Service-layer enforcement |
| Destructive actions | No confirmation (CSRF) | All confirmed | Audit log added |
| Data at rest | PHP flat files | SQLite (partial encrypt) | Encrypted at rest |
| **Overall score** | **18/100** | **52/100** | **Target: 82/100** |

DevKuroTik at v0.8.0 already scores 2.9× better than Mikhmon. After Phase 8, the target is 82/100 — which qualifies as production-secure for an internal network management tool.

---

## Summary

DevKuroTik v0.8.0 is ready to enter Phase 8 security hardening. The credential storage architecture, logging redaction, and destructive action protections are correctly implemented. Two critical gaps — transport security (no TLS) and device access control (no biometric lock) — are the primary Phase 8 objectives. One immediate pre-Phase-8 action is required: rotate the CHR admin passwords exposed in git history.

**Verdict: PROCEED WITH CONDITIONS**

Condition 1 (pre-Phase 8, immediate): Rotate CHR v7 and CHR v6 admin passwords.
Condition 2 (Phase 8 P1): Implement TLS transport (C-2).
Condition 3 (Phase 8 P2): Implement biometric lock + auto-lock (H-1).

---

## References

- `THREAT_MODEL.md` — Full threat analysis
- `SECURITY_ARCHITECTURE.md` — Architecture inventory
- `ATTACK_SURFACE.md` — Surface analysis
- `DEPENDENCY_AUDIT.md` — Dependency review
- `SECURITY_CHECKLIST.md` — Implementation and release gates
- `audit/SECURITY_REPORT.md` — Legacy Mikhmon security audit
- `audit/PHASE_8.md` — Phase 8 specification
- `ARCHITECTURE.md` — Approved technology baseline
- `CLAUDE.md` §12 — Real Router Test Environment security rules

---

*PHASE_8_READINESS_REPORT.md — DevKuroTik v0.8.0 | Generated 2026-07-26*
