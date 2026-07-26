# FINAL RECOMMENDATION — DevKuroTik
> **Question:** Should Mikhmon v3 be migrated to Flutter as DevKuroTik?
> **Verdict:** YES — but as a **full rewrite**, not a port.

---

## 1. Is Mikhmon Suitable for Migration to Flutter?

**YES — with conditions.**

Mikhmon v3 is a well-featured, battle-tested MikroTik management tool used daily by network operators. The core business logic is sound and the feature set is valuable. However:

| Aspect | Verdict | Reason |
|--------|---------|--------|
| Direct PHP → Flutter port | ❌ Not viable | PHP sessions, flat-file config, raw HTML rendering — none portable |
| Logic extraction for rewrite | ✅ Viable | RouterOS API patterns, data formats, feature set fully auditable |
| As a specification for Flutter | ✅ Ideal | Complete feature map, all API endpoints known, all edge cases documented |
| Production PHP deployment | ❌ Not safe | 4 Critical RCE vulnerabilities — must not be exposed to untrusted networks |

**The audit has produced everything needed to build DevKuroTik from scratch:**
- All 47 RouterOS API endpoints documented
- All 119 features inventoried with migration difficulty
- All 7 SDKs designed with full method signatures
- All security vulnerabilities documented and avoided in the new design
- All undocumented behaviors reverse-engineered (on-login encoding, script-as-DB, comment dual-use)

---

## 2. Which Modules Should Be Rewritten First?

### Sprint 1 — Foundation (Week 1–2)
```
1. mikrotik_sdk          ← Everything depends on this
   - TCP binary protocol client
   - Pre/post v6.43 login
   - Connection pool
   - RouterosFormat utilities

2. Multi-router config    ← Core UX differentiator
   - SQLite routers table
   - flutter_secure_storage for credentials
   - Router profile cards
```

### Sprint 2 — Core Revenue Feature (Week 3–5)
```
3. Hotspot user management
   - List / filter / detail
   - Add / edit / delete (with cascades)
   - Enable / disable / reset counters

4. User profile management + OnLoginScriptGenerator
   - This is the hardest single component — do it early
   - All 5 expiry modes + RouterScript generation
   - Background sweep scheduler lifecycle
```

### Sprint 3 — Revenue Generation (Week 6–8)
```
5. Bulk user generation
   - Character set generators
   - Batch comment encoding

6. Voucher printing (PDF)
   - pdf package integration
   - QR code (qr_flutter)

7. BT thermal print
   - QuickPrinter intent channel
   - QuickPrint packages CRUD
```

### Sprint 4 — Business Intelligence (Week 9–10)
```
8. Sales reports
   - /system/script parser
   - Filters: day / month / range / username / comment
   - CSV export + PDF print
   - Monthly chart (fl_chart)

9. Dashboard
   - System info cards
   - Live traffic chart
   - Active user count
   - Live income widget
```

### Sprint 5 — Polish (Week 11–14)
```
10. System management (scheduler, reboot, shutdown)
11. Network tools (DHCP, IP bindings, cookies, hosts)
12. PPP module (full implementation)
13. Notifications, offline mode, widgets
14. i18n, dark mode, tablet layout
```

---

## 3. Which Modules Are Highest Risk?

| Risk | Module | Reason | Mitigation |
|------|--------|--------|-----------|
| 🔴 Critical | `OnLoginScriptGenerator` | Must produce byte-identical RouterScript for all 5 expiry modes; wrong output silently corrupts all user expiry logic on the router | Unit test every mode against captured PHP output before shipping |
| 🔴 Critical | `on-login metadata decoder` | Must parse comma positions [0..6] from existing profiles without corruption | Test against 10+ real-world profiles captured from target routers |
| 🔴 Critical | `comment field parser` | Dual-use format (batch code vs expiry timestamp) must be detected correctly | Regex-based parser with explicit fallback and test suite |
| 🟠 High | `report_sdk` | 9-field pipe-delimited name parsing; existing records must remain readable after migration | Defensive parser with field-count validation |
| 🟠 High | `mikrotik_sdk` binary framing | Pre-v6.43 MD5 challenge-response must work perfectly; many ISPs still run old RouterOS | Integration test with both RouterOS versions |
| 🟠 High | BT thermal printing | QuickPrinter intent is undocumented; ESC/POS formatting varies by printer model | Test on 3+ printer models; implement fallback to PDF share |
| 🟡 Medium | `/system/script` QuickPrint parsing | `#`-delimited format with variable field count | Defensive parser; preserve unknown fields |
| 🟡 Medium | Multi-router connection pool | Concurrent connections to multiple routers; socket lifecycle management | Use mutex per router ID; implement heartbeat |

