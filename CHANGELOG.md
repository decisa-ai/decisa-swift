# Changelog

## 0.2.0

### Breaking

- Mobile SDKs now authenticate with **`app_key`** (`dcs_app_…`) instead of
  `pixel_key` (`dcs_px_…`). Create an app in the Decisa dashboard and embed its
  `app_key` in the binary. Pixel membership is server-side — no rebuild when
  pixels change.
- Public API renamed: `pixelKey` → `appKey`; request bodies use `app_key`.

### Added

- `Decisa.start(appKey:)` — synchronous kickoff from `App.init`.

## 0.1.1

### Fixed

- Crash when `Decisa.track` or `Decisa.identify` ran before `Decisa.initialize`
  finished (common with a first-screen paywall in DEBUG builds).
- `track` now waits for in-flight initialization instead of trapping.

### Added

- `Decisa.start(appKey:)` — synchronous kickoff from `App.init` so early events
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
