# PHASE_3.md
> Canonical implementation specification for Phase 3 — Dashboard.
> This document is self-contained and derived from `ROADMAP_V1.md` without changing architecture, technologies, scope, or timeline.

---

## 1. Overview

### Purpose
Provide the core monitoring experience that proves the DevKuroTik value proposition: “Mikhmon in your pocket.”

### Scope
Phase 3 covers:
- Resource monitoring
- Traffic
- User counts
- Statistics

### Objectives
1. Deliver a phone-first dashboard for the active router.
2. Show key router identity and system resource information.
3. Show hotspot counts and live monitoring data.
4. Distinguish live values from cached offline fallback values.
5. Validate the app’s monitoring flow before more complex hotspot workflows expand.

---

## 2. Inputs

Required inputs for this phase:
- `ROADMAP_V1.md`
- `PHASE_0.md`
- `PHASE_1.md`
- `PHASE_2.md`
- `MASTER_IMPLEMENTATION_PLAN.md`
- `DEPENDENCY_GRAPH.md`
- `EXECUTION_ORDER.md`
- `MIGRATION_BLUEPRINT.md`
- `SDK_DESIGN.md`
- `API_ENDPOINTS.md`
- `FEATURE_MATRIX.md`

---

## 3. Deliverables

1. Dashboard layout optimized for phone-first UX.
2. Router summary card(s) implemented.
3. System resource display implemented for uptime, board/model, OS version, CPU, and memory.
4. Hotspot counts implemented for total users and active users.
5. Traffic monitoring visualization implemented.
6. Router identity display implemented.
7. Pull-to-refresh and configurable refresh behavior implemented.
8. Empty, loading, and error states implemented.
9. Offline fallback using cached values implemented.
10. Dashboard performance thresholds documented.

---

## 4. Tasks

### Task 1 — Implement dashboard shell for the active router
Create the dashboard screen and layout bound to the active-router state established in Phase 2.

### Task 2 — Implement router summary display
Display the currently selected router’s identity and summary information in a stable and clearly scoped dashboard header/summary area.

### Task 3 — Implement system resource monitoring
Implement retrieval and display of:
- uptime
- board/model
- OS version
- CPU load
- memory status

### Task 4 — Implement hotspot count cards
Implement display of:
- total hotspot users
- active hotspot users

### Task 5 — Implement traffic monitoring visualization
Implement the approved traffic monitoring view using the roadmap-approved charting approach and the monitoring abstractions from the approved architecture.

### Task 6 — Implement refresh behavior
Implement:
- pull-to-refresh
- configurable refresh behavior
- deterministic refresh boundaries so polling does not become uncontrolled

### Task 7 — Implement offline and cached state behavior
Implement fallback behavior for cached dashboard values. Ensure the UI clearly distinguishes between live and cached data.

### Task 8 — Implement loading, empty, and error states
Provide explicit screen and component states for:
- initial loading
- router unavailable
- no data available
- partial monitoring failure

### Task 9 — Document dashboard performance expectations
Document the expected performance thresholds and constraints for dashboard refresh and rendering behavior.

### Task 10 — Validate dashboard stability under constrained conditions
Test and confirm the dashboard remains responsive under network delays, refresh repetition, and router availability changes.

---

## 5. Dependencies

### Requires
- Phase 1 complete
- Phase 2 complete

### Blocked by
- missing monitoring command coverage in SDK
- unstable active-router state

### External Dependencies
- test router for live resource and traffic validation
- Android device/emulator for UI and performance checks

---

## 6. Acceptance Criteria

1. Dashboard loads successfully for the selected active router.
2. Router identity is displayed correctly.
3. System resource data matches router values.
4. Hotspot total and active user counts display correctly.
5. Traffic visualization updates correctly and remains stable under repeated refresh.
6. Pull-to-refresh works correctly.
7. Configurable refresh behavior works without creating unbounded polling loops.
8. Cached and live states are clearly differentiated in the UI.
9. Dashboard remains responsive under constrained network conditions.
10. Empty, loading, and error states are implemented and usable.
11. All tests pass.
12. Minimum coverage for this phase is **75% feature coverage**.

---

## 7. Definition of Done

Phase 3 is done only when:
- all deliverables are completed
- acceptance criteria are satisfied
- tests are passing
- coverage threshold is met
- dashboard performance is acceptable on target Android devices
- no hidden refresh or resource leaks remain

---

## 8. Testing Requirements

### Required Test Types
- Unit tests
- Widget tests
- Performance tests

### Minimum Coverage Requirements
- **Coverage >= 75% feature coverage**

### Unit Test Requirements
Must cover:
- resource formatting helpers
- cache/live-state logic
- refresh interval handling
- dashboard state mapping

### Widget Test Requirements
Must cover:
- loading state
- error state
- empty state
- cached-state indication
- active-router-bound rendering

### Performance Test Requirements
Must cover:
- repeated refresh behavior
- constrained network responsiveness
- traffic visualization update stability
- dashboard rendering under normal monitored data volumes

### Required Validation Evidence
- green CI run
- coverage report meeting threshold
- performance validation notes for dashboard responsiveness

---

## 9. Risks

### Technical Risks
- over-polling drains battery and router resources
- unstable streaming/polling behavior degrades UI responsiveness
- cache/live-state confusion causes incorrect operational decisions

### Migration Risks
- dashboard semantics diverge from audited resource/traffic expectations
- monitoring abstractions become too UI-coupled for reuse

### Security Risks
- logs or errors expose sensitive router context
- refresh paths unintentionally emit sensitive information to telemetry/logging

---

## 10. Non-Goals

Phase 3 must **not** implement:
- hotspot CRUD flows
- voucher generation
- Quick Print
- `OnLoginScriptGenerator`
- PPP/Queue features
- premium widgets or notifications
- advanced analytics beyond the dashboard scope defined in roadmap

---

## 11. Estimated Duration

- **Optimistic:** 1.5 weeks
- **Realistic:** 2 weeks
- **Pessimistic:** 3 weeks

---

## 12. AI Execution Notes

Instructions for future AI agents assigned only this phase:
- Do not redesign the dashboard architecture.
- Do not introduce new monitoring technologies.
- Do not bypass active-router state from Phase 2.
- Do not turn dashboard scope into hotspot management scope.
- Do not create unbounded refresh behavior.
- Do not skip performance validation.
- Keep the dashboard strictly within the roadmap-defined monitoring scope.
