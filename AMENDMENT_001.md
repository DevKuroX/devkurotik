# AMENDMENT_001.md
> Supplemental specification: RouterOS Compatibility Layer.
> Additive amendment to PHASE_1.md and PHASE_2.md.
> Does NOT modify ROADMAP_V1.md, completed phase documents, or any governance source-of-truth.

---

## Amendment Identity

| Field | Value |
|---|---|
| **ID** | AMENDMENT_001 |
| **Type** | Additive Specification |
| **Status** | APPROVED — Pending Implementation |
| **Applies To** | PHASE_1.md (additive), PHASE_2.md (additive) |
| **Does NOT Modify** | ROADMAP_V1.md, GOVERNANCE.md, RULES.md, completed phase docs |
| **Origin** | Findings from real RouterOS v7 CHR integration testing (CHR 7.15.1, 2026-07-26) |
| **Author** | Principal Architect — Governance Audit |
| **Date** | 2026-07-26 |

---

## 1. Purpose

Phase 1 validated the `mikrotik_sdk` binary protocol implementation against RouterOS v7.15.1 (CHR). That validation confirmed the transport layer is correct but also exposed a structural gap: the SDK and application have no formal model for **RouterOS version identity** or **per-router capability state**.

This gap is acceptable for Phase 1 (SDK only) and Phase 2 (router CRUD) as originally scoped. However, it creates forward-risk because:

1. **Phase 3 (Dashboard)** must read `/system/resource/print` — the response schema differs between RouterOS v6 and v7.
2. **Phase 4 (Hotspot)** must read `/ip/hotspot/user/print` — profile field availability differs between versions.
3. **The v6 validation gap** documented in `PHASE_1_VALIDATION_GAP_REPORT.md` cannot be resolved without a formal version model to record results against.
4. **Phase 6 (hard release gate)** requires a verified compatibility matrix — which requires structured version identity data, not ad-hoc print results.

This amendment introduces a **RouterOS Compatibility Layer** — a small set of value objects and a capability detection service — that must be implemented as **additional deliverables inside the Phase 1 SDK** and **consumed during Phase 2 router-add flow**.

This amendment does **not** introduce new features, new UI, or new user-facing behavior. It introduces infrastructure needed to make existing phase deliverables version-safe.

---

## 2. Scope

### 2.1 In Scope

| Component | Location | Amendment Role |
|---|---|---|
| `RouterInfo` | `mikrotik_sdk` | Value object returned by capability detection |
| `RouterVersion` | `mikrotik_sdk` | Parsed, comparable RouterOS version struct |
| `CapabilityDetector` | `mikrotik_sdk` | Service: connects and queries version + feature flags |
| `CapabilityMatrix` | `mikrotik_sdk` | Static table of known version-to-capability mappings |
| `RouterProfile` | `devkurotik_app` | Extends `RouterModel` with `RouterInfo` association |

### 2.2 Out of Scope

This amendment does NOT introduce:

- New UI screens
- New user-facing router fields
- Cloud sync or fleet analytics
- Premium capabilities
- Any Phase 3+ logic
- Changes to `RouterModel` primary key or Drift schema columns

---

## 3. Impact Analysis

### 3.1 Impact on PHASE_1.md

PHASE_1.md is complete and its acceptance criteria remain fully satisfied. This amendment adds **two additional deliverables** to the `mikrotik_sdk` package that must be implemented and tested before Phase 6 closure. These deliverables are **not a Phase 1 re-open** — they are new additive SDK components that extend the existing public API surface.

The amendment does not invalidate:
- The 127 Phase 1 unit tests
- The 9/9 CHR v7 integration results
- The 85.6% coverage result
- The PHASE_1_COMPLETION_REPORT.md status of COMPLETE

### 3.2 Impact on PHASE_2.md

PHASE_2.md is complete and its acceptance criteria remain fully satisfied. This amendment adds **one additional integration point** to the Phase 2 application layer: the add-router flow should optionally invoke `CapabilityDetector` to populate `RouterProfile` at add-time if connectivity is available.

