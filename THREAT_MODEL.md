# THREAT_MODEL.md
> DevKuroTik v0.8.0 — Pre-Phase 8 Threat Model
> Scope: Mobile app (Android-primary) + MikroTik RouterOS API communication
> Date: 2026-07-26
> Status: READ-ONLY assessment. No code was modified.

---

## 1. Asset Inventory

| Asset | Location | Classification | Phase Owner |
|---|---|---|---|
| Router admin password | `flutter_secure_storage` | 🔴 Critical secret | Phase 2 |
| Router IP/hostname | Drift `routers` table | 🟠 Sensitive | Phase 2 |
| Router username | Drift `routers` table | 🟠 Sensitive | Phase 2 |
| Voucher credentials (name+pass pairs) | Drift `voucher_batch_table` | 🟡 Product data | Phase 5 |
| PPP secret credentials | RouterOS only (not cached locally) | 🟠 Sensitive | Phase 7 |
| Hotspot user credentials | RouterOS only (not cached locally) | 🟠 Sensitive | Phase 4 |
| On-login RouterScript | RouterOS only | 🟡 Configuration | Phase 6 |
| Sales records | RouterOS `/system/script` | 🟡 Business data | Future |
| App settings | Drift (non-sensitive) | 🟢 Low | Phase 2 |

---

## 2. Threat Actors

| Actor | Capability | Motivation | Likelihood |
|---|---|---|---|
| **Opportunistic phone thief** | Physical device access after unlock | Financial (router control, network abuse) | HIGH |
| **Targeted attacker (enterprise)** | MitM on managed network | Router credential theft, config manipulation | MEDIUM |
| **Compromised dependency** | Code execution in app process | Credential exfiltration, data theft | LOW–MEDIUM |
| **Rooted device owner** | Full filesystem + memory access | Credential extraction, debugging, data mining | MEDIUM |
| **Network-adjacent eavesdropper** | Passive TCP capture | Router credential harvest via plaintext API | HIGH (if on same LAN) |
| **Disgruntled employee / insider** | Legitimate app access, physical device access | Mass-delete hotspot users, reboot router | MEDIUM |
| **Backup restore attacker** | ADB backup or cloud restore of SQLite file | Voucher corpus theft | LOW |

---

## 3. Threat Scenarios

---

### T-01 — Lost or Stolen Phone

**Category:** Physical device theft
**Asset at risk:** Router admin passwords (flutter_secure_storage), voucher corpus (SQLite plaintext), PPP/hotspot data access

**Attack path:**
```
Phone stolen → Screen lock bypassed (biometric capture/PIN shoulder-surf) 
→ App opened → All routers listed → Admin password retrieved from Keystore 
→ Attacker connects to MikroTik → Full network control
```

**Secondary attack (no screen unlock required on rooted device):**
```
Phone stolen → USB debug enabled → ADB backup → SQLite extracted 
→ devkurotik.db opened → Router IPs, usernames, voucher credentials in plaintext
```

**Current controls:**
- ✅ Android Keystore protects router passwords (requires screen unlock)
- ✅ Drift DB is sandboxed to app process (on unrooted device)
- ❌ No auto-lock / biometric gate on app open
- ❌ Voucher credentials stored as plaintext JSON in SQLite
- ❌ No idle timeout to re-lock after inactivity

**Residual risk:** HIGH — phone theft is the primary risk for field ISP operators

---

### T-02 — Rooted or Jailbroken Device

**Category:** Device compromise
**Asset at risk:** All local data including flutter_secure_storage keys

**Attack path:**
```
App installed on rooted Android → Attacker (or malware) with root access 
→ Read /data/data/com.devkurotik.app/ → SQLite: voucher corpus, router metadata 
→ Read EncryptedSharedPreferences (requires Keymaster key, but root may bypass on some devices)
→ Optionally: ptrace app process → read in-memory decrypted password
```

**Note on Android Keystore:** Hardware-backed Keystore (StrongBox) on modern devices (Android 9+, Pixel 3+) is resistant to software root extraction. Older devices using software-backed keys are vulnerable to root-level extraction.

