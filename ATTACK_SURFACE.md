# ATTACK_SURFACE.md
> DevKuroTik v0.8.0 — Attack Surface Analysis
> Date: 2026-07-26
> Status: READ-ONLY assessment. No code was modified.

---

## 1. Overview

The attack surface of DevKuroTik v0.8.0 has four primary exposure areas:

1. **Physical device** — phone access with or without screen lock bypass
2. **Local storage** — Drift SQLite + `flutter_secure_storage`
3. **Network transport** — plaintext TCP to RouterOS port 8728
4. **App process** — memory, logs, exports, shared files

---

## 2. Surface Map

```
Attack Surface Components
├── A. Network Transport (HIGHEST RISK)
│   ├── TCP port 8728 — plaintext API
│   ├── MikroTik binary protocol — credentials in cleartext
│   └── No TLS, no cert verification
│
├── B. Local Storage
│   ├── flutter_secure_storage — router admin passwords
│   │   └── Android Keystore backed (strong protection)
│   ├── Drift SQLite (devkurotik.db)
│   │   ├── routers table — IP, hostname, username (not encrypted)
│   │   └── voucher_batches — voucher {name, password} plaintext JSON
│   └── Temporary files — /data/data/.../cache/ (PDF exports)
│
├── C. App Entry Points
│   ├── App launch — no authentication gate
│   ├── All routes — no auth redirect
│   ├── App resume from background — no re-auth
│   └── Deeplinks — go_router (no untrusted deeplinks currently)
│
├── D. Data Input Points
│   ├── Add/Edit Hotspot User form — validated
│   ├── Add/Edit PPP Secret form — validated (partial)
│   ├── Add/Edit Router form — validated
│   ├── Add Profile form — validated (Phase 6)
│   ├── Queue operations — no input validation
│   └── Search/filter fields — client-side only, no injection risk
│
├── E. Data Output Points
│   ├── Voucher PDF generation — plaintext credentials
│   ├── Share via OS share sheet — target uncontrolled
│   ├── QR codes in PDF — contains router IP + voucher credentials
│   └── Thermal printer (BT/Wi-Fi) — plaintext data over BT
│
├── F. External Dependencies
│   ├── flutter_thermal_printer ^2.0.1 — Bluetooth/Wi-Fi access, not audited
│   ├── share_plus — OS-level file sharing
│   ├── local_auth ^2.3.0 — installed, not active
│   └── pub.dev supply chain — no CVE monitoring
│
└── G. Development/Test Surface
    └── 13 integration test files — live CHR credentials hardcoded
```

---

## 3. Entry Point Analysis

### A. Network Transport

| Entry Point | Exposure | Controls |
|---|---|---|
| TCP port 8728 (RouterOS API) | 🔴 CRITICAL — credentials in cleartext | None currently |
| TCP port 8729 (SSL API) | Not used | — |
| Connection errors | Low — error messages sanitized | `RouterosConnectionException` redacted |

**Active attack path:** Any device on the same LAN as the MikroTik router can passively capture the admin username and password from a TCP dump of port 8728 traffic. This requires no special privilege — only network adjacency.

---

### B. Local Storage

| Storage Component | Attack Requires | Protected Fields | Unprotected Fields |
|---|---|---|---|
| `flutter_secure_storage` | Hardware Keystore access (root + bypass) or device-bound key export | Router admin passwords | — |
| Drift `routers` table | App sandbox access (root or ADB backup) | — | IP, hostname, username |
| Drift `voucher_batches` | App sandbox access (root or ADB backup) | — | Voucher `{name, password}` JSON |
| PDF cache files | App sandbox access | — | Voucher names+passwords |

---

### C. App Entry Points

| Entry Point | Unauthenticated Access? | Notes |
|---|---|---|
| App launch | ✅ Yes — no gate | Anyone with unlocked phone |
| All routes | ✅ Yes — no redirect | All screens reachable without auth |
| App resume | ✅ Yes — no re-auth | Background → foreground, no lock |
| Android recent-apps | ✅ Yes — app screenshot visible | No `FLAG_SECURE` set |

---

### D. Input Attack Surface

| Input Field | Validation | Reaches RouterOS API? | Injection Risk |
|---|---|---|---|
| Hotspot username | ✅ Allowlist regex | Yes (name param) | Low — allowlisted |
| Hotspot password | ✅ Length check | Yes | None |
| PPP secret name | ✅ Allowlist regex | Yes | Low |
| PPP callerId | ❌ None | Yes | Theoretical — protocol encoding mitigates |
| Queue target | ❌ None | Yes | Low — RouterOS validates server-side |
| Search fields | N/A — client-side only | No | None |
| Router host/IP | ✅ Non-empty check | Becomes TCP destination | Low |

