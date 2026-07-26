# RULES.md
> Hard rules for DevKuroTik repository execution.

---

## Purpose
Define non-negotiable repository rules for human contributors and AI agents.

## Scope
This document covers:
- forbidden actions
- mandatory controls
- enforcement severity
- implementation boundaries

## Audience
- human contributors
- reviewers
- maintainers
- AI agents

## Last Updated
2026-07-25

---

## 1. Severity Levels

### INFO
Guidance that improves quality but does not block work by itself.

### WARNING
A rule that should not be violated. Repeated or deliberate violation increases risk and may block review.

### CRITICAL
A serious violation that threatens correctness, security, or specification integrity.

### BLOCKER
A violation that prevents merge, release, or phase completion.

---

## 2. Hard Rules

### Rule 1 — No architecture changes
**Severity:** BLOCKER

Do not change:
- monorepo structure
- SDK boundaries
- Flutter as primary UI framework
- Riverpod as state management
- Drift as local database
- `go_router` as routing layer

Unless the project owner explicitly changes the source-of-truth documents, architecture is fixed.

---

### Rule 2 — No future phase implementation
**Severity:** BLOCKER

Do not implement work from a later phase while executing the current phase.

Examples:
- do not add dashboard behavior during Phase 2
- do not add voucher behavior during Phase 4
- do not add premium features during MVP phases

---

### Rule 3 — No undocumented dependencies
**Severity:** BLOCKER

Do not add libraries, frameworks, packages, or services unless they are already approved by canonical documents.

Examples:
- no Bloc when Riverpod is specified
- no alternative local database
- no alternative routing stack

---

### Rule 4 — No skipping tests
**Severity:** BLOCKER

All tests required by the assigned phase must run and pass.
Coverage and gate requirements in the phase document are mandatory.

---

### Rule 5 — No merging failing code
**Severity:** BLOCKER

Do not merge or recommend merge when:
- tests fail
- required validation is incomplete
- Definition of Done is not satisfied
- acceptance criteria are not met

---

### Rule 6 — No modifying source-of-truth documents casually
**Severity:** CRITICAL

Do not edit:
- roadmap
- master plan
- dependency graph
- execution order
- phase documents
- governance documents

unless explicitly instructed by the project owner.

---

### Rule 7 — No speculative implementation
**Severity:** CRITICAL

Do not implement guessed requirements, invented scope, or convenience-driven abstractions that are not present in the assigned phase.

---

### Rule 8 — No security downgrade for speed
**Severity:** BLOCKER

Do not weaken:
- validation
- redaction
- secure storage
- destructive-action protections
- regression requirements

to preserve schedule.

---

### Rule 9 — No hidden blocker bypass
**Severity:** CRITICAL

If the assigned phase requires:
- real router validation
- printer validation
- beta user/device coverage
- missing fixtures

then escalate. Do not fake completion.

---

### Rule 10 — No undocumented phase completion
**Severity:** BLOCKER

A phase is not complete unless:
- deliverables are finished
- acceptance criteria are satisfied
- Definition of Done is satisfied
- tests pass
- required docs are updated

---

## 3. Mandatory Execution Rules

### Rule 11 — Execute only assigned phase
**Severity:** BLOCKER

The assigned `PHASE_X.md` is the implementation contract.
If it is not in that phase, do not implement it.

---

### Rule 12 — Update required documentation
**Severity:** CRITICAL

If the phase requires documentation updates, they must be performed before claiming completion.

---

### Rule 13 — Respect dependency order
**Severity:** BLOCKER

Do not start a phase before its required predecessor phases are complete.
Use `DEPENDENCY_GRAPH.md` and `EXECUTION_ORDER.md`.

---

### Rule 14 — Escalate instead of improvising
**Severity:** CRITICAL

If implementation requires architecture change, new dependency, or undocumented scope, stop and escalate.

---

## 4. Special Rules

### Rule 15 — Phase 0 may not be skipped
**Severity:** BLOCKER

No feature work may begin before Phase 0 foundations are established.

---

### Rule 16 — Phase 6 is a hard release gate
**Severity:** BLOCKER

No merge to main, no release, and no beta should proceed past the required Phase 6 controls unless the canonical phase requirements are satisfied.

---

### Rule 17 — Premium scope must remain optional
**Severity:** WARNING

Phase 9 features must not contaminate MVP-critical execution.
If optional scope begins to affect core delivery, escalate immediately.

---

## 5. Enforcement Guidance

When a rule is violated:
- INFO → document and correct
- WARNING → review and correct before continuing
- CRITICAL → stop, escalate, and correct
- BLOCKER → no merge, no release, no completion claim

---

## 6. Final Rule

If there is uncertainty, follow this order:
1. project owner instruction
2. `docs/GOVERNANCE.md`
3. source-of-truth implementation documents
4. assigned `PHASE_X.md`
5. repository contract docs
6. implementation convenience last

---

## References
- `README.md`
- `CLAUDE.md`
- `AGENTS.md`
- `CONTRIBUTING.md`
- `ARCHITECTURE.md`
- `docs/GOVERNANCE.md`
- `ROADMAP_V1.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `PHASE_0.md` ... `PHASE_10.md`
