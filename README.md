# README.md
> Root repository overview for DevKuroTik.

---

## Purpose
Provide the primary repository entry point for humans and AI agents. This document explains what DevKuroTik is, the current project state, where to find the authoritative specification, and how implementation work must proceed.

## Scope
This document covers:
- project overview
- vision and goals
- current status
- repository structure
- phase status
- getting started
- documentation index
- development workflow

## Audience
- project owner
- maintainers
- human contributors
- AI coding agents
- reviewers and auditors

## Last Updated
2026-07-25

---

## 1. Project Overview

**DevKuroTik is a complete rewrite of Mikhmon.**

DevKuroTik is a mobile-first, Flutter-based successor to Mikhmon designed for secure, maintainable, offline-capable MikroTik hotspot and router management.

The project is not a PHP port.
It is a specification-driven rebuild based on a full audit of the legacy Mikhmon codebase.

---

## 2. Vision

DevKuroTik exists to deliver:
- **Mikhmon in your pocket**
- Android-first mobile usability
- iOS-ready architecture
- feature compatibility with Mikhmon where required by audit
- stronger security than the legacy system
- offline-first workflows
- multi-router support
- future-ready optional premium extensions without contaminating the core product

---

## 3. Goals

Primary goals:
1. Replace Mikhmon with a modern Flutter application.
2. Preserve audited business-critical behavior.
3. Avoid legacy security failures.
4. Deliver a maintainable monorepo with clear SDK boundaries.
5. Enforce phase-by-phase execution under repository governance.

---

## 4. Current Status

### Project Status
**SPECIFICATION COMPLETE**

### Preflight Status
**PROCEED WITH CONDITIONS**

### Meaning
The architecture, roadmap, phase documents, governance model, and execution controls are complete.
The project has transitioned from architecture/design mode into engineering execution mode.

### Current Rule
Implementation must begin with:
- `PHASE_0.md`
- and only `PHASE_0.md`

---

## 5. Repository Structure

Planned repository structure:

```text
devkurotik/
├── apps/
│   └── devkurotik_app/
├── packages/
│   ├── mikrotik_sdk/
│   ├── voucher_sdk/
│   ├── routeros_script_sdk/
│   ├── monitoring_sdk/
│   ├── hotspot_sdk/        # optional retained split
│   ├── system_sdk/         # optional retained split
│   ├── report_sdk/         # optional retained split
│   ├── ppp_sdk/            # optional retained split
│   └── queue_sdk/          # optional retained split
├── docs/
├── tools/
└── .github/
```

Repository-level contract documents are stored at root.
Canonical implementation and audit documents are currently maintained under the project documentation/audit structure.

---

## 6. Phase Status

| Phase | Title | Status |
|---|---|---|
| Phase 0 | Foundation | Ready to execute |
| Phase 1 | Core `mikrotik_sdk` | Spec complete |
| Phase 2 | Router Management | Spec complete |
| Phase 3 | Dashboard | Spec complete |
| Phase 4 | Hotspot | Spec complete |
| Phase 5 | Voucher Engine | Spec complete |
| Phase 6 | `OnLoginScriptGenerator` | Spec complete / highest risk |
| Phase 7 | PPP + Queue | Spec complete |
| Phase 8 | Security Hardening | Spec complete |
| Phase 9 | Premium Features (Optional) | Spec complete |
| Phase 10 | Beta Release | Spec complete |

---

## 7. Getting Started

Before implementing anything:
1. Read `README.md`
2. Read `RULES.md`
3. Read `GOVERNANCE.md`
4. Read `AGENTS.md`
5. Read `CLAUDE.md` if using Claude Code
6. Read `EXECUTION_ORDER.md`
7. Read the assigned `PHASE_X.md`

### Mandatory Start Point
If implementation has not yet begun, start with:
- `PHASE_0.md`

### Do Not Start With
- dashboard
- hotspot
- voucher generation
- premium features
- architecture redesign

---

## 8. Documentation Index

### Repository Contract Documents
- `README.md`
- `CLAUDE.md`
- `AGENTS.md`
- `RULES.md`
- `CONTRIBUTING.md`
- `ARCHITECTURE.md`
- `docs/GOVERNANCE.md`

### Source-of-Truth Execution Documents
- `ROADMAP_V1.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `PHASE_0.md` ... `PHASE_10.md`

### Validation Documents
- `PREFLIGHT_VALIDATION.md`
- `RISK_REGISTER.md`
- `EXECUTION_READINESS_REPORT.md`

### Audit Documents
- `AUDIT_REPORT.md`
- `API_ENDPOINTS.md`
- `FEATURE_MATRIX.md`
- `MIGRATION_BLUEPRINT.md`
- `SDK_DESIGN.md`
- `SECURITY_REPORT.md`
- `FINAL_RECOMMENDATION.md`

---

## 9. Development Workflow

Mandatory workflow:

```text
Assigned Phase
  ↓
Implement only assigned scope
  ↓
Run required tests
  ↓
Update required docs
  ↓
Review against DoD and acceptance criteria
  ↓
Tag phase checkpoint
  ↓
Proceed to next phase
```

### Do Not Use This Workflow

```text
Phase 0
Phase 1
Phase 2
Phase 3
implement all together
fix later
```

### Required Tagging Sequence
Recommended phase tags:
- Phase 0 → `v0.0.1`
- Phase 1 → `v0.1.0`
- Phase 2 → `v0.2.0`
- Phase 3 → `v0.3.0`
- Phase 4 → `v0.5.0`
- Phase 5 → `v0.7.0`
- Phase 6 → `v0.8.0`
- Phase 7 → `v0.9.0`
- Phase 8 → `v0.9.5`
- Phase 9 → `v0.9.8`
- Phase 10 → `v1.0.0`

---

## 10. Implementation Rule

If you are a contributor or AI agent, the correct default instruction is:

> **Execute the assigned `PHASE_X.md` exactly as written. Do not implement any future phases.**

---

## References
- `docs/GOVERNANCE.md`
- `ROADMAP_V1.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `PHASE_0.md` ... `PHASE_10.md`
- `PREFLIGHT_VALIDATION.md`
- `EXECUTION_READINESS_REPORT.md`
