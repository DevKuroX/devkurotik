# FEATURE MATRIX — Mikhmon v3
> Complete inventory of all features, migration priorities, and difficulty ratings.

---

## Legend

| Priority | Meaning |
|----------|---------|
| 🔴 Critical | Core business function — must exist in v1 |
| 🟠 High | Important, needed in v1.x |
| 🟡 Medium | Nice to have, v2 |
| 🟢 Low | Optional, v2+ |

| Difficulty | Meaning |
|-----------|---------|
| Easy | Direct API call → Flutter widget, no special logic |
| Medium | Some state management / formatting logic |
| Hard | Complex business logic or UI |
| Complex | Deep domain knowledge required, risky to migrate |

---

## Module 1 — Hotspot User Management

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| List users (all) | Show all hotspot users with profile, uptime, bytes, MAC | 🔴 Critical | Easy | `/ip/hotspot/user/print` → `ListView` |
| List users by profile | Filter user list by profile name | 🔴 Critical | Easy | Add filter param |
| List users by comment | Filter by batch code prefix | 🔴 Critical | Easy | `?comment=` filter |
| List expired users | Users with `limit-uptime=1s` | 🔴 Critical | Easy | Single filter |
| Add single user | Form: server, name, pass, profile, limits, comment | 🔴 Critical | Medium | Validate fields before API call |
| Edit user | Change name/pass/profile/limits/disabled/comment | 🔴 Critical | Medium | Pre-populate form from API |
| Delete single user | Remove user + cascade: script + scheduler | 🔴 Critical | Medium | Must also clean up script/scheduler |
| Bulk delete by comment | Delete all users in a batch | 🟠 High | Medium | Batch `.id` collection then remove |
| Bulk delete expired | Remove all limit-uptime=1s users | 🟠 High | Medium | Filter + batch remove |
| Enable / Disable user | Toggle `disabled` flag | 🔴 Critical | Easy | Single `set` call |
| Reset user counters | Zero uptime + bytes, clear expiry scheduler | 🟠 High | Medium | `reset-counters` + scheduler remove |
| User detail page | Show all user metadata, expiry status, QR code | 🔴 Critical | Hard | Aggregate: user + scheduler + profile on-login decode |
| WhatsApp share | Share credentials via WA deep link | 🟡 Medium | Easy | `url_launcher` → `wa.me` URL |
| Export to CSV | Download all users as CSV | 🟠 High | Easy | `csv` package + `share_plus` |
| Export to RouterOS script | Download as `/ip hotspot user add` commands | 🟡 Medium | Easy | String template |
| User expiry lookup | Check expiry from comment or scheduler | 🟠 High | Medium | Decode comment field or query scheduler |

---

## Module 2 — Bulk User Generation

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| Generate N users (1–500) | Batch create with configurable params | 🔴 Critical | Hard | Complex: random gen + API loop + temp store |
| Voucher mode (user=pass) | Username equals password | 🔴 Critical | Easy | Logic flag during generation |
| User+pass mode | Separate username and password | 🔴 Critical | Easy | Two random strings |
| Character set selection | lower / upper / mixed / numeric variants | 🔴 Critical | Medium | Dart random string helpers |
| Username prefix support | Prepend fixed prefix to generated names | 🟠 High | Easy | String concatenation |
| Profile/validity preview | Show price/validity before generating | 🟠 High | Medium | Decode on-login script |
| Last batch summary | Show last generated batch metadata | 🟡 Medium | Medium | Local SQLite cache |
| Auto-print after generate | Trigger print immediately post-generation | 🟠 High | Hard | Platform-specific print trigger |

---

## Module 3 — Quick Print (One-Touch)

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| Quick print package cards | Visual dashboard of saved packages | 🔴 Critical | Medium | GridView with package cards |
| Add/edit package | Store package config to MikroTik script | 🔴 Critical | Medium | Encode `#` delimited string → `/system/script/add` |
| Delete package | Remove from RouterOS scripts | 🔴 Critical | Easy | `/system/script/remove` |
| One-touch generate + print | Tap card → generate 1 user → print | 🔴 Critical | Complex | Generate → BT/thermal print in one flow |
| Auto-detect print mode | Mobile: BT thermal, Desktop: browser print | 🟠 High | Hard | Flutter: use `Platform.isAndroid` + BT plugin |