**Current controls:**
- ✅ `encryptedSharedPreferences: true` with Android Keystore backing
- ❌ No root/jailbreak detection
- ❌ No SafetyNet/Play Integrity attestation
- ❌ Voucher credentials in unencrypted SQLite (directly readable by root)

**Residual risk:** MEDIUM — hardware Keystore provides meaningful protection for router passwords; voucher DB is a weaker point

---

### T-03 — Man-in-the-Middle (MitM)

**Category:** Network interception
**Asset at risk:** Router admin password, all RouterOS API commands and responses

**Attack path:**
```
Attacker on same LAN as device (Wi-Fi hotspot operator environment)
→ ARP spoof / rogue AP → Intercept TCP stream to RouterOS port 8728
→ Capture complete MikroTik binary API session
→ Extract admin password from /login response sequence
→ Replay credentials → Full router access
```

**Current controls:**
- ❌ **No TLS/SSL transport** — `useSsl = false` hardcoded, `SecureSocket.connect()` never used
- ❌ No certificate pinning
- ❌ No network-level integrity verification
- ✅ SDK redacts passwords from local log output (does NOT protect network traffic)

**Residual risk:** CRITICAL — all API traffic including authentication is observable on-path. RouterOS API port 8728 is unencrypted by design; port 8729 (SSL API) exists on all RouterOS ≥6.49 and is not used.

---

### T-04 — Credential Leakage via Logs or Error Output

**Category:** Information disclosure
**Asset at risk:** Router admin password, API session data

**Attack path:**
```
Exception during API connection → Error message logged to crash reporter 
→ Password visible in log aggregator / adb logcat output
```

**Current controls:**
- ✅ Four-layer redaction in `MikrotikLogger` (pattern-based, covers `=password=VALUE`)
- ✅ `MikrotikCredentials.toString()` omits password
- ✅ Zero `print()`/`debugPrint()` in production lib/ code
- ⚠️ Raw `error` objects passed to logger warning — edge-case leakage possible (L-2)
- 🔴 Router admin password hardcoded in 13 integration test files committed to git (C-1)

**Residual risk:** LOW in production runtime; CRITICAL in git history (CHR credentials already exposed)

---

### T-05 — SQLite Database Theft

**Category:** Data-at-rest compromise
**Asset at risk:** Router metadata, voucher credentials (plaintext JSON)

**Attack path A (rooted device):**
```
Root access → copy /data/data/com.devkurotik.app/databases/devkurotik.db 
→ Open with SQLite viewer → Read voucher_batch_table.voucher_list_json
→ 100–500 hotspot product credentials in cleartext
```

**Attack path B (ADB backup, if enabled):**
```
USB access → adb backup com.devkurotik.app → extract .ab file 
→ java -jar abe.jar unpack backup.ab → SQLite readable without root
```

**Current controls:**
- ✅ Router admin password NOT in SQLite (in Keystore only)
- ✅ Drift DB sandboxed on unrooted device
- ❌ No SQLite encryption (`sqlcipher` not used)
- ❌ Voucher `{name, password}` pairs stored as plaintext JSON
- ❌ `android:allowBackup` in `AndroidManifest.xml` — not verified, default is `true` in Flutter apps

**Residual risk:** MEDIUM — router passwords protected, but voucher corpus is exposed on root/ADB-backup

---

### T-06 — Export (PDF/Share) Data Theft

**Category:** Data exfiltration via shared file
**Asset at risk:** Voucher credentials, router topology (IP in QR codes)

**Attack path:**
```
Operator shares voucher PDF batch via WhatsApp/email
→ PDF contains QR codes with http://<router_ip>/login?user=X&password=Y
→ Recipient or interceptor scans QR → Has both router IP and product credentials
→ Simultaneously: voucher name+password pairs readable as plaintext in PDF
```

**Current controls:**
- ✅ Router admin password never in PDF
- ✅ PDF written to app-private cache (not external storage)
- ✅ `Share.shareXFiles()` OS dialog — user controls target
- ❌ Router IP/hostname embedded in QR login URLs (by design, but operational risk)
- ❌ No PDF password protection option
- ❌ No watermarking / tracking of shared PDFs

