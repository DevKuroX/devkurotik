# ROADMAP_V1.md
> **Project:** DevKuroTik  
> **Type:** Engineering roadmap for a full rewrite of Mikhmon into a mobile-first Flutter application  
> **Source of Truth:** `AUDIT_REPORT.md`, `API_ENDPOINTS.md`, `FEATURE_MATRIX.md`, `MIGRATION_BLUEPRINT.md`, `SDK_DESIGN.md`, `SECURITY_REPORT.md`, `FINAL_RECOMMENDATION.md`  
> **Instruction Compliance:** No code, no implementation files, no placeholder tasks

---

## 1. Executive Summary

DevKuroTik should proceed as a **complete rewrite**, not a migration-in-place and not a PHP-to-Flutter port. The audit confirms that Mikhmon’s business value is high, but its current implementation is critically insecure, architecturally coupled, and operationally brittle. The roadmap below converts the audited legacy behavior into a deterministic, phased delivery plan for a secure, mobile-first successor.

### Project Goals
- Replace Mikhmon with a **mobile-first**, **Flutter-based** app
- Preserve **feature compatibility** where required by the audit
- Improve **security**, **maintainability**, **offline support**, and **multi-router UX**
- Ship **Android first**, while keeping architecture iOS-ready and desktop-extensible
- Use **Dart SDKs first**, with optional Go/native extensions only when justified

### Total Estimated Duration
Assuming **solo developer**, **20–30 hours/week**, and **heavy AI assistance**:
- **Optimistic:** 18 weeks
- **Realistic:** 24 weeks
- **Pessimistic:** 32 weeks

### Team Assumptions
- **Human team:** 1 solo developer acting as architect, engineer, QA owner, and release manager
- **AI support:**  
  - Claude Code  
  - OpenCode  
  - GPT-5.4  
  - Sonnet 4.6 / 5.6  
- **AI usage model:** code generation, test generation, parser test fixtures, architectural review, document drafting, regression matrix expansion, and release checklist assistance
- **Non-AI dependency:** at least one real MikroTik test environment must be available before SDK validation and beta

### Major Risks
1. **OnLoginScriptGenerator correctness**
   - Highest-risk logic in the project
   - Must preserve Mikhmon-compatible RouterScript generation for all 5 expiry modes
2. **Legacy metadata compatibility**
   - Existing profile metadata embedded in `on-login` script positions
   - Existing sales data stored in `/system/script`
   - Existing QuickPrint packages encoded in RouterOS scripts
3. **RouterOS protocol compatibility**
   - Support required for RouterOS binary API behavior, including pre/post v6.43 login behavior if retained by product scope
4. **Bluetooth thermal print fragmentation**
   - Android vendor/plugin behavior varies by device and printer
5. **Solo capacity bottleneck**
   - Architecture, implementation, testing, and release all converge on one person
6. **Security regression risk**
   - Legacy system had critical findings; rewrite must not repeat them in new forms

### Critical Modules
These modules are on the project critical path:
- `mikrotik_sdk`
- Router management + secure credential storage
- Hotspot user management
- Voucher engine
- `OnLoginScriptGenerator`
- Reports parser for `/system/script`
- Security hardening / release gating

### Delivery Principle
**Security takes precedence over feature count.**  
If a feature cannot be shipped safely and deterministically in v1, it must be deferred rather than rushed.

---

## 2. Phase Breakdown

---

## Phase 0 — Foundation

### Objectives
Establish the engineering baseline so that all subsequent phases are repeatable, testable, reviewable, and releasable without re-deciding architecture later.

### Scope
- Monorepo structure
- Flutter/Dart version pinning
- Riverpod setup conventions
- Drift setup conventions
- go_router setup conventions
- linting and formatting
- CI/CD baseline
- testing strategy baseline
- Git conventions
- ADR process
- documentation standards
- folder conventions
- dependency management
- tooling baseline

### Prescribed Technical Baseline
- **Flutter:** latest stable Flutter 3.x supported at project start; pin exact version in repo docs and CI
- **Dart:** version bundled with pinned Flutter stable release
- **State management:** Riverpod 2.x
- **Navigation:** go_router
- **Local DB:** SQLite via Drift
- **Secure storage:** flutter_secure_storage
- **Charts:** fl_chart
- **PDF:** pdf + printing
- **QR:** qr_flutter
- **Notifications:** flutter_local_notifications
- **Biometrics:** local_auth

### Deliverables
1. Monorepo initialized with final top-level structure
2. `apps/devkurotik_app` Flutter app scaffolded
3. `packages/` workspace created for SDKs
4. Shared lint rules defined and enforced
5. CI pipeline with:
   - dependency install
   - format check
   - static analysis
   - unit test execution
6. ADR template and initial ADR set written
7. CONTRIBUTING and engineering standards docs written
8. Test strategy document written
9. Versioning and release tagging strategy established
10. Branching and PR rules documented
11. Feature folder structure frozen
12. Dependency policy documented:
   - approved packages
   - evaluation criteria
   - upgrade cadence
13. Issue/decision templates for future phase execution

### Dependencies
- Audit documents complete
- Final product direction fixed to Flutter/Dart
- No implementation dependency on router hardware yet

