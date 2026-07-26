# PHASE_1.md
> Canonical implementation specification for Phase 1 — Core `mikrotik_sdk`.
> This document is self-contained and derived from `ROADMAP_V1.md` without changing architecture, technologies, scope, or timeline.

---

## 1. Overview

### Purpose
Build the foundational RouterOS access layer that all DevKuroTik business features depend on.

### Scope
Phase 1 covers:
- TCP client
- connection manager
- authentication
- command execution
- error handling
- retry strategy
- logging
- testing

### Objectives
1. Implement the approved `mikrotik_sdk` package foundation.
2. Support audited RouterOS binary API transport and authentication behavior required by roadmap.
3. Create stable command, error, timeout, and retry semantics for all later phases.
4. Ensure secrets are never leaked through logs, errors, or telemetry.
5. Deliver a validated SDK with unit and integration tests.

---

## 2. Inputs

Required inputs for this phase:
- `ROADMAP_V1.md`
- `PHASE_0.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `SDK_DESIGN.md`
- `API_ENDPOINTS.md`
- `MIGRATION_BLUEPRINT.md`
- `SECURITY_REPORT.md`
- `FINAL_RECOMMENDATION.md`

---

## 3. Deliverables

1. `mikrotik_sdk` package skeleton finalized.
2. Core RouterOS transport layer implemented.
3. Authentication layer implemented.
4. Command execution abstraction implemented.
5. Structured exception and error taxonomy implemented.
6. Timeout and retry policy implemented.
7. Logging policy implemented with credential redaction.
8. Connection invalidation and reconnect behavior implemented.
9. Unit test suite for protocol behaviors implemented.
10. Integration test suite against a controlled RouterOS target implemented.
11. Compatibility matrix documenting tested RouterOS versions created.
12. Public package API documented for downstream phases.

---

## 4. Tasks

### Task 1 — Create the `mikrotik_sdk` package structure
Use the package boundary defined in roadmap and SDK design. Do not merge it into app code. Ensure package structure supports public API exposure, internal implementation separation, and package-level tests.

### Task 2 — Implement binary RouterOS transport support
Implement the audited binary RouterOS API framing and socket communication behavior needed to support downstream RouterOS commands.

### Task 3 — Implement connection lifecycle management
Implement:
- connect
- disconnect
- connection state handling
- connection invalidation
- reconnect strategy consistent with roadmap requirements

### Task 4 — Implement authentication behavior
Implement authentication behavior compatible with audited requirements and documented RouterOS version handling. Do not change the roadmap requirement around protocol compatibility.

### Task 5 — Implement command execution abstraction
Create the stable command execution API that downstream SDKs and feature phases will use. This must support audited command patterns and must abstract transport details away from later feature work.

### Task 6 — Define and implement structured error handling
Implement deterministic exception and error taxonomy for:
- transport failures
- authentication failures
- timeout failures
- command-level failures
- retry exhaustion

### Task 7 — Implement timeout and retry policy
Implement the roadmap-approved retry/backoff and timeout behavior so later phases inherit predictable networking semantics.

### Task 8 — Implement secret-safe logging
Implement logging policy with explicit redaction of:
- credentials
- passwords
- sensitive authentication material
- secret-bearing command values where applicable

### Task 9 — Implement test harnesses
Create:
- unit tests for protocol encoding/decoding, retry, timeout, and error behavior
- integration tests against a controlled RouterOS target

### Task 10 — Produce compatibility documentation
Document the tested RouterOS compatibility assumptions, versions, and known limits without changing roadmap scope.

### Task 11 — Validate downstream usability
Confirm the SDK public surface is stable enough for later phases to consume without exposing internal transport details.

---

## 5. Dependencies

### Requires
- Phase 0 complete

### Blocked by
- Incomplete foundation setup
- Missing test infrastructure from Phase 0

### External Dependencies
- Real or virtual RouterOS test target
- network environment suitable for RouterOS integration testing

---

## 6. Acceptance Criteria

1. `mikrotik_sdk` exists as an independent package in the approved package workspace.
2. The SDK can connect to a configured router and execute audited print commands reliably.
3. Authentication succeeds using the roadmap-approved compatibility requirements.
4. Command execution API is stable and usable by downstream phases.
5. Timeout, retry, and disconnect behavior produce deterministic error types.
6. No plaintext credentials appear in logs, exceptions, or telemetry output.
7. Unit tests pass in CI.
8. Integration tests pass against at least one supported RouterOS environment.
9. Compatibility matrix is documented.
10. Public API documentation exists for downstream consumers.
11. Minimum coverage for this phase is **85% package coverage**.

---

## 7. Definition of Done

Phase 1 is done only when:
- all deliverables are completed
- acceptance criteria are satisfied
- unit and integration tests pass
- coverage target is met
- public API surface is documented
- downstream phases can consume the SDK without architecture changes

---

## 8. Testing Requirements

### Required Test Types
- Unit tests
- Integration tests

### Minimum Coverage Requirements
- **Coverage >= 85% package coverage**

### Unit Test Requirements
Must cover:
- transport framing behavior
- command abstraction behavior
- timeout handling
- retry behavior
- connection lifecycle behavior
- error taxonomy behavior
- secret-redaction behavior where testable

### Integration Test Requirements
Must cover:
- live router connection
- authentication flow
- execution of audited read commands
- error handling when router is unavailable or rejects auth

### Required Validation Evidence
- green CI test run
- coverage report meeting threshold
- successful integration test evidence against RouterOS target

---

## 9. Risks

### Technical Risks
- protocol edge cases not captured in static audit
- version-specific authentication differences
- unstable socket behavior under intermittent connectivity

### Migration Risks
- downstream phases become coupled to internal SDK implementation
- command abstraction fails to support audited usage patterns

### Security Risks
- secrets appear in logs or exceptions
- insecure fallback behavior under retry or auth failure conditions

---

## 10. Non-Goals

Phase 1 must **not** implement:
- router management UI
- dashboard screens
- hotspot user flows
- voucher generation
- Quick Print features
- `OnLoginScriptGenerator`
- PPP/Queue feature UIs
- premium features

This phase is limited to the foundational RouterOS SDK layer.

---

## 11. Estimated Duration

- **Optimistic:** 2 weeks
- **Realistic:** 3 weeks
- **Pessimistic:** 5 weeks

---

## 12. AI Execution Notes

Instructions for future AI agents assigned only this phase:
- Do not modify the package strategy from roadmap.
- Do not move router transport logic into app code.
- Do not skip integration testing.
- Do not expose secrets in logs or test fixtures.
- Do not implement hotspot, router management, dashboard, or voucher features.
- Do not change retry, timeout, or compatibility decisions from roadmap.
- Stay inside `mikrotik_sdk` scope and produce a stable downstream contract.