**Residual risk:** LOW — this is intentional product behavior (QR = login URL); risk is operational not technical

---

### T-07 — Backup Compromise

**Category:** Data recovery attack
**Asset at risk:** Entire app data including SQLite

**Attack path:**
```
Android cloud backup (Google One) or ADB backup captures devkurotik.db
→ Backup transferred to attacker-controlled device
→ App restored → SQLite accessible → Voucher corpus visible
```

**Note:** `flutter_secure_storage` keys are typically NOT transferred in backup (hardware-bound on most Android devices). Router passwords survive only if the backup includes the encrypted Keystore, which requires the same device or a full device-encrypted cloud backup.

**Current controls:**
- ✅ Keystore keys typically hardware-bound (non-transferable)
- ❌ SQLite not encrypted — voucher corpus in backup
- ❌ No `android:allowBackup="false"` confirmed in manifest

**Residual risk:** MEDIUM for voucher data; LOW for router passwords

---

### T-08 — Memory Inspection

**Category:** Runtime memory attack
**Asset at risk:** Admin password while in transit, decrypted voucher data in memory

**Attack path:**
```
Malware on device with memory access (root or debug build)
→ Attach to devkurotik process → Scan memory for password strings
→ Capture admin password during active connection window
```

**Attack window:** Password is in Dart heap from `getPassword()` call until `MikrotikClient` uses it. Duration: ~100ms–2s per operation. Not persistently in memory.

**Current controls:**
- ✅ Password retrieved on-demand per API call (not cached in state)
- ✅ No persistent Riverpod state holding password
- ❌ No `String.zero()` clearing after use (Dart does not expose memory zeroing)
- ❌ No obfuscation on release builds (not configured, `--obfuscate` not in build scripts)

**Residual risk:** LOW — short exposure window; requires active exploit on device; standard for mobile apps

---

### T-09 — Screenshot Leakage

**Category:** Sensitive UI disclosure
**Asset at risk:** Visible router credentials in UI, PPP/hotspot user data

**Attack path:**
```
Recent apps screenshot (Android system default)
→ Screenshot contains router management screen with IP/username visible
→ Attacker with screen access / malware reading recent-apps screenshots 
→ Captures router network topology
```

**Note:** Router admin password is not shown in any current UI screen (intentionally hidden in all form inputs). The risk is topology disclosure (IP addresses, usernames), not password disclosure.

**Current controls:**
- ✅ Password fields use `obscureText: true`
- ❌ No `FLAG_SECURE` / `WindowManager.FLAG_SECURE` to prevent screenshots
- ❌ Recent apps preview shows app content unobscured

**Residual risk:** LOW — no passwords visible; topology metadata is the concern

---

### T-10 — Supply-Chain Attack

**Category:** Dependency compromise
**Asset at risk:** Entire app runtime

**Attack path:**
```
Malicious update to flutter_thermal_printer or other third-party package 
→ Injected code executes in app context → Reads flutter_secure_storage 
→ Exfiltrates router admin credentials to attacker C2
```

**Highest-risk packages (third-party, less audited):**
- `flutter_thermal_printer ^2.0.1` — Bluetooth/Wi-Fi printer; not audited
- `share_plus` — system-level share APIs
- `local_auth ^2.3.0` — biometric hardware access

**Current controls:**
- ✅ `pubspec.lock` pinned — no auto-upgrade
- ❌ No `pub.dev` integrity verification beyond semver range
- ❌ No SBOM (Software Bill of Materials) generated
- ❌ `flutter_thermal_printer` not security-audited

**Residual risk:** MEDIUM — industry-standard pub.dev trust model; specific concern for `flutter_thermal_printer`

---

### T-11 — Dependency Compromise (Runtime)

**Category:** Compromised existing dependency
**Asset at risk:** Transport security, credential handling