---

## 4. Which Modules Should Become SDKs?

These 7 components are suitable for extraction as independent Dart packages, publishable to pub.dev:

| SDK Package | Scope | Publish to pub.dev? |
|------------|-------|-------------------|
| `mikrotik_sdk` | TCP binary API client, login, command/read | ✅ Yes — high community value |
| `hotspot_sdk` | Hotspot CRUD, profile management, batch generation, on-login generator | ✅ Yes — most-requested by ISPs |
| `system_sdk` | System info, scheduler, script store, reboot | ✅ Yes — general RouterOS utility |
| `report_sdk` | Sales record read/write (wraps /system/script as DB) | ✅ Yes — unique to Mikhmon ecosystem |
| `traffic_sdk` | Interface monitoring, bitrate formatting, live stream | ✅ Yes — broadly useful |
| `ppp_sdk` | PPP secrets, profiles, active sessions | ✅ Yes — PPPoE operators need this |
| `queue_sdk` | Simple/tree queue management | 🟡 Maybe — smaller audience |

### Recommended pub.dev Package Names
```yaml
mikrotik_dart:        # core protocol
mikrotik_hotspot:     # hotspot module
mikrotik_system:      # system module
mikrotik_ppp:         # ppp module
mikrotik_traffic:     # traffic module
mikrotik_reports:     # report/log module (Mikhmon-specific)
```

---

## 5. Flutter vs Kotlin for This Project

### Verdict: ✅ Flutter is the right choice

| Criterion | Flutter | Kotlin (Android only) |
|-----------|---------|----------------------|
| iOS support | ✅ Full | ❌ Android only |
| Single codebase | ✅ Yes | ❌ No (separate iOS needed) |
| Material 3 | ✅ Native | ✅ Native |
| RouterOS TCP socket | ✅ Dart `dart:io` | ✅ `java.net.Socket` |
| PDF generation | ✅ `pdf` package | ⚠️ Third-party |
| BT thermal print | ✅ Plugin or MethodChannel | ✅ Native |
| Desktop support | ✅ macOS / Windows / Linux | ❌ Android only |
| Tablet adaptive UI | ✅ `adaptive_layout` | ⚠️ Manual |
| Development speed (solo AI-assisted) | ✅ Faster (one codebase) | ❌ Slower (two codebases) |
| Community / packages | ✅ Large pub.dev ecosystem | ✅ Large but Android-only |
| Code sharing (SDK → pub.dev) | ✅ Dart packages | ❌ Kotlin only |

**Flutter wins on every cross-platform criterion. Kotlin plugins should be used only for:**
- Android home screen widget (`AppWidgetProvider`) — Flutter Glance
- QuickPrinter intent integration — via `MethodChannel`
- Battery-efficient background polling — via `WorkManager` Kotlin plugin

---

## 6. Estimated Development Time (Solo Developer + AI Agents)

### Assumptions
- Developer: Mid-to-senior Flutter developer
- AI assist: Claude Code / OpenCode for code generation, review, tests
- RouterOS test hardware: Available for integration testing
- Working hours: ~6 hours/day productive

### Timeline

| Phase | Description | Duration | AI-Assisted |
|-------|-------------|----------|------------|
| 0 | Audit + Architecture | Done | ✅ |
| 1 | Foundation (mikrotik_sdk + auth + routing) | 2 weeks | ✅ 60% |
| 2 | Dashboard | 1 week | ✅ 70% |
| 3 | Hotspot users | 2 weeks | ✅ 65% |
| 4 | User profiles + OnLoginGenerator | 2 weeks | ⚠️ 40% (complex domain) |
| 5 | Voucher + BT print + QuickPrint | 2 weeks | ✅ 55% |
| 6 | Reports + charts | 1.5 weeks | ✅ 70% |
| 7 | System tools + network | 1 week | ✅ 75% |
| 8 | PPP module | 1 week | ✅ 70% |
| 9 | Polish: notifications, offline, widget, i18n | 2 weeks | ✅ 60% |
| 10 | QA, testing, bug fixes | 1.5 weeks | ✅ 50% |
| **Total** | | **~16 weeks** | |

> **Realistic estimate: 4 months for MVP (Phases 1–7)**
> **Full-featured v1.0: 5 months**
> **With PPP + offline + widget + notifications: 6 months**

### AI Agent Productivity Boost
AI agents (Claude Code) are estimated to reduce development time by **35–40%** for:
- Boilerplate code generation (models, repositories, providers)
- Unit test generation for parsers (on-login, comment field, script name)
- RouterOS API integration code
- Material 3 widget scaffolding
- Documentation generation

