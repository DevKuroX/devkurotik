# RISK_REGISTER.md
> Final preflight risk register for the DevKuroTik specification.
> Derived from roadmap, master plan, dependency graph, phase specifications, and security audit.

---

## 1. Risk Register

| ID | Risk | Severity | Phase | Impact | Likelihood | Mitigation | Status |
|---|---|---|---|---|---|---|---|
| R-01 | `OnLoginScriptGenerator` produces incorrect compatibility behavior | Critical | 6 | Silent business-logic corruption, expiry errors, feature parity failure | High | Golden fixtures, regression suite, 95% critical-path coverage, real-router validation, no merge without review | Open |
| R-02 | RouterOS protocol/auth variance causes unstable SDK behavior | High | 1 | Blocks all downstream router-facing phases | Medium | Integration tests, compatibility matrix, real/virtual RouterOS test target | Open |
| R-03 | Router credentials leak through logs, telemetry, or storage | Critical | 1,2,8,10 | Security failure, release blocker | Medium | Secure storage enforcement, redaction policy, security checklist, crash/telemetry validation | Open |
| R-04 | Hotspot scope expands beyond controlled feature parity | High | 4 | Timeline slip, implementation sprawl, downstream instability | High | Strict adherence to phase non-goals, governance enforcement, acceptance-criteria review | Open |
| R-05 | Quick Print package compatibility diverges from audited format | High | 5 | Legacy package incompatibility, print workflow regression | Medium | Defensive parsing, regression tests, compatibility validation with real script data | Open |
| R-06 | Android print/thermal compatibility is fragmented across devices and printers | High | 5,10 | Unreliable field printing, beta instability | High | Print fallback matrix, real printer testing, preserve PDF/share fallback | Open |
| R-07 | Real router fixtures for Phase 6 are unavailable or insufficient | High | 6 | Delays validation and release confidence | Medium | Capture fixtures early, gate phase closure on fixture inventory | Open |
| R-08 | Active-router state becomes inconsistent across features | Medium | 2,3,4 | Incorrect router context, data/action confusion | Medium | Deterministic router state model, widget/integration tests, phase-boundary validation | Open |
| R-09 | Security hardening is treated as documentation instead of enforcement | High | 8 | Hidden release risk, audit failure in practice | Medium | Policy-based gate, checklist execution, integration validation, governance enforcement | Open |
| R-10 | Beta crash/telemetry tooling captures secrets | Critical | 10 | Security blocker, trust failure | Medium | Explicit secret-safety validation, telemetry review, security checklist before beta | Open |
| R-11 | PPP source incompleteness leads to invented behavior | Medium | 7 | Divergence from audit, wasted implementation effort | Medium | Stay within audited scope, document unsupported gaps, avoid speculation | Open |
| R-12 | Optional premium scope creeps into MVP-critical work | Medium | 9 | Timeline slip, architecture noise | Medium | Feature flags, defer-by-default, governance enforcement | Open |
| R-13 | Solo developer throughput becomes a schedule bottleneck | High | All | Timeline extension, reduced QA depth | High | Strict phase isolation, tag per phase, AI-assisted tests/docs, avoid parallel scope sprawl | Open |
| R-14 | Phase 1 abstractions are too loose and create refactor debt | High | 1 | Cascading rework into Phase 2–8 | Medium | Public API discipline, integration tests, compatibility review before closure | Open |
| R-15 | Phase 4 hotspot semantics are implemented loosely | High | 4 | Rework in voucher/profile/report features | Medium | Acceptance criteria discipline, regression tests, downstream readiness validation | Open |
| R-16 | Beta device/router/printer coverage is too narrow | Medium | 10 | False confidence before general release | Medium | Beta matrix, structured user pool, explicit exit criteria | Open |

---

## 2. Highest Priority Risks

### Critical Risks
1. **R-01 — `OnLoginScriptGenerator` correctness**
2. **R-03 — Credential leakage in logs/telemetry/storage**
3. **R-10 — Beta crash/telemetry secret exposure**

### High Risks
1. **R-02 — RouterOS SDK compatibility instability**
2. **R-04 — Hotspot scope overload**
3. **R-05 — Quick Print compatibility drift**
4. **R-06 — Android print fragmentation**
5. **R-09 — Security hardening not enforced in practice**
6. **R-13 — Solo developer throughput bottleneck**
7. **R-14 — Phase 1 abstraction debt**
8. **R-15 — Phase 4 semantic looseness**

---

## 3. Program-Level Risk Highlights

### Highest Risk Phase
**Phase 6 — `OnLoginScriptGenerator`**

### Longest Phase
**Phase 4 — Hotspot**

### Largest Unknown
**Real-world behavior variance across RouterOS profile scripts, scheduler linkage, and printer environments**

### Largest Technical Debt Risk
**Weak Phase 1 and Phase 4 implementation discipline leading to broad downstream refactor pressure**

---

## 4. MVP Risk Posture

### MVP-Affecting Risks
The following risks can directly affect MVP success:
- R-01
- R-02
- R-03
- R-04
- R-05
- R-06
- R-09
- R-10
- R-13
- R-14
- R-15

### MVP Risk Conclusion
MVP remains achievable if:
- Phase discipline is maintained
- Phase 6 is treated as a hard gate
- printer and router test assets are secured on time
- security controls are validated, not assumed

---

## 5. Risk Control Recommendations

1. **Start only with Phase 0** and do not preload future features.
2. **Tag after each completed phase** to reduce rollback cost.
3. **Capture real RouterOS fixtures early** rather than waiting for Phase 6.
4. **Secure at least one printer validation path early in Phase 5 planning**.
5. **Review public interfaces at the end of Phase 1 and Phase 4 before continuing**.
6. **Use governance enforcement as a release mechanism, not just a documentation artifact**.
7. **Require evidence for phase closure**: tests, docs, validation notes, and checklist completion.

---

## 6. Final Risk Interpretation

The specification risk posture is acceptable for implementation.

The risk profile is not low, but it is:
- known
- documented
- phase-mapped
- mitigated at the specification level

This is exactly the right state for beginning a disciplined rewrite.