### Risks
- Unpinned versions causing non-reproducible builds
- Package sprawl early in the project
- Feature folders drifting before standards are defined
- CI omitted or too weak, causing future defects to accumulate

### Acceptance Criteria
- Repo can be cloned and built on a clean machine using only documented steps
- CI fails on formatting, lint, or test failures
- At least one ADR exists for:
  - monorepo choice
  - Dart-first SDK strategy
  - offline-first local storage strategy
  - Android-first / iOS-ready platform plan
- Folder conventions are documented and used consistently
- Each planned SDK has a reserved package location
- A deterministic phase-execution template exists for future phase documents

### Definition of Done
- Engineering standards are documented, approved, and used by default
- CI is active and mandatory for merges
- The repository structure matches the long-term plan
- There are no open architectural decisions required to start Phase 1

### Estimated Duration
- **Optimistic:** 1 week
- **Realistic:** 2 weeks
- **Pessimistic:** 3 weeks

---

## Phase 1 — Core `mikrotik_sdk`

### Objectives
Build the foundational RouterOS access layer that all business features depend on.

### Scope
- TCP client
- Connection manager
- Authentication
- Command execution
- Error handling
- Retry strategy
- Logging
- Testing

### Required Functional Areas
1. Binary RouterOS API framing
2. Socket lifecycle management
3. Login/auth behavior compatible with audited requirements
4. Read/write command abstraction
5. Standard error taxonomy
6. Retry/backoff policy
7. Request logging with secret redaction
8. Connection invalidation and reconnect policy
9. Timeout handling
10. Test harness against mocked protocol and real router targets

### Deliverables
1. `mikrotik_sdk` package skeleton and package boundaries finalized
2. Core transport layer
3. Authentication layer
4. RouterOS command abstraction
5. Structured exception model
6. Retry and timeout policy
7. Logging policy with no credential leakage
8. Unit test suite for protocol behaviors
9. Integration test suite against a controlled RouterOS environment
10. Compatibility matrix documenting tested RouterOS versions

### Dependencies
- Phase 0 complete
- Real or virtual RouterOS test target available before completion
- Security rules from roadmap already enforced in package design

### Risks
- Protocol edge cases not visible in static audit
- RouterOS version differences
- Silent parsing errors
- Logging secrets unintentionally
- Treating transport errors and domain errors the same

### Acceptance Criteria
- App can connect to a configured router and execute audited print commands reliably
- SDK supports the audited command pattern required by future modules
- Timeouts, retries, and disconnects produce deterministic error types
- No plaintext credentials appear in logs, exceptions, or telemetry
- Integration suite passes against at least one supported RouterOS environment
- All downstream phases can depend on stable public APIs rather than internal transport details

### Definition of Done
- `mikrotik_sdk` is usable by other packages without requiring architecture changes
- Public API surface is documented
- Protocol and auth tests are green in CI
- Error semantics are stable enough to support UI and offline queue behavior

### Estimated Duration
- **Optimistic:** 2 weeks
- **Realistic:** 3 weeks
- **Pessimistic:** 5 weeks

---

## Phase 2 — Router Management

### Objectives
Deliver secure multi-router administration as the app’s first end-user capability.

### Scope
- Add/Edit/Delete router
- Multi-router support
- Health checks
- Local persistence
- Router grouping

### Deliverables
1. Router entity model and repository design
2. Secure credential storage policy
3. Add router flow
4. Edit router flow
5. Delete router flow
6. Router listing and quick switch
7. Health/connectivity check
8. Grouping/tagging model for routers
9. Local persistence via Drift + secure storage split
10. Active router state model
11. Last-used router behavior
12. Failure UI states for unreachable routers

### Dependencies
- Phase 0 complete
- Phase 1 core SDK stable
- Secure storage integration available

### Risks
- Credential-storage mistakes
- Router identity duplication
- Grouping model over-designed too early
- Inconsistent active-router context across app features

### Acceptance Criteria
- User can add, edit, delete, and test router connections
- Router credentials are never stored in SQLite plaintext
- Router switching is deterministic and isolated
- Unreachable routers fail gracefully without corrupting local state
- Router grouping supports future fleet views without changing data model

### Definition of Done
- Multi-router management is production-usable
- Local storage schema is migration-ready
- Router selection can be consumed by dashboard and hotspot modules without refactor

### Estimated Duration
- **Optimistic:** 1.5 weeks
- **Realistic:** 2 weeks
- **Pessimistic:** 3 weeks

---

## Phase 3 — Dashboard

### Objectives
Provide the core monitoring experience that validates the “Mikhmon in your pocket” proposition.

### Scope
- Resource monitoring
- Traffic
- User counts
- Statistics

### Deliverables
1. Dashboard layout for phone-first UX
2. Router summary card(s)
3. System resource display:
   - uptime
   - board/model
   - OS version
   - CPU/memory
4. Hotspot counts:
   - total users
   - active users
5. Traffic monitoring visualization
6. Router identity display
7. Pull-to-refresh and configurable refresh behavior
8. Empty/error/loading states
9. Offline fallback using cached values
10. Dashboard performance thresholds documented

