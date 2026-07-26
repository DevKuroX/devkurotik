# PHASE_5_BLOCKER_REPORT.md
> Phase 5 — Voucher Engine: Scope Conflict Blocker.

---

## Date
2026-07-26

## Severity
**BLOCKER** — Conflicting scope definitions prevent safe execution.

---

## 1. Blocker Description

The Phase 5 assignment contains **two directly contradictory sets of instructions** that cannot both be satisfied simultaneously.

---

## 2. Conflict Evidence

### Side A — PHASE_5.md (canonical phase document)

`audit/PHASE_5.md` Section 3 (Deliverables) requires:

| # | Deliverable |
|---|---|
| 6 | Voucher rendering templates (default, thermal, small) |
| 7 | **QR generation implemented locally only** |
| 8 | **Single-user voucher print/share flow implemented** |
| 9 | **Batch voucher print/share flow implemented** |
| 10 | **Quick Print package read/write compatibility implemented** |
| 11 | **One-touch generate + print flow implemented** |
| 12 | **Android-first print fallback matrix implemented** |

`audit/PHASE_5.md` Section 6 (Acceptance Criteria) requires:

> AC-7: QR generation is local only and does not leak credentials externally.
> AC-8: Single-user print/share flow works.
> AC-9: Batch print/share flow works.
> AC-10: Quick Print packages are compatible with the audited RouterOS storage format.
> AC-11: One-touch generate + print flow works in the approved Android-first model.

`audit/PHASE_5.md` Section 7 (Definition of Done) requires:

> "Quick Print compatibility works within approved scope"
> "print/share fallback behavior is reliable enough for operational use"

### Side B — Assignment Hard Constraints

The Phase 5 assignment brief states:

> **DO NOT implement:**
> - Printing
> - QR Codes
> - PDF Export
> - Payment Gateway
> - Cloud Sync
> - Notifications
> - PPP
> - Queue
> - Analytics
> - SaaS Features

And:

> **Hard Constraints — You MUST NOT:**
> 5. Implement Printing.
> 6. Implement QR Codes.
> 7. Implement PDF export.

---

## 3. Why This Is a Hard Blocker

### PHASE_5.md cannot be satisfied without printing and QR

The following PHASE_5.md Acceptance Criteria **require** printing and/or QR:
- AC-7 (QR generation)
- AC-8 (single-user print/share)
- AC-9 (batch print/share)
- AC-10 (Quick Print compatibility)
- AC-11 (one-touch generate + print)
- AC-12 (failure recovery after print)

PHASE_5.md Definition of Done is **unsatisfiable** without these features.

### The assignment's constraint also says "Treat PHASE_5.md as the ONLY source of truth"

The assignment simultaneously states:
> "Treat PHASE_5.md as the ONLY source of truth."

And:
> "DO NOT implement: Printing, QR Codes, PDF Export"

These are mutually exclusive. No interpretation can satisfy both.

### Quick Print requires `/system/script` read/write

PHASE_5.md Task 10 requires Quick Print package compatibility using the audited RouterOS `/system/script` storage format. This is well-defined in `API_ENDPOINTS.md` Section 6.1. However:
- The assignment's scope description only lists "Voucher Engine / Voucher Models / Voucher Generation / Voucher Templates / Voucher Batch Creation / Voucher Repository / Voucher State Management / Voucher Validation / Voucher Preview / Voucher History / Testing"
- Quick Print is NOT in this list

---

## 4. What Is Unambiguous (Safe to Implement)

The following items from PHASE_5.md are NOT in conflict with the assignment constraints and can be implemented safely:

| Component | Justification |
|---|---|
| Bulk user generation (count, mode, charset, prefix) | Explicitly in both PHASE_5.md and assignment scope |
| Voucher mode: user=pass, user+pass | Explicitly in assignment |
| Character-set selection | Explicitly in assignment |
| Prefix-based username generation | Explicitly in assignment |
| Profile/validity preview (metadata display) | Explicitly in assignment ("Templates are metadata ONLY") |
| Last-batch summary persistence | Explicitly in assignment ("Voucher History — persist batch metadata") |
| Voucher models and domain objects | Explicitly in assignment |
| Voucher repository (Drift/SQLite) | Explicitly in assignment |
| Voucher state management (Riverpod providers) | Explicitly in assignment |
| Voucher validation rules | Explicitly in assignment |
| Voucher preview screen (display only, no PDF) | Explicitly in assignment |
| Voucher history screen | Explicitly in assignment |
| Voucher templates as metadata-only | Assignment states: "Templates are metadata ONLY. They MUST NOT generate RouterOS scripts." |
| Multi-router batch isolation | Explicitly in assignment |
| Tests (unit, widget, provider, integration) | Explicitly in assignment |

---

## 5. Decision Required from Project Owner

The following questions require an explicit decision before implementation can proceed:

### Q1 — Printing scope
Should Phase 5 implement:
- **Option A (Full PHASE_5.md):** Printing, QR codes, PDF export, Quick Print `/system/script` compatibility, one-touch generate+print, BT thermal fallback — as required by PHASE_5.md Deliverables 6–14
- **Option B (Assignment constraints):** Voucher engine only — generation, templates (metadata), history, preview display, validation — NO printing, NO QR, NO PDF, NO Quick Print
- **Option C (Partial):** Some defined subset (e.g. QR local-only + PDF/share but NOT BT thermal)

### Q2 — Quick Print
Should Phase 5 implement Quick Print `/system/script` read/write compatibility (PHASE_5.md Task 10)?
- This requires reading/writing `/system/script` on the router, which is a significant additional scope item not explicitly in the assignment's permitted list.

### Q3 — Git tag
The assignment requires `v0.6.0`. Should this tag be applied after the constrained (Option B) scope, or only after full PHASE_5.md scope?

---

## 6. Recommended Path (Awaiting Approval)

If the project owner approves **Option B** (constrained scope matching the assignment brief):

The following can be delivered immediately without any blocker:
- VoucherModel, VoucherBatch, VoucherTemplate (metadata only)
- VoucherGeneratorService (generation logic, charset, prefix, modes)
- VoucherRepository (Drift persistence of batch history)
- Riverpod providers (hotspot-side generation, history, filter)
- UI: GenerateVoucherScreen, BatchVoucherScreen, VoucherPreviewScreen (text display), VoucherHistoryScreen, VoucherTemplateScreen
- Full test suite (unit, widget, provider) with ≥85% coverage
- Live validation (generate batches against CHR v7 + v6, verify naming, verify router isolation)
- PHASE_5_COMPLETION_REPORT.md and `v0.6.0` tag

Printing, QR, PDF, Quick Print, and BT thermal would be deferred to a separate sub-phase or Phase 6+.

---

## 7. Governance Reference

Per `RULES.md`:
- **Rule 9 — No hidden blocker bypass:** "If the assigned phase requires...missing fixtures, then escalate. Do not fake completion."
- **Rule 11 — Execute only assigned phase:** "The assigned PHASE_X.md is the implementation contract."
- **Rule 14 — Escalate instead of improvising:** "If implementation requires architecture change, new dependency, or undocumented scope, stop and escalate."

Per `CLAUDE.md` Section 9:
> "Claude Code must stop and escalate if: the assigned phase conflicts with another canonical document"

This is exactly that situation.

---

## 8. Current Status

**BLOCKED — awaiting project owner decision on scope.**

No implementation has been started beyond this blocker report.

Implementation of the unambiguous subset (Section 4) can begin immediately upon approval.
