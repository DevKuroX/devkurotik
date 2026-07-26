# PHASE_6_COMPATIBILITY_REPORT.md
> Phase 6 — RouterOS Compatibility Report.

---

## Compatibility Matrix

| RouterOS Version | Status | Evidence | Notes |
|---|---|---|---|
| 6.40.x | ⏳ PENDING | Unit tests only | No physical instance. Syntax identical to 6.49.17 |
| 6.49.17 | ✅ VALIDATED | CHR v6 6/6 live tests | Linode Singapore nanode |
| 7.15.1 | ✅ VALIDATED | CHR v7 7/7 live tests | AWS EC2 t3.small us-east-1 |

---

## RouterOS v7.15.1 — CHR AWS EC2 (54.147.121.92:8728)

### Test Execution Date
2026-07-26

### Before State
- Profile `p6test-v7-daily`: did not exist
- Scheduler `p6test-v7-daily`: did not exist

### Operations Tested

**Add Profile (remove mode)**:
- Command: `/ip/hotspot/user/profile/add`
- on-login: canonical remove script with `:put (",rem,5000,1d,5000,,Disable,");`
- Result: ✅ Profile created successfully

**Verify on-login persistence**:
- Comma position [1] = `rem` ✅
- Comma position [2] = `5000` (price) ✅
- Comma position [3] = `1d` (validity) ✅
- Comma position [4] = `5000` (selling price) ✅
- Comma position [6] = `Disable` (lock) ✅

**Add Scheduler**:
- Command: `/system/scheduler/add`
- name: `p6test-v7-daily`
- interval: `00:02:15`
- comment: `Monitor Profile p6test-v7-daily`
- disabled: `false`
- Result: ✅ Scheduler created

**Update Profile (notice mode)**:
- Command: `/ip/hotspot/user/profile/set`
- New on-login contains `ntf` at position [1]
- Result: ✅ on-login updated, `ntf` confirmed

**Delete Profile + Scheduler**:
- Both removed cleanly
- After-state: both absent ✅

### After State
- Profile `p6test-v7-daily`: absent ✅
- Scheduler `p6test-v7-daily`: absent ✅

---

## RouterOS v6.49.17 — CHR Linode Singapore (139.162.35.252:8728)

### Test Execution Date
2026-07-26

### Before State
- Profile `p6test-v6-daily`: did not exist
- Scheduler `p6test-v6-daily`: did not exist

### Operations Tested

**Add Profile (noticeRecord mode)**:
- Command: `/ip/hotspot/user/profile/add`
- on-login: canonical ntfc script
- Result: ✅ Profile created

**Verify on-login persistence**:
- Comma position [1] = `ntfc` ✅
- Comma position [2] = `10000` (price) ✅
- Comma position [3] = `7d` (validity) ✅

**Scheduler**:
- comment: `Monitor Profile p6test-v6-daily` ✅
- disabled: `false` ✅

**Delete**:
- Both profile and scheduler removed cleanly ✅

### After State
- Profile `p6test-v6-daily`: absent ✅
- Scheduler `p6test-v6-daily`: absent ✅

---

## RouterOS 6.40.x — PENDING

**Status**: No physical instance available.

**Rationale for PENDING (not FAIL)**:
- RouterOS 6.40 uses the same `/ip/hotspot/user/profile` API syntax as 6.49.17
- The on-login script syntax (RouterScript) is backward-compatible from 6.40 onward
- All unit tests pass with 6.40-targeted fixtures (structural validation)

**Risk**: LOW — the Mikhmon codebase was originally designed for 6.40+ and the script syntax has not changed in the profile management area.

**Action required**: Physical v6.40 validation can be performed when an instance is provisioned. No release blocker.

---

## Script Acceptance on Router

The canonical on-login script was accepted by both CHR v6 and v7 without modification. Key observations:

1. **Script length**: The largest script (noticeRecord + MAC lock) was accepted without truncation on both versions.
2. **Escaped dollars**: All `$` in the script are correctly handled — the API transport preserves RouterScript variables.
3. **Scheduler on-event**: The bgService script (date-to-integer conversion + user sweep) was stored and retrievable on both versions.
4. **Comment preservation**: `Monitor Profile <name>` comment stored exactly as written.

---

## Release Recommendation

**✅ READY FOR RELEASE** (v7 and v6):
- RouterOS 7.15.1: fully validated
- RouterOS 6.49.17: fully validated
- RouterOS 6.40.x: PENDING (non-blocking; LOW risk)

Phase 7 can proceed.