**Current controls:**
- ✅ All direct dependencies come from pub.dev (no git/path deps in production)
- ✅ `crypto` (MD5 auth) is official Dart team package
- ✅ `drift` (SQLite ORM) is well-maintained community package
- ❌ No automated CVE scanning integrated in CI

**Residual risk:** LOW

---

### T-12 — Log Leakage

**Category:** Operational log exposure
**Asset at risk:** Credentials, API session data, router topology

**Attack path:**
```
Developer/support enables logging consumer 
→ Raw log output visible in adb logcat / crash reporting service 
→ Password slip through redaction edge case 
→ Credential captured in log stream
```

**Current controls:**
- ✅ Redaction patterns cover standard RouterOS API password fields
- ✅ No log consumer configured by default (opt-in)
- ✅ Auth failure exceptions sanitized at SDK boundary
- ⚠️ Raw `error` objects passed to logger (L-2) — edge-case bypass

**Residual risk:** LOW

---

### T-13 — Multi-Router Compromise

**Category:** Lateral movement
**Asset at risk:** All routers configured in the app

**Attack path:**
```
Attacker gains access to one router's admin credentials (via T-03 or T-01)
→ app stores 5+ other router configurations in same SQLite DB
→ All router IPs, usernames discoverable from Drift (no password yet)
→ If MitM on one router, monitor for connections to other IPs 
→ Password retrieved from Keystore for each router on connection attempt
```

**Secondary:** If Keystore is compromised (root), all passwords are accessible simultaneously since they share one storage namespace with predictable key format (`router_pwd_<uuid>`).

**Current controls:**
- ✅ Each router password independently keyed in Keystore
- ✅ No password cross-contamination between routers
- ❌ All router metadata (IPs, usernames) in unencrypted Drift → single-point enumeration risk
- ❌ Compromise of one router doesn't technically grant access to others, but enumeration is trivial from the DB

**Residual risk:** MEDIUM — Drift DB provides a "target list" for an attacker who compromises the device

---

## 4. Threat Summary Matrix

| Threat | Likelihood | Impact | Risk Level | Phase 8 Required? |
|---|---|---|---|---|
| T-01 Lost/Stolen Phone | HIGH | CRITICAL | 🔴 **HIGH** | Yes |
| T-02 Rooted Device | MEDIUM | HIGH | 🟠 MEDIUM-HIGH | Partial |
| T-03 MitM | HIGH | CRITICAL | 🔴 **CRITICAL** | Yes |
| T-04 Credential Log Leakage | LOW | HIGH | 🟡 LOW-MEDIUM | Partial (C-1 must rotate) |
| T-05 SQLite Theft | MEDIUM | MEDIUM | 🟠 MEDIUM | Yes (voucher encrypt) |
| T-06 Export Theft | LOW | LOW-MEDIUM | 🟢 LOW | No (by design) |
| T-07 Backup Compromise | LOW | MEDIUM | 🟡 LOW-MEDIUM | Partial |
| T-08 Memory Inspection | LOW | HIGH | 🟡 LOW-MEDIUM | No |
| T-09 Screenshot Leakage | LOW | LOW | 🟢 LOW | Partial |
| T-10 Supply-Chain Attack | LOW | CRITICAL | 🟡 MEDIUM | Yes (audit) |
| T-11 Dependency Compromise | LOW | HIGH | 🟡 LOW | Yes (SBOM) |
| T-12 Log Leakage | LOW | MEDIUM | 🟢 LOW | Partial |
| T-13 Multi-Router Compromise | MEDIUM | HIGH | 🟠 MEDIUM | Yes |

---

## 5. Trust Boundaries

```
[Device OS Keychain] ← protected by hardware or OS keystore
       ↑ getPassword()
[App Process] ← sandbox on unrooted device
       ↓ TCP Socket
[RouterOS API Port 8728] ← PLAINTEXT ← NO TRUST BOUNDARY HERE
       ↓
[MikroTik Router] ← network device
```

**Critical missing boundary:** No TLS tunnel between app and router. The gap between app process and router is the most significant unmitigated risk.

---

*THREAT_MODEL.md — Phase 8 Pre-Assessment | DevKuroTik v0.8.0*
