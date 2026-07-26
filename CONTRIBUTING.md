# CONTRIBUTING.md
> Contribution contract for DevKuroTik.

---

## Purpose
Define how contributors must work in the DevKuroTik repository, including branch strategy, commit conventions, pull request expectations, review checklist, testing requirements, documentation requirements, release process, and tagging policy.

## Scope
This document applies to:
- human contributors
- maintainers
- reviewers
- AI-assisted implementation workflows

## Audience
- project owner
- maintainers
- contributors
- reviewers
- AI operators

## Last Updated
2026-07-25

---

## 1. Branch Strategy

Recommended branch model:
- `main`
- `develop`
- `feature/*`

### Branch Roles
- `main` → stable release-ready history
- `develop` → integration branch for approved, reviewed phase work
- `feature/*` → scoped work branch for one phase or one tightly bounded work item inside a phase

### Branch Rules
- Do not implement multiple phases in one feature branch.
- Keep branches phase-scoped.
- Do not merge directly to `main` from unreviewed feature branches.

---

## 2. Commit Conventions

Commits should be:
- phase-scoped
- descriptive
- reviewable
- easy to map to acceptance criteria and deliverables

### Recommended Commit Prefixes
- `phase0:`
- `phase1:`
- `phase2:`
- `phase3:`
- `phase4:`
- `phase5:`
- `phase6:`
- `phase7:`
- `phase8:`
- `phase9:`
- `phase10:`
- `docs:`
- `test:`
- `ci:`
- `chore:`

### Commit Guidance
- One commit should reflect one coherent change set.
- Do not combine unrelated phase work in one commit.
- Avoid vague messages such as `fix stuff` or `update app`.

---

## 3. Pull Request Requirements

Every PR must:
1. Identify the assigned phase.
2. Reference the canonical phase document.
3. Describe what was implemented.
4. Describe what was intentionally not implemented.
5. Include test results.
6. Include documentation updates.
7. Confirm no future-phase scope was added.
8. Confirm no unapproved dependencies were introduced.

### PR Template Expectations
A PR should include:
- Phase
- Scope summary
- Deliverables completed
- Acceptance criteria addressed
- Tests run
- Coverage or gate evidence
- Documentation updated
- Risks or blockers

---

## 4. Review Checklist

Reviewers must verify:
- scope matches the assigned phase
- no architecture changes were introduced
- no future-phase functionality was added
- no unapproved dependencies were introduced
- tests required by the phase were run
- failing checks are absent
- Definition of Done is satisfied
- documentation updates are included where required
- governance has not been violated

### Review Blockers
Reject the PR if:
- tests fail
- required docs are missing
- phase scope is violated
- architecture is changed without approval
- source-of-truth docs are casually modified
- security requirements are weakened

---

## 5. Testing Requirements

Contributors must run all tests required by the assigned phase document.

This may include:
- unit tests
- widget tests
- integration tests
- golden tests
- regression tests
- performance tests
- security validation
- beta validation evidence

### Testing Rule
If the phase requires it, it is mandatory.
No contributor may claim completion while required tests are incomplete or failing.

---

## 6. Documentation Requirements

Contributors must update all documentation required by the assigned phase.

### Required Behavior
- update setup docs when setup changes
- update testing docs when testing behavior changes
- update phase-specific evidence/checklists when required

### Forbidden Behavior
Do not modify final source-of-truth documents unless explicitly directed by the project owner.

This includes:
- `ROADMAP_V1.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `PHASE_0.md` ... `PHASE_10.md`
- `docs/GOVERNANCE.md`

---

## 7. Release Process

Release progression follows the phase model.

### Required Flow
```text
Assigned Phase
  ↓
Implement
  ↓
Test
  ↓
Review
  ↓
Merge
  ↓
Tag
  ↓
Next Phase
```

### Do Not
- merge unfinished phase work and “fix later”
- tag a phase before acceptance criteria are satisfied
- proceed to the next phase with unresolved blocker defects from the current one

---

## 8. Tagging Policy

Recommended phase tags:

| Phase | Tag |
|---|---|
| Phase 0 | `v0.0.1` |
| Phase 1 | `v0.1.0` |
| Phase 2 | `v0.2.0` |
| Phase 3 | `v0.3.0` |
| Phase 4 | `v0.5.0` |
| Phase 5 | `v0.7.0` |
| Phase 6 | `v0.8.0` |
| Phase 7 | `v0.9.0` |
| Phase 8 | `v0.9.5` |
| Phase 9 | `v0.9.8` |
| Phase 10 | `v1.0.0` |

Tags should only be created after:
- acceptance criteria pass
- tests pass
- documentation is current
- phase review is complete

---

## 9. Special Contribution Rules

### Phase 0
Must be completed before feature development begins.

### Phase 1
Must be validated carefully because defects propagate broadly.

### Phase 6
Must be treated as a hard release gate.
No relaxed merge standard is allowed.

### Phase 9
Must remain optional and non-blocking.

---

## 10. Default Contributor Instruction

If there is uncertainty, the default instruction is:

> Execute the assigned `PHASE_X.md` exactly as written. Do not implement any future phases.

---

## References
- `README.md`
- `CLAUDE.md`
- `AGENTS.md`
- `RULES.md`
- `ARCHITECTURE.md`
- `docs/GOVERNANCE.md`
- `ROADMAP_V1.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `PHASE_0.md` ... `PHASE_10.md`
