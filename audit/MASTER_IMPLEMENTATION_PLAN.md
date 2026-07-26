# MASTER_IMPLEMENTATION_PLAN.md
> Canonical implementation control document derived from `ROADMAP_V1.md`.
> This document does not change architecture, scope, technologies, or timelines.

---

## 1. Purpose

This document translates `ROADMAP_V1.md` into a program-level execution plan for DevKuroTik. It is intended for a solo developer working with AI coding agents. It defines milestones, timeline, critical path, parallelization boundaries, risk concentration areas, MVP scope, and v1.0 scope.

DevKuroTik remains:
- a complete rewrite of Mikhmon
- mobile-first
- Flutter-based
- Android-first, iOS-ready
- offline-first
- multi-router capable
- security-focused

All implementation work must remain aligned with:
- `ROADMAP_V1.md`
- `SDK_DESIGN.md`
- `FEATURE_MATRIX.md`
- `MIGRATION_BLUEPRINT.md`
- `SECURITY_REPORT.md`
- `FINAL_RECOMMENDATION.md`

---

## 2. Program Assumptions

### Delivery Model
- Solo developer
- Heavy AI assistance
- 20–30 hours per week
- Real MikroTik test environment required before SDK completion and beta sign-off

### Approved Technology Baseline
- Flutter 3.x
- Dart version bundled with pinned Flutter release
- Riverpod 2.x
- Drift + SQLite
- go_router
- flutter_secure_storage
- fl_chart
- pdf + printing
- qr_flutter
- flutter_local_notifications
- local_auth

### Program Constraints
- No architecture redesign outside `ROADMAP_V1.md`
- No technology substitutions
- No new feature additions beyond roadmap scope
- Security requirements are mandatory
- Phase timelines must be preserved exactly as defined in roadmap

---

## 3. Complete Timeline

### Optimistic Timeline — 18 Weeks
| Phase | Duration |
|---|---|
| Phase 0 | 1 week |
| Phase 1 | 2 weeks |
| Phase 2 | 1.5 weeks |
| Phase 3 | 1.5 weeks |
| Phase 4 | 3 weeks |
| Phase 5 | 2.5 weeks |
| Phase 6 | 2 weeks |
| Phase 7 | 1.5 weeks |
| Phase 8 | 1.5 weeks |
| Phase 10 | 1.5 weeks |
| **Total** | **18 weeks** |

### Realistic Timeline — 24 Weeks
| Phase | Duration |
|---|---|
| Phase 0 | 2 weeks |
| Phase 1 | 3 weeks |
| Phase 2 | 2 weeks |
| Phase 3 | 2 weeks |
| Phase 4 | 4 weeks |
| Phase 5 | 3 weeks |
| Phase 6 | 3 weeks |
| Phase 7 | 2 weeks |
| Phase 8 | 2 weeks |
| Phase 10 | 3 weeks |
| Phase 9 | parallel / deferred |
| **Total** | **24 weeks** |

### Pessimistic Timeline — 32 Weeks
| Phase | Duration |
|---|---|
| Phase 0 | 3 weeks |
| Phase 1 | 5 weeks |
| Phase 2 | 3 weeks |
| Phase 3 | 3 weeks |
| Phase 4 | 6 weeks |
| Phase 5 | 5 weeks |
| Phase 6 | 5 weeks |
| Phase 7 | 4 weeks |
| Phase 8 | 3 weeks |
| Phase 10 | 3 weeks |
| **Total** | **32 weeks** |

### Planning Baseline
Use the **24-week realistic timeline** as the operational planning baseline.

---

## 4. Milestones

### Milestone M0 — Foundation Complete
**Exit Condition:** Phase 0 complete
- Monorepo established
- CI active
- engineering standards documented
- repository structure frozen
- no open architecture blockers for implementation

### Milestone M1 — Core Connectivity Complete
**Exit Condition:** Phase 1 complete
- `mikrotik_sdk` usable by downstream phases
- RouterOS auth, command execution, retries, and errors stabilized
- integration tests passing against at least one test router environment

