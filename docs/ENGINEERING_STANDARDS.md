# ENGINEERING_STANDARDS.md
> DevKuroTik engineering standards and code quality requirements.

---

## Purpose
Define the mandatory engineering standards for all code produced in the DevKuroTik project. These standards apply to all contributors and AI agents.

## Last Updated
2026-07-26

---

## 1. Language and Framework Standards

### Dart Version
- Minimum: Dart 3.12.2 (bundled with Flutter 3.44.8)
- Sound null safety is mandatory. Nullable types must be explicitly declared.
- No `dynamic` in production code without documented justification.
- `late` keyword usage must be justified; prefer `final` and proper initialization.

### Flutter Version
- Pinned to Flutter 3.44.8 stable.
- Do not upgrade Flutter without updating this document and running the full test suite.

### Code Style
- Follow official [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- All files use UTF-8 encoding.
- Lines must not exceed 120 characters.
- Use `dart format` before every commit. CI enforces formatting.

---

## 2. Package and Import Standards

### Import Organization
Order imports as follows in every Dart file:
1. `dart:` core libraries
2. `package:flutter/` imports
3. `package:` third-party packages
4. Relative project imports (last)

Separate each group with a blank line.

### No Cross-Layer Imports
- SDK packages must not import `package:flutter`.
- SDK packages must not import other SDK packages unless explicitly approved in the dependency graph.
- `devkurotik_app` may import any SDK package.

### Relative vs. Package Imports
- Use package imports (`package:devkurotik_app/...`) inside the app, not relative imports.
- This rule is enforced by `avoid_relative_lib_imports` lint.

---

## 3. Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Classes | PascalCase | `RouterConnection` |
| Methods/functions | camelCase | `connectToRouter()` |
| Variables | camelCase | `connectionTimeout` |
| Constants | lowerCamelCase | `defaultPort` |
| Files | snake_case | `router_connection.dart` |
| Packages | snake_case | `mikrotik_sdk` |
| Enums | PascalCase | `ConnectionState` |
| Enum values | camelCase | `ConnectionState.connected` |
| Private members | `_prefixed` | `_socket` |

---

## 4. Documentation Standards

### Required Documentation
- Every public class must have a `///` doc comment.
- Every public method must have a `///` doc comment.
- Every public field that is not self-evident must have a `///` doc comment.
- Complex private methods should have `//` inline comments.

### Doc Comment Format
```dart
/// Short one-line summary ending with a period.
///
/// Additional paragraphs for complex explanations.
/// Include [param] references where helpful.
///
/// Throws [RouterConnectionException] if the connection fails.
```

### No TODO Comments in Merged Code
- `TODO` and `FIXME` comments are not allowed in code merged to `main` or `develop`.
- Use GitHub issues for tracking pending work.

---

## 5. Error Handling Standards

### No Silent Failures
- Never swallow exceptions silently.
- Every `catch` block must either re-throw, log, or explicitly handle the error.

### Typed Exceptions
- Domain and SDK errors must use typed exception classes defined in the relevant package.
- Generic `Exception` is acceptable for Phase 0 scaffold. Phase 1+ must use domain-specific exceptions.

### No Generic `catch (e)` in Production Code
- Always catch specific types where possible.
- If catching `Exception`, document why.

---

## 6. Testing Standards

See `docs/TESTING_STANDARDS.md` for full testing policy.

Summary:
- All public API surfaces must have unit tests by the phase that implements them.
- Widget tests are required for all non-trivial UI components.
- Integration tests are required for critical flows (Phase 4+).
- CI runs all tests on every PR. Failing tests block merge.

---

## 7. Security Standards

- No credentials in source code, git history, or log output.
- All user-provided input to RouterOS commands must be validated before use.
- Destructive actions (delete, disconnect, format) require explicit confirmation.
- `flutter_secure_storage` is the only approved mechanism for credential persistence.
- See `SECURITY_REPORT.md` and `ARCHITECTURE.md` Section 9 for full security requirements.

---

## 8. Dependency Standards

See `docs/DEPENDENCY_POLICY.md` for full dependency policy.

Summary:
- Only add dependencies approved in the canonical specification.
- New dependencies require explicit project owner approval.
- No dependencies with fewer than 100 pub.dev likes or last publish > 2 years.

---

## 9. CI/CD Requirements

- All PRs must pass CI before merge.
- CI runs: `flutter pub get` / `dart pub get`, `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos` / `dart analyze --fatal-infos`, `flutter test` / `dart test`.
- Flaky tests must be fixed, not skipped.
- Coverage is tracked from Phase 1 onward. Phase 0 has no minimum.

---

## 10. Git Standards

See `docs/GIT_CONVENTIONS.md` for full conventions.

Summary:
- Commit messages must use phase prefix: `phase0:`, `phase1:`, etc.
- One logical change per commit.
- Feature branches: `feature/phase0-<description>`.
- Do not commit directly to `main`.
- Do not commit generated files (`*.g.dart`, `*.freezed.dart`, `build/`) except where the approved `.gitignore` makes an exception.
