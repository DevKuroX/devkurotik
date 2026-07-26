# API ENDPOINTS — Mikhmon v3 RouterOS API Audit
> **Total Unique Endpoints:** 30
> **Total API Call-Sites:** ~112
> **Most Used:** `/ip/hotspot/user/print` (31 call-sites)

---

## 1. RouterOS API Class Overview

| Property | Value |
|----------|-------|
| File | `lib/routeros_api.class.php` |
| Class | `RouterosAPI` |
| Protocol | MikroTik RouterOS Binary API (TCP) |
| Default Port | 8728 |
| SSL Port | 8729 |
| Encoding | Variable-length word framing (1–5 byte prefix) |
| Login Mode | Auto-detect: post-v6.43 plain OR pre-v6.43 MD5 challenge |
| Connect Timeout | 3 seconds |
| Retry Attempts | 5 with 3s delay |
| Disconnect | `__destruct()` auto-called at end of PHP request |

### API Class Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `connect($ip, $login, $password)` | `bool` | Open TCP socket + perform login handshake |
| `disconnect()` | `void` | Close socket |
| `write($command, $param2=true)` | `bool` | Send single API word (length-prefixed) |
| `read($parse=true)` | `array` | Read full response until `!done` |
| `comm($command, $arr=[])` | `array` | High-level: write + read + parse |
| `parseResponse($response)` | `array` | Map `!re` entries to key→value array |
| `encodeLength($length)` | `string` | MikroTik variable-length byte encoding |
| `arrayChangeKeyName(&$array)` | `array` | Replace `-` and `/` in keys with `_` |

### `comm()` Parameter Convention

| Key Prefix | RouterOS Meaning | Example |
|-----------|-----------------|---------|
| `?key` | Query filter (equals) | `"?profile" => "daily"` |
| `~key` | Query filter (regex) | `"~name" => "^usr.*"` |
| `=key` | Attribute setter | `"=name" => "john"` |
| `count-only` | Return count only | `"count-only" => ""` |
| `.proplist` | Property projection | `"=.proplist" => ".id,name"` |

### Extra Utility Functions in `routeros_api.class.php`

| Function | Purpose |
|----------|---------|
| `encrypt($string, $key=128)` | XOR+base64 — stores RouterOS passwords |
| `decrypt($string, $key=128)` | Reverse XOR+base64 |
| `formatDTM($dtm)` | MikroTik uptime string → HH:MM:SS |
| `formatInterval($dtm)` | Remove trailing unit chars |
| `randN($len)` | Random digit string |
| `randUC($len)` | Random uppercase string |
| `randLC($len)` | Random lowercase string |
| `randULC($len)` | Random mixed-case string |
| `randNLC($len)` | Random digits + lowercase |
| `randNUC($len)` | Random digits + uppercase |
| `randNULC($len)` | Random digits + mixed-case |

---

## 2. Complete Endpoint Table

