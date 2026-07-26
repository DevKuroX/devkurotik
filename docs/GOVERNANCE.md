# GOVERNANCE.md
> Repository-level execution rules for DevKuroTik.
> This document defines mandatory guardrails for all human contributors and AI coding agents.

---

## 1. Purpose

DevKuroTik is being built using **spec-driven development**.

The execution chain is:

```text
AUDIT
  ↓
ROADMAP_V1
  ↓
MASTER_IMPLEMENTATION_PLAN
  ↓
DEPENDENCY_GRAPH
  ↓
EXECUTION_ORDER
  ↓
PHASE_0
PHASE_1
...
PHASE_10
```

These documents are not optional guidance. They are the implementation control system for the project.

---

## 2. Source of Truth Hierarchy

The source of truth hierarchy is:

1. `ROADMAP_V1.md`
2. `MASTER_IMPLEMENTATION_PLAN.md`
3. `DEPENDENCY_GRAPH.md`
4. `EXECUTION_ORDER.md`
5. `PHASE_0.md` … `PHASE_10.md`

### Interpretation Rule

> **If it is not in the assigned phase document, it does not exist for that phase.**

AI agents and human contributors must not infer extra scope, invent missing requirements, or redesign the architecture during implementation.

---

## 3. Canonical Roles of Documents

### `MASTER_IMPLEMENTATION_PLAN.md`
Acts as the:
- CEO / CTO document
- milestone and program control document
- critical path and risk reference

### `DEPENDENCY_GRAPH.md`
Acts as the:
- technical dependency contract
- blocker map
- predecessor / successor control document

### `EXECUTION_ORDER.md`
Acts as the:
- PM execution guide
- ordering and checkpoint reference
- sequencing control document

### `PHASE_0.md` … `PHASE_10.md`
Act as the:
- canonical implementation specifications
- phase-scoped contracts for execution
- Definition of Done and testing authority for each phase

---

## 4. Mandatory Rules for AI Agents

All AI coding agents working in this repository must follow these rules without exception.

### Rule 1 — AI agents MAY NOT modify architecture
- No architecture changes are allowed unless explicitly approved by the human owner and reflected in the canonical documents.
- Do not replace the approved monorepo/package structure.
- Do not substitute state management, storage, routing, or SDK boundaries.

### Rule 2 — AI agents MAY NOT introduce dependencies
- Do not add packages, libraries, frameworks, or services unless they are already approved by the roadmap and phase documentation.
- Do not replace approved technologies with alternatives.
- Example: do not introduce Bloc when the project specifies Riverpod.

### Rule 3 — AI agents MAY NOT implement future phases
- Only implement the assigned phase.
- Do not “prepare” future features by partially building them early.
- Do not bundle Phase 1, Phase 2, and Phase 3 work into one implementation pass.

### Rule 4 — AI agents MUST satisfy Definition of Done
- Every assigned phase must meet all deliverables, acceptance criteria, testing requirements, and Definition of Done before being considered complete.
- “Mostly done” is not done.

### Rule 5 — AI agents MUST update documentation
- If implementation changes any repository, setup, testing, or phase-specific documentation that is within the assigned scope, it must be updated.
- Documentation drift is considered a defect.

### Rule 6 — AI agents MUST pass tests
- Required tests for the assigned phase are mandatory.
- Do not skip tests to save time.
- Do not mark work complete while tests are failing.

### Rule 7 — Phase documents are the source of truth
- The assigned `PHASE_X.md` file defines the implementation boundary.
- If a requirement is outside the assigned phase document, do not implement it.
- If a conflict appears, escalate to the human owner instead of improvising.

---

## 5. Mandatory Rules for Human Review

Human review must enforce the same discipline.

Reviewers must reject changes that:
- modify architecture without approval
- introduce unapproved dependencies
- implement future-phase scope
- fail Definition of Done
- skip required tests
- leave documentation outdated
- contradict canonical phase specifications

---

## 6. Phase Execution Policy

The repository follows **phase-by-phase execution**, not bulk implementation.

### Required execution pattern

```text
Phase X
  ↓
Implement
  ↓
Test
  ↓
Review
  ↓
Tag
  ↓
Next Phase
```

### Prohibited execution pattern

```text
Phase 0
Phase 1
Phase 2
Phase 3
commit once later
```

### Reason
If an earlier foundational decision is wrong, later phases must not already depend on it.
This is especially critical for:
- Phase 0 foundations
- Phase 1 `mikrotik_sdk`
- Phase 6 `OnLoginScriptGenerator`

---

## 7. Tagging Policy

Recommended checkpoint tags:

| Phase | Suggested Tag |
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

This tagging scheme is used to preserve auditability and rollback safety across phase execution.

---

## 8. Special Rule for Phase 0

Phase 0 must never be skipped.

No AI agent may jump directly to dashboard, hotspot, voucher, or premium features before:
- repository foundations exist
- tooling baseline exists
- documentation baseline exists
- CI exists
- architecture guardrails are in place

---

## 9. Special Rule for Phase 6

`PHASE_6.md` is the highest-risk implementation document in the entire project.

### Phase 6 mandatory controls
- Regression suite is mandatory.
- No merge without review.
- Coverage requirement must follow the canonical phase document.
- Real-router validation is mandatory.
- No architecture or behavior improvisation is allowed.

### Reason
Failure in this phase can cause:
- incorrect voucher expiry behavior
- incorrect user session behavior
- broken feature parity with Mikhmon
- silent business-logic corruption

---

## 10. Escalation Policy

AI agents must stop and escalate to the human owner when:
1. a requested change contradicts the assigned phase document
2. a dependency is missing or unavailable
3. a later-phase requirement appears necessary to finish the current phase
4. tests required by the phase cannot be completed
5. the implementation would require architecture or dependency changes

When escalation is required, do not improvise.

---

## 11. Completion Rule

A phase is complete only when all of the following are true:
- deliverables are finished
- acceptance criteria are satisfied
- Definition of Done is satisfied
- required tests pass
- required documentation is updated
- no prohibited scope from future phases was implemented

---

## 12. Final Instruction

All contributors must treat DevKuroTik as a **spec-governed rewrite**.

AI agents are engineers executing a contract.
They are **not** product managers, architects, or scope owners.

If there is uncertainty:
- follow the assigned phase document
- follow repository governance
- escalate rather than invent
