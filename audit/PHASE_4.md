# PHASE_4.md
> Canonical implementation specification for Phase 4 — Hotspot.
> This document is self-contained and derived from `ROADMAP_V1.md` without changing architecture, technologies, scope, or timeline.

---

## 1. Overview

### Purpose
Reach operational hotspot feature parity required for daily use, based strictly on the audited feature set.

### Scope
Phase 4 covers the audited hotspot feature family:
- user management
- profile listing/management
- active sessions
- cookies
- hosts
- expiry lookup
- core hotspot workflows referenced in `FEATURE_MATRIX.md`

### Objectives
1. Deliver the critical hotspot user operations needed for daily field use.
2. Implement stable hotspot state flows around the active router.
3. Support user detail, session handling, and expiry display.
4. Handle destructive actions safely and auditable.
5. Provide the hotspot foundation required by voucher and high-risk profile logic phases.

---

## 2. Inputs

Required inputs for this phase:
- `ROADMAP_V1.md`
- `PHASE_0.md`
- `PHASE_1.md`
- `PHASE_2.md`
- `PHASE_3.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `FEATURE_MATRIX.md`
- `SDK_DESIGN.md`
- `API_ENDPOINTS.md`
- `MIGRATION_BLUEPRINT.md`
- `SECURITY_REPORT.md`

---

## 3. Deliverables

1. User list implemented with filters for all users, by profile, by comment, and expired users.
2. User detail view implemented.
3. Add user flow implemented.
4. Edit user flow implemented.
5. Delete single user flow implemented.
6. Bulk delete by comment implemented.
7. Bulk delete expired implemented.
8. Enable/disable user implemented.
9. Reset counters implemented.
10. Export capabilities implemented only within roadmap-approved MVP/v1 scope.
11. Active session list implemented.
12. Disconnect session flow implemented.
13. Cookie list and remove flow implemented.
14. Host list and remove flow implemented.
15. User expiry display logic implemented.
16. Validation rules for all user inputs implemented.
17. Error handling and destructive action confirmations implemented.
18. Local audit logging for destructive hotspot actions implemented where required by roadmap security baseline.

---

## 4. Tasks

### Task 1 — Implement hotspot user list and filters
Implement the hotspot user list with support for audited filters:
- all users
- by profile
- by comment
- expired users

### Task 2 — Implement user detail view
Implement the detailed user view showing the metadata required by roadmap, including expiry-related information where available.

### Task 3 — Implement add-user workflow
Implement the full add-user flow with input validation and use of the approved hotspot abstractions.

### Task 4 — Implement edit-user workflow
Implement the full edit-user flow with pre-populated state and validated update behavior.

### Task 5 — Implement safe single-user deletion
Implement single-user deletion with confirmation and audited local logging of destructive actions.

### Task 6 — Implement bulk delete by comment
Implement deterministic batch deletion by comment using the audited hotspot behavior and safe confirmation patterns.

### Task 7 — Implement bulk delete for expired users
Implement expired-user bulk deletion in a deterministic, testable, and confirmed flow.

### Task 8 — Implement enable/disable and reset counters
Implement user state toggles and counter reset behavior with explicit confirmations where operationally appropriate.

### Task 9 — Implement active session management
Implement:
- active session list
- session filtering if already supported by approved abstractions
- session disconnect flow

### Task 10 — Implement cookie and host management
Implement:
- cookie list and removal
- host list and removal

### Task 11 — Implement user expiry display logic
Implement expiry display logic using the approved roadmap interpretation of available router metadata. Do not invent new expiry logic.

### Task 12 — Implement hotspot validation and error handling
Implement input validation for all hotspot flows and explicit error states for network, router, and user-action failures.

### Task 13 — Implement export capabilities within approved scope
Implement only the export capability permitted by the roadmap’s MVP/v1 decision. Do not expand export beyond audited scope.

### Task 14 — Validate downstream readiness for voucher and profile logic phases
Confirm Phase 5 and Phase 6 can rely on hotspot user/profile/session behavior without redesign.

---

## 5. Dependencies

### Requires
- Phase 1 complete
- Phase 2 complete

### Blocked by
- unstable active-router state
- incomplete hotspot abstractions

### External Dependencies
- test router with hotspot data
- realistic hotspot user/session data for validation

---

## 6. Acceptance Criteria

1. All hotspot user operations marked Critical in `FEATURE_MATRIX.md` are implemented.
2. User list supports the required audited filters.
3. User detail renders correctly for existing hotspot users.
4. Add, edit, delete, enable/disable, and reset counter flows work correctly.
5. Bulk delete by comment works correctly.
6. Bulk delete expired users works correctly.
7. Active session list and disconnect flow work correctly.
8. Cookie list/remove and host list/remove flows work correctly.
9. User expiry display logic reflects the approved available router metadata without invented behavior.
10. Destructive actions require confirmation.
11. Destructive actions generate local audit log entries where required.
12. Hotspot data refreshes successfully without app restart.
13. Errors are surfaced clearly and do not corrupt local state.
14. All tests pass.
15. Minimum coverage for this phase is **80% feature coverage**.

---

## 7. Definition of Done

Phase 4 is done only when:
- all deliverables are completed
- acceptance criteria are satisfied
- required tests are passing
- coverage threshold is met
- destructive flows are safe and auditable
- hotspot workflows are usable for daily field operations
- downstream voucher and high-risk profile phases can build on this phase without redesign

---

## 8. Testing Requirements

### Required Test Types
- Unit tests
- Widget tests
- Integration tests
- Regression tests

### Minimum Coverage Requirements
- **Coverage >= 80% feature coverage**

### Unit Test Requirements
Must cover:
- filter logic
- validation logic
- expiry display mapping logic
- batch action preparation logic

### Widget Test Requirements
Must cover:
- user list states
- user detail states
- add/edit user forms
- destructive confirmations
- active session, cookie, and host list states

### Integration Test Requirements
Must cover:
- add/edit/delete hotspot user flows
- bulk delete flows
- enable/disable/reset flows
- session disconnect flow
- host/cookie removal flows

### Regression Test Requirements
Must cover:
- comment-field behavior where it affects hotspot presentation or filtering
- destructive batch logic stability
- expiry-related display logic stability

### Required Validation Evidence
- green CI run
- coverage report meeting threshold
- integration evidence against a router or controlled RouterOS target

---

## 9. Risks

### Technical Risks
- user detail logic depends on scheduler/profile-related metadata
- destructive cascades can become inconsistent
- hotspot state refresh may become unstable under poor connectivity

### Migration Risks
- legacy comment-field behavior may be interpreted incorrectly
- later voucher/profile phases may require rework if hotspot semantics are implemented loosely

### Security Risks
- destructive actions lack proper confirmation or audit trail
- user data or credentials appear in logs or exported outputs unsafely

---

## 10. Non-Goals

Phase 4 must **not** implement:
- voucher generation engine
- Quick Print package management beyond what is strictly needed as hotspot dependency groundwork
- `OnLoginScriptGenerator`
- PPP/Queue functionality
- premium notifications, widgets, QRIS, cloud sync, backup
- architecture refactors outside hotspot scope

---

## 11. Estimated Duration

- **Optimistic:** 3 weeks
- **Realistic:** 4 weeks
- **Pessimistic:** 6 weeks

---

## 12. AI Execution Notes

Instructions for future AI agents assigned only this phase:
- Do not redesign hotspot architecture.
- Do not invent new hotspot features beyond the audited scope.
- Do not implement voucher or profile generator logic here.
- Do not skip destructive action confirmation and audit behavior.
- Do not bypass approved SDK/package boundaries.
- Do not treat export scope as open-ended.
- Keep this phase focused on stable, daily-use hotspot operations only.
