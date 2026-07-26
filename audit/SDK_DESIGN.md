# SDK DESIGN — DevKuroTik
> Dart SDK modules extracted from Mikhmon v3 for the DevKuroTik Flutter app.
> Each SDK is an independent Dart package with its own tests and documentation.

---

## Overview

```
devkurotik/
├── packages/
│   ├── mikrotik_sdk/       ← Core: TCP connection + binary protocol
│   ├── hotspot_sdk/        ← Hotspot users, profiles, active, cookies
│   ├── system_sdk/         ← System info, scheduler, reboot, scripts
│   ├── report_sdk/         ← Sales records + user login log (via /system/script)
│   ├── traffic_sdk/        ← Interface monitoring + traffic samples
│   ├── ppp_sdk/            ← PPP secrets, profiles, active sessions
│   └── queue_sdk/          ← Simple queues, tree queues
└── app/                    ← Flutter app consuming all SDKs
```

---

## 1. `mikrotik_sdk` — Core RouterOS API Client

### Purpose
Dart implementation of the MikroTik RouterOS binary API protocol. Replaces `lib/routeros_api.class.php`. All other SDKs depend on this.

### Class: `MikrotikClient`

```dart
class MikrotikClient {
  final String host;
  final int port;          // default: 8728
  final int sslPort;       // default: 8729
  final bool useSsl;
  final Duration timeout;  // default: 3s
  final int maxRetries;    // default: 5

  // Connection lifecycle
  Future<void> connect(String username, String password);
  Future<void> disconnect();
  bool get isConnected;

  // Low-level API
  Future<List<Map<String, String>>> command(
    String path, {
    Map<String, String> query  = const {},  // ?key=val filters
    Map<String, String> params = const {},  // =key=val setters
    bool countOnly = false,
    List<String>? proplist,
  });

  // Execute (fire-and-forget, no response expected)
  Future<void> execute(String path);

  // Stream (for monitor-traffic / subscribe)
  Stream<Map<String, String>> stream(String path, Map<String, String> params);
}
```

### Class: `MikrotikCredentials`
```dart
class MikrotikCredentials {
  final String host;
  final String username;
  final String password;    // stored in flutter_secure_storage
  final int port;
  final bool useSsl;

  // Serialization
  Map<String, dynamic> toMap();
  factory MikrotikCredentials.fromMap(Map<String, dynamic> map);
}
```

### Class: `RouterosException`
```dart
class RouterosException implements Exception {
  final String message;
  final String? category;  // e.g. "no such item", "not permitted"
  final bool isFatal;
}
```

### Encryption Utilities
```dart
// Replaces the Caesar cipher from routeros_api.class.php
// Uses AES-256-GCM via the `cryptography` Dart package
class RouterosCredentialStore {
  Future<void> save(String id, MikrotikCredentials creds);
  Future<MikrotikCredentials?> load(String id);
  Future<void> delete(String id);
  Future<List<String>> listIds();
}
```

### Random String Utilities (Port from PHP)
```dart
// Replaces randN, randUC, randLC, randULC, randNLC, randNUC, randNULC
class RouterosRandom {
  static const _digits   = '23456789';
  static const _lower    = 'abcdefghjkmnpqrstuvwxyz';
  static const _upper    = 'ABCDEFGHJKMNPQRSTUVWXYZ';

  static String digits(int length);
  static String upper(int length);
  static String lower(int length);
  static String mixed(int length);
  static String digitLower(int length);
  static String digitUpper(int length);
  static String digitMixed(int length);
}
```

### Time Format Utilities (Port from PHP `formatDTM`)
```dart
class RouterosFormat {
  // Convert "1d2h3m4s" / "2h30m" / "45m" etc → HH:MM:SS display
  static String uptime(String dtm);

  // Format bytes: B / KB / MB / GB / TB
  static String bytes(int bytes);

  // Format bits/sec for traffic display
  static String bitrate(int bps);
}
```