The amendment does not invalidate:
- The 127 Phase 2 widget/unit/integration tests
- The 82.0% coverage result
- The PHASE_2_COMPLETION_REPORT.md status of COMPLETE

### 3.3 Forward Impact (Phase 3–6)

| Phase | Dependency on this Amendment |
|---|---|
| Phase 3 (Dashboard) | Uses `RouterProfile.routerInfo.version` to branch `/system/resource` field parsing |
| Phase 4 (Hotspot) | Uses `CapabilityMatrix.supportsHotspot(version)` to surface unsupported warnings |
| Phase 6 (Release Gate) | Requires `CapabilityMatrix` evidence per router version tested |

---

## 4. Additional Deliverables

### Deliverable A — `RouterVersion` (mikrotik_sdk)

A parsed, comparable value object for RouterOS version strings.

**Specification:**

```
RouterVersion
  major: int          // e.g. 7
  minor: int          // e.g. 15
  patch: int          // e.g. 1
  channel: String     // "stable" | "long-term" | "testing" | "development"
  raw: String         // original string e.g. "7.15.1 (stable)"

  isAtLeast(major, minor, [patch]) → bool
  isBefore(major, minor, [patch]) → bool
  supportsPlainAuth() → bool    // true if >= 6.43
  requiresMd5Auth() → bool      // true if < 6.43
```

**Parse source:** `/system/resource/print` → field `version` (e.g. `"7.15.1 (stable)"`).

**Constraints:**
- Must handle malformed or unexpected version strings without throwing.
- Must not make network calls — parsing only.
- Must be const-constructible for static matrix entries.

---

### Deliverable B — `RouterInfo` (mikrotik_sdk)

A value object capturing the identity snapshot of a connected router at the moment of detection.

**Specification:**

```
RouterInfo
  identity: String          // /system/identity → name
  version: RouterVersion    // parsed from /system/resource → version
  board: String             // /system/resource → board-name
  architecture: String      // /system/resource → architecture-name
  cpuCount: int             // /system/resource → cpu-count
  totalMemoryBytes: int     // /system/resource → total-memory
  isVirtual: bool           // true if board-name == "CHR" or architecture contains "x86"
  isChr: bool               // true if board-name == "CHR"
  platform: String          // /system/resource → platform (e.g. "MikroTik")
  detectedAt: DateTime      // wall clock at time of detection
```

**Constraints:**
- All fields must degrade gracefully if the corresponding API key is absent from the response (use defaults/empty).
- `isVirtual` and `isChr` must not require a separate API call — derived from fields already fetched.
- Must not store or expose router password.

---

### Deliverable C — `CapabilityMatrix` (mikrotik_sdk)

A static, immutable lookup table that maps known RouterOS versions to feature-availability flags.

**Specification:**

```
CapabilityMatrix

  static bool supportsPlainAuth(RouterVersion v)
  static bool requiresMd5Auth(RouterVersion v)
  static bool supportsHotspot(RouterVersion v)
  static bool supportsPppoe(RouterVersion v)
  static bool supportsApiSsl(RouterVersion v)
  static bool hasKnownVariance(RouterVersion v) → bool
  static String? varianceNote(RouterVersion v) → human-readable warning or null
```

**Known variance entries that must be seeded (minimum):**

| Version Range | Flag | Note |
|---|---|---|
| < 6.43 | requiresMd5Auth = true | MD5 challenge-response required |
| ≥ 6.43 | supportsPlainAuth = true | Plain-text credential login |
| ≥ 6.0 | supportsHotspot = true | Hotspot API available |
| ≥ 6.0 | supportsPppoe = true | PPPoE secrets API available |
| ≥ 6.49 | supportsApiSsl = true | Port 8729 TLS confirmed stable |
| 7.x | isVirtual hint | CHR returns trap for /system/routerboard |
| Any | hasKnownVariance = false (default) | No special handling required |

**Constraints:**
- Must be purely static — no network calls, no state.
- New entries may be added without breaking existing callers.
- Must not throw for unknown versions — return safe defaults.

---

### Deliverable D — `CapabilityDetector` (mikrotik_sdk)

A service that connects to a router and produces a `RouterInfo` value object by executing the minimum required API commands.

**Specification:**

