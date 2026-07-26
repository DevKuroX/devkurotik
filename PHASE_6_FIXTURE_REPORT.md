# PHASE_6_FIXTURE_REPORT.md
> Phase 6 — Golden Fixture Library Report.

---

## Overview

15 golden fixtures across 5 expiry modes × 3 RouterOS version targets.

## Fixture Directory Structure

```
apps/devkurotik_app/test/fixtures/
├── none/
│   ├── input_none_noprice.json       — mode=none, price=0, no lock, v7
│   ├── input_none_price.json         — mode=none, price=5000, no lock, v7
│   └── input_none_price_lock.json    — mode=none, price=5000, MAC lock, v6
├── remove/
│   ├── input_remove_basic.json       — mode=remove, 5000/1d, no lock, v7
│   ├── input_remove_mac_lock.json    — mode=remove, 20000/7d, MAC lock, v6
│   └── input_remove_sprice.json      — mode=remove, 50000/30d, sprice 45000, v6.40
├── notice/
│   ├── input_notice_basic.json       — mode=notice, 5000/1d, no lock, v7
│   ├── input_notice_mac_lock.json    — mode=notice, 2000/1h, MAC lock, v6
│   └── input_notice_sprice.json      — mode=notice, 3000/2d, sprice 2500, v6.40
├── remove_record/
│   ├── input_remove_record_basic.json      — mode=remc, 5000/1d, no lock, v7
│   ├── input_remove_record_mac_lock.json   — mode=remc, 20000/7d, MAC lock, v6
│   └── input_remove_record_nosprice.json   — mode=remc, 50000/30d, sprice=0, v6.40
└── notice_record/
    ├── input_notice_record_basic.json      — mode=ntfc, 5000/1d, no lock, v7
    ├── input_notice_record_premium.json    — mode=ntfc, 100000/30d, MAC lock, v6
    └── input_notice_record_free.json       — mode=ntfc, free/1h, no price, v6.40
```

## Fixture Format

Each `input_*.json` file contains:
```json
{
  "profileName": "...",
  "mode": "none|remove|notice|remove_record|notice_record",
  "price": "...",
  "validity": "...",
  "sellingPrice": "...",
  "macLock": true|false,
  "description": "...",
  "routerOsVersion": "..."
}
```

## Coverage Matrix

| Mode | No Price | With Price | MAC Lock | Selling Price | Router v7 | Router v6 | Router v6.40 |
|------|----------|-----------|---------|---------------|-----------|-----------|--------------|
| none | ✅ | ✅ | ✅ | — | ✅ | ✅ | — |
| remove | — | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| notice | — | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| removeRecord | — | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| noticeRecord | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Automated Test Coverage

All 15 fixtures are tested by `on_login_script_generator_test.dart` in the
"Golden fixture library — 15 inputs" group:
- On-login non-empty when expected
- bgService non-empty when expected  
- Profile name correctly embedded in bgService
- Comma positions valid (≥7 positions)

Additional golden tests verify:
- Exact :put header start: `:put (",rem,...") for remove mode
- Exact expiry mode token at position [1]
- Exact price at position [2]
- Exact validity at position [3]
- MAC lock token at position [6]: `Enable` vs `Disable`

## Real-Router Validation

Fixtures 4 (remove/v7) and 13 (noticeRecord/v6) were deployed to live routers:
- CHR v7.15.1: profile created, on-login read back, comma positions verified ✅
- CHR v6.49.17: profile created, on-login read back, ntfc position verified ✅

## RouterOS 6.40.x Status

Physical instance unavailable. Fixtures 6, 9, 12, 15 targeting v6.40 are unit-tested 
only (structural validation). Per PHASE_6.md Section 9, this is a known risk accepted
as LOW severity — v6.40 uses identical script syntax to v6.49.