| # | Endpoint | Operation | Module | Call-Sites | Files |
|---|----------|-----------|--------|-----------|-------|
| 1 | `/ip/hotspot/user/print` | READ | hotspot | 31 | users.php, exportusers.php, adduser.php, userbyname.php, userbyprofile.php, quickuser.php, dashboard/home.php, aload.php, removeexpiredhotspotuser.php, removehotspotuserbycomment.php, removehotspotuser.php, resethotspotuser.php, status/status.php, voucher/print.php |
| 2 | `/ip/hotspot/user/add` | WRITE | hotspot | 5 | adduser.php, generateuser.php (×2), quickuser.php (×2) |
| 3 | `/ip/hotspot/user/set` | WRITE | hotspot | 4 | userbyname.php, disablehotspotuser.php, enablehotspotuser.php, resethotspotuser.php |
| 4 | `/ip/hotspot/user/remove` | DELETE | hotspot | 4 | removehotspotuser.php (×2), removeexpiredhotspotuser.php, removehotspotuserbycomment.php |
| 5 | `/ip/hotspot/user/reset-counters` | EXECUTE | hotspot | 1 | resethotspotuser.php |
| 6 | `/ip/hotspot/user/profile/print` | READ | hotspot | 17 | userprofile.php, adduserprofile.php, adduser.php, userbyname.php (×2), userbyprofile.php, userprofilebyname.php (×2), generateuser.php (×3), listquickprint.php (×2), status/index.php, voucher/print.php, getvalidprice.php |
| 7 | `/ip/hotspot/user/profile/add` | WRITE | hotspot | 1 | adduserprofile.php |
| 8 | `/ip/hotspot/user/profile/set` | WRITE | hotspot | 1 | userprofilebyname.php |
| 9 | `/ip/hotspot/user/profile/remove` | DELETE | hotspot | 1 | removeuserprofile.php |
| 10 | `/ip/hotspot/active/print` | READ | hotspot | 7 | hotspotactive.php (×4), dashboard/home.php, aload.php, removeuseractive.php |
| 11 | `/ip/hotspot/active/remove` | DELETE | hotspot | 1 | removeuseractive.php |
| 12 | `/ip/hotspot/cookie/print` | READ | hotspot | 3 | cookies.php (×2), removeuseractive.php |
| 13 | `/ip/hotspot/cookie/remove` | DELETE | hotspot | 2 | removecookie.php, removeuseractive.php |
| 14 | `/ip/hotspot/host/print` | READ | hotspot | 6 | hosts.php (×6 with filters) |
| 15 | `/ip/hotspot/host/remove` | DELETE | hotspot | 1 | removehost.php |
| 16 | `/ip/hotspot/ip-binding/print` | READ | hotspot | 2 | ipbinding.php (×2) |
| 17 | `/ip/hotspot/ip-binding/set` | WRITE | hotspot | 2 | pipbinding.php (enable/disable) |
| 18 | `/ip/hotspot/ip-binding/remove` | DELETE | hotspot | 1 | pipbinding.php |
| 19 | `/ip/hotspot/print` | READ | hotspot | 4 | adduser.php, generateuser.php, userbyname.php, listquickprint.php |
| 20 | `/ip/pool/print` | READ | ip | 2 | adduserprofile.php, userprofilebyname.php |
| 21 | `/ip/arp/print` | READ | ip | 1 | pipbinding.php |
| 22 | `/ip/arp/remove` | DELETE | ip | 1 | pipbinding.php |
| 23 | `/ip/dhcp-server/lease/print` | READ | dhcp | 3 | dhcpleases.php (×2), pipbinding.php |
| 24 | `/ip/dhcp-server/lease/remove` | DELETE | dhcp | 1 | pipbinding.php |
| 25 | `/queue/simple/print` | READ | queue | 3 | adduserprofile.php, userprofilebyname.php, pipbinding.php |
| 26 | `/queue/simple/remove` | DELETE | queue | 1 | pipbinding.php |
| 27 | `/system/scheduler/print` | READ | system | 10 | scheduler.php (×2), userprofile.php, userprofilebyname.php, userbyname.php, pipbinding.php, removeuserprofile.php, removehotspotuser.php (×2), resethotspotuser.php |
| 28 | `/system/scheduler/add` | WRITE | system | 2 | adduserprofile.php, userprofilebyname.php |
| 29 | `/system/scheduler/set` | WRITE | system | 4 | adduserprofile.php, userprofilebyname.php, pscheduler.php (×2) |
| 30 | `/system/scheduler/remove` | DELETE | system | 8 | adduserprofile.php, userprofilebyname.php, pscheduler.php, pipbinding.php, removeuserprofile.php, removehotspotuser.php (×2), resethotspotuser.php |
| 31 | `/system/script/print` | READ | system | 15 | listquickprint.php (×2), quickprint.php, quickuser.php, removehotspotuser.php (×2), selling.php (×4), livereport.php, print.php (×4) |
| 32 | `/system/script/add` | WRITE | system | 1 | listquickprint.php |
| 33 | `/system/script/set` | WRITE | system | 1 | listquickprint.php |
| 34 | `/system/script/remove` | DELETE | system | 5 | listquickprint.php, removehotspotuser.php (×2), removereport.php, selling.php |
| 35 | `/system/clock/print` | READ | system | 4 | dashboard/home.php, aload.php, selling.php, report/print.php |
| 36 | `/system/resource/print` | READ | system | 2 | dashboard/home.php, aload.php |
| 37 | `/system/routerboard/print` | READ | system | 2 | dashboard/home.php, aload.php |
| 38 | `/system/identity/print` | READ | system | 1 | index.php |
| 39 | `/system/logging/print` | READ | system | 2 | dashboard/home.php (commented), aload.php |
| 40 | `/system/logging/add` | WRITE | system | 2 | dashboard/home.php (commented), aload.php |
| 41 | `/system/reboot` | EXECUTE | system | 1 | process/reboot.php |
| 42 | `/system/shutdown` | EXECUTE | system | 1 | process/shutdown.php |
| 43 | `/sys/sch/print` | READ | system | 1 | status/status.php ⚠️ non-canonical alias |
| 44 | `/log/print` | READ | log | 3 | hotspot/log.php, dashboard/home.php (commented), aload.php |
| 45 | `/interface/print` | READ | interface | 2 | dashboard/home.php, traffic/trafficmonitor.php |
| 46 | `/interface/monitor-traffic` | EXECUTE | interface | 1 | traffic/traffic.php |
| 47 | `/ppp/active/remove` | DELETE | ppp | 1 | process/removepactive.php |

