# SECURITY_ARCHITECTURE.md
> DevKuroTik v0.8.0 — Security Architecture Inventory
> Date: 2026-07-26
> Status: READ-ONLY assessment. No code was modified.

---

## 1. Security Architecture Overview

DevKuroTik's security architecture at v0.8.0 is **partially implemented**. The credential isolation layer (Keystore + Drift separation) is correctly designed and implemented. The transport security layer (TLS) and the device access control layer (biometric/auto-lock) are missing.

```
┌─────────────────────────────────────────────────────┐
│  DEVICE LAYER              Status                   │
│  ─────────────────────────────────────────────────  │
│  Biometric/PIN gate        ❌ NOT IMPLEMENTED        │
│  Auto-lock / idle timeout  ❌ NOT IMPLEMENTED        │
│  Root detection            ❌ NOT IMPLEMENTED        │
│  Screenshot protection     ❌ NOT IMPLEMENTED        │
└─────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────┐
│  APP LAYER                 Status                   │
│  ─────────────────────────────────────────────────  │
│  Credential storage        ✅ Keystore-backed         │
│  Schema separation         ✅ No secrets in Drift     │
│  Input validation          ✅ Hotspot/PPP (partial)   │
│  Destructive confirmations ✅ All 11 covered          │
│  Route auth guards         ❌ NOT IMPLEMENTED         │
│  Session lifecycle         ❌ NOT IMPLEMENTED         │
│  Voucher data encryption   ❌ Plaintext in SQLite     │
└─────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────┐
│  SDK/TRANSPORT LAYER       Status                   │
│  ─────────────────────────────────────────────────  │
│  TLS/SSL transport         ❌ NOT IMPLEMENTED        │
│  Certificate pinning       ❌ NOT IMPLEMENTED        │
│  Log redaction             ✅ 4-layer redaction       │
│  Auth error isolation      ✅ No retry on auth fail   │
│  Connection security       ❌ Plaintext TCP only      │
└─────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────┐
│  RouterOS / NETWORK        Status                   │
│  ─────────────────────────────────────────────────  │
│  API port 8728 (plain)     Used exclusively          │
│  API port 8729 (SSL)       Documented, never used    │
│  Firewall rules            Out of app scope          │
└─────────────────────────────────────────────────────┘
```

---

## 2. Credential Storage Architecture

### Implemented Design (Correct)

```
RouterModel (Drift)          flutter_secure_storage (Android Keystore)
──────────────────           ──────────────────────────────────────────
id          TEXT            key:  "router_pwd_<id>"
name        TEXT            value: "<plaintext password>"
host        TEXT                   ↑ protected by hardware keystore
port        INT             key:  "last_used_router_id"
username    TEXT            value: "<router_id>"   (non-secret)
groupName   TEXT
note        TEXT?
──────────────────
NO password column
```

**`router_providers.dart:30–34`:**
```dart
const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  // iOSOptions not set — default behavior
)
```

**Retrieval pattern (`router_repository.dart:143`):**
```dart
Future<String?> getPassword(String routerId) =>
    _secure.read(key: '$_kPasswordPrefix$routerId');
```
Password is never held in a Riverpod provider or cached in memory between API calls.

### Gaps

| Gap | Location | Severity |
|---|---|---|
| iOS `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` not set | `router_providers.dart:30` | Low |
| No `KeyguardManager` check before Keystore access | — | Low |

---

## 3. Transport Security Architecture

### Current State (Deficient)

**`mikrotik_credentials.dart:25–37`:**
```dart
final int sslPort;    // 8729 — documented only
final bool useSsl;    // false — hardcoded

// MikrotikConnection:
final socket = await Socket.connect(host, port, timeout: timeout);
// ← plain TCP, never SecureSocket
```

### Required State (Phase 8)

```dart
// Option A: SSL API (RouterOS ≥6.49)
final socket = await SecureSocket.connect(
  host, sslPort,
  onBadCertificate: (_) => true,  // self-signed cert tolerance
  timeout: timeout,
);

// Option B: Optional pinned cert
final socket = await SecureSocket.connect(
  host, sslPort,
  context: pinnedCtx,
  timeout: timeout,
);
```

**RouterOS SSL API availability:**
- RouterOS ≥6.49: Port 8729 available — confirmed on both CHR instances
- RouterOS ≥7.x: Port 8729 available — confirmed on CHR v7

The `CapabilityMatrix` in `mikrotik_sdk` already notes SSL API support. Phase 8 must activate it.

---

## 4. Logging / Redaction Architecture

### Implemented (Correct)

All logging is routed through `MikrotikLogger` with four redaction layers:

```dart
// mikrotik_logger.dart
static String redact(String message) {
  return message
    .replaceAll(RegExp(r'=password=[^\s,)]+'), '=password=***')
    .replaceAll(RegExp(r'(?<=password=)[^\s&]+'), '***')
    .replaceAll(RegExp(r'\x00[0-9a-fA-F]{32}'), '***md5-response***')
    .replaceAll(RegExp(r'(?:response|digest|challenge|hash|md5)=[0-9a-fA-F]+'), '***=***');
}
```

Sink is the Dart `logging` package — consumer must explicitly add a `Logger.root.onRecord` listener. Production builds emit nothing by default.

**TX log path** (`mikrotik_connection.dart:264`):
```dart
if (_logger.isLoggable(Level.FINEST)) {
  _logger.finest('TX: ${MikrotikLogger.redactWords(words)}');
}
```

### Gap

`_logger.warning(message, error, stackTrace)` at line 67 passes `error` unredacted. If an exception carries a credential in its `toString()`, it would bypass the `message`-level redaction. Current exception classes (`RouterosConnectionException`, `RouterosAuthException`) do not include credentials in their messages, but the structural risk exists.