### Dependencies
- Phase 1
- Phase 2
- Monitoring command coverage in SDK
- Local cache conventions from Phase 0

### Risks
- Over-polling drains battery and router resources
- Poor streaming/polling abstraction causes UI instability
- Dashboard latency hides protocol issues
- Cached values mistaken for live values

### Acceptance Criteria
- Dashboard loads a selected router with deterministic refresh behavior
- Resource and user count metrics match router values
- Traffic chart behavior is stable under repeated refresh
- App distinguishes cached vs live data
- Dashboard remains responsive under constrained network conditions

### Definition of Done
- Dashboard is suitable for daily monitoring use
- Performance is acceptable on Android target devices
- No unbounded polling loops or hidden resource leaks remain

### Estimated Duration
- **Optimistic:** 1.5 weeks
- **Realistic:** 2 weeks
- **Pessimistic:** 3 weeks

---

## Phase 4 — Hotspot

### Objectives
Reach complete hotspot feature parity required for operational use, based strictly on the audited feature set.

### Scope
Must include the audited hotspot feature family:
- User management
- Profile listing/management
- Active sessions
- Cookies
- Hosts
- Expiry lookup
- Core hotspot workflows referenced in `FEATURE_MATRIX.md`

### Deliverables
1. User list with filters:
   - all users
   - by profile
   - by comment
   - expired users
2. User detail view
3. Add user flow
4. Edit user flow
5. Delete single user
6. Bulk delete by comment
7. Bulk delete expired
8. Enable/disable user
9. Reset counters
10. Export capabilities scoped to MVP/v1 decision
11. Active session list and disconnect flow
12. Cookie list and remove flow
13. Host list and remove flow
14. User expiry display logic
15. Validation rules for all user inputs
16. Error handling and destructive action confirmations

### Dependencies
- Phase 1
- Phase 2
- Phase 3 recommended but not strictly blocking
- Finalized active-router state
- Stable hotspot API abstraction in SDK

### Risks
- User detail logic depends on scheduler/profile parsing
- Delete/reset cascades can break related state if not deterministic
- Legacy comment-field behavior may affect expiry rendering
- Scope creep due to large hotspot feature set

### Acceptance Criteria
- All hotspot user operations listed as Critical in `FEATURE_MATRIX.md` are supported
- Core High-priority hotspot actions are either included in phase scope or explicitly deferred in roadmap release scope
- Destructive actions require confirmation and produce audit log entries locally
- Hotspot data can be refreshed without app restart
- User detail accurately reflects associated profile/session metadata available from router

### Definition of Done
- A field operator can perform core daily hotspot operations exclusively from DevKuroTik
- No hotspot flow requires the legacy PHP app for completion within MVP scope
- Hotspot APIs and UI flows are stable enough for beta users

### Estimated Duration
- **Optimistic:** 3 weeks
- **Realistic:** 4 weeks
- **Pessimistic:** 6 weeks

---

## Phase 5 — Voucher Engine

### Objectives
Deliver the revenue-generating workflow that makes user generation and voucher distribution practical on mobile.

### Scope
Derived from `FEATURE_MATRIX.md` and `MIGRATION_BLUEPRINT.md`:
- Bulk user generation
- Voucher modes
- Character-set generation
- Last-batch persistence
- Voucher rendering
- Batch and single print
- Quick Print flows
- Android printing path

### Deliverables
1. Bulk user generation workflow
2. Voucher mode:
   - user = pass
   - user + pass
3. Character set selection logic
4. Prefix support
5. Profile/validity preview
6. Last batch summary persistence
7. Voucher rendering templates:
   - default
   - thermal
   - small if included in release scope
8. QR generation locally only
9. Single-user voucher print/share
10. Batch voucher print/share
11. Quick Print package read/write compatibility
12. One-touch generate + print flow
13. Android-first print fallback matrix:
   - PDF/share
   - thermal/BT where supported
14. Failure recovery behavior if print fails after generation

### Dependencies
- Phase 1
- Phase 2
- Phase 4 user/profile foundations
- Parsing compatibility for QuickPrint script format
- PDF/QR/print stack decided in Phase 0

### Risks
- Print subsystem fragmentation on Android
- Generated users created successfully but print/share fails
- QuickPrint compatibility format errors
- Overly desktop-inspired voucher layouts unsuitable for mobile workflow

### Acceptance Criteria
- User can generate vouchers from mobile without external web template editing
- QR generation does not leak credentials to external services
- Last batch metadata is recoverable locally
- QuickPrint packages are compatible with audited RouterOS storage format
- Generation + print is recoverable when interrupted
- Voucher output is readable, consistent, and operationally usable

### Definition of Done
- Voucher generation is production-usable for Android field operations
- Quick Print is reliable enough for common operator workflows
- No dependency remains on Mikhmon’s PHP template editor

### Estimated Duration
- **Optimistic:** 2.5 weeks
- **Realistic:** 3 weeks
- **Pessimistic:** 5 weeks

---

## Phase 6 — `OnLoginScriptGenerator` (High Risk)

### Objectives
Safely reproduce Mikhmon-compatible profile RouterScript generation and parsing behavior with exhaustive validation.