```
CapabilityDetector
  detect({
    required MikrotikCredentials credentials,
    Duration timeout = const Duration(seconds: 10),
  }) → Future<RouterInfo>
```

**Internal sequence (must execute in order, stop on failure):**

1. Open `MikrotikConnection` to the router.
2. Authenticate.
3. Execute `/system/identity/print` → capture `name`.
4. Execute `/system/resource/print` → capture `version`, `board-name`, `architecture-name`, `cpu-count`, `total-memory`, `platform`.
5. Disconnect.
6. Construct and return `RouterInfo`.

**Failure behavior:**

| Failure | Behavior |
|---|---|
| Authentication fails | Propagate `RouterosAuthException` — do not return partial `RouterInfo` |
| Connection fails | Propagate `RouterosConnectionException` |
| Timeout | Propagate `RouterosTimeoutException` |
| `/system/resource/print` returns trap | Return `RouterInfo` with `version = RouterVersion.unknown`, other fields populated where available |
| Any field absent from response | Use field default (empty string / 0 / false) — do not throw |

**Constraints:**
- Must use only `MikrotikClient` from the existing SDK public API.
- Must not add new SDK dependencies.
- Must not cache results — each call produces a fresh detection.
- Detection is optional from the caller's perspective — callers must handle failures gracefully.

---

### Deliverable E — `RouterProfile` (devkurotik_app)

An extension of `RouterModel` that associates a `RouterInfo` snapshot with a persisted router.

**Specification:**

```
RouterProfile
  router: RouterModel         // the base persisted router
  routerInfo: RouterInfo?     // null if never detected or detection failed
  lastDetectedAt: DateTime?   // when routerInfo was last populated

  hasInfo → bool
  isVersionKnown → bool
  capabilityWarnings → List<String>   // from CapabilityMatrix.varianceNote
```

**Storage policy:**
- `RouterInfo` is **not persisted to Drift**. It is transient state held in memory for the session.
- `lastDetectedAt` is not persisted — it resets on app restart.
- `RouterProfile` is a **view model** over `RouterModel`, not a replacement.

**Constraints:**
- Must not add new Drift columns. Schema v1 is final for Phase 2.
- Must not change the `RouterModel` public API.
- Must not block add/edit/delete flows — detection is opt-in and async.

---

## 5. Validation Requirements

### 5.1 Unit Tests Required (mikrotik_sdk)

| Test | Requirement |
|---|---|
| `RouterVersion` parsing from canonical string | `"7.15.1 (stable)"` → major=7, minor=15, patch=1, channel=stable |
| `RouterVersion` parsing from short string | `"6.49"` → major=6, minor=49, patch=0 |
| `RouterVersion.isAtLeast` comparison | Must pass boundary cases at each segment |
| `RouterVersion.supportsPlainAuth` | Returns true for ≥6.43, false for <6.43 |
| `RouterVersion.requiresMd5Auth` | Inverse of above |
| `RouterVersion` graceful degradation on malformed input | No throw on `""`, `"unknown"`, `"7"` |
| `RouterInfo` construction with all fields | All accessors return expected values |
| `RouterInfo.isChr` detection | True when board-name == "CHR" |
| `RouterInfo.isVirtual` detection | True for CHR and x86 board names |
| `CapabilityMatrix` static methods | Cover all defined version thresholds |
| `CapabilityMatrix` unknown version | Returns safe defaults, does not throw |
| `CapabilityDetector` with mock RouterOS server | Returns correct `RouterInfo` from mock responses |
| `CapabilityDetector` auth failure propagation | `RouterosAuthException` is not swallowed |
| `CapabilityDetector` missing field degradation | Returns `RouterInfo` with defaults when fields absent |

### 5.2 Integration Tests Required (CHR v7)

| Test | Required Evidence |
|---|---|
| `CapabilityDetector.detect()` against CHR v7.15.1 | Returns `RouterInfo` with correct version, board=CHR, isChr=true |
| `RouterVersion` parsed from live `/system/resource/print` | Major=7, minor≥15 |
| `CapabilityMatrix.supportsPlainAuth(v7)` | Returns true |
| `CapabilityMatrix.requiresMd5Auth(v7)` | Returns false |
| `CapabilityMatrix.supportsHotspot(v7)` | Returns true |