**Without AI assistance: ~10 months solo.**
**With AI assistance: ~4–5 months solo.**

---

## 7. Recommended Final Architecture: DevKuroTik

```
devkurotik/
├── packages/                           # Independent Dart SDKs
│   ├── mikrotik_dart/                  # Core protocol
│   │   ├── lib/src/
│   │   │   ├── client.dart
│   │   │   ├── connection_pool.dart
│   │   │   ├── format.dart
│   │   │   └── random.dart
│   │   └── test/
│   ├── mikrotik_hotspot/               # Hotspot SDK
│   │   ├── lib/src/
│   │   │   ├── hotspot_sdk.dart
│   │   │   ├── onlogin_generator.dart  # CRITICAL
│   │   │   ├── batch_generator.dart
│   │   │   └── models/
│   │   └── test/
│   ├── mikrotik_system/
│   ├── mikrotik_reports/
│   ├── mikrotik_traffic/
│   └── mikrotik_ppp/
│
├── plugins/                            # Native platform plugins
│   ├── devkurotik_android/             # Kotlin: widget + BT print intent
│   └── devkurotik_ios/                 # Swift: CoreBluetooth (optional)
│
└── app/                                # Flutter application
    ├── lib/
    │   ├── main.dart
    │   ├── app.dart                    # MaterialApp + go_router
    │   ├── core/
    │   │   ├── database/               # drift: routers, settings, cache, queue
    │   │   ├── secure_storage/         # flutter_secure_storage wrapper
    │   │   ├── theme/                  # Material 3 color schemes
    │   │   └── l10n/                   # .arb files: en, id, es, tl, tr
    │   ├── features/
    │   │   ├── auth/                   # Biometric + PIN login
    │   │   │   ├── providers/
    │   │   │   └── screens/
    │   │   ├── router_management/      # Add/edit/delete routers
    │   │   ├── dashboard/              # Sysinfo, charts, counts
    │   │   ├── hotspot/
    │   │   │   ├── users/
    │   │   │   ├── profiles/
    │   │   │   ├── active/
    │   │   │   ├── generator/
    │   │   │   ├── quickprint/
    │   │   │   └── voucher/
    │   │   ├── reports/
    │   │   │   ├── selling/
    │   │   │   ├── chart/
    │   │   │   └── userlog/
    │   │   ├── system/
    │   │   │   ├── scheduler/
    │   │   │   └── control/
    │   │   ├── network/
    │   │   │   ├── dhcp/
    │   │   │   ├── ipbinding/
    │   │   │   └── traffic/
    │   │   ├── ppp/
    │   │   └── settings/
    │   └── shared/
    │       ├── widgets/                # Reusable M3 widgets
    │       ├── providers/              # Shared Riverpod providers
    │       └── utils/
    └── test/
        ├── unit/
        ├── widget/
        └── integration/
```

### State Architecture (Riverpod)
```dart
// Per-router provider scope
final activeRouterProvider = StateProvider<RouterConfig?>((ref) => null);

final mikrotikClientProvider = Provider.family<MikrotikClient, String>((ref, routerId) {
  final creds = ref.watch(credentialsProvider(routerId));
  return MikrotikClient(creds.host, creds.port);
});

// Hotspot users — cached + refreshable
final hotspotUsersProvider = FutureProvider.family.autoDispose<List<HotspotUser>, UserFilter>(
  (ref, filter) async {
    final client = ref.watch(mikrotikClientProvider(ref.watch(activeRouterProvider)!.id));
    return HotspotSdk(client).users(profile: filter.profile, comment: filter.comment);
  },
);

// Live traffic — streaming
final trafficProvider = StreamProvider.family.autoDispose<TrafficSample, String>(
  (ref, interfaceName) {
    final client = ref.watch(mikrotikClientProvider(ref.watch(activeRouterProvider)!.id));
    return TrafficSdk(client).monitor(interfaceName);
  },
);
```

