# MIGRATION BLUEPRINT — Mikhmon v3 → DevKuroTik (Flutter)
> **Source:** Mikhmon v3 (PHP + RouterOS API)
> **Target:** DevKuroTik (Flutter + Dart + Material 3)
> **Strategy:** Full rewrite — not a port

---

## 1. Target Stack

### Frontend
| Layer | Technology | Notes |
|-------|-----------|-------|
| UI Framework | Flutter 3.x | Cross-platform: Android + iOS + Desktop |
| Design System | Material 3 (Material You) | Dynamic color, adaptive layout |
| State Management | Riverpod 2.x | Async providers, caching, DI |
| Navigation | go_router | Deep links, shell routes |
| Local Storage | SQLite via `drift` | Typed queries, migrations |
| Secure Storage | `flutter_secure_storage` | RouterOS credentials, tokens |
| HTTP/WS | `dio` + custom TCP socket | RouterOS API is raw TCP, not HTTP |
| Charts | `fl_chart` | Area, line, bar charts |
| QR Code | `qr_flutter` | Client-side, no external API |
| PDF / Print | `pdf` + `printing` | Voucher generation |
| BT Print | `flutter_thermal_printer` or `esc_pos_utils` | Android thermal printer |
| i18n | `flutter_localizations` + `intl` | Multi-language support |
| Notifications | `flutter_local_notifications` | Expiry alerts, system events |
| Biometrics | `local_auth` | Fingerprint / Face ID login |
| Image Picker | `image_picker` | Logo upload |

### Optional Native Plugins
| Platform | Use Case | Technology |
|----------|---------|-----------|
| Android | BT thermal print intent | Kotlin `MethodChannel` |
| Android | Home screen widget | Kotlin `AppWidgetProvider` |
| iOS | BT peripheral scan | Swift `CoreBluetooth` |

### Core SDK (Dart)
| Package | Purpose |
|---------|---------|
| `mikrotik_sdk` | RouterOS TCP API client |
| `hotspot_sdk` | Hotspot user/profile operations |
| `report_sdk` | Sales record read/write/delete |
| `system_sdk` | System info, scheduler, reboot |
| `traffic_sdk` | Interface monitoring |

### Optional Go Microservice
| Service | Purpose |
|---------|---------|
| `devkurotik-sync` | Background sync + offline queue flush |
| `devkurotik-notify` | Push notification dispatcher |

---

## 2. Feature Migration Classification

### 2.1 REWRITE (implement fresh in Flutter)

