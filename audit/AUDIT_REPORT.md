# AUDIT REPORT — Mikhmon v3
> **Project:** Mikhmon v3 (MikroTik Hotspot Manager)
> **Auditor:** Senior Software Architect + Security Engineer
> **Date:** 2026-07-25
> **Target Migration:** DevKuroTik (Flutter Mobile App)

---

## 1. Executive Summary

| Metric | Value |
|--------|-------|
| Total PHP Files | 100 |
| Total JS Files | 16 |
| Total CSS Files | 14 |
| Total Lines of Code | ~16,758 |
| PHP LOC | 13,223 |
| JS LOC | 1,045 |
| CSS LOC | 2,490 |
| Templates / Views | 8 (3 voucher layouts × 2 + 2 standalone) |
| Estimated Complexity | **7 / 10** |
| Estimated Migration Effort | **Large** |
| Technical Debt | **Critical** |

### Complexity Justification
- No framework, no MVC, no ORM
- 608-line procedural front-controller (`index.php`)
- Config stored as raw PHP file mutated at runtime
- MikroTik `/system/script` abused as a flat-file database for sales records and QuickPrint configs
- Per-profile RouterScript auto-generation embedded inline in PHP strings
- 3 distinct printing subsystems (browser, Android BT intent, legacy BT URI)
- Obfuscated anti-fork JavaScript with domain-lock kill switch

### Technical Debt Assessment
| Area | Debt Level | Notes |
|------|-----------|-------|
| Security | 🔴 Critical | 4 RCE vectors, zero CSRF, no output encoding |
| Architecture | 🔴 Critical | Monolithic, no separation of concerns |
| Maintainability | 🟠 High | Copy-paste everywhere, 30+ duplicate API patterns |
| Testing | 🔴 Critical | Zero tests, zero CI, zero linting |
| Documentation | 🟡 Medium | README exists but no inline docs |
| Dependencies | 🟡 Medium | All vendored locally, some obsolete |
| Encryption | 🔴 Critical | XOR+base64 cipher with fixed key |

---

## 2. Architecture Analysis

### 2.1 Directory Structure