### Milestone M2 — Device and Router Management Ready
**Exit Condition:** Phase 2 complete
- multi-router support working
- secure credential storage in place
- router add/edit/delete/test flow production-usable

### Milestone M3 — Monitoring Experience Ready
**Exit Condition:** Phase 3 complete
- dashboard operational
- resource and traffic monitoring stable
- cache/live-state distinction implemented

### Milestone M4 — Core Hotspot Operations Ready
**Exit Condition:** Phase 4 complete
- critical hotspot operations working from mobile
- user CRUD, session handling, and expiry display operational

### Milestone M5 — Voucher Operations Ready
**Exit Condition:** Phase 5 complete
- bulk generation operational
- voucher printing/sharing operational
- Quick Print compatibility operational in approved scope

### Milestone M6 — High-Risk Profile Logic Validated
**Exit Condition:** Phase 6 complete
- `OnLoginScriptGenerator` validated
- parser/generator regression suite green
- real-router validation completed

### Milestone M7 — Expanded Router Operations Ready
**Exit Condition:** Phase 7 complete
- PPP/Queue features in scope operational
- audited non-hotspot parity expanded safely

### Milestone M8 — Security Release Gate Ready
**Exit Condition:** Phase 8 complete
- security checklist complete
- validation and redaction controls enforced
- beta build security-ready

### Milestone M9 — Optional Premium Scope Defined
**Exit Condition:** Phase 9 complete or explicitly deferred
- premium work safely isolated
- feature flags and architectural boundaries documented

### Milestone M10 — Closed Beta Complete
**Exit Condition:** Phase 10 complete
- closed beta executed
- feedback triaged
- go/no-go decision supported by evidence

---

## 5. Critical Path

### Critical Path Sequence
**Phase 0 → Phase 1 → Phase 2 → Phase 4 → Phase 6 → Phase 8 → Phase 10**

### Why These Phases Are Critical
- **Phase 0** establishes engineering discipline and repo standards
- **Phase 1** unlocks all router-facing work
- **Phase 2** establishes operational router management and secure storage
- **Phase 4** delivers the core business workflow
- **Phase 6** validates the highest-risk compatibility module
- **Phase 8** gates release readiness from a security perspective
- **Phase 10** validates product readiness with real users and environments

### Critical Path Risk Notes
- Any delay in `mikrotik_sdk` affects all feature phases
- Any delay in `OnLoginScriptGenerator` delays safe hotspot profile parity and voucher confidence
- Security hardening cannot be deferred past beta

---

## 6. Parallel Work Opportunities

Parallel work is allowed only where `ROADMAP_V1.md` explicitly permits or logically supports overlap without architectural redesign.

### Approved Partial Parallelization
1. **Phase 3 dashboard UI work** may begin after Phase 1 and Phase 2 interfaces stabilize
2. **Report parser design and compatibility planning** may occur while Phase 4 hotspot UI is under implementation
3. **PPP/Queue scoping** may occur while Phase 5 voucher engine is underway
4. **Security checklist authoring and review preparation** may occur during feature implementation before Phase 8 formal closure
5. **Beta planning** may begin during late Phase 8
6. **Phase 9** is explicitly parallel/deferred relative to the realistic plan

### Work That Must Not Be Parallelized Aggressively
- Phase 1 protocol/auth core
- Phase 6 parser/generator validation
- Phase 8 security release gating
- Phase 10 beta triage and stabilization decisions

---

## 7. Risk Matrix

| Risk Area | Severity | Primary Phase(s) | Mitigation |
|---|---|---|---|
| `OnLoginScriptGenerator` correctness | Critical | 6 | Golden fixtures, regression suite, real-router validation |
| RouterOS protocol/auth variance | High | 1 | Integration testing, explicit compatibility matrix |
| Legacy `/system/script` compatibility | High | 5, 6 | Parser fixtures, canonical serialization tests |
| Quick Print compatibility | High | 5 | Defensive parsing, compatibility validation |
| Bluetooth thermal print fragmentation | High | 5, 10 | Fallback matrix, tested device/printer combinations |
| Credential exposure in logs or storage | Critical | 1, 2, 8 | Redaction policy, secure storage, checklist enforcement |
| Hotspot cascade-delete/reset defects | High | 4 | Integration tests and destructive action confirmations |
| Solo developer bottleneck | High | All | Strict scope control, phase isolation, AI-assisted test generation |
| Beta feedback overload | Medium | 10 | Structured triage, beta exit criteria, severity-based prioritization |
| Premium feature scope creep | Medium | 9 | Feature flags, explicit non-goals, defer-by-default |