---

## Module 4 — User Profile Management

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| List profiles | Show all profiles with decoded metadata | 🔴 Critical | Medium | Decode on-login string at positions [1..6] |
| Add profile | Create profile + auto-generate on-login RouterScript + scheduler | 🔴 Critical | Complex | Must generate valid RouterScript string |
| Edit profile | Update profile + re-generate on-login + update scheduler | 🔴 Critical | Complex | Same RouterScript generation logic |
| Delete profile | Remove profile + associated scheduler | 🔴 Critical | Medium | Cascade: profile + scheduler |
| Expiry modes | none / remove / notice / remove+record / notice+record | 🔴 Critical | Complex | Each mode generates different RouterScript |
| Rate limit config | Upload/download speed limits | 🔴 Critical | Medium | `rate-limit` format: `512k/1M` |
| Address pool assignment | Link to IP pool | 🟠 High | Easy | Dropdown from `/ip/pool/print` |
| Parent queue assignment | Link to queue | 🟡 Medium | Easy | Dropdown from `/queue/simple/print` |
| MAC lock | Auto-bind MAC on first login | 🟠 High | Hard | Embedded in RouterScript logic |
| Price / selling price | Metadata stored in on-login string | 🔴 Critical | Medium | Parse/encode comma-delimited positions |
| Background sweep scheduler | Auto-creates 2-min sweep per profile | 🔴 Critical | Complex | Must manage lifecycle with profile |

---

## Module 5 — Active Sessions

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| List active sessions | Show IP, MAC, uptime, bytes, server | 🔴 Critical | Easy | `/ip/hotspot/active/print` |
| Filter by server | Show only specific hotspot server | 🟠 High | Easy | `?server=` filter |
| Disconnect session | Remove active session + cookie | 🔴 Critical | Medium | Cascade: active/remove + cookie/remove |
| Auto-refresh | Periodic reload of active list | 🟠 High | Easy | Flutter `Timer.periodic` |
| Tap to open user | Navigate to user detail from active list | 🟡 Medium | Easy | Route push |

---

## Module 6 — Voucher & Printing

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| Print vouchers (browser) | Render HTML voucher and call `window.print()` | 🔴 Critical | Hard | Flutter: generate PDF with `pdf` package |
| Default layout | 220px wide, optional QR | 🔴 Critical | Medium | Replicate layout in Flutter PDF |
| Small layout | 160px wide | 🟡 Medium | Medium | Alternative PDF template |
| Thermal layout | 180px with timestamp | 🔴 Critical | Medium | Thermal-specific formatting |
| QR code on voucher | Encodes login URL | 🔴 Critical | Easy | `qr_flutter` package |
| Print by batch | Print all vouchers for a comment code | 🔴 Critical | Medium | Filter + loop print |
| Print single user | Print one user's voucher | 🔴 Critical | Easy | Single user render |
| Bluetooth thermal print | QuickPrinter Android intent | 🔴 Critical | Complex | `url_launcher` intent OR `flutter_thermal_printer` plugin |
| QR on BT receipt | Embed QR image in BT receipt | 🟠 High | Hard | BT printer ESC/POS image command |
| Voucher template editor | CodeMirror PHP editor for template files | 🟡 Medium | Hard | Replace with Flutter template customizer UI |

---