```
mikhmonv3-master/
├── admin.php               # Pre-connection hub: login, sessions CRUD, admin settings
├── index.php               # Post-connection hub: 608-line if-elseif router for all modules
├── include/
│   ├── config.php          # Flat PHP array: all router configs + admin credentials (MUTATED AT RUNTIME)
│   ├── readcfg.php         # Unpacks config array into named variables per session
│   ├── login.php           # Login form HTML
│   ├── menu.php            # Sidebar + navbar HTML (includes version.php)
│   ├── headhtml.php        # HTML <head> + CSS/JS asset tags
│   ├── version.php         # App version + update-check
│   ├── lang.php            # Active language setting (overwritten on language change)
│   ├── theme.php           # Active theme + color (overwritten on theme change)
│   ├── quickbt.php         # BT QR setting (overwritten on settings save)
│   ├── userlog.php         # Selling log reader/renderer (fetches /system/script)
│   └── about.php           # About page
├── lib/
│   ├── routeros_api.class.php   # RouterOS API TCP client + utility functions
│   └── formatbytesbites.php     # formatBytes() helper
├── dashboard/
│   ├── home.php            # Dashboard: sysinfo, charts, hotspot counts (403 LOC)
│   ├── aload.php           # AJAX partial loader for dashboard widgets (283 LOC)
│   └── index.php           # Dashboard index wrapper
├── hotspot/
│   ├── users.php           # User list + filters (269 LOC)
│   ├── adduser.php         # Add single user form
│   ├── userbyname.php      # User detail/edit page (461 LOC)
│   ├── userbyprofile.php   # Profile card dashboard
│   ├── userprofile.php     # Profile list
│   ├── adduserprofile.php  # Add profile form (254 LOC)
│   ├── userprofilebyname.php # Profile edit page (315 LOC)
│   ├── generateuser.php    # Bulk user generator (481 LOC)
│   ├── quickuser.php       # One-touch generate + print (267 LOC)
│   ├── quickprint.php      # QuickPrint package cards
│   ├── listquickprint.php  # QuickPrint package CRUD (373 LOC)
│   ├── hotspotactive.php   # Active sessions list
│   ├── exportusers.php     # CSV / RouterOS script export (205 LOC)
│   ├── ipbinding.php       # IP bindings list
│   ├── cookies.php         # Hotspot cookies list
│   ├── hosts.php           # Hotspot hosts list
│   ├── log.php             # Hotspot log viewer
│   └── (+ userprofilebyname, userbyname sub-files)
├── process/                # AJAX action handlers (no HTML output)
│   ├── removehotspotuser.php
│   ├── removehotspotuserbycomment.php
│   ├── removeexpiredhotspotuser.php
│   ├── resethotspotuser.php
│   ├── enablehotspotuser.php
│   ├── disablehotspotuser.php
│   ├── removeuseractive.php
│   ├── removeuserprofile.php
│   ├── removehost.php
│   ├── removecookie.php
│   ├── pipbinding.php      # IP binding enable/disable/remove cascade
│   ├── pscheduler.php      # Scheduler enable/disable/remove
│   ├── removereport.php    # Delete selling report records
│   ├── getvalidprice.php   # AJAX: profile price/validity info
│   ├── reboot.php          # Router reboot
│   └── shutdown.php        # Router shutdown
├── report/
│   ├── selling.php         # Sales report (456 LOC)
│   ├── resumereport.php    # Monthly Highcharts chart
│   ├── livereport.php      # AJAX live income widget
│   ├── userlog.php         # User login log (252 LOC)
│   └── print.php           # Print-friendly report (443 LOC)
├── voucher/
│   ├── print.php           # Voucher print renderer (209 LOC)
│   ├── printbt.php         # BT / QuickPrinter receipt
│   ├── template.php        # Default voucher layout (editable)
│   ├── template-small.php  # Small voucher layout (editable)
│   ├── template-thermal.php # Thermal voucher layout (editable)
│   ├── default.php         # Default layout backup
│   ├── default-small.php
│   ├── default-thermal.php
│   ├── variable.php        # Template variable reference
│   ├── vpreview.php        # Template preview popup
│   └── temp.php            # Last-generation metadata (auto-generated)
├── system/
│   └── scheduler.php       # Scheduler list + management
├── traffic/
│   ├── traffic.php         # AJAX JSON: interface traffic data
│   └── trafficmonitor.php  # Traffic chart page
├── status/
│   ├── status.php          # User expiry lookup (AJAX)
│   ├── ping-test.php       # TCP ping test to RouterOS port
│   └── index.php
├── dhcp/
│   └── dhcpleases.php      # DHCP lease list
├── settings/
│   ├── settings.php        # Per-router settings form (262 LOC)
│   ├── sessions.php        # Router session CRUD (admin)
│   ├── settheme.php        # Theme change handler
│   ├── setlang.php         # Language change handler
│   ├── uplogo.php          # Logo upload/delete
│   └── vouchereditor.php   # In-browser PHP template editor ⚠️ RCE
├── lang/
│   ├── en.php, id.php, es.php, tl.php, tr.php
│   └── isocodelang.php
├── js/
│   ├── jquery.min.js
│   ├── mikhmon.js          # Core JS: idle timer, AJAX loaders, print helpers
│   ├── highcharts/         # Highcharts + 5 themes
│   ├── qrious.min.js       # QR code generator
│   ├── pace.min.js         # Page load indicator
│   ├── editor.min.js       # CodeMirror editor
│   └── mikhmon-ui.*.min.js # 5 theme variants
├── css/
│   ├── mikhmon-ui.*.min.css
│   ├── pace.*.css
│   ├── editor.min.css
│   └── font-awesome/
├── img/
│   ├── logo.png, favicon.png
│   └── logo-*.png          # Per-session uploaded logos
├── docker-compose.yml
└── nginx.conf
```

### 2.2 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        BROWSER CLIENT                       │
│  jQuery.ajax()  │  window.print()  │  Intent:// URI (BT)   │
└────────┬────────┴────────┬─────────┴───────────┬───────────┘
         │ HTTP GET/POST   │ Print popup          │ Android
         ▼                 ▼                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     PHP APPLICATION LAYER                   │