**RouterOS API injection note:** The MikroTik binary API uses length-prefixed words. Unlike HTTP, there is no delimiter-injection risk from special characters in field values. RouterOS performs its own validation server-side. The primary validation value is user experience (clear error messages) rather than injection prevention.

---

### E. Output Attack Surface

| Output Path | Contains Credentials? | Accessible To? | Controls |
|---|---|---|---|
| Voucher PDF | Yes — product {name, pass} + QR URLs | Anyone the user shares with | None — by design |
| QR code in PDF | Yes — router IP in URL | Anyone who scans | None — by design |
| Thermal print | Yes — voucher data | Printer network | Bluetooth pairing / Wi-Fi access |
| Share sheet | Depends on target | OS-controlled target selection | OS dialog |
| ADB logcat | No (in production) | Developer with USB access | Log consumer opt-in |

---

### F. Dependency Attack Surface

| Package | Access Granted | Audit Status | Risk |
|---|---|---|---|
| `flutter_secure_storage` | Android Keystore R/W | Well-audited, widely used | Low |
| `local_auth` | Biometric hardware | Well-audited, Flutter team | Low (not active) |
| `flutter_thermal_printer` | Bluetooth + Wi-Fi sockets | **NOT AUDITED** | Medium |
| `share_plus` | File system + OS share | Well-audited, Fluttercommunity | Low |
| `drift` | SQLite R/W | Well-audited | Low |
| `crypto` | MD5 hash only | Official Dart team | Low |
| `pdf` + `printing` | File system + print subsystem | Commonly used, not security-critical | Low |

**`flutter_thermal_printer ^2.0.1`** is the only third-party package with network/Bluetooth access that has not been reviewed for security posture. In a worst-case supply-chain scenario, a compromised version could read `flutter_secure_storage` from the same process context.

---

### G. Development/Test Surface

| Component | Severity | Finding |
|---|---|---|
| 13 integration test `.dart` files | 🔴 CRITICAL | Live CHR admin password `Ssh19233@` hardcoded and committed to git |
| `chr.txt` / `chr6.txt` | ✅ Not committed | Correctly gitignored |
| Test fixtures | ✅ Safe | No real credentials |

The hardcoded password is in committed git history for:
- `packages/mikrotik_sdk/test/integration_chr_test.dart`
- `packages/mikrotik_sdk/test/integration_chr_v6_test.dart`
- `packages/mikrotik_sdk/test/integration_dashboard_v7_test.dart`
- `packages/mikrotik_sdk/test/integration_dashboard_v6_test.dart`
- `packages/mikrotik_sdk/test/integration_hotspot_v6_test.dart`
- `packages/mikrotik_sdk/test/integration_hotspot_v7_test.dart`
- `packages/mikrotik_sdk/test/integration_ppp_v6_test.dart`
- `packages/mikrotik_sdk/test/integration_ppp_v7_test.dart`
- `packages/mikrotik_sdk/test/integration_compat_test.dart`
- `packages/mikrotik_sdk/test/integration_profile_v6_test.dart`
- `packages/mikrotik_sdk/test/integration_profile_v7_test.dart`
- `packages/mikrotik_sdk/test/integration_voucher_v6_test.dart`
- `packages/mikrotik_sdk/test/integration_voucher_v7_test.dart`

Any user who clones the public or private repository and runs these tests has full admin access to both CHR instances.

---

## 4. Attack Surface Reduction Opportunities (Phase 8)

| Reduction | Addresses | Priority |
|---|---|---|
| Enable TLS (port 8729) | T-03 MitM, network credential exposure | 🔴 Critical |
| Implement biometric/PIN gate | T-01 stolen phone, T-09 screenshot | 🟠 High |
| Implement idle auto-lock | T-01 unlocked phone, T-13 multi-router | 🟠 High |
| Encrypt `voucherListJson` | T-05 SQLite theft, T-07 backup | 🟠 Medium |
| Rotate CHR passwords + read from file | T-04 credential leakage | 🔴 Immediate |
| Audit `flutter_thermal_printer` | T-10 supply chain | 🟡 Medium |
| Set `android:allowBackup="false"` | T-07 backup compromise | 🟡 Medium |
| Set iOS `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | T-07 iCloud sync | 🟡 Low |
| Add root/jailbreak detection | T-02 rooted device | 🟡 Optional |
| Set `FLAG_SECURE` | T-09 screenshot | 🟡 Low |
| Add `obfuscate` to release builds | T-08 memory inspection | 🟢 Low |
| Add SBOM generation | T-10 T-11 supply chain | 🟡 Medium |

---

*ATTACK_SURFACE.md — Phase 8 Pre-Assessment | DevKuroTik v0.8.0*