## Module 7 — Reports & Sales

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| Selling report | List all sales from RouterOS script store | 🔴 Critical | Complex | Parse name field: `date-\|-time-\|-user-\|-price-\|-ip-\|-mac-\|-validity-\|-profile-\|-comment` |
| Filter by day | Show sales for specific date | 🔴 Critical | Medium | `?source=date` filter |
| Filter by month | Show all sales in a month | 🔴 Critical | Medium | `?owner=MonYYYY` filter |
| Filter by username prefix | Search by username | 🟠 High | Easy | Client-side filter |
| Filter by comment | Filter batch code | 🟠 High | Easy | Client-side filter |
| Filter by date range | From/to date range | 🟡 Medium | Medium | Client-side filter + sort |
| CSV export | Download sales as CSV | 🟠 High | Easy | `csv` + `share_plus` |
| Print report | Printable sales list | 🟠 High | Medium | `pdf` package |
| Delete records by day | Remove sales records for a day | 🟠 High | Medium | Batch script remove |
| Delete records by month | Remove all records for a month | 🟠 High | Medium | Batch with `?owner=` filter |
| Auto-sum of price | Total income for filtered view | 🔴 Critical | Easy | `fold()` in Dart |
| Monthly chart | Highcharts area chart per day | 🟠 High | Medium | `fl_chart` AreaChart |
| Live income widget | Today + month totals on dashboard | 🟠 High | Medium | Dashboard card with periodic refresh |
| User login log | Login events with IP/MAC/validity | 🟡 Medium | Medium | Same script store, different field layout |
| Delete log records | Remove log entries | 🟡 Medium | Medium | Batch script remove |

---

## Module 8 — System & Scheduler

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| List schedulers | All system schedulers with run-count | 🟠 High | Easy | `/system/scheduler/print` |
| Enable / Disable scheduler | Toggle scheduler | 🟠 High | Easy | `/system/scheduler/set` |
| Delete scheduler | Remove scheduler entry | 🟠 High | Easy | `/system/scheduler/remove` |
| Router reboot | Confirm + reboot | 🔴 Critical | Easy | `/system/reboot` |
| Router shutdown | Confirm + shutdown | 🔴 Critical | Easy | `/system/shutdown` |

---

## Module 9 — Dashboard

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| System clock / timezone | RouterOS clock display | 🔴 Critical | Easy | `/system/clock/print` |
| System uptime | Formatted uptime string | 🔴 Critical | Easy | `formatDTM()` equivalent in Dart |
| Board name + OS version | Hardware info | 🟠 High | Easy | `/system/resource/print` |
| CPU load + free memory | System resources | 🟠 High | Easy | `/system/resource/print` |
| Hotspot user count | Active + total users | 🔴 Critical | Easy | Two `count-only` calls |
| Live traffic chart | TX/RX real-time chart | 🟠 High | Hard | Poll `/interface/monitor-traffic` + `fl_chart` |
| Hotspot log table | Last 20 hotspot log entries | 🟡 Medium | Medium | `/log/print` with filter |
| Live income widget | Today + month sales totals | 🟠 High | Medium | Periodic fetch from script store |
| Router switcher | Switch between multiple routers | 🔴 Critical | Medium | Dropdown → reconnect |
| Router identity | Display router name | 🟠 High | Easy | `/system/identity/print` |
| Ping test | TCP connectivity check | 🟠 High | Easy | Dart `Socket.connect()` |

---

## Module 10 — IP / DHCP / Network

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| DHCP lease list | Show all DHCP leases | 🟡 Medium | Easy | `/ip/dhcp-server/lease/print` |
| Hotspot cookies list | Session cookies | 🟢 Low | Easy | `/ip/hotspot/cookie/print` |
| Remove cookie | Delete specific cookie | 🟢 Low | Easy | Single remove call |
| IP binding list | Show all IP bindings | 🟡 Medium | Easy | `/ip/hotspot/ip-binding/print` |
| Enable/disable binding | Toggle IP binding | 🟡 Medium | Easy | `set` call |
| Remove binding | Delete binding + cascade (queue/scheduler/ARP/DHCP) | 🟡 Medium | Medium | 4-step cascade delete |
| Hotspot hosts list | All/authorized/bypassed devices | 🟢 Low | Easy | Filtered prints |
| Remove host | Remove host entry | 🟢 Low | Easy | Single remove |
| Hotspot log viewer | RouterOS log filtered by hotspot topic | 🟡 Medium | Easy | `/log/print` |

---