│                                                             │
│  admin.php ──► include/login.php                           │
│      │         include/config.php  ◄── runtime writes      │
│      │         include/readcfg.php                         │
│      ▼                                                      │
│  index.php (608-line if-elseif dispatch)                   │
│      │                                                      │
│      ├── hotspot/* ──── process/* ──── report/*            │
│      ├── dashboard/*    system/*       voucher/*            │
│      ├── traffic/*      dhcp/*         settings/*           │
│      └── status/*                                           │
│                                                             │
│  include/userlog.php  ──  lib/formatbytesbites.php         │
│  lang/*.php           ──  lib/routeros_api.class.php       │
└────────────────────────┬────────────────────────────────────┘
                         │ TCP :8728 (Binary API)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  RouterosAPI CLASS LAYER                    │
│  connect() → login() → comm() → read() → disconnect()      │
│  Supports: pre-v6.43 MD5 challenge / post-v6.43 plain     │
│  Reconnects on every HTTP request (no pooling)             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   MIKROTIK ROUTEROS                         │
│  /ip/hotspot/*     /system/script  (used as DB!)           │
│  /system/scheduler /interface/*    /queue/*                │
│  /log/*            /ppp/active     /ip/dhcp-server/*       │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Entry Points

| Entry Point | Role | Auth Required |
|-------------|------|---------------|
| `admin.php` | Login, router session CRUD, admin settings | No (login page) |
| `index.php` | Full router workspace (all modules) | Yes (`$_SESSION['mikhmon']`) |
| `dashboard/aload.php` | AJAX widget loader | Partial (reads `?session=`) |
| `traffic/traffic.php` | AJAX traffic JSON feed | Partial |
| `report/livereport.php` | AJAX income widget | Partial |
| `voucher/print.php` | Standalone voucher renderer | Partial (reads `?session=`) |
| `status/ping-test.php` | TCP connectivity test | Partial |
| `process/getvalidprice.php` | Profile price/validity AJAX | Partial |

### 2.4 Authentication Flow

```
1. Browser → GET admin.php
2. admin.php → session_start() + error_reporting(0)
3. include config.php ($data array)
4. include readcfg.php → extract $useradm, $passadm (decrypt)
5. Render include/login.php (form)
6. User → POST user=mikhmon&pass=icel
7. Compare: $user == $useradm && $pass == decrypt($passadm, 128)
8. Match → $_SESSION['mikhmon'] = $username
9. JS redirect → admin.php?id=sessions
10. All pages: if (!isset($_SESSION['mikhmon'])) → redirect login
11. Router workspace: also requires ?session=<name> GET param
12. index.php → $_SESSION[$session] = $session (per-router flag)

⚠ NO session_regenerate_id() after login
⚠ NO CSRF tokens on any form
⚠ Session timeout: client-side JS only (not server-enforced)
⚠ Logout: session_destroy() only — no cookie invalidation
```

### 2.5 Configuration Management

```
Storage:  include/config.php (flat PHP array)
Format:   $data['session_name'][N] = 'session_name<delimiter><value>'

Fields per router session:
  [1]  IP / hostname
  [2]  RouterOS username
  [3]  RouterOS password (XOR+base64 encrypted)
  [4]  Hotspot server name
  [5]  DNS name (for voucher QR URLs)
  [6]  Currency
  [7]  Auto-reload interval (seconds)
  [8]  Default interface index
  [9]  Live report display mode
  [10] Idle timeout (MM:SS)
  [11] Live report enable/disable

Admin credentials:
  $data['mikhmon'][1] = 'mikhmon<|<<username>'
  $data['mikhmon'][2] = 'mikhmon>|><encrypted_password>'

Theme:    include/theme.php  → <?php $theme='dark'; $themecolor='#3a4149'; ?>
Language: include/lang.php   → <?php $langid='en'; ?>
QR-BT:    include/quickbt.php → <?php $qrbt='enable'; ?>

⚠ Config file is read AND WRITTEN at runtime via file_get_contents/fwrite
⚠ No file locking — race conditions possible under concurrent requests
⚠ Encryption: XOR caesar cipher with fixed key '128' — trivially reversible
```

### 2.6 Router Connection Lifecycle

```
Per-request (no pooling):
  1. new RouterosAPI()
  2. $API->connect($iphost, $userhost, decrypt($passwdhost))
     → stream_socket_client('tcp://ip:8728', timeout=3s)
     → retry up to 5 times with 3s delay
     → login: post-v6.43 plain OR pre-v6.43 MD5 challenge-response
  3. $API->comm($command, $params)
     → write(): encode length, send words
     → read(): collect until !done, parseResponse()
  4. (Implicit) $API->__destruct() → disconnect() at end of PHP request

⚠ No connection pooling — TCP handshake on every page load
⚠ aload.php opens up to 3 separate connections per dashboard refresh
⚠ No exception handling — failed API calls return empty arrays silently
```

### 2.7 State Handling

| State | Storage | Notes |
|-------|---------|-------|
| Admin login | `$_SESSION['mikhmon']` | Username string |
| Active router | `?session=` GET param | NOT a PHP session var |
| Per-router flag | `$_SESSION[$session]` | String = session name |
| Theme | `$_SESSION['theme']` + `include/theme.php` | Dual-stored |
| Language | `$_SESSION['lang']` + `include/lang.php` | Dual-stored |
| Sales report data | `$_SESSION['dataresume']` | For chart rendering |
| Idle timer | Client-side JS countdown | No server enforcement |

---

## 3. Core Modules Summary

| Module | Files | LOC | Complexity |
|--------|-------|-----|-----------|
| RouterOS API Client | 1 | 647 | Medium |
| Hotspot Users | 8 | ~2,200 | High |
| User Profiles | 4 | ~900 | Very High |
| Voucher / Printing | 9 | ~800 | High |
| Reports / Sales | 5 | ~1,600 | High |
| Dashboard | 3 | ~700 | Medium |
| Settings / Config | 6 | ~700 | High |
| System / Scheduler | 2 | ~300 | Low |
| Traffic Monitor | 2 | ~200 | Medium |
| Process Actions | 16 | ~500 | Medium |
| DHCP / Status | 3 | ~150 | Low |
| Language / i18n | 6 | ~600 | Low |

---

## 4. Dependencies

### PHP (Built-in only — no Composer)
| Function | Usage |
|----------|-------|
| `session_*` | Auth + state management |
| `fopen/fwrite/file_get_contents` | Config writes, template editing |
| `move_uploaded_file / getimagesize` | Logo upload |
| `fsockopen` | Ping test |
| `date / date_default_timezone_set` | Report filtering |
| `rand` | Username generation |
| `json_encode` | Traffic monitor AJAX |
| `ob_start('ob_gzhandler')` | Gzip output on voucher pages |
| `opendir / readdir` | Logo file listing |

### JavaScript Libraries (all vendored, no CDN)
| Library | Version | Size | Purpose |
|---------|---------|------|---------|
| jQuery | ~3.x | 84.9 KB | AJAX, DOM |
| Highcharts | ~9.x | ~350 KB | Charts |
| QRious | 4.0.2 | 17.2 KB | QR codes |
| Pace.js | — | 12.1 KB | Page loader |
| CodeMirror | — | 254.5 KB | Template editor |
| Font Awesome | 4.7 | — | Icons |

### Obsolete / Replace in Flutter
| Item | Status | Flutter Replacement |
|------|--------|---------------------|
| Google Charts QR API | ⚠️ Deprecated (still referenced) | `qr_flutter` |
| Classic BT URI scheme | ⚠️ Commented out legacy | `flutter_bluetooth_serial` |
| Highcharts | Replace | `fl_chart` or `syncfusion_flutter_charts` |
| CodeMirror editor | Replace | `flutter_code_editor` |
| jQuery AJAX | Replace | Dart `http` / `dio` package |
| Font Awesome 4 | Replace | Material Icons 3 |

---

## 5. Top 20 Largest Files

| File | Lines |
|------|-------|
| lib/routeros_api.class.php | 647 |
| index.php | 608 |
| hotspot/generateuser.php | 481 |
| hotspot/userbyname.php | 461 |
| report/selling.php | 456 |
| report/print.php | 443 |
| dashboard/home.php | 403 |
| include/menu.php | 389 |
| hotspot/listquickprint.php | 373 |
| hotspot/userprofilebyname.php | 315 |
| dashboard/aload.php | 283 |
| hotspot/users.php | 269 |
| hotspot/quickuser.php | 267 |
| settings/settings.php | 262 |
| hotspot/adduserprofile.php | 254 |
| report/userlog.php | 252 |
| include/userlog.php | 251 |
| lang/tr.php | 211 |
| voucher/print.php | 209 |
| hotspot/exportusers.php | 205 |

---

*Report 1 of 7 — DevKuroTik Migration Audit*
