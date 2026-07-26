# PHASE_7.md
> Canonical implementation specification for Phase 7 — PPP + Queue.
> This document is self-contained and derived from `ROADMAP_V1.md` without changing architecture, technologies, scope, or timeline.

---

## 1. Overview

### Purpose
Add the non-hotspot operational features needed for broader MikroTik management parity within the audited scope.

### Scope
Phase 7 covers:
- PPP
- Queue
- related management flows aligned with the audited feature set

### Objectives
1. Implement PPP capabilities documented in the roadmap and feature matrix.
2. Implement Queue capabilities required by approved scope.
3. Support PPP active session management.
4. Preserve boundaries so PPP/Queue work does not destabilize hotspot/profile flows.
5. Explicitly document unsupported legacy gaps instead of inventing behavior.

---

## 2. Inputs

Required inputs for this phase:
- `ROADMAP_V1.md`
- `PHASE_0.md`
- `PHASE_1.md`
- `PHASE_2.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `FEATURE_MATRIX.md`
- `SDK_DESIGN.md`
- `API_ENDPOINTS.md`
- `MIGRATION_BLUEPRINT.md`
- `AUDIT_REPORT.md`

---

## 3. Deliverables

1. PPP secrets list implemented.
2. Add PPP secret flow implemented.
3. Edit PPP secret flow implemented.
4. PPP profiles support implemented where included in approved scope.
5. PPP active sessions list implemented.
6. PPP active session disconnect implemented.
7. Queue listing support implemented.
8. Queue assignment integration implemented where needed by hotspot/profile flows.
9. Queue removal operations implemented only if they are within roadmap scope.
10. Error handling and confirmations implemented.
11. Documentation created for PPP source-gap handling and audited limitations.

---

## 4. Tasks

### Task 1 — Define PPP and Queue implementation boundaries
Use roadmap, feature matrix, and API audit to define exactly what PPP and Queue capabilities are in scope for this phase. Do not invent missing legacy behavior.

### Task 2 — Implement PPP secrets listing
Implement the PPP secrets listing flow using the approved SDK architecture.

### Task 3 — Implement add/edit PPP secret flows
Implement creation and update flows for PPP secrets within the audited scope.

### Task 4 — Implement PPP profiles support if in approved release scope
Implement PPP profile listing/management only to the extent approved by roadmap and feature matrix.

### Task 5 — Implement PPP active session management
Implement:
- PPP active session list
- PPP active session disconnect

### Task 6 — Implement Queue listing support
Implement queue listing in the approved scope and bind it to the existing architecture.

### Task 7 — Implement Queue assignment integration
Implement queue assignment integration only where needed by approved hotspot/profile-related flows.

### Task 8 — Implement Queue removal only if in approved scope
If queue removal is approved by roadmap scope, implement it with confirmations and safe error handling. If not, explicitly omit it.

### Task 9 — Implement errors and confirmations
Implement clear failure states, confirmations, and guardrails for PPP and Queue actions.

### Task 10 — Document source-gap boundaries
Document the fact that PPP support in Mikhmon source is incomplete and that this implementation is grounded only in audited references and the endpoint map.

---

## 5. Dependencies

### Requires
- Phase 1 complete
- Phase 2 complete

### Blocked by
- missing PPP/Queue abstractions in SDK layer
- insufficient scope discipline around incomplete legacy source behavior

### External Dependencies
- test router with PPP and queue data
- realistic PPP active-session validation environment

---

## 6. Acceptance Criteria

1. Audited PPP features in approved scope are operational.
2. Audited Queue features in approved scope are operational.
3. PPP active session management works reliably.
4. Queue integration does not break hotspot/profile workflows.
5. Unsupported legacy behaviors are explicitly documented instead of guessed.
6. Error handling and confirmations are implemented.
7. All tests pass.
8. Minimum coverage for this phase is **75% feature coverage**.

---

## 7. Definition of Done

Phase 7 is done only when:
- all deliverables are completed
- acceptance criteria are satisfied
- required tests are passing
- coverage threshold is met
- unsupported legacy gaps are documented clearly
- PPP/Queue behavior remains within audited scope

---

## 8. Testing Requirements

### Required Test Types
- Unit tests
- Integration tests

### Minimum Coverage Requirements
- **Coverage >= 75% feature coverage**

### Unit Test Requirements
Must cover:
- PPP input validation
- queue assignment logic
- confirmation and error-state mapping

### Integration Test Requirements
Must cover:
- PPP secret list/add/edit flows
- PPP active session disconnect
- queue listing
- queue assignment integration within approved scope

### Required Validation Evidence
- green CI run
- coverage report meeting threshold
- router-backed validation of PPP active session handling

---

## 9. Risks

### Technical Risks
- PPP source behavior is not fully present in the legacy repository
- queue behavior may intersect profile/hotspot logic unexpectedly

### Migration Risks
- inventing unsupported PPP behavior creates divergence from audit
- queue integrations force rework into earlier feature phases

### Security Risks
- PPP or queue actions lack proper confirmations or validation
- sensitive PPP information leaks through logging or error handling

---

## 10. Non-Goals

Phase 7 must **not** implement:
- hotspot feature redesign
- voucher engine logic
- `OnLoginScriptGenerator`
- premium features
- cloud sync
- QRIS
- architecture changes outside PPP/Queue scope

---

## 11. Estimated Duration

- **Optimistic:** 1.5 weeks
- **Realistic:** 2 weeks
- **Pessimistic:** 4 weeks

---

## 12. AI Execution Notes

Instructions for future AI agents assigned only this phase:
- Do not guess unsupported PPP behavior.
- Do not expand queue scope beyond roadmap requirements.
- Do not destabilize hotspot/profile integrations.
- Do not skip router-backed validation for PPP active sessions.
- Do not implement premium or unrelated network features.
- Keep the scope narrow, audited, and explicit.
