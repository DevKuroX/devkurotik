# ADR-0004 — Android-first, iOS-ready platform strategy

## Status
ACCEPTED

## Date
2026-07-26

## Context
DevKuroTik targets mobile users managing MikroTik routers from a smartphone. The primary user base uses Android devices. iOS support is required in the v1.0 scope but is secondary to Android during development and validation.

The architecture specifies "Android-first, iOS-ready" — meaning:
- Development and testing focuses on Android first
- The architecture must not break iOS support
- No Android-specific hacks that would prevent iOS builds
- iOS support must be achievable without architectural changes later

Additional constraints:
- The `local_auth` dependency supports both Android (fingerprint/face) and iOS (Face ID/Touch ID)
- `flutter_secure_storage` requires Android Keystore configuration and iOS Keychain entitlements
- `sqlite3_flutter_libs` supports both platforms
- CI will run `flutter analyze` (cross-platform) but not device/simulator tests in Phase 0

## Decision
We will develop and test DevKuroTik **Android-first** with the following commitments:
1. All code is written in platform-agnostic Flutter/Dart — no Android-specific code in business logic.
2. Platform-specific configuration (AndroidManifest.xml, Info.plist) will be correctly set up for both platforms in Phase 0 scaffolding.
3. iOS simulator testing is not required for Phase 0–4 but must not be blocked by architectural choices.
4. CI will not require iOS builds until Phase 8 or Phase 10 (when cross-platform validation is required).
5. All approved dependencies in the baseline support both Android and iOS.

## Rationale
- Mandated by ROADMAP_V1.md: "Android-first mobile usability, iOS-ready architecture."
- Flutter is inherently cross-platform — no Android-specific code is needed for domain logic.
- Solo developer operating model requires prioritization: Android first, then iOS validation.
- All dependencies in the approved baseline (flutter_secure_storage, local_auth, drift, etc.) support iOS.
- Delaying iOS CI to Phase 8/10 is practical without compromising iOS readiness.

## Consequences
**Positive:**
- Development velocity is maximized by focusing device testing on Android.
- Architecture remains cross-platform — iOS support can be activated without refactoring.
- All dependencies are pre-vetted for iOS compatibility.

**Negative:**
- iOS-specific bugs may accumulate during Android-first development phases and be discovered late.
- No iOS CI means platform regressions could be introduced unknowingly.
- `local_auth` and `flutter_secure_storage` require iOS-specific entitlement configuration that must be tested on actual hardware or simulator.

## Alternatives Considered
- **iOS-first** → Rejected. Primary user base is Android. Adds App Store review overhead without proportional benefit in early phases.
- **Android only, iOS deferred indefinitely** → Rejected. ROADMAP_V1.md requires iOS-ready architecture for v1.0. Architecture choices that preclude iOS are not acceptable.
- **Web/Desktop support** → Out of scope. DevKuroTik is a mobile application. Web/desktop is not in the approved baseline or roadmap.

## References
- ROADMAP_V1.md — Vision: "Android-first mobile usability, iOS-ready architecture"
- ARCHITECTURE.md — Section 1 (Architectural Summary): "Android-first, iOS-ready"
- PHASE_0.md — Task 2 (Pin approved technical baseline)
- PHASE_10.md — Beta release requirements (cross-platform validation)
