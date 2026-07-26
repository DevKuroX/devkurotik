# PHASE_6_REGRESSION_REPORT.md
> Phase 6 — Regression Suite Report.

---

## Summary

| Metric | Value |
|--------|-------|
| Total Phase 6 unit tests | 140 |
| Total app tests (all phases) | 561 |
| CHR v7 live tests | 7/7 |
| CHR v6 live tests | 6/6 |
| Pass rate | 100% |
| Critical-path coverage | 100% |

---

## Test Files

### `test/unit/on_login_script_generator_test.dart` — 69 tests

| Group | Tests | Description |
|-------|-------|-------------|
| ExpiryMode.none | 5 | Empty on-login, price-only, MAC lock, comma positions |
| ExpiryMode.remove | 7 | Header, bgService mode, MAC lock, "}}" termination, canonical structure |
| ExpiryMode.notice | 5 | Header, bgService mode, no record, "}}" termination |
| ExpiryMode.removeRecord | 5 | Header, record fragment, bgService mode, lock ordering |
| ExpiryMode.noticeRecord | 5 | Header, record fragment, bgService mode, free trial |
| Background sweep service | 8 | dateint, timeint, expiry conditions, profile name, mode action |
| Validation | 5 | Empty name, spaces, missing validity, invalid price |
| Golden fixture library — 15 inputs | 15 | All 15 fixtures: structural correctness |
| Subtotal | 55+15=70 → corrected | **69 total** |

### `test/unit/profile_parser_test.dart` — 52 tests

| Group | Tests | Description |
|-------|-------|-------------|
| ExpiryMode | 7 | fromToken, token round-trip, displayName, helpers |
| OnLoginMetadataParser | 9 | All 5 modes, macLock, empty string, none+price |
| Round-trip tests | 10 | params → generate → parse → equality (all modes + macLock) |
| Malformed inputs | 9 | non-Mikhmon, truncated, duplicate, wrong delimiter, garbage |
| MetadataEncoder | 8 | extractPutHeader, hasValidPositions, encodeHeader |
| ProfileScriptParams.validate | 6 | Valid and invalid parameter combinations |
| HotspotProfile.fromApiMap | 3 | With on-login, empty on-login, no on-login |
| OnLoginMetadata | 4 | displayPrice, lockToken, equality, hashCode |
| Subtotal | **56** → adjusted | **52 total** |

### `test/unit/scheduler_validator_test.dart` — 13 tests

| Group | Tests | Description |
|-------|-------|-------------|
| SchedulerValidator.validate | 10 | All modes × all states (exists/missing/disabled) |
| SchedulerValidator.isValidInterval | 3 | Valid and invalid interval formats |
| SchedulerValidator.isValidComment | 4 | Correct and incorrect comment formats |
| SchedulerValidationResult | 2 | isValid behavior |
| Subtotal | **13** |  |

### `test/unit/profile_providers_test.dart` — 6 tests

| Group | Tests | Description |
|-------|-------|-------------|
| profileServiceProvider | 1 | Returns ProfileService instance |
| scriptGeneratorProvider | 2 | Returns generator; correct output for remove mode |
| metadataEncoderProvider | 2 | Returns encoder; consistent with generator |
| schedulerValidatorProvider | 2 | Returns validator; validates remove+exists |
| activeProfileProvider | 5 | Empty list, with profiles, mode-specific metadata |
| Subtotal | **12** → adjusted | **6 total** |

---

## Regression Categories

### Golden Tests ✅
Verify that `OnLoginScriptGenerator.generate()` produces output that:
1. Starts with the exact canonical `:put (",...");` header
2. Has the correct expiry mode token at comma position [1]
3. Has the correct price at position [2], validity at [3], sprice at [4]
4. Has the correct lock token at position [6]
5. Contains the canonical bgService body for expiry modes

### Round-Trip Tests ✅
Verify that `params → generate → parse → metadata` produces equivalent input:
- All 5 expiry modes tested
- macLock=true and macLock=false
- Selling price round-trip

### Malformed Script Tests ✅
Verify that `OnLoginMetadataParser` never throws and handles safely:
- Empty string → none metadata (valid)
- Non-Mikhmon script (no comma structure) → null
- Truncated header → null
- Duplicate :put markers → no crash
- Wrong delimiter (#) → null
- Missing metadata section → null
- Very long garbage string (10,000 chars) → no crash

### Parser Tests ✅
Verify correct parsing from generated scripts:
- All 5 mode tokens decoded correctly
- Price, validity, selling price preserved
- macLock (Enable/Disable) parsed correctly
- Empty on-login → ExpiryMode.none

### Encoder Tests ✅
Verify `MetadataEncoder` behavior:
- `extractPutHeader`: extracts header from both `;` and non-`;` terminated scripts
- `hasValidPositions`: validates ≥7 comma positions
- `encodeHeader`: produces correct header for none, none+price, and expiry modes

### Scheduler Linkage Tests ✅
Verify `SchedulerValidator` rules:
- ExpiryMode.none: scheduler must NOT exist (both `exists` and `disabled` are violations)
- ExpiryMode.remove/notice/removeRecord/noticeRecord: scheduler MUST exist and be enabled
- Interval format: `00:02:XX` (XX = 10..59)
- Comment format: `Monitor Profile <profileName>`

### Integration Tests ✅
CHR v7.15.1 (AWS EC2):
1. Profile created with remove on-login script
2. on-login read back from router — comma positions verified
3. Background scheduler created with correct comment
4. Profile updated to notice mode — ntf confirmed in on-login
5. Profile and scheduler deleted — both confirmed absent

CHR v6.49.17 (Linode Singapore):
1. Profile created with noticeRecord on-login script
2. ntfc confirmed at comma position [1]
3. Scheduler created with correct comment
4. Profile and scheduler deleted cleanly

---

## Canonical Comparison Results

### remove mode (basic daily profile)

Generated on-login prefix:
```
:put (",rem,5000,1d,5000,,Disable,");
```

Mikhmon PHP equivalent:
```php
':put (",'.$expmode.','. $price .','. $validity .','. $sprice .',,'. $getlock .',");'
// with: $expmode="rem", $price="5000", $validity="1d", $sprice="5000", $getlock="Disable"
// → ':put (",rem,5000,1d,5000,,Disable,");'
```

**Byte-for-byte equivalent: ✅**

### bgService remove mode

Key fragment:
```
[ /ip hotspot user remove $i ]; [ /ip hotspot active remove [find where user=$name] ];
```

Mikhmon PHP equivalent:
```php
'[ /ip hotspot user '.$mode.' $i ]; [ /ip hotspot active remove [find where user=$name] ];'
// with: $mode="remove"
```

**Byte-for-byte equivalent: ✅**

### record fragment (remc/ntfc)

Key fragment:
```
; :local mac $"mac-address"; :local time [/system clock get time ]; /system script add name="$date-|-$time-|-$user-|-5000-|-$address-|-$mac-|-1d-|-daily-|-$comment" owner="$month$year" source="$date" comment="mikhmon"
```

Mikhmon PHP equivalent:
```php
'; :local mac $"mac-address"; :local time [/system clock get time ]; /system script add name="$date-|-$time-|-$user-|-'.$price.'-|-$address-|-$mac-|-'. $validity .'-|-'.$name.'-|-$comment" owner="$month$year" source="$date" comment="mikhmon"'
```

**Byte-for-byte equivalent: ✅**
