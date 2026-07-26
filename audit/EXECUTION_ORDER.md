# EXECUTION_ORDER.md
> Canonical execution order derived from `ROADMAP_V1.md`.
> This document defines the recommended sequence, mandatory sequence, parallelizable phases, high-risk phases, longest phases, and checkpoints.

---

## 1. Recommended Order

The recommended implementation order from `ROADMAP_V1.md` is:

1. **Phase 0 — Foundation**
2. **Phase 1 — Core `mikrotik_sdk`**
3. **Phase 2 — Router Management**
4. **Phase 3 — Dashboard**
5. **Phase 4 — Hotspot**
6. **Phase 6 — `OnLoginScriptGenerator`**
7. **Phase 5 — Voucher Engine**
8. **Phase 7 — PPP + Queue**
9. **Phase 8 — Security Hardening**
10. **Phase 10 — Beta Release**
11. **Phase 9 — Premium Features (Optional / parallel / deferred)**

### Rationale
- Foundation must exist before implementation starts
- `mikrotik_sdk` unlocks all RouterOS work
- Router management is required before meaningful app workflows
- Dashboard provides early validation of live connectivity and monitoring
- Hotspot is the core business feature set
- `OnLoginScriptGenerator` must be solved before profile-dependent parity is considered safe
- Voucher engine depends on hotspot and profile logic
- Security hardening must happen before beta
- Premium features must not interfere with MVP or v1.0 execution

---

## 2. Mandatory Order

The mandatory order is the minimum execution chain that cannot be broken without violating roadmap dependencies.

### Mandatory Sequence
1. **Phase 0**
2. **Phase 1**
3. **Phase 2**
4. **Phase 4**
5. **Phase 6**
6. **Phase 8**
7. **Phase 10**

### Mandatory Dependency Notes
- Phase 1 cannot start without Phase 0
- Phase 2 cannot close without Phase 1
- Phase 4 cannot close without Phases 1 and 2
- Phase 6 cannot close without Phases 1 and 4 plus real fixtures and test infrastructure
- Phase 8 cannot close until core functionality is substantially complete
- Phase 10 cannot start as a release candidate phase until Phase 8 is complete

---

## 3. Parallelizable Phases

Parallelization is limited and must not change scope boundaries.

### Approved Partial Parallelization
- **Phase 3** may proceed after Phase 1 and Phase 2 stabilize
- **Phase 7** may begin after Phase 1 and Phase 2 stabilize
- **Phase 5** and **Phase 6** may proceed in parallel after Phase 4, but Phase 6 should be treated as higher risk and higher priority
- **Phase 8 preparation work** may begin during late feature development, but Phase 8 cannot be declared complete early
- **Phase 10 planning** may begin during late Phase 8
- **Phase 9** is explicitly parallel/deferred in the realistic plan

### Parallelization Restrictions
Do not parallelize:
- Phase 1 protocol/auth core
- Phase 6 validation and regression sign-off
- Phase 8 release gating
- Phase 10 beta stabilization and go/no-go decisions

---

## 4. High-Risk Phases

### Highest-Risk Phase
1. **Phase 6 — `OnLoginScriptGenerator`**
   - highest-risk module in the entire project
   - risk of silent business logic corruption
   - requires fixture-driven validation and real-router confirmation

### Additional High-Risk Phases
2. **Phase 1 — Core `mikrotik_sdk`**
   - protocol/auth compatibility risks
   - transport and error semantics affect all later phases
3. **Phase 5 — Voucher Engine**
   - printing fragmentation
   - Quick Print compatibility
4. **Phase 8 — Security Hardening**
   - release-blocking security gates
   - risk of hidden credential exposure or unsafe fallbacks
5. **Phase 10 — Beta Release**
   - external user/device/printer variability
   - feedback and defect triage pressure

---

## 5. Longest Phases

Using roadmap duration ranges, the longest phases are:

### By Realistic Duration
1. **Phase 4 — Hotspot**: 4 weeks
2. **Phase 1 — Core `mikrotik_sdk`**: 3 weeks
3. **Phase 5 — Voucher Engine**: 3 weeks
4. **Phase 6 — `OnLoginScriptGenerator`**: 3 weeks
5. **Phase 10 — Beta Release**: 3 weeks
6. **Phase 9 — Premium Features**: 3 weeks if undertaken

### By Pessimistic Duration
1. **Phase 4 — Hotspot**: 6 weeks
2. **Phase 5 — Voucher Engine**: 5 weeks
3. **Phase 6 — `OnLoginScriptGenerator`**: 5 weeks
4. **Phase 1 — Core `mikrotik_sdk`**: 5 weeks
5. **Phase 7 — PPP + Queue**: 4 weeks
6. **Phase 10 — Beta Release**: 4 weeks

### Planning Implication
The program schedule is especially sensitive to slips in:
- Phase 1
- Phase 4
- Phase 6
- Phase 10

---

## 6. Suggested Checkpoints

### Checkpoint 1 — Foundation Gate
**After Phase 0**
Validate:
- monorepo structure
- tooling baseline
- CI enforcement
- ADR and documentation baseline
- no open architecture ambiguities

### Checkpoint 2 — Connectivity Gate
**After Phase 1**
Validate:
- RouterOS connection reliability
- command execution
- retry and timeout behavior
- error taxonomy stability
- integration testing against a test router

### Checkpoint 3 — Secure Router Operations Gate
**After Phase 2**
Validate:
- add/edit/delete router flows
- secure credential handling
- multi-router switching
- health checks and failure states

### Checkpoint 4 — Monitoring Usability Gate
**After Phase 3**
Validate:
- dashboard responsiveness
- stable traffic/resource display
- clear live vs cached data states

### Checkpoint 5 — Core Business Workflow Gate
**After Phase 4**
Validate:
- hotspot core operations usable from mobile
- destructive actions controlled and auditable
- user/session/profile interactions stable enough for downstream work

### Checkpoint 6 — Revenue Workflow Gate
**After Phase 5**
Validate:
- bulk user generation
- voucher rendering
- print/share fallback paths
- Quick Print compatibility in approved scope

### Checkpoint 7 — High-Risk Compatibility Gate
**After Phase 6**
Validate:
- all 5 expiry modes covered
- generator regression suite complete
- parser compatibility verified
- real-router validation complete

### Checkpoint 8 — Security Release Gate
**After Phase 8**
Validate:
- credential protections enforced
- validation rules complete
- logs and telemetry scrubbed
- release security checklist passed

### Checkpoint 9 — Beta Readiness Gate
**Before starting Phase 10 execution**
Validate:
- MVP implementation complete
- unresolved P0/P1 blockers addressed or explicitly deferred
- real test users and devices available

### Checkpoint 10 — Beta Exit Gate
**After Phase 10**
Validate:
- beta feedback triaged
- blockers resolved or dispositioned
- v1.0 scope confirmed by evidence

---

## 7. Recommended Operating Sequence by Program Stage

### Stage A — Foundation and Core Infrastructure
- Phase 0
- Phase 1
- Phase 2

### Stage B — Core User Value
- Phase 3
- Phase 4
- Phase 6
- Phase 5

### Stage C — Expanded Functional Surface
- Phase 7
- Phase 8

### Stage D — Validation and Optional Expansion
- Phase 10
- Phase 9

---

## 8. Execution Rules for Future AI Agents

For all future implementation agents:
- Use this execution order unless a human explicitly instructs otherwise
- Respect mandatory order even if a later phase appears easy to start early
- Do not treat optional phases as blockers for MVP
- Do not move premium scope into core delivery phases
- Do not sacrifice testing or security gates to preserve timeline targets
- Do not infer architecture changes from local implementation convenience

---

## 9. Final Recommendation

For the solo developer + AI-assisted operating model, the safest and most effective execution sequence is:

**Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 6 → Phase 5 → Phase 7 → Phase 8 → Phase 10 → Phase 9**

This preserves the roadmap’s architecture, respects the critical path, addresses the highest-risk compatibility work before release, and prevents optional premium work from destabilizing the core product.