### 5.3 Integration Tests Required (RouterOS v6 — when environment available)

| Test | Required Evidence |
|---|---|
| `CapabilityDetector.detect()` against RouterOS v6.x | Returns `RouterInfo` with correct version, isChr derived correctly |
| `CapabilityMatrix.requiresMd5Auth(v6_pre643)` | Returns true |
| `CapabilityMatrix.supportsPlainAuth(v6_post643)` | Returns true |

> **Note:** v6 tests are blocked pending a KVM-capable test environment (Vultr/Hetzner CHR v6 or physical hardware). See `PHASE_1_VALIDATION_GAP_REPORT.md` Section 5. These tests are **required before Phase 6 closure** but do not block Phase 1 or Phase 2 re-validation.

---

## 6. Acceptance Criteria

| # | Criterion | Notes |
|---|---|---|
| AC-A1 | `RouterVersion` parses all known RouterOS version string formats without throwing | Includes short form, full form, channel variants |
| AC-A2 | `RouterVersion` comparison operators produce correct ordering across v6/v7 boundary | `isAtLeast(7,0)` false for v6.49, true for v7.0 |
| AC-A3 | `RouterInfo` constructed from CHR v7 live data returns `isChr = true` | Validated via integration test |
| AC-A4 | `CapabilityDetector.detect()` returns a populated `RouterInfo` for CHR v7 | 9-second timeout is sufficient for CHR |
| AC-A5 | `CapabilityDetector` propagates `RouterosAuthException` unmodified | Must not swallow or wrap auth errors |
| AC-A6 | `CapabilityMatrix` returns safe defaults for version `0.0.0` (unknown) | No throw, no panic |
| AC-A7 | `RouterProfile` does not cause Drift schema migration | Schema v1 must remain unchanged |
| AC-A8 | `RouterProfile.capabilityWarnings` returns empty list for v7.15.1 | No known variances for validated version |
| AC-A9 | All new unit tests pass | Per Section 5.1 |
| AC-A10 | All CHR v7 integration tests pass | Per Section 5.2 |
| AC-A11 | Coverage of new components ≥ 85% (mikrotik_sdk) | Consistent with Phase 1 SDK coverage target |
| AC-A12 | `flutter analyze` and `dart analyze` pass with no new issues | No regressions to existing analysis baseline |

---

## 7. Risks

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| RA-01 | `/system/resource/print` version string format changes in future RouterOS | MEDIUM | `RouterVersion` parses defensively; unknown formats return `RouterVersion.unknown` without throwing |
| RA-02 | CHR v7 board-name field value changes (currently `"CHR"`) | LOW | `isChr` detection checks board-name; `isVirtual` also checks architecture as fallback |
| RA-03 | `CapabilityDetector` adds latency to the add-router flow | LOW | Detection is opt-in and async; UI must not block on it; failures are non-fatal |
| RA-04 | v6 MD5 auth behavior in `CapabilityDetector` not validated without hardware | HIGH | `CapabilityDetector` reuses existing `RouterosAuth` which is unit-tested for MD5; gap documented |
| RA-05 | `RouterProfile` becomes a shadow model for `RouterModel` and causes confusion | MEDIUM | `RouterProfile` is explicitly a view model, not a persistence entity; must not be stored |
| RA-06 | `CapabilityMatrix` entries become stale as MikroTik releases new versions | LOW | Matrix is additive — new entries added without removing old ones; stale entries degrade to safe defaults |
| RA-07 | Implementor conflates `RouterProfile` with `RouterModel` and adds Drift columns | CRITICAL | Explicitly prohibited in Section 4E; enforcement via code review |

---

## 8. Execution Notes

### 8.1 Implementation Order

Deliverables must be implemented in this order — each depends on the prior:

```
RouterVersion       (no dependencies)
    ↓
RouterInfo          (depends on RouterVersion)
    ↓
CapabilityMatrix    (depends on RouterVersion)
    ↓
CapabilityDetector  (depends on RouterInfo, CapabilityMatrix, MikrotikClient)
    ↓
RouterProfile       (depends on RouterInfo, RouterModel — app layer only)
```