| Feature | Reason | Target |
|---------|--------|--------|
| RouterOS API client | PHP socket → Dart async TCP socket | `mikrotik_sdk` |
| Authentication | PHP session → local biometric + secure storage | `local_auth` + `flutter_secure_storage` |
| Configuration storage | PHP flat file → SQLite routers table | `drift` |
| Dashboard | jQuery AJAX polling → Riverpod StreamProvider | Flutter widgets |
| Hotspot user list | jQuery .load() → paginated Riverpod provider | `ListView.builder` |
| User generation | PHP rand() loops → Dart crypto random | Dart `Random.secure()` |
| Voucher printing | `window.print()` → PDF generation | `pdf` + `printing` |
| BT thermal print | Android intent URL → native plugin | `flutter_thermal_printer` |
| Sales reports | JS CSV blob → share_plus + csv package | Dart `csv` + `share_plus` |
| Traffic monitor | Highcharts → fl_chart live chart | `fl_chart` StreamChart |
| Navigation | PHP ?id= GET dispatch → go_router | Shell route with bottom nav |
| Theming | 5 CSS themes → Material 3 ColorScheme | `ThemeData` + dynamic color |
| Multi-language | PHP lang/*.php files → Flutter l10n | `.arb` files + `intl` |
| Settings storage | PHP file writes → Riverpod + SQLite | `drift` settings table |

### 2.2 REPLACE (same function, better implementation)

| Old | New | Notes |
|-----|-----|-------|
| Highcharts.js | `fl_chart` | Open source, no license |
| QRious.js | `qr_flutter` | Flutter-native |
| CodeMirror editor | Template builder UI | Replace file-edit with structured form |
| jQuery AJAX | Dart `dio` / Riverpod | Typed, testable |
| Font Awesome 4 | Material Icons 3 + `flutter_svg` | Consistent with M3 |
| Pace.js progress bar | Flutter `LinearProgressIndicator` | Native |
| Caesar cipher encryption | AES-256-GCM via `cryptography` package | Proper encryption |
| PHP `session_start()` | Flutter Riverpod state + secure storage | Typed, testable |
| PHP flat config file | SQLite `routers` table via `drift` | Structured, safe |
| Google Chart QR API | `qr_flutter` (local) | No external dependency |
| Legacy BT URI scheme | `flutter_thermal_printer` | Maintained plugin |

### 2.3 MODERNIZE (same feature + new capabilities)

| Feature | Current | Modernized Version |
|---------|---------|-------------------|
| Login | Username/password form | + Biometric (fingerprint/Face ID) |
| Dashboard | Auto-reload every N seconds | + Pull-to-refresh + StreamProvider |
| Voucher print | Browser popup | + PDF share + BT print + save to gallery |
| Sales report | Table only | + Chart + export + filter chips |
| Multi-router | ?session= GET param | + Router profile cards + quick switch |
| User generation | Single batch | + Saved presets + offline queue |
| Profile management | Manual RouterScript | + Guided wizard |
| Traffic monitor | 3-second poll | + Configurable interval + historical |
| Notifications | None | + Expiry alerts + active session alerts |

### 2.4 REMOVE (not needed in Flutter)

| Feature | Reason |
|---------|--------|
| PHP voucher template editor (CodeMirror) | Replace with structured template builder |
| `window.print()` browser print | Replaced by `pdf` + `printing` package |
| Google Charts QR API | Replaced by local `qr_flutter` |
| Legacy BT URI scheme (`my.bluetoothprint.scheme://`) | Deprecated, replaced |
| PHP session management | Replaced by Riverpod + secure storage |
| Obfuscated anti-fork JS | Remove entirely |
| Domain-lock kill switch | Remove entirely |
| temp.php generation cache | Replace with SQLite lastBatch table |
| PHP file-based theme/lang storage | Replace with SQLite settings |
| `include/config.php` PHP runtime writes | Replace with SQLite |

### 2.5 KEEP AS-IS (logic to preserve exactly)

| Logic | Reason |
|-------|--------|
| RouterOS API binary wire protocol | Unchanged — TCP socket framing |
| on-login script comma-position encoding | Must produce identical RouterScript |
| Comment field dual-use parsing | Mikhmon-created users have this format |
| `/system/script` sales record format | Existing records must still be readable |
| QuickPrint `#`-delimited config format | Existing packages in RouterOS must work |
| Expiry mode RouterScript templates | Each mode produces specific MikroTik RouterScript |
| formatDTM() uptime conversion | Same logic in Dart |
| Background sweep scheduler interval (2 min) | RouterOS requirement |
| User batch comment encoding: `vc-/up-` prefix | Existing users have this |

---

## 3. Phased Migration Plan

### Phase 1 — Foundation (Weeks 1–3)
```
✅ Project setup: Flutter 3.x + Riverpod 2 + go_router + drift
✅ mikrotik_sdk: TCP socket client, binary framing, login handshake
✅ Authentication: username/password + biometric
✅ Multi-router management: SQLite routers table, add/edit/delete
✅ Router connection test (ping-test equivalent)
✅ Basic navigation shell: bottom nav + drawer
✅ Secure credential storage: flutter_secure_storage
```

### Phase 2 — Dashboard (Weeks 3–4)
```
✅ System info card: board, OS version, uptime, CPU, memory
✅ Hotspot count card: active + total users
✅ Live traffic chart: fl_chart + StreamProvider polling
✅ Hotspot log widget: last 20 log entries
✅ Live income widget: today + month totals
✅ Router switcher: profile card selector
✅ Pull-to-refresh + auto-refresh interval
```

### Phase 3 — Hotspot Users (Weeks 4–6)
```
✅ User list: paginated, filtered by profile/comment/expired
✅ User detail: full metadata + expiry status + QR code
✅ Add user: form with profile picker + price preview
✅ Edit user: pre-populated form
✅ Delete user: single + bulk + by comment + expired
✅ Enable/disable user
✅ Reset user counters
✅ Export: CSV + RouterOS script
✅ WhatsApp share
```

### Phase 4 — User Profiles (Weeks 6–8)
```
✅ Profile list: decoded metadata (expiry mode, price, validity)
✅ Add profile: guided wizard → generate RouterScript
✅ Edit profile: update RouterScript + scheduler
✅ Delete profile: cascade to scheduler
✅ on-login RouterScript generation engine (critical)
✅ Background sweep scheduler lifecycle management
```

### Phase 5 — Voucher & Printing (Weeks 8–10)
```
✅ PDF voucher generator: default + small + thermal layouts
✅ QR code on voucher: qr_flutter
✅ Print by batch / single user
✅ BT thermal print: flutter_thermal_printer integration
✅ QuickPrint packages: CRUD + one-touch generate+print
✅ Bulk user generation: configurable params
```

### Phase 6 — Reports (Weeks 10–11)
```
✅ Selling report: list + filters + sum
✅ Monthly chart: fl_chart area chart
✅ CSV export + print (PDF)
✅ Delete records: by day/month/selection
✅ User login log
✅ Live income widget polish
```

### Phase 7 — System & Network (Week 12)
```
✅ Scheduler list + enable/disable/delete
✅ Router reboot/shutdown with confirmation
✅ DHCP lease list
✅ IP bindings: list + enable/disable/delete (cascade)
✅ Hotspot cookies + hosts
✅ Hotspot log viewer
✅ Traffic monitor: interface selector + live chart
```

### Phase 8 — Polish & Advanced (Weeks 13–14)
```
✅ Push notifications: expiry alerts, active session count
✅ Offline mode: cache last-known state in SQLite
✅ Home screen widget (Android): active users + today income
✅ Dark mode + theme customization
✅ Tablet adaptive layout
✅ PPP module (secrets, profiles, active sessions)
✅ Multi-language: EN, ID, ES, TL, TR + new languages
✅ Settings: all per-router config options
✅ Logo management: image_picker + local storage
```

---

## 4. Data Migration Strategy

### 4.1 RouterOS Script Records (Sales Data)
```
Existing Mikhmon sales records in /system/script are readable as-is.
DevKuroTik report_sdk must parse the name field:
  "Jan/01/2025-|-14:30:00-|-john-|-15000-|-192.168.1.5-|-AA:BB:CC-|-1day-|-daily-|-vc-abc"
  Split on "-|-" → [date, time, user, price, ip, mac, validity, profile, comment]

No migration required — data stays on RouterOS.
```

### 4.2 on-login Script Metadata
```
Existing profile on-login scripts have Mikhmon metadata at comma positions [1..6].
DevKuroTik must parse and re-generate this format exactly.
Migration: read existing → parse → store in local SQLite cache → re-encode on save.
```

### 4.3 Local App Config
```
Old:  include/config.php (PHP flat file, Caesar cipher)
New:  SQLite routers table (drift) + flutter_secure_storage

Routers table schema:
  id          INTEGER PRIMARY KEY
  name        TEXT UNIQUE        -- session name
  ip_host     TEXT               -- router IP
  user_host   TEXT               -- RouterOS username
  pass_host   TEXT (secure)      -- stored in flutter_secure_storage by id
  hotspot     TEXT               -- hotspot server name
  dns_name    TEXT               -- DNS name for QR URLs
  currency    TEXT               -- display currency
  reload_sec  INTEGER            -- auto-reload interval
  iface       TEXT               -- default interface
  idle_to     TEXT               -- idle timeout
  livereport  INTEGER            -- 0/1
  created_at  INTEGER            -- unix timestamp
```

### 4.4 QuickPrint Packages
```
Existing packages in /system/script (comment=QuickPrintMikhmon) are readable.
DevKuroTik must parse # delimited source string:
  "#Package Name#server#vc#5#prefix#lower#daily#0s#0#comment"
  Split on "#" → [empty, name, server, mode, length, prefix, chars, profile, limits, ...]

Migration: read from RouterOS → parse → display in Flutter UI.
On save: re-encode and write back to /system/script.
```

---

## 5. Architecture: DevKuroTik

```
┌─────────────────────────────────────────────────────────────────┐
│                     DEVKUROTIK APP (Flutter)                    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    PRESENTATION LAYER                    │  │
│  │  Material 3 Widgets  │  go_router  │  Adaptive Layout    │  │
│  │  Dashboard  │  Hotspot  │  Reports  │  Settings          │  │
│  └─────────────────────┬────────────────────────────────────┘  │
│                        │                                        │
│  ┌─────────────────────▼────────────────────────────────────┐  │
│  │                   STATE LAYER (Riverpod)                  │  │
│  │  RouterProvider  │  HotspotProvider  │  ReportProvider    │  │
│  │  StreamProvider (live traffic)  │  FutureProvider        │  │
│  └─────────────────────┬────────────────────────────────────┘  │
│                        │                                        │
│  ┌─────────────────────▼────────────────────────────────────┐  │
│  │                   DOMAIN / SDK LAYER                     │  │
│  │  mikrotik_sdk  │  hotspot_sdk  │  report_sdk             │  │
│  │  system_sdk    │  traffic_sdk  │  ppp_sdk                │  │
│  └──────────┬──────────────────────────────┬───────────────┘  │
│             │                              │                   │
│  ┌──────────▼──────────┐  ┌───────────────▼───────────────┐  │
│  │   LOCAL DATA LAYER  │  │        ROUTEROS LAYER         │  │
│  │  drift (SQLite)     │  │  TCP Socket :8728             │  │
│  │  - routers          │  │  Binary API protocol          │  │
│  │  - settings         │  │  Login: plain / MD5           │  │
│  │  - last_batch       │  │  Retry logic                  │  │
│  │  - offline_queue    │  └───────────────┬───────────────┘  │
│  │  flutter_secure_    │                  │                   │
│  │    storage (creds)  │                  │ TCP :8728         │
│  └─────────────────────┘                  ▼                   │
└───────────────────────────────────────────────────────────────┘
                                            │
                               ┌────────────▼─────────────┐
                               │    MIKROTIK ROUTEROS     │
                               │  /ip/hotspot/*           │
                               │  /system/script (DB)     │
                               │  /system/scheduler       │
                               │  /interface/*            │
                               │  /queue/* /ppp/*         │
                               └──────────────────────────┘
```

---

## 6. Mobile-First Design Recommendations

### Material 3 Layout
```
Phone Portrait:
  Bottom Navigation Bar: 4 tabs
    [Dashboard] [Hotspot] [Reports] [Settings]
  FAB: Quick Generate / Quick Print

Phone Landscape:
  Navigation Rail (left side)
  Content area (right)

Tablet (≥600dp):
  Navigation Drawer (permanent)
  Two-pane layout for lists + detail
  Dashboard: 2-column card grid
```

### Adaptive Navigation
```dart
// go_router shell route
final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => AdaptiveScaffold(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: ...),
        GoRoute(path: '/hotspot', builder: ...),
        GoRoute(path: '/reports', builder: ...),
        GoRoute(path: '/settings', builder: ...),
      ],
    ),
  ],
);
```

### Dark Mode
- Use `ThemeData.from(colorScheme: ColorScheme.fromSeed(..., brightness: Brightness.dark))`
- All charts: fl_chart supports dark/light theme
- System-follow + manual override in settings

### Offline Mode
```
Cache strategy:
  - Last-known user list → SQLite `cached_users` table (TTL: 5 min)
  - Last-known active sessions → TTL: 30 sec
  - Sales report data → TTL: 10 min
  - System resources → TTL: 1 min
  
Offline queue:
  - Actions taken offline → `offline_queue` table
  - Flush on next successful connection
  - Show pending badge on relevant screens
```

### Home Screen Widget (Android)
```kotlin
// AppWidgetProvider — DevKuroTik Glance Widget
- Active users count
- Today's income
- Connection status (dot indicator)
- Last updated timestamp
- Tap to open app
```

### Biometric Authentication
```dart
final localAuth = LocalAuthentication();
final isAvailable = await localAuth.canCheckBiometrics;
if (isAvailable) {
  final authenticated = await localAuth.authenticate(
    localizedReason: 'Authenticate to access DevKuroTik',
    options: const AuthenticationOptions(biometricOnly: false),
  );
}
```

### Push Notifications
```
Notification types:
  1. User expiry warning (1 hour before, from local timer)
  2. Router disconnected (background socket monitor)
  3. New active session spike (threshold alert)
  4. Daily income summary (scheduled local notification)
```

---

## 7. Migration Risk Assessment

| Risk | Level | Mitigation |
|------|-------|-----------|
| RouterScript generation for profiles | 🔴 High | Write comprehensive unit tests covering all 5 expiry modes |
| on-login comma-position encoding | 🔴 High | Validate against known-good profiles before writing |
| `/system/script` as DB parsing | 🟠 Medium | Parse all field variations defensively with fallback |
| BT thermal print compatibility | 🟠 Medium | Test against real ESC/POS printers; implement QuickPrinter intent fallback |
| Pre-v6.43 RouterOS login support | 🟠 Medium | Keep MD5 challenge-response in mikrotik_sdk |
| Offline queue race conditions | 🟠 Medium | Use SQLite transactions + idempotent RouterOS writes |
| Comment field dual-use parsing | 🟡 Low | Well-defined format; implement parser with regex |
| PPP module (missing in source) | 🟡 Low | Implement fresh from RouterOS API docs |

---

*Report 4 of 7 — DevKuroTik Migration Audit*
