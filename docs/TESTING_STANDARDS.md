# TESTING_STANDARDS.md
> DevKuroTik testing policy and baseline requirements.

---

## Purpose
Define the mandatory testing standards for all phases of the DevKuroTik project. These standards apply to all contributors and AI agents.

## Last Updated
2026-07-26

---

## 1. Test Types

### Unit Tests
- Required for all public APIs in SDK packages.
- Required for all domain logic, parsers, generators, and model transformations.
- Must run with `dart test` (SDK packages) or `flutter test` (app package).
- Must be hermetic — no network, no file system, no real devices.

### Widget Tests
- Required for all Flutter UI components that contain non-trivial logic.
- Must test both rendered output and interaction behavior.
- Run with `flutter test`.

### Integration Tests
- Required for critical user flows starting from Phase 4.
- Defined in `apps/devkurotik_app/integration_test/`.
- Run with `flutter test integration_test/`.

### Golden Tests
- Required for UI components whose visual correctness is critical.
- Introduced when Phase 3 UI is implemented.
- Golden files are committed to the repository and reviewed in PRs.

### Regression Tests
- Phase 6 (`routeros_script_sdk`) requires a full regression suite.
- Fixture-driven: test inputs and expected outputs are committed as fixed files in `tools/fixtures/`.
- Regression tests must catch any change in generator output.
- This requirement is non-negotiable (RULES.md Rule 16 — Phase 6 is a hard release gate).

---

## 2. Coverage Requirements by Phase

| Phase | Minimum Coverage | Notes |
|---|---|---|
| Phase 0 | None | Smoke tests only |
| Phase 1 | 80% line coverage on `mikrotik_sdk` public API | Critical transport layer |
| Phase 2 | 75% | Router persistence and secure storage |
| Phase 3 | 70% | Dashboard models and monitoring |
| Phase 4 | 75% | Hotspot domain logic |
| Phase 5 | 80% | Voucher generation logic |
| Phase 6 | 95% critical-path coverage | Regression suite mandatory |
| Phase 7 | 70% | PPP/Queue |
| Phase 8 | All security paths covered | No line target — must cover all security gates |
| Phase 10 | Beta evidence required | CI passing + beta validation |

---

## 3. Test File Conventions

### Naming
- Test files: `<source_file>_test.dart`
- Integration test files: `<feature>_integration_test.dart`
- Golden test files: `<widget>_golden_test.dart`

### Location
- Unit/widget tests: in `test/` directory of each package or app.
- Integration tests: in `apps/devkurotik_app/integration_test/`.
- Fixtures: in `tools/fixtures/` for Phase 6 regression data.

### Test Structure
```dart
void main() {
  group('ClassName', () {
    setUp(() { ... });
    
    group('methodName', () {
      test('returns expected result when ...', () { ... });
      test('throws when ...', () { ... });
    });
  });
}
```

---

## 4. CI Integration

- All test types that exist at a given phase must run in CI.
- CI `flutter test --coverage` generates coverage reports.
- Phase 6 CI must run the regression fixture suite as a separate step.
- Test failures always block merge. No exceptions.
- Flaky tests (inconsistent pass/fail) must be fixed before merge. No skip-and-merge.

---

## 5. Evidence Requirements for Phase Closure

Each phase is not complete until testing evidence is provided:

| Evidence | Required From |
|---|---|
| CI run URL showing all tests pass | Every phase |
| Coverage report showing required % | Phase 1+ |
| Regression suite run log | Phase 6 |
| Real-router validation log | Phase 6 |
| Beta device test report | Phase 10 |
| Printer compatibility report | Phase 5, Phase 10 |

---

## 6. Test Quality Rules

- Do not test implementation details — test observable behavior.
- Do not use `print` in tests. Use `expect` with descriptive failure messages.
- Do not use `sleep` or `Timer` in tests. Use `fake_async` or test helpers.
- Do not test third-party packages. Test your own code's behavior with those packages.
- Mock external dependencies (RouterOS connection, file system) at package boundaries.

---

## 7. Prohibited Test Patterns

- `// ignore: ...` to suppress test failures
- `skip: true` without a dated issue reference
- Tests that depend on execution order
- Tests with hardcoded credentials or real router addresses
- Tests that require internet access in CI

---

## References
- RULES.md — Rule 4 (No skipping tests), Rule 5 (No merging failing code)
- PHASE_0.md — Section 8 (Testing Requirements)
- PHASE_6.md — Regression requirements
- CONTRIBUTING.md — Testing requirements
