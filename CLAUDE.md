# CLAUDE.md
> Claude Code operating contract for DevKuroTik.

---

## Purpose
Define mandatory operating instructions for Claude Code when working in the DevKuroTik repository.

## Scope
This document governs:
- Claude execution behavior
- scope limitations
- forbidden actions
- mandatory actions
- testing requirements
- documentation requirements
- governance requirements
- phase execution requirements

## Audience
- Claude Code
- maintainers supervising Claude Code output
- reviewers validating Claude-produced changes

## Last Updated
2026-07-25

---

## 1. Claude Operating Instructions

Claude Code must operate as an execution agent, not as a project architect.

Claude Code must assume:
- architecture is already decided
- roadmap is final
- phase documents are canonical
- governance rules are mandatory

Claude Code must always work from the assigned phase document and remain inside that scope.

---

## 2. Scope Limitations

Claude Code may:
- implement only the requested phase
- update documentation required by that phase
- run required tests for that phase
- fix defects discovered inside the requested phase scope

Claude Code may not:
- redesign architecture
- change phase boundaries
- add future-phase functionality
- expand scope because something “seems useful”
- reinterpret roadmap decisions into new technical directions

---

## 3. Forbidden Actions

Claude Code must never:
1. Modify architecture without explicit owner approval.
2. Introduce dependencies not already approved by the specification.
3. Implement future phases.
4. Rewrite source-of-truth documents.
5. Change timelines.
6. Add speculative features.
7. Skip tests.
8. Mark work complete when tests fail.
9. Merge or recommend merge of failing code.
10. Treat convenience as a reason to violate phase boundaries.

---

## 4. Mandatory Actions

Claude Code must always:
1. Read the assigned `PHASE_X.md` before implementation.
2. Follow `docs/GOVERNANCE.md`.
3. Follow `RULES.md`.
4. Respect `DEPENDENCY_GRAPH.md` and `EXECUTION_ORDER.md`.
5. Satisfy all deliverables in the assigned phase.
6. Satisfy all acceptance criteria in the assigned phase.
7. Satisfy the Definition of Done in the assigned phase.
8. Run all required tests for the assigned phase.
9. Update required documentation inside the assigned scope.
10. Escalate instead of improvising when blocked.

---

## 5. Testing Requirements

Claude Code must:
- run all tests required by the assigned phase
- report failures faithfully
- never suppress or skip failing tests without explicit owner approval
- treat coverage thresholds in phase documents as mandatory
- treat Phase 6 regression requirements as non-negotiable

If the phase requires:
- unit tests
- integration tests
- widget tests
- golden tests
- regression tests
- performance tests

Claude Code must execute or prepare them exactly as required by the phase document.

---

## 6. Documentation Requirements

Claude Code must update documentation when the assigned phase requires it.

Claude Code must not:
- rewrite roadmap documents
- change governance language
- edit architectural source-of-truth docs unless explicitly instructed by owner

Claude Code may update:
- phase-scoped implementation docs
- test/readme/setup docs that are part of the assigned phase deliverables
- evidence/checklist documentation required for phase closure

---

## 7. Governance Requirements

Claude Code must treat the following as hard constraints:
- `docs/GOVERNANCE.md`
- `RULES.md`
- assigned `PHASE_X.md`

Interpretation rule:

> If it is not in the assigned phase document, it does not exist for that phase.

If Claude detects a conflict between execution convenience and governance, governance wins.

---

## 8. Phase Execution Requirements

Claude Code must:
- execute only the requested phase
- never implement future phases
- never skip Phase 0
- never bypass the critical path
- never downgrade the requirements of Phase 6

### Required Execution Model

```text
Read assigned phase
  ↓
Implement only assigned scope
  ↓
Run required tests
  ↓
Update required docs
  ↓
Validate against acceptance criteria and DoD
  ↓
Stop
```

Claude Code must not continue into the next phase unless explicitly instructed by the project owner.

---

## 9. Escalation Rules

Claude Code must stop and escalate if:
1. the assigned phase conflicts with another canonical document
2. an implementation requires architecture changes
3. an implementation requires unapproved dependencies
4. tests required by the phase cannot be completed
5. real-router or printer validation is required but unavailable
6. the requested instruction attempts to bypass governance

When escalation is needed, Claude must explain the blocker and not improvise a workaround that violates the specification.

---

## 10. Special Rule for Phase 6

Phase 6 is the highest-risk implementation gate in the project.

Claude Code must treat Phase 6 as:
- no merge without review
- no release without regression suite
- no beta without real-router validation
- no behavior improvisation allowed

Coverage and regression requirements must follow the canonical phase document exactly.

---

## 11. Default Safe Instruction

If the project owner asks Claude to work on DevKuroTik, the correct safe interpretation is:

> Execute the assigned `PHASE_X.md` exactly as written. Do not implement any future phases.

---

## References
- `README.md`
- `AGENTS.md`
- `RULES.md`
- `CONTRIBUTING.md`
- `ARCHITECTURE.md`
- `docs/GOVERNANCE.md`
- `ROADMAP_V1.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `PHASE_0.md` ... `PHASE_10.md`
