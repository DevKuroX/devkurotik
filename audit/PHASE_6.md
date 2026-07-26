# PHASE_6.md
> Canonical implementation specification for Phase 6 — `OnLoginScriptGenerator`.
> This document is self-contained and derived from `ROADMAP_V1.md` without changing architecture, technologies, scope, or timeline.

---

## 1. Overview

### Purpose
Safely reproduce Mikhmon-compatible profile RouterScript generation and parsing behavior with exhaustive validation.

### Scope
Phase 6 covers:
- generator for all 5 expiry modes
- parser/decoder for existing metadata
- scheduler relationship rules
- regression validation
- compatibility fixtures from real routers

### Objectives
1. Implement the highest-risk compatibility module in the project.
2. Parse and generate approved `on-login` metadata behavior exactly as required by roadmap.
3. Validate all supported expiry modes against known-good fixtures.
4. Verify scheduler linkage behavior and metadata correctness.
5. Establish a regression gate that blocks unsafe changes in future phases.

---

## 2. Inputs

Required inputs for this phase:
- `ROADMAP_V1.md`
- `PHASE_0.md`
- `PHASE_1.md`
- `PHASE_4.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `SDK_DESIGN.md`
- `MIGRATION_BLUEPRINT.md`
- `FEATURE_MATRIX.md`
- `API_ENDPOINTS.md`
- `AUDIT_REPORT.md`
- `FINAL_RECOMMENDATION.md`

---

## 3. Deliverables

1. Formal specification for audited metadata positions and script variants created.
2. Generator requirements documented.
3. Parser/decoder requirements documented.
4. Golden test fixture library created using captured PHP outputs and real-router scripts.
5. Generation matrix implemented for all supported expiry modes:
   - none
   - remove
   - notice
   - remove+record
   - notice+record
6. MAC lock behavior validation implemented.
7. Price/validity metadata encoding validation implemented.
8. Scheduler linkage validation implemented.
9. Regression suite implemented with byte-level or canonical-equivalence assertions.
10. Change-control policy documented for future modifications to this module.
11. Real-router validation evidence recorded.

---

## 4. Tasks

### Task 1 — Formalize the audited metadata specification
Write the precise specification for all audited `on-login` metadata positions, supported variants, and required script semantics. This specification must reflect the roadmap and audit findings only.

### Task 2 — Define parser requirements
Define the parser behavior for existing profile scripts, including metadata extraction, malformed input handling, and preservation rules for approved compatibility fields.

### Task 3 — Define generator requirements
Define the generator behavior for all supported expiry modes and metadata combinations. Do not introduce new generation behaviors.

### Task 4 — Build the fixture library
Capture and organize known-good fixtures from:
- audited legacy outputs
- real-router scripts

Ensure fixtures are versioned and usable in automated regression testing.

### Task 5 — Implement parser/decoder behavior
Implement the parser/decoder for existing profile scripts and metadata positions using the approved compatibility model.

### Task 6 — Implement generation behavior for all supported expiry modes
Implement the generator for:
- none
- remove
- notice
- remove+record
- notice+record

### Task 7 — Validate metadata encoding rules
Validate encoding behavior for:
- price
- validity
- MAC lock behavior
- required positional metadata rules

### Task 8 — Validate scheduler linkage behavior
Implement and validate the scheduler relationship rules required by roadmap and hotspot profile behavior.

### Task 9 — Implement the regression suite
Create automated regression coverage using:
- golden tests against known-good outputs
- parser round-trip tests
- canonical-equivalence or byte-level assertions
- negative tests for malformed scripts

### Task 10 — Perform real-router validation
Validate generated and updated profile behavior on a real RouterOS environment to confirm script and scheduler behavior works operationally.

### Task 11 — Document change-control policy
Document the rule that any future change to this module requires:
- fixture review
- parser review
- manual router validation
- release note entry

---

## 5. Dependencies

### Requires
- Phase 1 complete
- Phase 4 complete
- Phase 0 test infrastructure available

### Blocked by
- missing real script fixtures
- incomplete profile domain understanding from hotspot phase

### External Dependencies
- access to real scripts captured from routers
- real RouterOS test target for validation

---

## 6. Acceptance Criteria

1. All 5 audited expiry modes are implemented.
2. Existing profile metadata can be decoded from real examples.
3. Generated scripts match approved semantics and canonical structure.
4. MAC lock behavior is validated.
5. Price and validity metadata encoding is validated.
6. Scheduler linkage behavior is validated.
7. Golden fixture library exists and is used by automated tests.
8. Regression suite is mandatory and passing.
9. Real-router validation confirms actual router behavior matches intended behavior.
10. Change-control policy is documented.
11. All tests pass.
12. Minimum coverage for this phase is **95% critical-path coverage**.

---

## 7. Definition of Done

Phase 6 is done only when:
- all deliverables are completed
- acceptance criteria are satisfied
- regression suite is complete and passing
- real-router validation has been performed
- no unresolved ambiguity remains in metadata positions or generation rules
- this module is ready to act as a release gate for profile management

---

## 8. Testing Requirements

### Required Test Types
- Golden tests
- Regression tests
- Integration tests

### Minimum Coverage Requirements
- **Coverage >= 95% critical-path coverage**

### Golden Test Requirements
Must cover:
- known-good generator outputs
- canonical script structure for all approved expiry modes
- parser round-trip expected outputs

### Regression Test Requirements
Must cover:
- all 5 expiry modes
- required metadata combinations in release scope
- malformed scripts
- scheduler linkage behavior
- compatibility of parser and generator with fixture library

### Integration Test Requirements
Must cover:
- profile create/update flows that depend on generated script output
- real-router validation of generated behavior
- actual expiry/scheduler behavior where testable

### Required Validation Evidence
- green CI run
- coverage report meeting threshold
- fixture inventory
- documented real-router validation results

---

## 9. Risks

### Technical Risks
- silent logical corruption rather than visible failure
- synthetic tests provide false confidence
- scheduler behavior differs from expectations under real router conditions

### Migration Risks
- existing profile scripts fail to decode correctly
- metadata position handling drifts from audited compatibility rules

### Security Risks
- malformed or unvalidated script handling introduces unsafe behavior
- debug output leaks sensitive script content or profile metadata

---

## 10. Non-Goals

Phase 6 must **not** implement:
- general hotspot CRUD beyond what is strictly needed for validation
- voucher engine features
- PPP/Queue features
- premium features
- architecture redesign
- non-audited script generation variants

---

## 11. Estimated Duration

- **Optimistic:** 2 weeks
- **Realistic:** 3 weeks
- **Pessimistic:** 5 weeks

---

## 12. AI Execution Notes

Instructions for future AI agents assigned only this phase:
- Do not treat this as a normal feature phase.
- Do not change compatibility rules from the roadmap or audit.
- Do not skip real-router validation.
- Do not ship without a fixture-driven regression suite.
- Do not introduce new expiry modes or metadata semantics.
- Do not optimize away canonical behavior for convenience.
- This phase is a release gate and must be implemented conservatively.
