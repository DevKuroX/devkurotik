# PHASE_5.md
> Canonical implementation specification for Phase 5 — Voucher Engine.
> This document is self-contained and derived from `ROADMAP_V1.md` without changing architecture, technologies, scope, or timeline.

---

## 1. Overview

### Purpose
Deliver the revenue-generating workflow that makes bulk user generation and voucher distribution practical on mobile.

### Scope
Derived from `FEATURE_MATRIX.md` and `MIGRATION_BLUEPRINT.md`, Phase 5 covers:
- bulk user generation
- voucher modes
- character-set generation
- last-batch persistence
- voucher rendering
- batch and single print
- Quick Print flows
- Android printing path

### Objectives
1. Implement mobile-first bulk user generation.
2. Implement voucher rendering and sharing/printing in the approved formats.
3. Support Quick Print compatibility within the roadmap scope.
4. Ensure QR generation is local and never leaks credentials externally.
5. Provide reliable fallback behavior when printing fails.

---

## 2. Inputs

Required inputs for this phase:
- `ROADMAP_V1.md`
- `PHASE_0.md`
- `PHASE_1.md`
- `PHASE_2.md`
- `PHASE_4.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `FEATURE_MATRIX.md`
- `MIGRATION_BLUEPRINT.md`
- `SDK_DESIGN.md`
- `API_ENDPOINTS.md`
- `SECURITY_REPORT.md`
- `FINAL_RECOMMENDATION.md`

---

## 3. Deliverables

1. Bulk user generation workflow implemented.
2. Voucher mode support implemented for user=pass and user+pass.
3. Character set selection logic implemented.
4. Prefix support implemented.
5. Profile/validity preview implemented.
6. Last batch summary persistence implemented.
7. Voucher rendering templates implemented for default, thermal, and small if included in release scope.
8. QR generation implemented locally only.
9. Single-user voucher print/share flow implemented.
10. Batch voucher print/share flow implemented.
11. Quick Print package read/write compatibility implemented.
12. One-touch generate + print flow implemented.
13. Android-first print fallback matrix implemented for PDF/share and thermal/BT where supported.
14. Failure recovery behavior after print failure implemented.
15. Voucher engine documentation updated.

---

## 4. Tasks

### Task 1 — Implement bulk user generation workflow
Implement configurable batch generation within the audited scope, including count, mode, character set, and prefix behavior.

### Task 2 — Implement voucher mode logic
Implement the approved voucher modes:
- user = pass
- user + pass

Do not add additional generation modes.

### Task 3 — Implement character-set and prefix logic
Implement generation controls for the roadmap-approved character set variations and username prefix support.

### Task 4 — Implement profile/validity preview
Implement preview behavior for profile and validity details required before generation.

### Task 5 — Implement last-batch summary persistence
Persist the last generated batch metadata using the approved local storage strategy.

### Task 6 — Implement voucher rendering outputs
Implement the roadmap-approved voucher rendering outputs, including default and thermal templates, and small template only if it remains in release scope.

### Task 7 — Implement local QR generation
Generate voucher QR content locally only. Do not use external QR/chart services.

### Task 8 — Implement single-user voucher print/share flow
Implement print/share flow for a single generated or existing voucher target.

### Task 9 — Implement batch voucher print/share flow
Implement print/share flow for batch-generated vouchers with predictable sequencing and failure handling.

### Task 10 — Implement Quick Print compatibility
Implement read/write compatibility for Quick Print packages using the approved compatibility strategy from roadmap and SDK design.

### Task 11 — Implement one-touch generate + print
Implement the one-touch workflow that generates a user and immediately proceeds to print/share using the approved Android-first flow.

### Task 12 — Implement Android-first print fallback matrix
Implement the approved fallback logic for:
- PDF/share
- thermal/BT where supported

Do not add unapproved printing platforms or services.

### Task 13 — Implement failure recovery behavior
Implement predictable recovery when generation succeeds but print/share fails, ensuring users can recover without data loss or duplicate confusion.

### Task 14 — Validate operational usability
Confirm voucher workflows are usable in field conditions and remain compatible with audited Quick Print behavior.

---

## 5. Dependencies

### Requires
- Phase 1 complete
- Phase 2 complete
- Phase 4 complete

### Blocked by
- incomplete user/profile foundations
- missing Quick Print compatibility understanding
- unresolved print stack setup from Phase 0

### External Dependencies
- Android device for print/share validation
- printer hardware for BT/thermal validation where supported
- realistic Quick Print and voucher test data

---

## 6. Acceptance Criteria

1. Bulk user generation works within approved batch scope.
2. Both approved voucher modes work correctly.
3. Character set and prefix controls work correctly.
4. Profile/validity preview displays correctly before generation.
5. Last batch metadata is persisted and recoverable locally.
6. Voucher rendering outputs are readable and operationally usable.
7. QR generation is local only and does not leak credentials externally.
8. Single-user print/share flow works.
9. Batch print/share flow works.
10. Quick Print packages are compatible with the audited RouterOS storage format.
11. One-touch generate + print flow works in the approved Android-first model.
12. If printing fails after generation, recovery behavior preserves usability.
13. All tests pass.
14. Minimum coverage for this phase is **80% feature coverage**.

---

## 7. Definition of Done

Phase 5 is done only when:
- all deliverables are completed
- acceptance criteria are satisfied
- required tests are passing
- coverage threshold is met
- voucher generation is usable in field workflows
- Quick Print compatibility works within approved scope
- print/share fallback behavior is reliable enough for operational use

---

## 8. Testing Requirements

### Required Test Types
- Unit tests
- Integration tests
- Golden tests
- Regression tests

### Minimum Coverage Requirements
- **Coverage >= 80% feature coverage**

### Unit Test Requirements
Must cover:
- generation parameter validation
- mode logic
- character-set logic
- prefix logic
- last-batch persistence logic
- QR payload rules

### Integration Test Requirements
Must cover:
- batch generation
- single voucher flow
- batch voucher flow
- Quick Print package compatibility behavior
- generate-then-print failure recovery behavior

### Golden Test Requirements
Must cover:
- voucher template outputs
- rendered output consistency for approved voucher layouts

### Regression Test Requirements
Must cover:
- Quick Print parsing/encoding behavior
- generation/printing recovery logic
- local-only QR generation guarantees

### Required Validation Evidence
- green CI run
- coverage report meeting threshold
- golden output verification
- Android print/share validation evidence

---

## 9. Risks

### Technical Risks
- print subsystem fragmentation on Android
- generated users succeed but print/share fails
- template rendering varies across devices or output modes

### Migration Risks
- Quick Print compatibility format errors break legacy package usage
- voucher layout decisions drift away from approved mobile-first scope

### Security Risks
- QR content leaks credentials to external services
- voucher or print paths log sensitive user credentials

---

## 10. Non-Goals

Phase 5 must **not** implement:
- `OnLoginScriptGenerator`
- PPP/Queue functionality
- cloud sync
- QRIS
- desktop print workflows
- premium widget ecosystems
- architecture changes outside voucher and Quick Print scope

---

## 11. Estimated Duration

- **Optimistic:** 2.5 weeks
- **Realistic:** 3 weeks
- **Pessimistic:** 5 weeks

---

## 12. AI Execution Notes

Instructions for future AI agents assigned only this phase:
- Do not redesign voucher architecture.
- Do not use external QR services.
- Do not skip failure recovery behavior after print errors.
- Do not introduce unsupported print technologies.
- Do not expand generation modes beyond roadmap scope.
- Do not implement premium payment or cloud features.
- Keep Quick Print compatibility exact and defensive.