---

## 3. Endpoints by Module

### 🔴 Hotspot (19 endpoints — core module)
```
/ip/hotspot/user/print          READ    ← most used (31 sites)
/ip/hotspot/user/add            WRITE
/ip/hotspot/user/set            WRITE
/ip/hotspot/user/remove         DELETE
/ip/hotspot/user/reset-counters EXECUTE
/ip/hotspot/user/profile/print  READ    ← 2nd most used (17 sites)
/ip/hotspot/user/profile/add    WRITE
/ip/hotspot/user/profile/set    WRITE
/ip/hotspot/user/profile/remove DELETE
/ip/hotspot/active/print        READ
/ip/hotspot/active/remove       DELETE
/ip/hotspot/cookie/print        READ
/ip/hotspot/cookie/remove       DELETE
/ip/hotspot/host/print          READ
/ip/hotspot/host/remove         DELETE
/ip/hotspot/ip-binding/print    READ
/ip/hotspot/ip-binding/set      WRITE
/ip/hotspot/ip-binding/remove   DELETE
/ip/hotspot/print               READ
```

### 🟠 System (17 endpoints — used as data store)
```
/system/scheduler/print   READ     ← used for user expiry + profile monitors
/system/scheduler/add     WRITE
/system/scheduler/set     WRITE
/system/scheduler/remove  DELETE   ← cascades on user/profile delete
/system/script/print      READ     ← used as FLAT FILE DATABASE for sales records
/system/script/add        WRITE    ← used to store QuickPrint configs
/system/script/set        WRITE
/system/script/remove     DELETE
/system/clock/print       READ
/system/resource/print    READ
/system/routerboard/print READ
/system/identity/print    READ
/system/logging/print     READ
/system/logging/add       WRITE
/system/reboot            EXECUTE
/system/shutdown          EXECUTE
/sys/sch/print            READ     ⚠️ non-canonical alias
```

### 🟡 IP / DHCP (5 endpoints)
```
/ip/pool/print              READ
/ip/arp/print               READ
/ip/arp/remove              DELETE
/ip/dhcp-server/lease/print READ
/ip/dhcp-server/lease/remove DELETE
```

### 🟢 Queue (2 endpoints)
```
/queue/simple/print   READ
/queue/simple/remove  DELETE
```

### 🔵 Log / Interface / PPP (4 endpoints)
```
/log/print                  READ
/interface/print            READ
/interface/monitor-traffic  EXECUTE
/ppp/active/remove          DELETE
```

---

## 4. Most Frequently Used Endpoints

| Rank | Endpoint | Call-Sites |
|------|----------|-----------|
| 1 | `/ip/hotspot/user/print` | 31 |
| 2 | `/ip/hotspot/user/profile/print` | 17 |
| 3 | `/system/script/print` | 15 |
| 4 | `/system/scheduler/print` | 10 |
| 5 | `/ip/hotspot/host/print` | 6 |
| 6 | `/ip/hotspot/user/add` | 5 |
| 7 | `/system/script/remove` | 5 |
| 8 | `/ip/hotspot/active/print` | 7 |
| 9 | `/system/scheduler/remove` | 8 |
| 10 | `/system/clock/print` | 4 |

---

## 5. Low-Level `write()/read()` Usage (bypasses `comm()`)