### 8.2 Package Boundaries

| Deliverable | Package | Dependency Rule |
|---|---|---|
| `RouterVersion` | `mikrotik_sdk` | No new dependencies |
| `RouterInfo` | `mikrotik_sdk` | No new dependencies |
| `CapabilityMatrix` | `mikrotik_sdk` | No new dependencies |
| `CapabilityDetector` | `mikrotik_sdk` | Uses `MikrotikClient`, `MikrotikCredentials` — already in SDK |
| `RouterProfile` | `devkurotik_app` | Imports `mikrotik_sdk`; must NOT import drift directly |

### 8.3 Public API Export

All four `mikrotik_sdk` deliverables must be exported via the existing barrel file:

```dart
// mikrotik_sdk.dart — add to existing exports
export 'src/compatibility/router_version.dart';
export 'src/compatibility/router_info.dart';
export 'src/compatibility/capability_matrix.dart';
export 'src/compatibility/capability_detector.dart';
```

New directory: `packages/mikrotik_sdk/lib/src/compatibility/`

### 8.4 CHR Real-Test Requirement

Per `CLAUDE.md` Section 12, integration tests for `CapabilityDetector` **must be run against the CHR** before this amendment is marked complete.

Required integration test file: `packages/mikrotik_sdk/test/integration_compat_test.dart`

The test must record:
- `RouterInfo.version.raw` from the live CHR
- `RouterInfo.isChr` value
- `RouterInfo.board`
- `CapabilityMatrix.supportsPlainAuth(version)` result

Results must be included in the amendment completion evidence.

### 8.5 This Amendment Does Not Re-Open Phases

Implementing these deliverables does **not** require:
- Modifying existing Phase 1 or Phase 2 tests
- Changing any existing public API
- Bumping Drift schema version
- New Flutter dependencies

The amendment completion report (`AMENDMENT_001_COMPLETION_REPORT.md`) is separate from and additive to the Phase 1 and Phase 2 completion reports.

### 8.6 Completion Gating

This amendment's deliverables are:
- **Optional for Phase 3 start** — Phase 3 may begin without this amendment, but must consume `RouterProfile` once available
- **Required for Phase 4 start** — Phase 4 (Hotspot) depends on `CapabilityMatrix.supportsHotspot()`
- **Mandatory for Phase 6 closure** — the release gate requires a full compatibility matrix with CHR and v6 evidence

---

## 9. Amendment Completion Evidence Required

When this amendment is implemented, the implementor must produce:

1. `AMENDMENT_001_COMPLETION_REPORT.md` containing:
   - All deliverables status (A–E)
   - Unit test results (count and pass rate)
   - CHR v7 integration test output (raw version string, isChr, board)
   - `dart analyze` result
   - Coverage for new components

2. Updated `PHASE_1_VALIDATION_GAP_REPORT.md` Section 9 (Validation Plan) marked with CapabilityDetector CHR result.

3. No modifications to `PHASE_1_COMPLETION_REPORT.md` or `PHASE_2_COMPLETION_REPORT.md` — those reports document work as originally scoped.

---

## References

- `audit/PHASE_1.md` — Original SDK phase specification
- `audit/PHASE_2.md` — Original router management phase specification
- `PHASE_1_COMPLETION_REPORT.md` — Phase 1 evidence (not modified)
- `PHASE_1_VALIDATION_GAP_REPORT.md` — v6/v7 compatibility gap documentation
- `PHASE_2_COMPLETION_REPORT.md` — Phase 2 evidence (not modified)
- `CLAUDE.md` Section 12 — Real router test environment instructions
- `chr.txt` (gitignored) — CHR v7 test target credentials
- `audit/RISK_REGISTER.md` — R-02 (RouterOS protocol variance risk)
- `audit/SDK_DESIGN.md` — Original SDK public API contract
- `audit/MIGRATION_BLUEPRINT.md` — Pre-v6.43 authentication note
- `packages/mikrotik_sdk/test/integration_chr_test.dart` — CHR v7 validation baseline