### Database Schema (SQLite via drift)
```sql
-- Router configurations
CREATE TABLE routers (
  id          TEXT PRIMARY KEY,
  name        TEXT UNIQUE NOT NULL,
  ip_host     TEXT NOT NULL,
  user_host   TEXT NOT NULL,
  port        INTEGER DEFAULT 8728,
  use_ssl     INTEGER DEFAULT 0,
  hotspot     TEXT,
  dns_name    TEXT,
  currency    TEXT DEFAULT 'IDR',
  reload_sec  INTEGER DEFAULT 30,
  iface       TEXT,
  idle_to     INTEGER DEFAULT 1800,
  livereport  INTEGER DEFAULT 1,
  sort_order  INTEGER DEFAULT 0,
  created_at  INTEGER NOT NULL
);

-- Settings (key-value per router)
CREATE TABLE settings (
  router_id   TEXT NOT NULL,
  key         TEXT NOT NULL,
  value       TEXT,
  PRIMARY KEY (router_id, key)
);

-- Offline action queue
CREATE TABLE offline_queue (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  router_id   TEXT NOT NULL,
  action      TEXT NOT NULL,   -- JSON: {sdk, method, params}
  created_at  INTEGER NOT NULL,
  retries     INTEGER DEFAULT 0
);

-- Local cache (invalidated by TTL)
CREATE TABLE user_cache (
  router_id   TEXT NOT NULL,
  data        TEXT NOT NULL,   -- JSON array of HotspotUser
  cached_at   INTEGER NOT NULL,
  PRIMARY KEY (router_id)
);

-- Last generation batch
CREATE TABLE last_batch (
  router_id   TEXT NOT NULL,
  batch_code  TEXT,
  profile     TEXT,
  count       INTEGER,
  generated_at INTEGER,
  PRIMARY KEY (router_id)
);
```

---

## 8. Modernization Opportunities (Beyond Mikhmon)

These features don't exist in Mikhmon but should be in DevKuroTik:

| Feature | Value | Implementation |
|---------|-------|---------------|
| QRIS Payment Integration | High (Indonesian market) | `qr_flutter` + QRIS spec encoding |
| Multi-router dashboard | High | Side-by-side cards, fleet overview |
| Expiry push notifications | High | `flutter_local_notifications` |
| Offline voucher generation | High | Generate locally, sync when connected |
| Biometric authentication | High | `local_auth` (fingerprint + Face ID) |
| Android home screen widget | Medium | Kotlin `AppWidgetProvider` via Glance |
| Cloud backup (optional) | Medium | Export config to Google Drive / iCloud |
| NFC voucher delivery | Medium | `flutter_nfc_kit` — tap phone to deliver credentials |
| Hotspot portal preview | Low | WebView showing hotspot login page |
| PPPoE client management | Medium | Full PPP module (missing in Mikhmon) |
| Queue visualization | Low | Tree view of simple/tree queues |
| Revenue analytics chart | High | Monthly/weekly income trends |
| CSV import (bulk users) | Medium | Import users from spreadsheet |
| Voucher PDF templates | Medium | Multiple professional templates |
| Operator multi-tenant | Low | Multiple operator accounts per router |

---

## 9. Go/No-Go Checklist for Migration

### Technical Pre-requisites
- [x] All RouterOS API endpoints documented ✅
- [x] on-login script encoding reverse-engineered ✅
- [x] Comment field dual-use documented ✅
- [x] /system/script DB format documented ✅
- [x] QuickPrint config format documented ✅
- [x] All security vulnerabilities known (avoid in rewrite) ✅
- [ ] RouterOS test hardware available for integration tests
- [ ] Test profiles with all 5 expiry modes captured from real router
- [ ] Flutter dev environment set up with all packages

### Business Pre-requisites
- [ ] Product name confirmed: DevKuroTik
- [ ] App Store / Play Store accounts ready
- [ ] Target RouterOS version range defined (v6.43+ recommended minimum)
- [ ] Localization requirements confirmed

---

## 10. Final Scores

| Dimension | Score | Verdict |
|-----------|-------|---------|
| **Security** | 18/100 | 🔴 Rewrite immediately |
| **Maintainability** | 22/100 | 🔴 Too coupled to migrate safely |
| **Migration Readiness** | 15/100 | 🔴 Full rewrite recommended |
| **Feature Value** | 82/100 | 🟢 Highly valuable feature set |
| **Business Logic Complexity** | 71/100 | 🟠 Complex but well-documented |
| **Flutter Migration Feasibility** | 85/100 | 🟢 Very feasible with AI assistance |

---

## TL;DR

> **Mikhmon v3 is a critically insecure PHP monolith with exceptional business logic value. It is not safe to deploy in production. It is not suitable for a port — only for a full Flutter rewrite.**
>
> **DevKuroTik should be built from scratch using the 7 SDK modules defined in this audit, the 47 RouterOS endpoints catalogued, and the 119 features inventoried. The most critical component is the `OnLoginScriptGenerator` which must be exhaustively unit-tested before any profile management feature ships.**
>
> **Solo developer + AI agents (Claude Code): ~4 months to MVP, ~6 months to v1.0.**
>
> **Flutter is the correct choice over Kotlin for cross-platform support (iOS + Android + Desktop), single codebase, and pub.dev SDK publishing.**

---

*Report 7 of 7 — DevKuroTik Migration Audit*
*Generated: 2026-07-25*
*Auditor: Senior Software Architect + Security Engineer*