| File | Lines | Command | Reason |
|------|-------|---------|--------|
| `process/reboot.php` | 29 | `/system/reboot` | No response expected |
| `process/shutdown.php` | 29 | `/system/shutdown` | No response expected |
| `report/selling.php` | 47–56 | `/system/script/print` | Multi-word with `.proplist` |
| `report/selling.php` | 59–69 | `/system/script/remove` | Bulk delete loop |
| `report/userlog.php` | 31–55 | `/system/script/print` | Non-standard `?=key=val` syntax ⚠️ |

---

## 6. Critical Design Issues

### 6.1 `/system/script` Used as a Database
```
Sales records stored as RouterOS scripts:
  name   = "Jan/01/2025-|-14:30:00-|-john-|-15000-|-192.168.1.5-|-AA:BB:CC-|-1day"
  owner  = "Jan2025"          ← used as month-year index
  source = "Jan/01/2025"      ← used as date index
  comment = "mikhmon"         ← used as record type marker

QuickPrint configs stored as RouterOS scripts:
  name    = "Package Name"
  source  = "#server#vc#5#prefix#lower#daily#0s#0#comment"  ← # delimited config
  comment = "QuickPrintMikhmon"  ← differentiates from sales records
```

### 6.2 on-login Script as Metadata Store
```
Profile on-login script stores Mikhmon metadata at fixed comma positions:
  [0] = RouterScript preamble
  [1] = expiry mode (none/remc/ntfc/remcrc/ntfcrc)
  [2] = price (IDR amount)
  [3] = validity string (e.g. "1 Day")
  [4] = selling price
  [5] = (empty)
  [6] = lock setting (lock/nolock)

⚠ This is NOT standard RouterOS — it is a Mikhmon-specific convention
⚠ Any edit to the profile MUST preserve comma positions exactly
```

### 6.3 Comment Field Dual-Use
```
User comment field serves two purposes:
  Before first login:  "vc-RANDCODE-DATE-COMMENT" (batch identifier)
  After first login:   "Jan/01/2025 14:30:00 vc-RANDCODE" (expiry + original)

Parsing requires detecting which format is present.
```

### 6.4 Non-Standard API Usage
```
status/status.php line 45:
  $API->comm("/sys/sch/print", ...)    ← abbreviated path (works but inconsistent)

report/userlog.php lines 33, 43:
  $API->write('?=source=' . $idhr)     ← non-standard ?= prefix (should be ?source=)
```

---

## 7. Missing Abstractions (Flutter SDK Opportunities)

| Current Pattern | Occurrences | Recommended SDK Method |
|----------------|-------------|----------------------|
| `comm("/ip/hotspot/user/print", ["?profile"=>...])` | 31 | `hotspot.users(filter?)` |
| `comm("/ip/hotspot/user/profile/print")` | 17 | `hotspot.profiles()` |
| `comm("/system/script/print", ["?comment"=>"mikhmon"])` | 15 | `report.getSales(filter?)` |
| `comm("/system/scheduler/print", ["?name"=>...])` | 10 | `scheduler.findByName(name)` |
| `comm("/system/resource/print")` | 2 | `system.resources()` |
| `comm("/interface/monitor-traffic", ...)` | 1 | `traffic.monitor(iface)` |
| `write('/system/reboot')` | 1 | `system.reboot()` |
| `write('/system/shutdown')` | 1 | `system.shutdown()` |

---

## 8. Proposed Flutter SDK API Mapping

```dart
// mikrotik_sdk — core connection
final client = MikrotikClient(host, user, password);
await client.connect();
await client.disconnect();

// hotspot_sdk
final users = await client.hotspot.users(profile: 'daily');
await client.hotspot.addUser(name, password, profile, ...);
await client.hotspot.removeUser(id);
await client.hotspot.setUser(id, {disabled: true});
await client.hotspot.resetCounters(id);
final profiles = await client.hotspot.profiles();
await client.hotspot.addProfile(name, rateLimit, onLogin, ...);
final active = await client.hotspot.activeSessions();
await client.hotspot.removeSession(id);

// system_sdk
final res = await client.system.resources();
final clock = await client.system.clock();
await client.system.reboot();
await client.system.shutdown();
final schedulers = await client.system.schedulers();
await client.system.addScheduler(name, interval, onEvent);

// report_sdk (wraps /system/script)
final sales = await client.report.getSales(date: '2025-01-01');
await client.report.deleteSales(ids);

// traffic_sdk
final sample = await client.traffic.monitor(interface: 'ether1');
```

---

*Report 2 of 7 — DevKuroTik Migration Audit*
