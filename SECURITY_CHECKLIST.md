# SECURITY_CHECKLIST.md
> DevKuroTik — Security Checklist (Phase 8 Implementation + Release Gate)
> Version: v0.8.0 baseline
> Date: 2026-07-26

---

## Part I — Phase 8 Implementation Checklist

All items in this section must be COMPLETE before Phase 8 can be marked Done.
Each item maps to an acceptance criterion in `PHASE_8.md`.

---

### Section 1 — Credential Security

| # | Control | Required Evidence | Status |
|---|---|---|---|
| 1.1 | Router admin passwords stored ONLY in `flutter_secure_storage` with `encryptedSharedPreferences: true` (Android) | Code review: no password column in Drift schema | ⬜ VERIFY |
| 1.2 | iOS `iOSOptions(accessibility: KeychainAccessibility.unlockedThisDevice)` set | `router_providers.dart` updated | ⬜ TODO |
| 1.3 | macOS `MacOsOptions(accessibility: KeychainAccessibility.unlockedThisDevice)` set | `router_providers.dart` updated | ⬜ TODO |
| 1.4 | No plaintext credential in any Drift column | Schema inspection | ✅ DONE (v0.8.0) |
| 1.5 | No plaintext credential in any debug/release log output | Run app with log consumer; search output for password patterns | ⬜ VERIFY |
| 1.6 | CHR integration test passwords read from `chr.txt`/`chr6.txt`, NOT hardcoded | All 13 integration test files updated | 🔴 BLOCKER |
| 1.7 | CHR v7 and CHR v6 admin passwords rotated | Done on both CHR instances | 🔴 IMMEDIATE |
| 1.8 | Old CHR passwords removed from git history (if repo is public) | `git filter-repo` or BFG applied + force push | 🔴 ASSESS |

---

### Section 2 — Transport Security

| # | Control | Required Evidence | Status |
|---|---|---|---|
| 2.1 | `MikrotikConnection` supports `SecureSocket.connect()` when `useSsl = true` | `mikrotik_connection.dart` code review | ⬜ TODO |
| 2.2 | `MikrotikClient` constructor exposes `useSsl` parameter (default `false` for backward compat) | Constructor signature review | ⬜ TODO |
| 2.3 | RouterOS SSL API (port 8729) validated against CHR v7 and CHR v6 | Live integration test passing on port 8729 | ⬜ TODO |
| 2.4 | Self-signed cert behavior documented: `onBadCertificate` policy explicit | Code comment + documentation | ⬜ TODO |
| 2.5 | TLS usage recommendation documented in user-facing settings | In-app help or settings screen | ⬜ TODO |
| 2.6 | Non-TLS mode still functional (backward compat with older RouterOS) | Tests on port 8728 still pass | ⬜ TODO |

---

### Section 3 — Log Redaction

| # | Control | Required Evidence | Status |
|---|---|---|---|
| 3.1 | `=password=VALUE` redacted in all log output | Unit test: verify redaction function | ✅ DONE (v0.8.0) |
| 3.2 | MD5 challenge-response bytes redacted | Unit test: redactWords with auth words | ✅ DONE (v0.8.0) |
| 3.3 | Raw `error` objects sanitized before `.warning()` call | `mikrotik_logger.dart:67` fix | ⬜ TODO |
| 3.4 | No credential visible in `adb logcat` output (release build) | Manual test with log consumer enabled | ⬜ VERIFY |
| 3.5 | Crash reporter (if integrated in Phase 9/10) configured to strip credentials | N/A until Phase 9 | N/A |

---

### Section 4 — Input Validation

