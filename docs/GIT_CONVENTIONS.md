# GIT_CONVENTIONS.md
> DevKuroTik git workflow, branching, commit, and tagging conventions.

---

## Purpose
Define the required git workflow for all contributors and AI agents working on the DevKuroTik project.

## Last Updated
2026-07-26

---

## 1. Branch Model

```
main              ← stable release-ready history
develop           ← integration branch
feature/*         ← scoped phase work
```

### Branch Descriptions

| Branch | Purpose |
|---|---|
| `main` | Stable, tagged, release-ready commits only |
| `develop` | Integration of reviewed phase work |
| `feature/<scope>-<description>` | One phase or one bounded work item |

### Branch Rules
- Never implement multiple phases in one feature branch.
- Never merge directly to `main` from unreviewed branches.
- Branch names must include the phase scope: `feature/phase0-monorepo-scaffold`.

---

## 2. Commit Message Format

```
<prefix>: <short imperative description>

[Optional body — explain WHY, not WHAT]

[Optional: Refs: #issue-number]
```

### Required Prefixes

| Prefix | Use for |
|---|---|
| `phase0:` | Phase 0 foundation work |
| `phase1:` | Phase 1 mikrotik_sdk work |
| `phase2:` | Phase 2 router management |
| `phase3:` | Phase 3 dashboard |
| `phase4:` | Phase 4 hotspot |
| `phase5:` | Phase 5 voucher engine |
| `phase6:` | Phase 6 routeros_script_sdk |
| `phase7:` | Phase 7 PPP + Queue |
| `phase8:` | Phase 8 security hardening |
| `phase9:` | Phase 9 premium features |
| `phase10:` | Phase 10 beta release |
| `docs:` | Documentation changes only |
| `test:` | Test additions or fixes only |
| `ci:` | CI/CD configuration |
| `chore:` | Dependency updates, tooling, config |
| `fix:` | Bug fix inside current phase scope |

### Commit Rules
- Subject line: imperative mood, ≤ 72 characters.
- Do not end subject with a period.
- Do not use vague messages: `fix stuff`, `update code`, `misc`.
- One commit = one logical change.
- Do not mix phase work in one commit.

### Examples — Good
```
phase0: initialize monorepo structure with apps/ and packages/
phase0: scaffold devkurotik_app with Riverpod ProviderScope
phase0: add analysis_options.yaml with strict lint rules
ci: add GitHub Actions workflow for app and SDK packages
docs: add ADR-0001 monorepo structure decision
```

### Examples — Bad
```
fix stuff
update
phase0 and phase1 work
wip
```

---

## 3. Tagging Policy

Tags are created after a phase passes all acceptance criteria.

| Phase | Tag |
|---|---|
| Phase 0 | `v0.0.1` |
| Phase 1 | `v0.1.0` |
| Phase 2 | `v0.2.0` |
| Phase 3 | `v0.3.0` |
| Phase 4 | `v0.5.0` |
| Phase 5 | `v0.7.0` |
| Phase 6 | `v0.8.0` |
| Phase 7 | `v0.9.0` |
| Phase 8 | `v0.9.5` |
| Phase 9 | `v0.9.8` |
| Phase 10 | `v1.0.0` |

Tags must be annotated:
```bash
git tag -a v0.0.1 -m "Phase 0 — Foundation complete"
```

Tags must not be created before:
- All acceptance criteria pass
- All tests pass
- Required documentation is committed
- Phase completion report is committed

---

## 4. Pull Request Requirements

Every PR must include:
1. Phase identifier in the PR title: `[phase0]`
2. Reference to the canonical phase document
3. List of deliverables completed
4. Acceptance criteria addressed
5. Test results
6. Documentation updates
7. Confirmation: no future-phase scope added
8. Confirmation: no unapproved dependencies added

### PR Title Format
```
[phase0] initialize monorepo structure and Flutter app scaffold
```

---

## 5. .gitignore Requirements

The repository `.gitignore` must exclude:
- `build/` (Flutter and Dart build output)
- `.dart_tool/` (pub cache metadata)
- `*.g.dart`, `*.freezed.dart` (generated code)
- `.flutter-plugins`, `.flutter-plugins-dependencies`
- `.packages` (deprecated but generated)
- IDE directories: `.idea/`, `.vscode/` (optional — developers may commit `.vscode/settings.json`)
- `mikhmonv3-master/` (legacy PHP source, excluded from repo)
- `mikhmonv3.zip` (legacy archive, excluded from repo)

---

## References
- CONTRIBUTING.md — PR requirements and branching strategy
- RULES.md — Rule 2 (No future phase implementation)
- PHASE_0.md — Task 8 (Engineering governance documents)