---

## 5. Input Validation Architecture

### Hotspot Domain (`hotspot_models.dart:628–703`)

All validation is in `HotspotUserValidation`:
- `validateName` — allowlist `[a-zA-Z0-9._@\-]+`, max 64
- `validatePassword` — non-empty, max 64
- `validateProfile` — non-empty
- `validateLimitUptime` — strict RouterOS time format
- `validateMacAddress` — full hex colon notation

**Validation is enforced in UI forms** (`add_hotspot_user_screen.dart`, `edit_hotspot_user_screen.dart`) via `TextFormField.validator`. The forms prevent navigation to the service call if validation fails.

**Gap:** Validation objects are callable in unit tests but not enforced at the service layer. If a service method is called programmatically (not via form), unvalidated data can reach `command()`.

### PPP Domain (`ppp_models.dart:491–561`)

- `validateName` — allowlist + max 64 ✅
- `validatePassword` — non-empty + max 64 ✅
- `validateProfile` — non-empty ✅
- `validateIpOrEmpty` — IPv4 regex (no octet range check) ⚠️
- `callerId` — no validation ⚠️

### Missing Validation Coverage

| Context | Status |
|---|---|
| Queue operations | ❌ Queue name/target not validated |
| Profile on-login generator | ✅ `ProfileScriptParams.validate()` in Phase 6 |
| Scheduler operations | ✅ `SchedulerValidator` in Phase 6 |
| Router add/edit form | ✅ `RouterRepository.validateRouterModel()` |

---

## 6. Data-at-Rest Architecture

### Drift Schema Security

| Table | Sensitive Fields | Encrypted? |
|---|---|---|
| `routers` | `host`, `username` | ❌ No (metadata only) |
| `voucher_batches` | `voucherListJson` (`{name, password}[]`) | ❌ No — plaintext JSON |
| `router_profiles` | profile config | ❌ No (non-secret) |

**`voucher_batch_table.dart:50`:**
```dart
TextColumn get voucherListJson => text()(); // [{name, password}] JSON array
```

These are hotspot product credentials — not router admin passwords — but they represent the commercial product of an ISP operator. On a rooted device or via ADB backup, the entire voucher corpus is recoverable in plaintext.

**Required Phase 8 action:** Encrypt `voucherListJson` using a key derived from `flutter_secure_storage` or use `SQLCipher` for the entire database.

---

## 7. Destructive Action Architecture

### Implemented (Complete)

All destructive UI operations require a two-step confirmation:
1. Trigger action (tap, swipe, or menu)
2. Confirm via `AlertDialog` with visually distinct red `FilledButton`

Covered: router delete, hotspot user delete, counter reset, session disconnect (hotspot + PPP), cookie remove, host remove, queue remove, PPP secret delete, voucher batch delete, Quick Print package delete.

**Not yet in UI (future phases):** router reboot, router shutdown. When implemented, Phase 8 requires confirmation dialogs.

---

## 8. App-Level Access Control Architecture

### Current State (Missing)

```dart
// main.dart — entire app launch
void main() => runApp(const ProviderScope(child: DevKuroTikApp()));
```

No `WidgetsBindingObserver`, no `AppLifecycleState` monitoring, no biometric gate, no idle timer, no `go_router redirect`.

`local_auth ^2.3.0` is installed but has zero call sites in `lib/`.

### Required Phase 8 Architecture

```dart
// Conceptual — for assessment purposes only

class AuthGuard extends ConsumerWidget {
  // Watches AppLifecycleState via WidgetsBindingObserver
  // Triggers re-auth when app returns from background after idle_timeout
  // Uses local_auth.authenticate() for biometric gate
}

// go_router redirect:
redirect: (context, state) {
  if (!ref.read(appLockProvider).isUnlocked) {
    return '/lock';
  }
  return null;
}
```

The `idle_to` (idle timeout) column already exists in the Drift `routers` table schema per `FINAL_RECOMMENDATION.md`. The per-router idle timeout infrastructure is partially designed — only the enforcement layer is missing.

---

## 9. Release Security Architecture Gaps Summary

| Layer | Component | Status | Phase 8 Action |
|---|---|---|---|
| Device | Biometric gate | ❌ Missing | Implement `local_auth` gate |
| Device | Auto-lock / idle timeout | ❌ Missing | Implement lifecycle observer |
| Device | Root detection | ❌ Missing | Optional: `flutter_jailbreak_detection` |
| Device | Screenshot protection | ❌ Missing | Set `FLAG_SECURE` on Android |
| Transport | TLS/SSL API (port 8729) | ❌ Missing | Use `SecureSocket.connect()` |
| Transport | Certificate pinning | ❌ Missing | Optional; document decision |
| App | Route auth guards | ❌ Missing | `go_router redirect` |
| App | Voucher data encryption | ❌ Missing | Encrypt `voucherListJson` |
| App | iOS Keychain hardening | ⚠️ Partial | Set `iOSOptions` |
| Credentials | CHR test passwords in git | 🔴 Violated | Rotate credentials immediately |
| Logging | Raw error object to logger | ⚠️ Risk | Redact before `.warning()` |
| Validation | IPv4 octet range check | ⚠️ Partial | Add ≤255 check |
| Validation | `callerId` field | ⚠️ Missing | Add basic validation |
| Ops | `android:allowBackup` | ❓ Unknown | Verify/set to false |
| Ops | Release build obfuscation | ❓ Unknown | Verify `--obfuscate` flag |

---

*SECURITY_ARCHITECTURE.md — Phase 8 Pre-Assessment | DevKuroTik v0.8.0*
