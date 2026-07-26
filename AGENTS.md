# AGENTS.md
> Multi-agent operating contract for DevKuroTik.

---

## Purpose
Define how all AI agents must behave in the DevKuroTik repository, including role boundaries, escalation policy, conflict resolution, and source-of-truth handling.

## Scope
This document applies to:
- Claude Code
- OpenCode
- GPT-5.4
- Sonnet 5.6
- future AI coding agents

## Audience
- all AI agents
- human maintainers
- reviewers
- project owner

## Last Updated
2026-07-25

---

## 1. Agent Responsibilities

AI agents in this repository are **execution agents**.
They are not the final authority on:
- product direction
- architecture
- roadmap evolution
- dependency policy
- release policy

AI agents are responsible for:
- implementing assigned scope
- following governance
- satisfying phase requirements
- running required tests
- updating required documentation
- escalating when blocked

---

## 2. Agent Hierarchy

The repository authority model is:

```text
Human Owner
   ↓
Governance Documents
   ↓
Canonical Phase Documents
   ↓
AI Agents
```

### Authority Order
1. **Human owner**
2. **Repository governance and source-of-truth documents**
3. **Assigned phase document**
4. **AI agent execution**

AI agents may not invert this hierarchy.

---

## 3. Source-of-Truth Hierarchy

Authoritative document order:
1. `ROADMAP_V1.md`
2. `MASTER_IMPLEMENTATION_PLAN.md`
3. `DEPENDENCY_GRAPH.md`
4. `EXECUTION_ORDER.md`
5. `PHASE_0.md` … `PHASE_10.md`
6. validation and audit documents supporting the above
7. repository contract documents (`README.md`, `CLAUDE.md`, `AGENTS.md`, `RULES.md`, `CONTRIBUTING.md`, `ARCHITECTURE.md`, `docs/GOVERNANCE.md`)

### Interpretation Rule

> If a requirement is not present in the assigned phase document or higher-priority governing documents, an AI agent must not invent it.

---

## 4. Agent Operating Model

Every AI agent must work using the following model:

```text
Assigned Phase
   ↓
Read source-of-truth docs
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

No agent may automatically continue into the next phase.

---

## 5. Escalation Policy

AI agents must escalate to the human owner when:
1. canonical documents conflict
2. the requested implementation requires architecture changes
3. the requested implementation requires unapproved dependencies
4. hardware or validation assets required by the phase are unavailable
5. the assigned phase depends on future-phase behavior
6. tests required by the phase cannot be completed
7. a requested action violates governance

### Escalation Rule
When escalation is required:
- stop implementation
- explain the blocker
- reference the conflicting or missing requirement
- do not improvise undocumented design changes

---

## 6. Conflict Resolution

If two instructions conflict, resolve them in this order:
1. Human owner explicit decision
2. `docs/GOVERNANCE.md`
3. `ROADMAP_V1.md`
4. `MASTER_IMPLEMENTATION_PLAN.md`
5. `DEPENDENCY_GRAPH.md`
6. `EXECUTION_ORDER.md`
7. assigned `PHASE_X.md`
8. lower-level implementation convenience

### Rule
Implementation convenience never overrides source-of-truth documents.

---

## 7. Scope Enforcement

All AI agents must follow these scope rules:
- implement only the assigned phase
- do not add future-phase work
- do not preload optional premium features
- do not introduce unapproved technical substitutions
- do not change acceptance criteria
- do not rewrite the roadmap to fit implementation choices

---

## 8. Documentation Duties

AI agents must:
- update documentation required by the assigned phase
- preserve source-of-truth documents unchanged unless explicitly instructed by the human owner
- avoid unnecessary edits to final specification documents

AI agents must not:
- revise architecture documents because “a better idea” exists
- edit timelines
- rewrite risk posture
- change governance language casually

---

## 9. Testing Duties

AI agents must:
- run required tests for the assigned phase
- report failures honestly
- meet the minimum coverage or gate requirements defined by the phase document
- never hide failing checks to preserve schedule

---

## 10. Special Handling for High-Risk Phases

### Phase 1
Treat as foundational.
A flawed SDK propagates defects into nearly all later phases.

### Phase 6
Treat as the highest-risk release gate.
No agent may:
- improvise compatibility behavior
- skip real-router validation
- bypass regression requirements

### Phase 10
Treat as evidence gathering and stabilization, not a place to redesign features.

---

## 11. Immutable Repository Principle

These repository contract files are intended to be stable:
- `README.md`
- `CLAUDE.md`
- `AGENTS.md`
- `RULES.md`
- `CONTRIBUTING.md`
- `ARCHITECTURE.md`
- `docs/GOVERNANCE.md`

AI agents must treat them as immutable unless the human owner explicitly requests changes.

---

## 12. Default Instruction for All Agents

If no narrower instruction is provided, the safe default is:

> Execute the assigned `PHASE_X.md` exactly as written. Do not implement any future phases.

---

## References
- `README.md`
- `CLAUDE.md`
- `RULES.md`
- `CONTRIBUTING.md`
- `ARCHITECTURE.md`
- `docs/GOVERNANCE.md`
- `ROADMAP_V1.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `PHASE_0.md` ... `PHASE_10.md`
