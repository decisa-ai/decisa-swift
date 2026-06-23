# Changelog

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
