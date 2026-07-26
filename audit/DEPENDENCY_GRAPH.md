# DEPENDENCY_GRAPH.md
> Canonical dependency graph derived from `ROADMAP_V1.md`.
> This graph defines required predecessor phases, blockers, and execution relationships.

---

## 1. High-Level Dependency Graph

```text
Phase 0 — Foundation
   |
   v
Phase 1 — Core mikrotik_sdk
   |
   v
Phase 2 — Router Management
   |
   +-----------------------> Phase 3 — Dashboard
   |
   +-----------------------> Phase 4 — Hotspot
   |
   +-----------------------> Phase 7 — PPP + Queue
                              
Phase 4 — Hotspot
   |
   +-----------------------> Phase 5 — Voucher Engine
   |
   +-----------------------> Phase 6 — OnLoginScriptGenerator

Phase 1 + Phase 2 + Phase 4 + Phase 5 + Phase 6 + Phase 7
   |
   v
Phase 8 — Security Hardening
   |
   +-----------------------> Phase 9 — Premium Features (Optional, parallel/deferred)
   |
   v
Phase 10 — Beta Release
```

---

## 2. Detailed Dependency Graph

```text
Phase 0 — Foundation
  Requires: None
  Blocks: Phase 1, indirectly all later phases

Phase 1 — Core mikrotik_sdk
  Requires: Phase 0
  Blocks: Phase 2, Phase 3, Phase 4, Phase 5, Phase 6, Phase 7

Phase 2 — Router Management
  Requires: Phase 0, Phase 1
  Blocks: Phase 3, Phase 4, Phase 7
  Supports: Phase 5 indirectly via user/profile foundations

Phase 3 — Dashboard
  Requires: Phase 1, Phase 2
  Recommended before: Phase 4 user-facing validation work
  Does not block: Phase 4 strictly

Phase 4 — Hotspot
  Requires: Phase 1, Phase 2
  Recommended input: Phase 3
  Blocks: Phase 5, Phase 6

Phase 5 — Voucher Engine
  Requires: Phase 1, Phase 2, Phase 4
  Blocks: Phase 8 release completeness for MVP/v1.0 voucher scope

Phase 6 — OnLoginScriptGenerator
  Requires: Phase 1, Phase 4, Phase 0 test infrastructure
  Blocks: Safe profile parity, release confidence, Phase 8, Phase 10

Phase 7 — PPP + Queue
  Requires: Phase 1, Phase 2
  Does not block: MVP if explicitly deferred by scope pressure
  Included in: v1.0 scope

Phase 8 — Security Hardening
  Requires: Core functional phases substantially complete
  Strongest practical inputs: Phase 1, Phase 2, Phase 4, Phase 5, Phase 6, and Phase 7 if in v1.0 scope
  Blocks: Phase 10
  Supports: Phase 9

Phase 9 — Premium Features (Optional)
  Requires: MVP core stable, Phase 8 security baseline complete
  Parallel/deferred in realistic plan
  Does not block: MVP or v1.0 by default

Phase 10 — Beta Release
  Requires: MVP phases complete, Phase 8 complete, test suite healthy, real users and router test pool available
  Final release gate before general availability
```

---

## 3. Phase-by-Phase Requires / Blocked By Matrix

| Phase | Requires | Blocked By | Blocks |
|---|---|---|---|
| Phase 0 | None | None | All later phases indirectly |
| Phase 1 | Phase 0 | Missing foundation, missing test environment | Phase 2, 3, 4, 5, 6, 7 |
| Phase 2 | Phase 0, Phase 1 | Unstable SDK, missing secure storage baseline | Phase 3, 4, 7 |
| Phase 3 | Phase 1, Phase 2 | Missing monitoring coverage, no active router context | None strictly |
| Phase 4 | Phase 1, Phase 2 | Missing hotspot abstractions, unstable router selection | Phase 5, Phase 6 |
| Phase 5 | Phase 1, Phase 2, Phase 4 | Missing user/profile flows, missing Quick Print compatibility | Phase 8 indirectly |
| Phase 6 | Phase 1, Phase 4, Phase 0 test infrastructure | Missing real fixtures, unresolved profile model understanding | Phase 8, Phase 10 |
| Phase 7 | Phase 1, Phase 2 | Missing PPP/Queue abstractions | None for MVP; relevant to v1.0 |
| Phase 8 | Core phases substantially complete | Incomplete functionality, unresolved security controls | Phase 10 |
| Phase 9 | MVP stable, Phase 8 complete | Unstable core product, unresolved security baseline | None by default |
| Phase 10 | MVP complete, Phase 8 complete | Missing beta readiness, missing router/user test pool | General release readiness |

---

## 4. Critical Path Graph

```text
Phase 0
  -> Phase 1
      -> Phase 2
          -> Phase 4
              -> Phase 6
                  -> Phase 8
                      -> Phase 10
```

This is the mandatory release path.

Any slip on this chain moves the MVP and v1.0 delivery target.

---

## 5. Parallelization Windows

### Window A
After Phase 2 stabilizes:
- Phase 3 can run
- Phase 4 can run
- Phase 7 can begin scoping or implementation

### Window B
After Phase 4 stabilizes:
- Phase 5 can run
- Phase 6 can run

### Window C
During late feature development:
- Phase 8 security preparation can be staged
- Phase 10 beta planning can begin during late Phase 8
- Phase 9 can remain deferred or parallelized after security baseline

---

## 6. External Dependencies

The following are not phases, but they can block execution:

### RouterOS Test Environment
Blocks:
- Phase 1 completion
- Phase 6 validation
- Phase 10 beta confidence

### Android Test Devices
Blocks:
- Phase 3 validation quality
- Phase 5 print validation
- Phase 10 device coverage

### Printer Hardware / Compatibility Access
Blocks:
- Phase 5 full validation
- Phase 10 print-path confidence

### Real Legacy Script Fixtures
Blocks:
- Phase 6 confidence
- Phase 5 Quick Print compatibility confidence

### Structured Beta User Pool
Blocks:
- Phase 10 exit quality

---

## 7. Blocker Escalation Rules

If any of the following occurs, phase execution must stop and escalate:
1. A required predecessor phase has not met its acceptance criteria
2. A required real-router validation asset is unavailable for router-facing closure
3. A future phase depends on assumptions not documented in `ROADMAP_V1.md`
4. Security controls required by Phase 8 are being bypassed to preserve schedule
5. A phase attempts to absorb scope from a later phase

---

## 8. Final Dependency Guidance

For all future AI coding agents:
- Do not start a phase unless its required predecessors are complete
- Do not treat “recommended” dependencies as “optional” when they affect quality or risk validation
- Do not collapse phases together unless explicitly approved by the human owner
- Do not implement optional premium scope inside MVP-critical phases
- Do not bypass the critical path to accelerate delivery at the expense of risk control