| # | Control | Required Evidence | Status |
|---|---|---|---|
| 4.1 | Hotspot user name: allowlist + length | `HotspotUserValidation.validateName` | ✅ DONE (Phase 4) |
| 4.2 | Hotspot password: non-empty + length | `HotspotUserValidation.validatePassword` | ✅ DONE (Phase 4) |
| 4.3 | PPP secret name: allowlist + length | `PppSecretValidation.validateName` | ✅ DONE (Phase 7) |
| 4.4 | PPP secret password: non-empty + length | `PppSecretValidation.validatePassword` | ✅ DONE (Phase 7) |
| 4.5 | IPv4 address validation: correct octet range (≤255) | `PppSecretValidation.validateIpOrEmpty` fix | ⬜ TODO |
| 4.6 | `callerId` field basic validation (printable ASCII, no protocol chars) | `PppSecretValidation` | ⬜ TODO |
| 4.7 | Queue name/target basic validation | `SimpleQueue` create form (future) | ⬜ TODO |
| 4.8 | Router host/IP validated on add/edit | `RouterRepository.validateRouterModel()` | ✅ DONE (Phase 2) |
| 4.9 | Router port validated: range 1–65535 | `RouterRepository.validateRouterModel()` | ✅ DONE (Phase 2) |
| 4.10 | Validation enforced at service layer (not only form layer) | `PppService.addSecret` checks validation before `command()` | ⬜ TODO |

---

### Section 5 — Local Authentication & Session

| # | Control | Required Evidence | Status |
|---|---|---|---|
| 5.1 | Biometric/PIN gate on app launch (when setting enabled) | `local_auth.authenticate()` on startup | ⬜ TODO |
| 5.2 | Auto-lock when app backgrounded (after configurable timeout) | `WidgetsBindingObserver` implementation | ⬜ TODO |
| 5.3 | Re-authentication on app foreground after idle | `AppLifecycleState.resumed` handler | ⬜ TODO |
| 5.4 | `go_router` redirect to lock screen when unauthenticated | Route guard implementation | ⬜ TODO |
| 5.5 | Per-router idle timeout (`idle_to` column) respected | Provider reading `idle_to` from router config | ⬜ TODO |
| 5.6 | Biometric fallback to PIN/password | `local_auth` `biometricOnly: false` | ⬜ TODO |

---

### Section 6 — Destructive Action Protections

| # | Control | Required Evidence | Status |
|---|---|---|---|
| 6.1 | Delete router: confirmation dialog | `DeleteConfirmationDialog` | ✅ DONE |
| 6.2 | Delete hotspot user: confirmation dialog | `AlertDialog` | ✅ DONE |
| 6.3 | Reset user counters: confirmation dialog | `AlertDialog` | ✅ DONE |
| 6.4 | Disconnect hotspot session: confirmation dialog | `AlertDialog` | ✅ DONE |
| 6.5 | Disconnect PPP session: confirmation dialog | `AlertDialog` | ✅ DONE |
| 6.6 | Delete PPP secret: confirmation dialog | `AlertDialog` | ✅ DONE |
| 6.7 | Delete queue: confirmation dialog | `AlertDialog` | ✅ DONE |
| 6.8 | Delete voucher batch: confirmation dialog | `AlertDialog` (swipe) | ✅ DONE |
| 6.9 | Delete Quick Print package: confirmation dialog | `AlertDialog` (long-press) | ✅ DONE |
| 6.10 | Router reboot (future): confirmation dialog required | Phase 8/9 requirement | ⬜ FUTURE |
| 6.11 | Router shutdown (future): confirmation dialog required | Phase 8/9 requirement | ⬜ FUTURE |
| 6.12 | Local audit log of destructive actions | SQLite audit table or equivalent | ⬜ TODO |

---

### Section 7 — Local Data Security

| # | Control | Required Evidence | Status |
|---|---|---|---|
| 7.1 | Voucher credentials encrypted at rest | `voucherListJson` encrypted (AES via Keystore key) | ⬜ TODO |
| 7.2 | `android:allowBackup="false"` in AndroidManifest.xml | Manifest inspection | ⬜ VERIFY |
| 7.3 | iOS `NSAllowsArbitraryLoads` set to false (App Transport Security) | `Info.plist` inspection | ⬜ VERIFY |
| 7.4 | Temporary PDF files cleaned up after sharing | `print_service.dart` post-share cleanup | ⬜ VERIFY |
| 7.5 | No sensitive data in app logs written to disk | Confirm no file-based log sinks | ✅ (no file sink configured) |

---

### Section 8 — Platform Hardening