### Connection Pool (Enhancement over PHP)
```dart
// PHP reconnects on every request. Flutter can maintain persistent connections.
class MikrotikConnectionPool {
  static final _instance = MikrotikConnectionPool._();
  factory MikrotikConnectionPool() => _instance;

  Future<MikrotikClient> acquire(String routerId);
  Future<void> release(String routerId);
  Future<void> invalidate(String routerId);
  Future<void> closeAll();
}
```

---

## 2. `hotspot_sdk` — Hotspot Management

### Purpose
All operations on `/ip/hotspot/*`. Replaces hotspot/*.php, process/removehotspotuser.php, etc.

```dart
class HotspotSdk {
  final MikrotikClient client;

  // ── Users ──────────────────────────────────────────────
  Future<List<HotspotUser>> users({
    String? profile,
    String? comment,
    bool expiredOnly = false,
  });

  Future<int> userCount({String? profile, String? comment});

  Future<HotspotUser?> userByName(String name);
  Future<HotspotUser?> userById(String id);

  Future<void> addUser(HotspotUserCreate params);
  Future<void> setUser(String id, HotspotUserUpdate params);
  Future<void> removeUser(String id);
  Future<void> removeUsersByComment(String comment);
  Future<void> removeExpiredUsers();
  Future<void> enableUser(String id);
  Future<void> disableUser(String id);
  Future<void> resetCounters(String id);

  // Also removes: script + scheduler associated with user
  Future<void> removeUserFull(String id);

  // ── Profiles ───────────────────────────────────────────
  Future<List<HotspotProfile>> profiles();
  Future<HotspotProfile?> profileByName(String name);

  Future<void> addProfile(HotspotProfileCreate params);
  Future<void> setProfile(String id, HotspotProfileUpdate params);
  // Cascade: removes profile + background sweep scheduler
  Future<void> removeProfile(String id);

  // ── Active Sessions ────────────────────────────────────
  Future<List<HotspotActive>> activeSessions({String? server});
  Future<int> activeCount({String? server});
  // Also removes associated cookie
  Future<void> disconnectSession(String id);

  // ── Cookies ────────────────────────────────────────────
  Future<List<HotspotCookie>> cookies();
  Future<void> removeCookie(String id);

  // ── Hosts ──────────────────────────────────────────────
  Future<List<HotspotHost>> hosts({HostFilter filter = HostFilter.all});
  Future<void> removeHost(String id);

  // ── IP Bindings ────────────────────────────────────────
  Future<List<HotspotIpBinding>> ipBindings();
  Future<void> setIpBinding(String id, {required bool enabled});
  // Cascade: binding + queue + scheduler + ARP + DHCP lease
  Future<void> removeIpBindingFull(String id);

  // ── Servers ────────────────────────────────────────────
  Future<List<HotspotServer>> servers();
}
```

### Models

```dart
class HotspotUser {
  final String id;
  final String name;
  final String password;
  final String profile;
  final String server;
  final bool disabled;
  final String? limitUptime;
  final int? limitBytesTotal;
  final String? comment;
  final String? macAddress;
  final DateTime? createdAt;
  // Decoded from comment field:
  final String? batchCode;
  final DateTime? expiryDate;
  final UserMode mode; // voucher | userpass
}

enum UserMode { voucher, userPass }
enum HostFilter { all, authorized, bypassed }
enum ExpiryMode { none, remove, notice, removeRecord, noticeRecord }

class HotspotProfile {
  final String id;
  final String name;
  final String? rateLimit;
  final String? addressPool;
  final int? sharedUsers;
  final String? parentQueue;
  // Decoded from on-login script:
  final ExpiryMode expiryMode;
  final double price;
  final double sellingPrice;
  final String validity;
  final bool macLock;
}

class HotspotProfileCreate {
  final String name;
  final String? rateLimit;
  final String? addressPool;
  final int sharedUsers;
  final String? parentQueue;
  final ExpiryMode expiryMode;
  final double price;
  final double sellingPrice;
  final String validity;
  final bool macLock;
}
```

### OnLogin RouterScript Generator (Critical)

```dart
/// Generates MikroTik RouterScript for hotspot user profile on-login event.
/// This is the most complex piece of logic in the entire migration.
/// Must produce output identical to Mikhmon's PHP generation.
class OnLoginScriptGenerator {
  static String generate(HotspotProfileCreate params) {
    // Returns full RouterScript string with Mikhmon metadata
    // encoded at comma positions [0..6]
    // Handles all 5 expiry modes with correct MikroTik RouterScript syntax
  }

  static HotspotProfileCreate decode(String onLoginScript) {
    // Parses existing on-login script back to typed params
    // Reads comma positions [1..6] for Mikhmon metadata
  }

  static String generateSweepScript(String profileName, ExpiryMode mode) {
    // Generates the background sweep RouterScript body for /system/scheduler
  }
}
```

### User Batch Generator

```dart
class HotspotBatchGenerator {
  static Future<List<HotspotUserCreate>> generate({
    required int count,
    required String profile,
    required String server,
    required UserMode mode,
    required CharacterSet charSet,
    required int usernameLength,
    String prefix = '',
    String? limitUptime,
    int? limitBytesTotal,
    String? extraComment,
  });
}

enum CharacterSet { lower, upper, mixed, numeric, digitLower, digitUpper, digitMixed }
```

---

## 3. `system_sdk` — System Operations

### Purpose
All `/system/*` operations. Includes the `/system/script` data-store pattern used by Mikhmon for QuickPrint configs.

```dart
class SystemSdk {
  final MikrotikClient client;

  // ── Resource / Info ────────────────────────────────────
  Future<SystemResource> resources();
  Future<SystemClock> clock();
  Future<RouterboardInfo> routerboard();
  Future<String> identity();

  // ── Control ────────────────────────────────────────────
  Future<void> reboot();
  Future<void> shutdown();

  // ── Scheduler ──────────────────────────────────────────
  Future<List<SystemScheduler>> schedulers();
  Future<SystemScheduler?> schedulerByName(String name);
  Future<void> addScheduler(SystemSchedulerCreate params);
  Future<void> setScheduler(String id, SystemSchedulerUpdate params);
  Future<void> removeScheduler(String id);
  Future<void> enableScheduler(String id);
  Future<void> disableScheduler(String id);

  // ── Scripts (QuickPrint store) ─────────────────────────
  Future<List<SystemScript>> scripts({String? comment});
  Future<SystemScript?> scriptByName(String name);
  Future<void> addScript(SystemScriptCreate params);
  Future<void> setScript(String id, SystemScriptUpdate params);
  Future<void> removeScript(String id);
  Future<void> removeScripts(List<String> ids);

  // ── Logging ────────────────────────────────────────────
  Future<List<LogEntry>> log({String topics = 'hotspot,info,debug'});
  Future<bool> hasLoggingRule(String prefix);
  Future<void> ensureLoggingRule({String prefix = '->', String topics = 'hotspot,info,debug'});
}
```

### QuickPrint Package Store

```dart
class QuickPrintRepository {
  final SystemSdk system;

  Future<List<QuickPrintPackage>> all();
  Future<QuickPrintPackage?> byName(String name);
  Future<void> save(QuickPrintPackage pkg);  // add or update
  Future<void> delete(String id);

  // Encodes/decodes # delimited source string
  static String encode(QuickPrintPackage pkg);
  static QuickPrintPackage decode(SystemScript script);
}

class QuickPrintPackage {
  final String? id;       // RouterOS .id (null for new)
  final String name;
  final String server;
  final UserMode mode;
  final int usernameLength;
  final String prefix;
  final CharacterSet charSet;
  final String profile;
  final String? limitUptime;
  final int? limitBytesTotal;
  final String? comment;
}
```

---

## 4. `report_sdk` — Sales Reports

### Purpose
Wraps the `/system/script`-as-database pattern used by Mikhmon for sales records and user login logs.

```dart
class ReportSdk {
  final MikrotikClient client;

  // ── Sales Records ──────────────────────────────────────
  Future<List<SaleRecord>> sales({
    DateTime? date,
    String? month,        // format: "Jan2025"
    String? usernamePrefix,
    String? comment,
    DateTimeRange? range,
  });

  Future<SalesSummary> summary({DateTime? date, String? month});

  Future<void> deleteByDay(DateTime date);
  Future<void> deleteByMonth(String month);  // "Jan2025"
  Future<void> deleteByIds(List<String> ids);

  // ── User Login Log ─────────────────────────────────────
  Future<List<LoginRecord>> loginLog({
    DateTime? date,
    String? month,
  });

  Future<void> deleteLogByDay(DateTime date);
  Future<void> deleteLogByMonth(String month);
}
```

### Models

```dart
class SaleRecord {
  final String id;           // RouterOS script .id
  final DateTime dateTime;   // Parsed from script name
  final String username;
  final double price;
  final String ipAddress;
  final String macAddress;
  final String validity;
  final String profile;
  final String? comment;

  // Parse from RouterOS script name field:
  // "Jan/01/2025-|-14:30:00-|-john-|-15000-|-192.168.1.5-|-AA:BB:CC-|-1day-|-daily-|-vc-abc"
  factory SaleRecord.fromScript(Map<String, String> script);
}

class SalesSummary {
  final int totalVouchers;
  final double totalIncome;
  final Map<int, double> byDay;  // day-of-month → total income
}

class LoginRecord {
  final String id;
  final DateTime dateTime;
  final String username;
  final String ipAddress;
  final String macAddress;
  final String validity;
}
```

---

## 5. `traffic_sdk` — Interface Traffic Monitor

```dart
class TrafficSdk {
  final MikrotikClient client;

  Future<List<NetworkInterface>> interfaces();

  // Single sample
  Future<TrafficSample> sample(String interfaceName);

  // Continuous stream (replaces 3-second AJAX polling)
  Stream<TrafficSample> monitor(
    String interfaceName, {
    Duration interval = const Duration(seconds: 3),
    int maxSamples = 20,
  });
}

class TrafficSample {
  final DateTime timestamp;
  final int txBitsPerSecond;
  final int rxBitsPerSecond;
  // Formatted strings
  String get txFormatted => RouterosFormat.bitrate(txBitsPerSecond);
  String get rxFormatted => RouterosFormat.bitrate(rxBitsPerSecond);
}

class NetworkInterface {
  final String id;
  final String name;
  final String type;
  final bool running;
  final bool disabled;
}
```

---

## 6. `ppp_sdk` — PPP/PPPoE Management

### Purpose
Implements the PPP module that is referenced in `index.php` but missing from the Mikhmon v3 source tree.

```dart
class PppSdk {
  final MikrotikClient client;

  // ── Secrets (PPPoE users) ──────────────────────────────
  Future<List<PppSecret>> secrets({String? profile, String? service});
  Future<PppSecret?> secretByName(String name);
  Future<void> addSecret(PppSecretCreate params);
  Future<void> setSecret(String id, PppSecretUpdate params);
  Future<void> removeSecret(String id);
  Future<void> enableSecret(String id);
  Future<void> disableSecret(String id);

  // ── Active Sessions ────────────────────────────────────
  Future<List<PppActive>> activeSessions();
  Future<void> disconnectSession(String id);

  // ── Profiles ───────────────────────────────────────────
  Future<List<PppProfile>> profiles();
  Future<void> addProfile(PppProfileCreate params);
  Future<void> setProfile(String id, PppProfileUpdate params);
  Future<void> removeProfile(String id);
}

class PppSecret {
  final String id;
  final String name;
  final String password;
  final String service;   // pppoe / pptp / l2tp / any
  final String? profile;
  final String? remoteAddress;
  final String? localAddress;
  final bool disabled;
  final String? comment;
}

class PppActive {
  final String id;
  final String name;
  final String service;
  final String address;
  final String uptime;
  final String? encoding;
}
```

---

## 7. `queue_sdk` — Queue Management

```dart
class QueueSdk {
  final MikrotikClient client;

  // ── Simple Queues ──────────────────────────────────────
  Future<List<SimpleQueue>> simpleQueues({bool excludeDynamic = true});
  Future<SimpleQueue?> simpleQueueByName(String name);
  Future<void> addSimpleQueue(SimpleQueueCreate params);
  Future<void> setSimpleQueue(String id, SimpleQueueUpdate params);
  Future<void> removeSimpleQueue(String id);
  Future<void> enableSimpleQueue(String id);
  Future<void> disableSimpleQueue(String id);

  // ── Tree Queues ────────────────────────────────────────
  Future<List<TreeQueue>> treeQueues();
  Future<void> removeTreeQueue(String id);
}

class SimpleQueue {
  final String id;
  final String name;
  final String target;
  final String? maxLimit;    // "1M/2M"
  final String? burstLimit;
  final bool dynamic;
  final bool disabled;
  final String? comment;
  final String? parent;
}
```

---

## 8. SDK Implementation Recommendations

### Dart Implementation (Primary)

```yaml
# mikrotik_sdk/pubspec.yaml
name: mikrotik_sdk
description: MikroTik RouterOS API client for Dart/Flutter
version: 1.0.0
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  cryptography: ^2.7.0        # AES-256-GCM for credential storage
  flutter_secure_storage: ^9.0.0
  meta: ^1.9.0
dev_dependencies:
  test: ^1.24.0
  mockito: ^5.4.0
```

### Go Implementation (Optional Microservice)

```go
// go-mikrotik-sdk
package mikrotik

type Client struct {
    Host     string
    Port     int
    Username string
    Password string
    conn     net.Conn
    mu       sync.Mutex
}

func (c *Client) Connect() error
func (c *Client) Disconnect() error
func (c *Client) Command(path string, opts ...CommandOpt) ([]Record, error)
func (c *Client) Execute(path string) error
func (c *Client) Stream(path string) (<-chan Record, error)

// Use case: devkurotik-sync Go service for background operations
// - Offline queue flushing
// - Periodic data sync to cloud
// - Push notification dispatching
```

### Native Android Plugin (Kotlin)

```kotlin
// devkurotik_android_plugin/
// MethodChannel: "devkurotik/thermal_print"
class ThermalPrintPlugin : FlutterPlugin, MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "printReceipt" -> printViaQuickPrinter(call.arguments)
            "printEscPos"  -> printEscPos(call.arguments)
            "isAvailable"  -> checkPrinterAvailability(result)
        }
    }
    
    private fun printViaQuickPrinter(args: Any?) {
        // Build Android Intent for QuickPrinter app
        // intent://TEXT#Intent;scheme=quickprinter;
        //   package=pe.diegoveloper.printerserverapp;end;
    }
}

// MethodChannel: "devkurotik/widget"
class WidgetPlugin : FlutterPlugin, MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updateWidget" -> AppWidgetManager.updateWidget(call.arguments)
        }
    }
}
```

### Native iOS Plugin (Swift)

```swift
// devkurotik_ios_plugin/
// FlutterMethodChannel: "devkurotik/biometric"
class BiometricPlugin: NSObject, FlutterPlugin {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "authenticate":
            authenticateWithBiometrics(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

---

## 9. Testing Strategy

```
mikrotik_sdk/test/
  unit/
    binary_encoding_test.dart     ← test encodeLength edge cases
    login_handshake_test.dart     ← test pre/post v6.43 login
    format_test.dart              ← test formatDTM, formatBytes, formatBitrate
    random_test.dart              ← test character set generators
  integration/
    connection_test.dart          ← requires real RouterOS or mock server
    
hotspot_sdk/test/
  unit/
    onlogin_generator_test.dart   ← test all 5 expiry modes → RouterScript
    onlogin_decoder_test.dart     ← test parse existing on-login strings
    batch_generator_test.dart     ← test N user generation, no duplicates
    comment_parser_test.dart      ← test dual-use comment field parsing

report_sdk/test/
  unit/
    sale_record_parser_test.dart  ← test name field pipe-delimited parsing
    date_filter_test.dart         ← test filter by day/month/range
```

---

*Report 5 of 7 — DevKuroTik Migration Audit*