### Scope
- Generator for all 5 expiry modes
- Parser/decoder for existing metadata
- Scheduler relationship rules
- Regression validation
- Compatibility fixtures from real routers

### Why This Phase Is Special
This is the **highest-risk module in the entire project**.  
It must never be treated as a normal feature phase.

### Deliverables
1. Formal spec for audited metadata positions and script variants
2. Generator requirements document
3. Parser/decoder requirements document
4. Golden test fixture library:
   - captured PHP outputs
   - captured real-router scripts
5. Generation matrix for all supported expiry modes:
   - none
   - remove
   - notice
   - remove+record
   - notice+record
6. MAC lock behavior validation
7. Price/validity metadata encoding validation
8. Scheduler linkage validation
9. Regression suite with byte-level or canonical-equivalence assertions
10. Change-control policy:
   - any future changes to generator require explicit approval and fixture updates

### Test Strategy
- Golden tests against known-good outputs captured from Mikhmon
- Parser round-trip tests
- Existing-profile decode tests using real router samples
- Regression suite for every expiry mode and setting combination in release scope
- Negative tests for malformed scripts
- Manual validation against real router behavior before beta

### Validation Strategy
1. Capture known-good fixtures from audited legacy behavior
2. Decode those fixtures into structured models
3. Re-generate outputs from structured models
4. Compare with expected canonical output
5. Validate created/updated profiles on real RouterOS test targets
6. Verify actual expiry behavior, scheduler creation, and post-login effects

### Regression Requirements
- No release candidate may ship without the full generator regression suite passing
- No “minor” refactor may skip fixtures
- Generator changes require:
  - fixture review
  - parser review
  - manual router validation
  - release note entry

### Dependencies
- Phase 1
- Phase 4 profile domain understanding
- Access to real scripts captured from routers
- Stable test infrastructure from Phase 0

### Risks
- Silent logical corruption rather than visible failure
- False confidence from synthetic tests only
- Existing profiles failing to decode correctly
- Scheduler lifecycle mismatches
- Solo developer pressure causing premature closure

### Acceptance Criteria
- All 5 audited expiry modes are implemented and validated
- Existing profile metadata can be decoded from real examples
- Re-generated scripts match expected semantics and canonical structure
- Scheduler lifecycle behavior is validated on real routers
- Regression suite is mandatory and green
- Manual validation proves actual router behavior matches intended behavior

### Definition of Done
- The module is proven correct by tests and real-router validation
- No unresolved ambiguity remains in metadata positions or generation rules
- This phase is signed off as a release gate for profile management

### Estimated Duration
- **Optimistic:** 2 weeks
- **Realistic:** 3 weeks
- **Pessimistic:** 5 weeks

---

## Phase 7 — PPP + Queue

### Objectives
Add the non-hotspot operational features needed for broader MikroTik management parity.

### Scope
- PPP
- Queue
- Related management flows aligned with the audited feature set

### Deliverables
1. PPP secrets list
2. Add/edit PPP secret
3. PPP profiles support where included in scope
4. PPP active sessions and disconnect
5. Queue listing support
6. Queue assignment integration where needed by hotspot/profile flows
7. Queue removal operations only if supported by roadmap scope
8. Error/confirmation handling
9. Documentation of source gap:
   - PPP partially absent in Mikhmon repo
   - implementation based on audited references and RouterOS endpoint map

### Dependencies
- Phase 1
- Phase 2
- Queue/PPP abstractions stable in SDK layer

### Risks
- PPP source behavior not fully present in legacy codebase
- Scope can expand into a separate product surface
- Queue interactions may intersect hotspot profile logic unexpectedly

### Acceptance Criteria
- Audited PPP and queue features in roadmap scope are operational
- Unsupported legacy behaviors are explicitly documented, not guessed
- PPP active session management works reliably
- Queue integration does not break hotspot/profile workflows

### Definition of Done
- PPP/Queue capabilities required for v1 are present and documented
- No invented behavior contradicts the audit
- Unsupported edge cases are explicitly deferred

### Estimated Duration
- **Optimistic:** 1.5 weeks
- **Realistic:** 2 weeks
- **Pessimistic:** 4 weeks

---

## Phase 8 — Security Hardening

### Objectives
Translate the audit’s `SECURITY_REPORT.md` into enforced product controls, release gates, and operational safeguards.

### Scope
Must address the rewrite equivalents of the legacy findings:
- credential handling
- transport security
- logging hygiene
- validation
- session/device auth
- destructive action controls
- secure local data handling
- dependency review

### Deliverables
1. Security requirements baseline for DevKuroTik
2. Threat model for mobile app + router communication
3. Secure credential storage review
4. Secret redaction and logging policy enforcement
5. Input validation policy for all SDK commands
6. TLS/SSL usage policy and fallback rules
7. Local authentication and idle timeout policy
8. Destructive action protection rules
9. Audit log requirements for sensitive actions
10. Dependency and license security review
11. Release security checklist
12. Security regression checklist for each later release

### Dependencies
- All core functional phases substantially complete
- Security controls partly introduced earlier, hardened here
- Router connection model stabilized