| # | Control | Required Evidence | Status |
|---|---|---|---|
| 8.1 | `FLAG_SECURE` set on Android activity (prevents screenshots + recent-apps preview) | `MainActivity.kt` or `FlutterActivity` extension | ⬜ TODO |
| 8.2 | Root/jailbreak detection configured (optional — document decision) | Implement or explicitly document as out-of-scope | ⬜ DECIDE |
| 8.3 | Release builds compiled with `--obfuscate --split-debug-info` | Build script or CI configuration | ⬜ VERIFY |
| 8.4 | R8/ProGuard enabled for Android release (default in Flutter) | `build.gradle` confirmation | ⬜ VERIFY |

---

### Section 9 — Dependency Security

| # | Control | Required Evidence | Status |
|---|---|---|---|
| 9.1 | `flutter_thermal_printer` source code manually reviewed | Code review report | ⬜ TODO |
| 9.2 | `sqlite3_flutter_libs` bundled SQLite version checked against CVE list | Version check + NVD lookup | ⬜ TODO |
| 9.3 | All licenses confirmed compatible with commercial distribution | License scan | ⬜ TODO |
| 9.4 | SBOM generated and stored | `cyclonedx-dart` or equivalent | ⬜ TODO |
| 9.5 | `dart pub outdated` run; results documented | CI output | ⬜ TODO |

---

### Section 10 — Security Regression Tests

| # | Test | Verification | Status |
|---|---|---|---|
| 10.1 | Credential redaction unit test: `=password=SECRET` → `=password=***` | `mikrotik_logger_test.dart` | ✅ DONE |
| 10.2 | Auth error does not expose password in exception message | Unit test on `RouterosAuthException.message` | ⬜ TODO |
| 10.3 | Integration test reads credentials from file (not hardcoded) | Verify test file structure | ⬜ TODO (C-1 fix) |
| 10.4 | Destructive actions: confirmation required before execution | Widget tests for each confirmation dialog | ✅ PARTIAL (existing tests cover 11 dialogs) |
| 10.5 | Validation rejects malformed input (name, IP, password) | Unit tests for each validator | ✅ PARTIAL |
| 10.6 | `flutter_secure_storage` not accessible without screen unlock | Device-level test | ⬜ VERIFY |
| 10.7 | TLS connection validated against CHR v7 (if implemented) | Integration test on port 8729 | ⬜ TODO |
| 10.8 | Biometric gate: app locked after timeout | Widget/integration test | ⬜ TODO |

---

## Part II — Release Security Checklist

Run before every release candidate from v0.9.5 onward.

---

### Pre-Release Gate

| # | Check | Pass Criteria |
|---|---|---|
| R-1 | No hardcoded credentials in committed files | `git grep -r 'password\s*=' packages/*/test/ \| grep -v chr.txt` returns nothing sensitive |
| R-2 | `flutter analyze --fatal-infos` — no issues | Zero issues |
| R-3 | Full test suite passes | `flutter test` — 0 failures |
| R-4 | Integration tests pass against CHR v7 | All tests green |
| R-5 | Integration tests pass against CHR v6 | All tests green |
| R-6 | `dart pub outdated` — no critical updates | Run + document results |
| R-7 | Manual smoke test: password not visible in logcat on real device | Confirm visually |
| R-8 | Manual smoke test: PDF share does not expose admin password | PDF review |
| R-9 | All destructive actions require confirmation | Widget test regression |
| R-10 | Release APK built with `--obfuscate` | Build script verification |

---

## Part III — Security Regression Checklist

Run after any change to credential handling, transport, logging, or validation code.

| # | Check | Triggers |
|---|---|---|
| SR-1 | Re-run credential redaction unit tests | Any change to `mikrotik_logger.dart` |
| SR-2 | Re-run input validation tests | Any change to model validation classes |
| SR-3 | Re-run confirmation dialog widget tests | Any change to destructive action screens |
| SR-4 | Re-verify `flutter_secure_storage` schema | Any change to `router_repository.dart` |
| SR-5 | Re-run integration tests (CHR v7 + v6) | Any change to `mikrotik_sdk` |
| SR-6 | Re-run full test suite | Any code change before merge |
| SR-7 | Re-check for new hardcoded credentials | Any new test file added |
| SR-8 | Re-audit new dependencies | Any `pubspec.yaml` change |

---

*SECURITY_CHECKLIST.md — Phase 8 Pre-Assessment | DevKuroTik v0.8.0*
