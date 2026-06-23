# DecisaSDK — Decisa mobile attribution SDK for iOS (Swift)

A first-party mobile attribution SDK that connects an **ad click → app install →
in-app conversions**, reusing Decisa's existing public attribution ingest. It is
a "native pixel": it authenticates with your **public** `pixel_key`, reads the
platform's deferred-attribution signal on first launch, and then posts
identify/track events to the same endpoints `pixel.js` uses in the browser.

- **iOS** is probabilistic: there is no Play Install Referrer, so the install is
  matched server-side by IP + timestamp; the AdServices token enriches Apple Search
  Ads campaigns only.

---

## The public `pixel_key`, never a secret

The SDK authenticates **only** with your workspace's public `pixel_key` — the
string that begins with `dcs_px_`. It is the same public credential `pixel.js`
embeds in a public web page, and it is sent in the request body. It is **not a
secret** and is safe to ship inside an IPA.

**Never put a secret key in a mobile app.** The server-side Decisa SDKs (Node,
PHP, Python) authenticate with a secret `dcs_ak_` / `dcs_sk_` key. A mobile
binary can be decompiled, so a secret in the binary can be extracted and used to
forge conversions and poison your attribution. This SDK refuses anything that is
not a `dcs_px_` key (an assertion fires in debug builds).

---

## Install

Add the package via Swift Package Manager in Xcode (**File → Add Package
Dependencies**) using the repository URL, or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/decisa-ai/decisa-swift", from: "0.1.0"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "DecisaSDK", package: "decisa-swift"),
        ]
    ),
]
```

While developing inside the Decisa monorepo, you can also depend on a local path:

```swift
.package(path: "../decisa-swift"),
```

Minimum platform version: **iOS 13.0** (the AdServices token requires iOS 14.3+,
guarded at runtime).

---

## Quickstart

```swift
import DecisaSDK

@main
struct MyApp: App {
    init() {
        Task {
            // First launch: reads the AdServices token, POSTs /v1/resolve,
            // and persists the visitor id + UTM attribution. Subsequent
            // launches reuse the persisted visitor id (no re-resolve).
            await Decisa.initialize(pixelKey: "dcs_px_your_public_key")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// When a user signs in or is known, associate them. Email/phone are SHA-256
// hashed on-device — raw PII never leaves the phone.
await Decisa.identify(
    userId: "user_123",
    email: "jane@example.com"
)

// Record a conversion. The install's utm_* attribution rides along in metadata.
await Decisa.track(DecisaEvent.purchase(value: 49.90, currency: "USD"))
```

### Events

`DecisaEvent` has a named constructor per canonical event:

```swift
DecisaEvent.purchase(value: 49.90, currency: "USD")
DecisaEvent.lead()
DecisaEvent.completeRegistration()
DecisaEvent.startTrial()
DecisaEvent.subscribe()
DecisaEvent.addToCart(value: 19.99, currency: "USD")
DecisaEvent.initiateCheckout()
DecisaEvent.addPaymentInfo()
DecisaEvent.viewContent()
DecisaEvent.pageView()
DecisaEvent.search()
DecisaEvent.appInstall()
DecisaEvent.custom("viewed_pricing", metadata: ["plan": "pro"])
```

A fresh `eventId` (`evt_` + UUID) is generated per event so retries dedupe
server-side and never double-count.

---

## Deferred deep links (how the install gets attributed)

1. **Mint the click.** Point your ad at a Decisa UTM short link in `?app=1`
   mode: `https://api.decisa.ai/k/<slug>?app=1`.
2. **Configure store URLs.** On the UTM link's metadata set `ios_store_url`
   so the `?app=1` redirect sends iOS users to the correct App Store listing.
3. **Resolve on first launch.** `Decisa.initialize` reads the AdServices token
   and POSTs `/v1/resolve`. The backend matches **probabilistically** by IP +
   timestamp; the AdServices token enriches Apple Search Ads campaigns.
4. **Bind and track.** `/v1/resolve` returns a `visitor_id` bound to the click.
   The SDK persists it for every later `identify` / `track`.

If resolve finds no match (or the key is unknown, returning a silent `204`), the
SDK mints a local fallback `visitor_id` (`v_…`) so tracking still works.

> The SDK does **not** prompt for App Tracking Transparency (ATT) or read the
> IDFA in v1. `madid` is attached to event metadata only if already available
> without a prompt.

---

## Backend contract

| Endpoint | Purpose | Returns |
| --- | --- | --- |
| `POST /v1/resolve` | First-run deferred-attribution lookup | `200 { data: { visitor_id, matched, match_type, utm_* } }` or `204` |
| `POST /v1/identify` | Associate hashed identity with the visitor | `202` |
| `POST /v1/track` | Record a pixel event | `202` |

---

## Architecture

```
Sources/DecisaSDK/
  Decisa.swift              # initialize / identify / track orchestration
  DecisaEvent.swift         # DecisaEvent + named constructors
  DecisaEventName.swift     # canonical event name enum
  DecisaAttribution.swift   # resolved attribution model + JSON
  DecisaTransport.swift     # URLSession POST + envelope decode
  DecisaPersistence.swift   # UserDefaults-backed visitor_id / external_id
  DecisaHashing.swift       # client-side SHA-256 of email/phone/name
  DeferredSignalReader.swift # AdServices attribution token
Tests/DecisaSDKTests/
  DecisaSDKTests.swift      # unit tests with injectable mocks
```

---

## License

MIT. See [LICENSE](LICENSE).