### Risks
- Treating security as a late polish task
- Feature teams bypassing validation for convenience
- Incomplete redaction in logs or crash reports
- Insecure fallback behavior for router transport

### Acceptance Criteria
- No plaintext credentials in logs, local DB, crash reports, or external services
- Validation exists for all user-supplied router command parameters
- Destructive actions are confirmable and auditable
- Secure storage is used consistently
- Security checklist passes for beta candidate
- Known legacy critical vulnerabilities have no equivalent in new design

### Definition of Done
- Security controls are enforced, not aspirational
- Release cannot proceed if security gates fail
- Product is materially safer than Mikhmon by design, not just by UI differences

### Estimated Duration
- **Optimistic:** 1.5 weeks
- **Realistic:** 2 weeks
- **Pessimistic:** 3 weeks

---

## Phase 9 — Premium Features (Optional)

### Objectives
Design and optionally deliver advanced capabilities without contaminating the MVP critical path.

### Scope
Optional features only:
- Cloud Sync
- QRIS
- Notifications
- Widgets
- Backup

### Deliverables
1. Premium feature ADR set
2. Feature flag strategy
3. Optional cloud sync architecture
4. Backup/export/import design
5. Android widget design
6. Notification engine design and scoped implementation
7. QRIS feasibility and market validation package
8. Monetization/deployment constraints document if premium packaging is planned

### Dependencies
- MVP core stable
- Phase 8 security baseline complete
- Clear product strategy for monetization/optional services

### Risks
- Pulling premium features into MVP too early
- Cloud sync introducing privacy/security complexity
- Widgets/background tasks increasing maintenance cost
- QRIS increasing compliance/payment scope

### Acceptance Criteria
- Optional features are isolated behind clear scope boundaries
- None of these features block beta or v1.0
- Security and privacy implications are documented before implementation
- Premium features can be cut without architectural damage

### Definition of Done
- Optional features are either implemented safely or cleanly deferred
- Core product remains coherent without them

### Estimated Duration
- **Optimistic:** 2 weeks
- **Realistic:** 3 weeks
- **Pessimistic:** 6 weeks

---

## Phase 10 — Beta Release

### Objectives
Validate DevKuroTik in controlled real-world use before general release.

### Scope
- Closed beta
- Telemetry
- Crash reporting
- Feedback loop

### Deliverables
1. Closed beta candidate
2. Beta environment checklist
3. Crash reporting integration
4. Privacy-safe telemetry/events plan
5. In-app or structured feedback workflow
6. Beta test matrix:
   - router versions
   - device classes
   - printer combinations
   - network conditions
7. Defect triage process
8. Go/no-go release rubric
9. Beta exit criteria
10. Stabilization backlog

### Dependencies
- All MVP phases complete
- Security hardening complete
- Test suite healthy
- Real user and router test pool available

### Risks
- Beta too broad before stability
- Inadequate crash/feedback signal
- Printer/device fragmentation not covered
- Developer bandwidth overwhelmed by unstructured feedback

### Acceptance Criteria
- Closed beta installs and runs on target Android devices
- Crash reporting is active and secrets-safe
- Critical user flows are exercised by real users
- All P0/P1 defects are triaged with ownership
- Beta exit criteria are met before wider release

### Definition of Done
- Product has passed closed beta exit criteria
- Release blockers are resolved or explicitly deferred with rationale
- v1.0 scope is confirmed by evidence, not optimism

### Estimated Duration
- **Optimistic:** 2 weeks
- **Realistic:** 3 weeks
- **Pessimistic:** 4 weeks

---

## 3. Deliverables Matrix

| Phase | Deliverables | Dependencies | Risks | Estimated Duration |
|---|---|---|---|---|
| Phase 0 | Monorepo, standards, CI, ADRs, docs, tooling baseline | Audit complete | Weak foundations, version drift | 1–3 weeks |
| Phase 1 | `mikrotik_sdk`, protocol/auth/error/retry/logging/tests | Phase 0, RouterOS test target | Protocol variance, auth edge cases | 2–5 weeks |
| Phase 2 | Router CRUD, secure persistence, grouping, health checks | Phases 0–1 | Credential handling mistakes | 1.5–3 weeks |
| Phase 3 | Dashboard, monitoring, traffic, counts, cache states | Phases 1–2 | Polling/performance issues | 1.5–3 weeks |
| Phase 4 | Hotspot feature parity core set | Phases 1–2 | Large scope, cascade logic | 3–6 weeks |
| Phase 5 | Voucher engine, generation, Quick Print, PDF/QR/print | Phases 1,2,4 | Printing fragmentation, compatibility formats | 2.5–5 weeks |
| Phase 6 | `OnLoginScriptGenerator`, parser, golden fixtures, regression suite | Phases 1,4, test fixtures | Silent logic corruption | 2–5 weeks |
| Phase 7 | PPP + Queue capabilities in audited scope | Phases 1–2 | Missing legacy source details | 1.5–4 weeks |
| Phase 8 | Security hardening, threat model, release gates | Core phases substantially complete | Late security integration | 1.5–3 weeks |
| Phase 9 | Optional premium features, flags, backup/cloud/widget plans | MVP stable, security baseline | Scope creep | 2–6 weeks |
| Phase 10 | Closed beta, telemetry, crash reporting, triage | MVP + security complete | Weak beta signal, fragmented devices | 2–4 weeks |