## Module 11 — Settings & Configuration

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| Per-router settings | IP, user, pass, hotspot name, DNS, currency | 🔴 Critical | Medium | Store in Flutter SQLite, not PHP file |
| Theme selection | 5 color themes | 🟡 Medium | Easy | Material 3 `ColorScheme` |
| Language selection | 6 languages | 🟠 High | Medium | Flutter `l10n` / `intl` |
| Logo upload | Per-session custom logo | 🟡 Medium | Medium | `image_picker` + local storage |
| Idle timeout | Auto-logout after inactivity | 🟠 High | Medium | Flutter `InactivityDetector` |
| Auto-reload interval | Dashboard refresh rate | 🟡 Medium | Easy | `Timer.periodic` interval setting |
| BT QR enable/disable | QR code on BT receipts | 🟡 Medium | Easy | Boolean setting |
| Voucher template editor | Edit PHP templates | 🟡 Medium | Hard | Not needed in Flutter — use template builder |
| Multi-router management | Add/edit/delete router sessions | 🔴 Critical | Medium | SQLite `routers` table |

---

## Module 12 — PPP (Referenced but Incomplete in Source)

| Feature | Description | Priority | Difficulty | Migration Notes |
|---------|-------------|----------|-----------|-----------------|
| PPP secrets list | List PPPoE/VPN users | 🟠 High | Easy | `/ppp/secret/print` (not in current source) |
| Add PPP secret | Create PPPoE user | 🟠 High | Medium | Not implemented in this repo |
| Edit PPP secret | Modify PPPoE user | 🟠 High | Medium | Not implemented |
| PPP profiles | Manage PPP profiles | 🟡 Medium | Medium | Not implemented |
| PPP active sessions | List + disconnect active VPN/PPPoE | 🟠 High | Easy | `/ppp/active/remove` exists in process/ |

---

## Undocumented Features

| Feature | Discovery | Priority | Difficulty |
|---------|-----------|----------|-----------|
| on-login script as metadata protocol | Reverse-engineered from adduserprofile.php | 🔴 Critical | Complex |
| `/system/script` as flat-file DB | Reverse-engineered from report/selling.php | 🔴 Critical | Complex |
| Comment field dual-use (batch vs expiry) | Reverse-engineered from users.php + userlog.php | 🔴 Critical | Hard |
| QuickPrint config in RouterOS scripts | Reverse-engineered from listquickprint.php | 🔴 Critical | Hard |
| Anti-fork JS domain lock | Found in obfuscated JS blocks | 🟢 Low | Easy (remove) |
| temp.php encrypted generation cache | Found in generateuser.php | 🟡 Medium | Medium |
| Multi-router simultaneous support | Inferred from `?session=` GET pattern | 🔴 Critical | Medium |
| Background profile-monitor schedulers | Found in adduserprofile.php on-login generation | 🔴 Critical | Complex |

---

## Feature Count Summary

| Module | Total Features | Critical | High | Medium | Low |
|--------|---------------|---------|------|--------|-----|
| Hotspot Users | 16 | 10 | 4 | 2 | 0 |
| Bulk Generation | 8 | 5 | 2 | 1 | 0 |
| Quick Print | 5 | 4 | 1 | 0 | 0 |
| User Profiles | 11 | 7 | 2 | 2 | 0 |
| Active Sessions | 5 | 3 | 2 | 0 | 0 |
| Voucher/Printing | 10 | 6 | 2 | 2 | 0 |
| Reports/Sales | 16 | 5 | 7 | 4 | 0 |
| System/Scheduler | 5 | 2 | 3 | 0 | 0 |
| Dashboard | 11 | 4 | 5 | 2 | 0 |
| IP/DHCP/Network | 10 | 0 | 0 | 4 | 6 |
| Settings/Config | 9 | 4 | 3 | 2 | 0 |
| PPP (partial) | 5 | 0 | 3 | 2 | 0 |
| Undocumented | 8 | 5 | 0 | 2 | 1 |
| **TOTAL** | **119** | **55** | **34** | **23** | **7** |

---

*Report 3 of 7 — DevKuroTik Migration Audit*
