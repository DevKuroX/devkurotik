# PHASE_2.md
> Canonical implementation specification for Phase 2 — Router Management.
> This document is self-contained and derived from `ROADMAP_V1.md` without changing architecture, technologies, scope, or timeline.

---

## 1. Overview

### Purpose
Deliver secure multi-router administration as DevKuroTik’s first end-user capability.

### Scope
Phase 2 covers:
- Add/Edit/Delete router
- Multi-router support
- Health checks
- Local persistence
- Router grouping

### Objectives
1. Implement secure router CRUD workflows.
2. Establish active router selection and switching behavior.
3. Persist router configuration locally using the approved storage model.
4. Protect credentials using the approved secure storage strategy.
5. Deliver multi-router behavior that can be consumed by dashboard and hotspot phases without refactor.

---

## 2. Inputs

Required inputs for this phase:
- `ROADMAP_V1.md`
- `PHASE_0.md`
- `PHASE_1.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `MIGRATION_BLUEPRINT.md`
- `SDK_DESIGN.md`
- `SECURITY_REPORT.md`
- `FINAL_RECOMMENDATION.md`

---

## 3. Deliverables

1. Router entity model and repository design implemented.
2. Secure credential storage policy applied to router secrets.
3. Add router flow implemented.
4. Edit router flow implemented.
5. Delete router flow implemented.
6. Router listing and quick-switch flow implemented.
7. Health/connectivity check implemented.
8. Grouping/tagging model for routers implemented.
9. Local persistence split across Drift and secure storage implemented.
10. Active router state model implemented.
11. Last-used router behavior implemented.
12. Failure states for unreachable routers implemented.
13. Router management documentation updated.

---

## 4. Tasks

### Task 1 — Define router persistence model
Implement the router entity and persistence model based on roadmap and migration blueprint, using:
- SQLite/Drift for router metadata
- secure storage for credentials/secrets

### Task 2 — Implement router repository and storage boundary
Ensure router persistence logic is separated from UI and aligned with the approved architecture. The repository must support add, edit, delete, load, and list operations.

### Task 3 — Implement add-router workflow
Implement the full add-router flow, including validation, secure storage of credentials, and persistence of non-secret metadata.

### Task 4 — Implement edit-router workflow
Implement the edit-router flow so users can safely update router metadata and credentials without corrupting existing stored state.

### Task 5 — Implement delete-router workflow
Implement deletion flow with confirmation and correct cleanup of persisted router metadata and associated secure credentials.

### Task 6 — Implement router listing and selection
Implement router listing and active-router selection behavior. Ensure the app has a deterministic active router context for all future phases.

### Task 7 — Implement router quick switch behavior
Implement fast switching between routers while preserving isolation of router-specific state.

### Task 8 — Implement health/connectivity checks
Implement connectivity validation against the selected router using the approved `mikrotik_sdk` layer. Surface reachable/unreachable states clearly.

### Task 9 — Implement router grouping/tagging model
Implement the grouping/tagging capability defined in roadmap without over-expanding it into fleet analytics or premium features.

### Task 10 — Implement last-used router behavior
Persist and restore last-used router selection in a deterministic way consistent with local storage and security policy.

### Task 11 — Implement error and unreachable-router states
Implement explicit failure states for:
- invalid configuration
- failed credential use
- unreachable router
- deleted or missing router state

### Task 12 — Verify downstream compatibility
Confirm that Phase 3 and Phase 4 can consume router selection and persistence behavior without changing Phase 2 design.

---

## 5. Dependencies

### Requires
- Phase 0 complete
- Phase 1 complete

### Blocked by
- unstable `mikrotik_sdk`
- unresolved secure storage baseline

### External Dependencies
- test router target for connection validation
- device/emulator environment for verifying persistence behavior

---

## 6. Acceptance Criteria

1. User can add a router successfully.
2. User can edit a router successfully.
3. User can delete a router successfully.
4. User can list multiple routers and switch between them deterministically.
5. Router credentials are never stored in SQLite plaintext.
6. Router metadata and credentials are persisted in the approved split-storage model.
7. Health/connectivity checks correctly identify reachable and unreachable routers.
8. Unreachable router states do not corrupt local state.
9. Last-used router behavior works consistently across app restarts.
10. Router grouping/tagging works without changing the persistence model later.
11. Phase 3 and Phase 4 can consume active router state without refactor.
12. All tests pass.
13. Minimum coverage for this phase is **80% feature coverage**.

---

## 7. Definition of Done

Phase 2 is done only when:
- all deliverables are completed
- acceptance criteria are satisfied
- tests are passing
- coverage threshold is met
- active-router behavior is stable
- secure credential handling is verified
- downstream phases can consume router management without redesign

---

## 8. Testing Requirements

### Required Test Types
- Unit tests
- Widget tests
- Integration tests

### Minimum Coverage Requirements
- **Coverage >= 80% feature coverage**

### Unit Test Requirements
Must cover:
- router model validation
- repository logic
- storage split logic
- last-used router behavior
- grouping/tagging logic

### Widget Test Requirements
Must cover:
- add router screen states
- edit router screen states
- delete confirmation behavior
- router list and switching behavior
- unreachable-router error states

### Integration Test Requirements
Must cover:
- add/edit/delete persistence behavior
- secure credential storage interaction
- connectivity/health check integration with `mikrotik_sdk`
- app restart / reload persistence of router state where testable

### Required Validation Evidence
- green CI run
- coverage report meeting threshold
- successful live or controlled integration checks with router connection flow

---

## 9. Risks

### Technical Risks
- active-router state leaks across screens
- metadata and credentials become unsafely coupled
- grouping model becomes too complex too early

### Migration Risks
- local storage schema is too weak for future dashboard/hotspot use
- router switching behavior causes rework in downstream phases

### Security Risks
- credentials stored in plaintext or exposed via logs
- failed connection flows reveal secret values in errors

---

## 10. Non-Goals

Phase 2 must **not** implement:
- dashboard metrics
- hotspot user management
- voucher generation
- `OnLoginScriptGenerator`
- PPP/Queue features
- premium fleet analytics
- QRIS, widgets, cloud sync, or backup

This phase is limited to router management foundations only.

---

## 11. Estimated Duration

- **Optimistic:** 1.5 weeks
- **Realistic:** 2 weeks
- **Pessimistic:** 3 weeks

---

## 12. AI Execution Notes

Instructions for future AI agents assigned only this phase:
- Do not redesign the storage model.
- Do not store secrets in SQLite plaintext.
- Do not bypass `mikrotik_sdk` for connection checks.
- Do not implement dashboard or hotspot business flows.
- Do not add cloud or premium fleet features.
- Do not skip widget or integration tests for critical state flows.
- Keep router management deterministic and reusable by later phases.
