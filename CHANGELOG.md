# Changelog

## 0.1.1

### Fixed

- Crash when `Decisa.track` or `Decisa.identify` ran before `Decisa.initialize`
  finished (common with a first-screen paywall in DEBUG builds).
- `track` now waits for in-flight initialization instead of trapping.

### Added

- `Decisa.start(pixelKey:)` — synchronous kickoff from `App.init` so early events
  can await resolve without wrapping `initialize` in an unstructured `Task`.

## 0.1.0

- Initial native iOS SDK for Decisa mobile attribution (Swift Package Manager).
- Public API: `Decisa.initialize`, `Decisa.identify`, `Decisa.track`,
  and `DecisaEvent` with named constructors (`purchase`, `lead`, `startTrial`,
  `subscribe`, `addToCart`, `custom`, and the rest of the canonical taxonomy).
- First-run deferred attribution via `POST /v1/resolve`, persisted with
  `UserDefaults`; local fallback visitor id on no-match / 204.
- Client-side SHA-256 hashing of email/phone for `POST /v1/identify`.
- Native AdServices attribution-token reader (iOS 14.3+, guarded at runtime).
- Injectable transport/persistence/signal-reader seams for unit tests.
