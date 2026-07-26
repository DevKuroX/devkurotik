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
2026-07-26

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

## 12. Real Router Test Environment

Two live MikroTik CHR instances are available for integration testing.

### Instances

| Instance | File | IP | Port | Username | Version | Provider |
|---|---|---|---|---|---|---|
| CHR v7 | `chr.txt` | 54.147.121.92 | 8728 | admin | 7.15.1 (stable) | AWS EC2 t3.small |
| CHR v6 | `chr6.txt` | 139.162.35.252 | 8728 | admin | 6.49.17 (stable) | Linode nanode ap-south |

Both files are gitignored and must never be committed.

**Both instances must remain alive until Phase 10 is complete.**

### Firewall

- CHR v6 uses Linode firewall `CHR` (ID 88330218) — ports 8728, 8729, 8291, 80, 22, 21, 23 open.
- CHR v7 uses AWS Security Group — port 8728 open.
- IP mungkin diblokir ISP Indonesia — akses manual via VPN atau weblish Linode.
- API tests dari server/CI tidak terpengaruh pemblokiran ISP.

### When Claude Must Use the CHR

Claude **must** run real-router integration tests against both CHR instances when:

| Phase | Trigger | Primary | Secondary |
|---|---|---|---|
| Phase 1 | SDK transport, auth, command execution | v7 | v6 |
| Phase 2 | Health check integration | v7 | v6 |
| Phase 3 | Dashboard data fetch | v7 | v6 |
| Phase 4 | Hotspot user list/add | v7 | v6 |
| Phase 5 | Voucher print flow | v7 | v6 |
| Phase 6 | Full regression suite (mandatory gate) | v7 | v6 |
| Any phase | Whenever phase document requires real-router evidence | v7 | v6 |

### How to Run CHR Tests

1. Read credentials from `chr.txt` (v7) and `chr6.txt` (v6).
2. Set host/port/password in the integration test file.
3. Run directly (not via `flutter test` CI sweep):
   ```bash
   # mikrotik_sdk package
   dart test test/integration_chr_test.dart        # v7
   dart test test/integration_chr_v6_test.dart     # v6
   dart test test/integration_dashboard_v7_test.dart
   dart test test/integration_dashboard_v6_test.dart

   # Flutter app package (Phase 2+)
   flutter test test/integration/chr_health_test.dart
   ```
4. Record pass/fail in the phase completion report.
5. **Never commit `chr.txt`, `chr6.txt`, or credentials in test source files.**

### Security Rules for CHR Usage

- Credentials must come from `chr.txt` / `chr6.txt` — never hardcoded in committed files.
- Password must never appear in logs, test output summaries, or completion reports.
- If a test file ran with hardcoded credentials, redact before any future commit.

### If CHR Is Unavailable

If a CHR instance is unreachable during a phase:
1. Document the gap in the phase completion report.
2. Continue with unit and mock tests.
3. Do **not** mark integration tests as passing if they were not run.
4. Flag as PENDING in the compatibility matrix.
5. Try the other CHR instance if available.

### CHR v6 Recovery Procedure

If CHR v6 API becomes inaccessible:
1. Check port: `nc -z -w 5 139.162.35.252 8728`
2. If closed — login via weblish: `https://cloud.linode.com/linodes/101417810/lish/weblish`
3. Run: `/ip service enable api` then `/ip service set api port=8728`
4. If instance dead — rebuild: delete + create from image `private/40202857`, set config `kernel=linode/direct-disk virt_mode=fullvirt all-helpers=false`, attach to Linode firewall `CHR` (ID 88330218), boot.

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
- `chr.txt` (gitignored) — real router credentials