---

## 4. Critical Path Analysis

### Blocking Phases
These phases block most downstream delivery:
1. **Phase 0 — Foundation**
2. **Phase 1 — Core `mikrotik_sdk`**
3. **Phase 2 — Router Management**
4. **Phase 4 — Hotspot**
5. **Phase 6 — OnLoginScriptGenerator**
6. **Phase 8 — Security Hardening**
7. **Phase 10 — Beta Release**

### Highest-Risk Modules
1. `OnLoginScriptGenerator`
2. on-login metadata decoder/parser
3. `/system/script` sales parser
4. QuickPrint package compatibility parser
5. `mikrotik_sdk` auth/protocol layer
6. Android BT thermal printing path

### Suggested Implementation Order
1. Phase 0
2. Phase 1
3. Phase 2
4. Phase 3
5. Phase 4
6. Phase 6
7. Phase 5
8. Phase 7
9. Phase 8
10. Phase 10
11. Phase 9

### Why This Order
- `mikrotik_sdk` is foundational to everything
- Router management is required before meaningful UI flows
- Dashboard validates connectivity and monitoring early
- Hotspot is the main business module
- `OnLoginScriptGenerator` must be solved before profile-dependent parity is considered safe
- Voucher engine depends on both hotspot and profile logic
- Security hardening must precede beta, but should be progressively applied throughout

### Parallelizable Work
These can run partially in parallel once prerequisites are met:
- Dashboard UI work after Phase 1/2 interfaces stabilize
- Report parser design while hotspot UI is being built
- PPP/Queue scoping while voucher engine is in development
- Security checklist authoring during feature development
- Beta test planning during Phase 8

### Non-Parallelizable Work
These should not be split prematurely:
- Phase 1 protocol/auth core
- Phase 6 generator/parser validation
- Security release gating
- Final beta exit triage

### Critical Path Summary
**Foundation → SDK → Router Mgmt → Hotspot → OnLoginScriptGenerator → Security Hardening → Beta**

Any slip in these phases moves the release.

---

## 5. Repository Architecture

### Recommended Structure

```text
devkurotik/
├── apps/
│   └── devkurotik_app/
├── packages/
│   ├── mikrotik_sdk/
│   ├── voucher_sdk/
│   ├── routeros_script_sdk/
│   ├── monitoring_sdk/
│   ├── hotspot_sdk/           # if retained separately from voucher concerns
│   ├── system_sdk/            # optional split if needed by team
│   ├── report_sdk/            # optional split if kept separate
│   ├── ppp_sdk/               # optional split
│   └── queue_sdk/             # optional split
├── docs/
│   ├── adr/
│   ├── architecture/
│   ├── phases/
│   ├── testing/
│   ├── security/
│   └── release/
├── tools/
│   ├── ci/
│   ├── scripts/
│   ├── fixtures/
│   └── generators/
└── .github/
│   └── workflows/
```

### Recommendations by Top-Level Area

#### `apps/`
Contains the end-user Flutter applications.
- Start with one app: `devkurotik_app`
- Future-ready for:
  - admin/internal variants
  - desktop shell
  - white-label variants if ever needed

#### `packages/`
Contains reusable domain SDKs and package-level tests.
- Keep transport and domain logic out of app UI
- Each package owns:
  - public API
  - internal models/serializers
  - unit/integration tests
  - changelog and package docs

#### `docs/`
Single source for architecture and delivery governance.
Must contain:
- ADRs
- phase docs (`PHASE_0.md` ... `PHASE_10.md`)
- testing standards
- security standards
- release checklists
- compatibility matrix
- printer/device validation notes

#### `tools/`
Contains automation and durable project assets.
Use for:
- fixture storage
- validation data
- CI helper scripts
- release automation
- synthetic RouterOS test assets where permitted

### App Internal Structure Recommendation
Inside `apps/devkurotik_app/lib/`, use:
- `core/`
- `features/`
- `shared/`

Recommended breakdown:
- `core/`: app shell, database, secure storage, theme, config, platform services
- `features/`: router management, dashboard, hotspot, vouchers, reports, system, PPP, settings
- `shared/`: reusable UI widgets, utilities, provider helpers, error UI patterns

### Governance Recommendation
Do not allow feature code to directly bypass package boundaries into raw transport logic.  
All RouterOS operations must pass through SDK abstractions.

---

## 6. SDK Strategy

The roadmap should begin with a **Dart-first modular SDK architecture**.

## 6.1 `mikrotik_sdk`

### Responsibilities
- RouterOS binary protocol transport
- connection lifecycle
- authentication
- command execution
- retries/timeouts
- standardized errors
- secret-safe logging
- connection pooling/invalidation policy

### Boundaries
- Must not contain UI
- Must not contain app-specific local storage
- Must not embed hotspot business rules
- Must not know about voucher templates or report parsing semantics beyond raw command support

### Dependencies
- Dart IO / platform networking
- security/logging policies from app foundation
- no dependency on Flutter UI layer

---

## 6.2 `voucher_sdk`

