# PHASE_0.md
> Canonical implementation specification for Phase 0 — Foundation.
> This document is self-contained and derived from `ROADMAP_V1.md` without changing architecture, technologies, scope, or timeline.

---

## 1. Overview

### Purpose
Establish the engineering baseline for DevKuroTik so that all later phases can be implemented in a repeatable, testable, reviewable, and release-ready manner.

### Scope
Phase 0 covers:
- monorepo structure
- Flutter/Dart version pinning
- Riverpod setup conventions
- Drift setup conventions
- go_router setup conventions
- linting and formatting
- CI/CD baseline
- testing strategy baseline
- Git conventions
- ADR process
- documentation standards
- folder conventions
- dependency management
- tooling baseline

### Objectives
1. Freeze the project structure before feature work begins.
2. Pin the approved technical baseline from roadmap.
3. Establish CI, linting, testing, and documentation rules.
4. Create the repository and governance scaffolding needed by all later phases.
5. Ensure there are no unresolved architecture questions before Phase 1 starts.

---

## 2. Inputs

Required inputs for this phase:
- `ROADMAP_V1.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `MIGRATION_BLUEPRINT.md`
- `SDK_DESIGN.md`
- `SECURITY_REPORT.md`
- `FINAL_RECOMMENDATION.md`

---

## 3. Deliverables

1. Monorepo initialized with final top-level structure.
2. `apps/devkurotik_app` Flutter app scaffolded.
3. `packages/` workspace created for approved SDK packages.
4. Shared lint rules defined and enforced.
5. CI pipeline configured for dependency install, format check, static analysis, and test execution.
6. ADR template created.
7. Initial ADR set created for monorepo, Dart-first SDK strategy, offline-first local storage, and Android-first / iOS-ready platform plan.
8. CONTRIBUTING guide created.
9. Engineering standards document created.
10. Test strategy baseline document created.
11. Branching, PR, versioning, and release tagging conventions documented.
12. Folder conventions documented and frozen.
13. Dependency policy documented, including approved packages, evaluation criteria, and upgrade cadence.
14. Issue and decision templates created for future phases.
15. Baseline repository documentation updated to reflect the above.

---

## 4. Tasks

### Task 1 — Initialize the canonical repository structure
Create the top-level repository layout exactly as defined by roadmap:
- `apps/`
- `packages/`
- `docs/`
- `tools/`
- `.github/workflows/`

Ensure the structure aligns with the approved target architecture for:
- `apps/devkurotik_app`
- future SDK packages under `packages/`
- architecture and phase documentation under `docs/`
- fixtures and automation assets under `tools/`

### Task 2 — Pin the approved technical baseline
Document and pin the approved stack:
- Flutter stable 3.x used at project start
- Dart version bundled with that Flutter release
- Riverpod 2.x
- go_router
- Drift + SQLite
- flutter_secure_storage
- fl_chart
- pdf + printing
- qr_flutter
- flutter_local_notifications
- local_auth

Record these in repository setup and engineering docs so future phases do not re-decide them.

### Task 3 — Scaffold the application workspace
Create the application workspace for `apps/devkurotik_app` and ensure the baseline application can be installed, analyzed, and launched in a clean environment.

### Task 4 — Reserve package workspace boundaries
Create the package workspace layout for the roadmap-approved package strategy:
- `mikrotik_sdk`
- `voucher_sdk`
- `routeros_script_sdk`
- `monitoring_sdk`
- optional split package locations if retained later by scope

Do not redesign package boundaries. Only reserve the approved structure.

### Task 5 — Define formatting and linting standards
Configure and document:
- formatting rules
- lint rules
- static analysis expectations
- merge blocking behavior for lint/analyze failures

### Task 6 — Establish CI/CD baseline
Create a baseline CI workflow that runs at minimum:
- dependency installation
- format validation
- static analysis
- unit tests / smoke tests

CI must fail on violations and be suitable for enforcement in later phases.

### Task 7 — Create architecture decision record system
Create ADR templates and write the initial ADR set for the roadmap-mandated decisions:
- monorepo structure
- Dart-first SDK strategy
- offline-first local storage strategy
- Android-first / iOS-ready platform plan

### Task 8 — Create engineering governance documents
Write and organize:
- CONTRIBUTING guide
- engineering standards
- documentation standards
- folder conventions
- Git conventions
- PR expectations
- branching policy
- release tagging strategy

### Task 9 — Create testing baseline documentation
Write a testing baseline document that future phases must follow, including:
- unit test expectations
- widget/integration/golden/regression test usage
- CI integration
- evidence requirements for phase closure

### Task 10 — Define dependency management policy
Document:
- approved dependency list
- dependency evaluation criteria
- version update cadence
- criteria for rejecting new dependencies

### Task 11 — Create future execution templates
Create issue, decision, and implementation templates to support deterministic execution of later phases.

### Task 12 — Validate readiness for Phase 1
Confirm there are no unresolved architectural or repository-level blockers preventing Phase 1 from starting.

---

## 5. Dependencies

### Requires
- None

### Blocked by
- None

### External Dependencies
- Access to Flutter toolchain
- Access to CI platform/environment
- Clean build environment for reproducibility verification

---

## 6. Acceptance Criteria

1. Repository contains the approved top-level structure from roadmap.
2. `apps/devkurotik_app` exists and launches successfully in the baseline environment.
3. `packages/` contains reserved package workspace locations consistent with roadmap.
4. CI runs format checks, static analysis, and test execution successfully.
5. CI fails when formatting, analysis, or tests fail.
6. ADR template exists and the four required initial ADRs are present.
7. Folder conventions are documented and consistent with the repository layout.
8. Engineering standards, contribution rules, branching rules, and dependency policy are documented.
9. Project setup can be reproduced on a clean machine using documented steps.
10. There are no unresolved architecture decisions required to begin Phase 1.

---

## 7. Definition of Done

Phase 0 is done only when:
- all deliverables are completed
- all acceptance criteria are satisfied
- CI is active and passing
- required documentation is committed and current
- the repository structure matches the roadmap
- later phases can begin without repository or architecture rework

---

## 8. Testing Requirements

### Required Test Types
- CI smoke tests
- Static analysis validation
- Format validation

### Minimum Coverage Requirements
- No line coverage target required for Phase 0
- Baseline test execution must be wired into CI
- At least one smoke validation must prove the application scaffolding runs successfully

### Required Validation Evidence
- successful CI run
- successful static analysis run
- successful format validation run
- successful clean-environment setup verification

---

## 9. Risks

### Technical Risks
- Unpinned tooling causes inconsistent builds
- CI setup is incomplete and misses failures
- repository structure drifts before feature work begins

### Migration Risks
- later phases redefine directory or package structure because Phase 0 was left ambiguous
- missing ADRs force architecture re-litigation in later phases

### Security Risks
- dependency policy is weak and allows insecure additions later
- governance docs fail to enforce secure defaults

---

## 10. Non-Goals

Phase 0 must **not** implement:
- router management features
- RouterOS protocol logic
- hotspot features
- dashboard data features
- voucher generation
- `OnLoginScriptGenerator`
- PPP/Queue functionality
- QRIS or premium features
- business logic beyond project scaffolding and governance

---

## 11. Estimated Duration

- **Optimistic:** 1 week
- **Realistic:** 2 weeks
- **Pessimistic:** 3 weeks

---

## 12. AI Execution Notes

Instructions for future AI agents assigned only this phase:
- Do not modify architecture from `ROADMAP_V1.md`.
- Do not introduce technologies outside the approved stack.
- Do not start feature implementation.
- Do not add future-phase SDK logic.
- Do not skip CI, lint, or documentation work.
- Do not leave setup decisions implicit; document them.
- Stay strictly within repository, tooling, documentation, and governance scope.