---

## 8. MVP Definition

MVP scope is exactly as defined by `ROADMAP_V1.md`.

### MVP Includes
- Phase 0
- Phase 1
- Phase 2
- Phase 3
- Phase 4 core hotspot features
- Phase 5 core voucher generation and PDF/share
- Phase 6
- Phase 8 minimum hardening
- Phase 10 closed beta readiness

### MVP Excludes
- premium cloud features
- nonessential network tools
- broad PPP/Queue expansion if the schedule tightens
- advanced widget/notification ecosystems

### MVP Exit Condition
MVP is considered achieved when:
- the core router management, dashboard, hotspot, and voucher flows work on Android
- `OnLoginScriptGenerator` is validated
- security baseline is enforced
- closed beta candidate is ready and usable

---

## 9. v1.0 Definition

### v1.0 Includes
- all MVP capabilities
- stable Quick Print support
- reports
- PPP/Queue in audited scope
- hardened security and release process
- improved offline/cache behavior
- stronger printer/device compatibility coverage

### v1.0 Excludes by Default
Unless separately approved under Phase 9:
- cloud sync
- QRIS
- desktop support
- advanced widgets and premium add-ons beyond the documented optional scope

---

## 10. Program Control Rules

### Mandatory Rules for All AI Agents
- Do not modify architecture from `ROADMAP_V1.md`
- Do not introduce new dependencies unless already approved by roadmap baseline
- Do not implement future-phase scope inside the current phase
- Do not skip tests to preserve schedule
- Do not trade security for feature completeness
- Do not redefine timelines
- Do not redesign SDK boundaries

### Mandatory Rules for Human Review
- Reject any implementation that expands scope beyond the assigned phase
- Reject any implementation that changes public architecture without ADR update and explicit approval
- Reject any implementation that omits measurable acceptance criteria
- Reject any implementation that lacks required test evidence

---

## 11. Suggested Checkpoint Cadence

### Checkpoint A — End of Phase 0
Confirm:
- repo structure
- tooling baseline
- CI health
- architecture consistency

### Checkpoint B — End of Phase 1
Confirm:
- live router connectivity
- protocol/auth stability
- testability of SDK

### Checkpoint C — End of Phase 2
Confirm:
- secure credential storage
- router CRUD stability
- active router state correctness

### Checkpoint D — End of Phase 4
Confirm:
- hotspot core operational without PHP dependency
- destructive actions safe and auditable

### Checkpoint E — End of Phase 6
Confirm:
- high-risk generator validated
- fixtures and regression suite complete
- no unresolved metadata ambiguities remain

### Checkpoint F — End of Phase 8
Confirm:
- release security gate ready
- logs, storage, and telemetry scrubbed

### Checkpoint G — End of Phase 10
Confirm:
- beta exit criteria met
- v1.0 scope evidence-backed

---

## 12. Success Criteria for the Full Program

The program is successful when:
1. DevKuroTik replaces Mikhmon’s core mobile-use workflows without inheriting its security model
2. Android users can manage routers, hotspot users, and vouchers safely from mobile
3. compatibility with audited legacy data conventions is preserved where required
4. critical business logic is regression-tested and validated against real routers
5. the resulting codebase is maintainable, modular, and extensible for future phases

---

## 13. Final Instruction for Future Execution

Use the phase documents as implementation contracts.

If a future AI agent is assigned a single phase, it must:
- stay inside that phase’s boundaries
- honor all dependencies
- satisfy all measurable acceptance criteria
- meet all testing requirements
- update documentation before closure

No phase may be considered complete by intent alone; completion requires evidence.