### Responsibilities
- Bulk user generation orchestration rules
- voucher payload assembly
- batch metadata semantics
- Quick Print package compatibility logic
- printable voucher domain models
- QR payload rules
- output formats shared across app printing flows

### Boundaries
- Must not own raw transport
- Must not own app-specific widget/layout code
- Must not embed insecure external QR generation
- Must not own local secure storage

### Dependencies
- `mikrotik_sdk`
- hotspot/profile abstractions as needed
- local renderers only through app-layer adapters if PDF generation is kept outside package

---

## 6.3 `routeros_script_sdk`

### Responsibilities
- `on-login` metadata parsing
- `OnLoginScriptGenerator`
- `/system/script` record parsing
- QuickPrint script encoding/decoding
- canonical serialization rules
- round-trip compatibility fixtures

### Boundaries
- Must not own TCP transport
- Must not own app presentation
- Must not directly manage router selection or secure storage
- Must be fixture-driven and heavily regression tested

### Dependencies
- Pure Dart preferred
- depends on domain schemas, not UI
- may be consumed by hotspot, voucher, and reports layers

---

## 6.4 `monitoring_sdk`

### Responsibilities
- Dashboard-oriented resource retrieval
- interface traffic abstractions
- resource formatting helpers
- polling/stream semantics suitable for UI consumption
- health-check models

### Boundaries
- No widget code
- No app navigation logic
- No credential persistence
- No voucher/business record logic

### Dependencies
- `mikrotik_sdk`

---

## Recommended Boundary Notes
If package count becomes too heavy for a solo developer, use this consolidation rule:
- Keep `mikrotik_sdk` separate no matter what
- Keep `routeros_script_sdk` separate because it is high risk
- Merge `voucher_sdk` and hotspot-domain package only if packaging overhead becomes costly
- Keep monitoring either standalone or as a thin domain package over `mikrotik_sdk`

---

## 7. Testing Strategy

Testing must be phase-specific, coverage-driven, and risk-weighted.

### Test Types Required
- Unit tests
- Integration tests
- Golden tests
- Widget tests
- Regression tests
- Performance tests

---

### Phase-by-Phase Coverage Targets

| Phase | Primary Test Types | Coverage Target |
|---|---|---|
| Phase 0 | CI checks, smoke tests | N/A baseline only |
| Phase 1 | Unit + integration | 85% package coverage |
| Phase 2 | Unit + widget + integration | 80% feature coverage |
| Phase 3 | Unit + widget + performance | 75% feature coverage |
| Phase 4 | Unit + widget + integration + regression | 80% feature coverage |
| Phase 5 | Unit + integration + golden + regression | 80% feature coverage |
| Phase 6 | Golden + regression + integration | 95% critical-path coverage |
| Phase 7 | Unit + integration | 75% feature coverage |
| Phase 8 | Security regression + integration | policy-based gate |
| Phase 10 | end-to-end beta validation | scenario completion gate |

---

### Unit Tests
Use for:
- parsers
- formatters
- command builders
- validation rules
- retry policies
- repository logic
- local cache TTL logic

### Integration Tests
Use for:
- RouterOS command execution
- add/edit/delete router workflows
- hotspot CRUD flows
- profile script creation/update flows
- report parsing from real router data
- PPP/Queue operations in supported scope

### Golden Tests
Use for:
- voucher output templates
- critical structured outputs
- `OnLoginScriptGenerator` canonical outputs
- parser round-trip expected outputs

### Widget Tests
Use for:
- router management screens
- dashboard states
- hotspot list/detail flows
- destructive action confirmations
- error/loading/empty states

### Regression Tests
Mandatory for:
- comment-field dual-use parsing
- QuickPrint script encoding/decoding
- `/system/script` sales parsing
- `OnLoginScriptGenerator`
- printer flow recovery logic
- offline queue idempotency if implemented in scope

### Performance Tests
Must cover:
- dashboard refresh under poor connectivity
- large hotspot user list handling
- batch voucher generation response times
- report parsing speed with realistic script volumes

### Testing Gates
A phase cannot close if:
- critical tests are skipped
- generator/parser regression suite is incomplete
- RouterOS integration tests have not been run for router-facing phases
- beta-critical workflows lack manual validation evidence

### Definition of Done for Testing
Each phase must produce:
- test plan
- automated tests in CI
- manual validation checklist where hardware/network behavior matters
- documented known gaps

---

## 8. Security Plan

Based on `SECURITY_REPORT.md`, DevKuroTik must treat security as a first-class workstream.

### Security Priorities by Severity Mapping

#### Priority 1 — Critical Rewrite Controls
Mapped from legacy critical findings:
- eliminate runtime code injection patterns
- eliminate unsafe file/path operations
- eliminate hardcoded/default credentials
- eliminate reversible credential storage
- eliminate dynamic code generation in user-editable contexts

**Remediation Phase:** Phase 0, 1, 2, 8

#### Priority 2 — High-Risk Operational Controls
Mapped from legacy high findings:
- no credential exposure in UI/logs/telemetry
- no external QR credential leakage
- no insecure destructive actions
- robust local auth/session timeout
- strict validation for all router parameters
- secure upload/media handling if logo/custom assets remain in scope

**Remediation Phase:** Phase 2, 4, 5, 8

#### Priority 3 — Medium/Low Hardening Controls
- brute-force protection on local app auth if applicable
- secure logout/device state clearing
- defensive error handling
- secure headers only where web surfaces exist in future optional cloud/admin tooling
- dependency hygiene
- anti-tamper not required for MVP, but no obfuscated lockout logic allowed

**Remediation Phase:** Phase 8, Phase 10

---

### Security Acceptance Criteria
Before beta:
1. No default credentials anywhere
2. No plaintext credentials in local DB
3. No plaintext credentials in logs
4. No credentials sent to third-party QR/chart services
5. Sensitive actions are confirmed and locally auditable
6. Validation exists for all user-driven RouterOS command inputs
7. Crash reporting is scrubbed of secrets
8. Secure storage is used consistently
9. TLS/SSL strategy is documented and enforced where supported
10. Security review checklist passes

### Security Definition of Done
- Known legacy critical vulnerabilities have no architectural analogue
- Threat model is documented
- Release checklist includes security gates
- Beta build has passed security acceptance criteria

---

## 9. Timeline

Assumption:
- Solo developer
- Heavy AI assistance
- 20–30 hours/week

### Optimistic Timeline — 18 Weeks
Best case if:
- router test hardware available early
- few protocol surprises
- printing path works quickly
- limited rework on generator/parser

| Segment | Duration |
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
Most likely path for a disciplined solo build.

| Segment | Duration |
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
| Phase 9 | parallel/deferred |
| **Total** | **24 weeks** |

### Pessimistic Timeline — 32 Weeks
If protocol issues, hardware variability, or generator rework are significant.

| Segment | Duration |
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

### Recommended Planning Baseline
Use the **24-week realistic timeline** for delivery planning.  
Treat the 18-week plan as stretch only, not a management promise.

---

## 10. Final Recommendations

### 1. Is Flutter still the best choice?
**Yes.**  
Flutter remains the best fit because DevKuroTik is:
- mobile-first
- Android-first but iOS-ready
- single-codebase constrained
- UI-heavy with offline/local-storage needs
- likely to benefit from reusable Dart SDK packages

### 2. Is Dart SDK preferable over Go SDK initially?
**Yes.**  
Start with a **Dart-native SDK strategy**.
Reasons:
- lower complexity for solo development
- direct app integration
- fewer deployment surfaces
- faster testing/debugging loop
- adequate for the current scope

Go should remain optional for:
- future sync services
- background processing beyond mobile constraints
- server-side/cloud features

### 3. Which phase should begin immediately?
**Phase 0 — Foundation.**  
Without it, later phase outputs will drift and require avoidable rework.

### 4. Which phase must never be rushed?
**Phase 6 — OnLoginScriptGenerator.**  
This is the single module most likely to cause silent business-logic corruption.

### 5. What should be deferred to v2?
Defer unless they become commercially mandatory:
- cloud sync
- QRIS
- Android widgets
- advanced notifications
- desktop support
- multi-tenant/operator roles
- advanced analytics beyond core reports
- backup/sync services beyond basic export/import

### 6. Recommended MVP scope
MVP should include:
- Phase 0
- Phase 1
- Phase 2
- Phase 3
- Phase 4 core hotspot features
- Phase 5 core voucher generation and PDF/share
- Phase 6
- Phase 8 minimum hardening
- Phase 10 closed beta

MVP should exclude:
- premium cloud features
- nonessential network tools
- broad PPP/Queue expansion if schedule tightens
- advanced widget/notification ecosystems

### 7. Recommended v1.0 scope
v1.0 should include:
- all MVP capabilities
- stable Quick Print support
- reports
- PPP/Queue in audited scope
- hardened security/release process
- improved offline/cache behaviors
- stronger printer/device compatibility coverage

### 8. Long-term architecture recommendation
Adopt a **monorepo with SDK-centric boundaries**:
- Flutter app in `apps/`
- stable Dart domain packages in `packages/`
- architecture/process documents in `docs/`
- automation/fixtures in `tools/`

Long term:
- preserve `mikrotik_sdk` as the foundational package
- preserve `routeros_script_sdk` as an isolated high-risk compatibility package
- keep cloud features optional and separate from the offline-first core
- prefer explicit interfaces and package APIs over convenience shortcuts

---

## Recommended MVP vs v1.0 Summary

### MVP
- Router management
- Dashboard
- Hotspot core
- Voucher generation
- `OnLoginScriptGenerator`
- Basic reports if schedule allows
- Security baseline
- Closed beta readiness

### v1.0
- all MVP capabilities
- PPP/Queue support
- Report maturity
- Better print compatibility
- stronger offline resilience
- optional premium groundwork without full dependence on cloud

---

## Final Program Guidance

DevKuroTik should be managed as a **high-discipline rewrite**, not a fast feature clone.

The engineering rule for every subsequent phase document should be:

1. no contradiction to the audit  
2. no hidden architectural decisions postponed to implementation  
3. no release of high-risk compatibility logic without fixtures and regression evidence  
4. no security tradeoff made to preserve schedule  
