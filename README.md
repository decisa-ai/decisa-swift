# DecisaSDK — iOS attribution SDK for Swift (Swift Package Manager)

**DecisaSDK** is a native **iOS attribution SDK** distributed via **Swift Package
Manager (SPM)**. It connects **paid ads → App Store install → in-app conversions**
using Decisa's first-party attribution ingest — the same public endpoints as
`pixel.js` in the browser.

Ship a **native pixel** in your Swift or SwiftUI app: authenticate with your
public `pixel_key` (`dcs_px_`), resolve deferred attribution on first launch,
then send **conversion tracking** events to `/v1/identify` and `/v1/track`.
Built for **web2app** and **funnel2app** flows where users click an ad or
landing page, install from the App Store, and convert days later — without
ATT prompts or IDFA in v1.

| | **decisa-swift** (this repo) | [decisa-flutter](https://github.com/decisa-ai/decisa-flutter) |
| --- | --- | --- |
| Platform | Native iOS (Swift) | Flutter (iOS + Android) |
| Install match | Probabilistic (IP + timestamp) + AdServices token for Apple Search Ads | Android: deterministic Play Install Referrer; iOS: same probabilistic model |
| Package manager | Swift Package Manager | pub.dev |
| Best for | SwiftUI/UIKit apps, iOS-only stacks | Cross-platform mobile apps |

---

## Use cases: web2app & funnel2app

**Web2app** — A user clicks a Meta, Google, or TikTok ad that lands on a Decisa
UTM link, gets redirected to the App Store, installs, and opens the app. On first
launch, `Decisa.initialize` calls `/v1/resolve` to bind the install back to the
original click and its `utm_*` parameters.

**Funnel2app** — A multi-step funnel (quiz, lead form, checkout page) lives on
the web; the final step sends users to the store via `?app=1`. In-app events
(`Lead`, `CompleteRegistration`, `Purchase`) carry the install attribution
forward so you can measure **funnel-to-app** conversion, not just installs.

**Paid ads without ATT** — v1 does not prompt for App Tracking Transparency or
read IDFA. Installs are matched server-side; the AdServices token enriches
**Apple Search Ads** campaigns. For SKAdNetwork-style aggregate reporting, pair
this SDK with your MMP or platform conversion APIs — DecisaSDK focuses on
first-party, event-level attribution you own.

**CAPI & server-side fanout** — Events ingested via `/v1/track` flow through
Decisa's existing conversion pipeline (same taxonomy as the web pixel), enabling
**CAPI**-style server-side delivery to ad platforms without embedding secret keys
in the app binary.

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

## Install (Swift Package Manager)

Add the package via Swift Package Manager in Xcode (**File → Add Package
Dependencies**) using the repository URL, or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/decisa-ai/decisa-swift", from: "0.1.1"),
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
        // Synchronous kickoff so paywall / first-screen events can await resolve.
        Decisa.start(pixelKey: "dcs_px_your_public_key")
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

## Deferred deep linking & install attribution

The hard part of **mobile ad attribution** is connecting *"who clicked the ad"*
to *"who opened the app after installing"* across a multi-day gap with no shared
cookie. Decisa solves this with a server-minted click and the iOS deferred signal:

1. **Mint the click.** Point your ad at a Decisa UTM short link in `?app=1`
   mode: `https://api.decisa.ai/k/<slug>?app=1`. The backend mints a click
   (carrying UTM attribution, a hashed IP, and a timestamp) and redirects to
   the App Store.
2. **Configure store URLs.** On the UTM link's metadata set `ios_store_url`
   so the `?app=1` redirect sends iOS users to the correct App Store listing.
3. **Resolve on first launch.** `Decisa.initialize` reads the **AdServices
   attribution token** and POSTs `/v1/resolve`. The backend matches
   **probabilistically** by IP + timestamp; the token enriches **Apple Search
   Ads** campaigns only.
4. **Bind and track.** `/v1/resolve` returns a `visitor_id` bound to the click.
   The SDK persists it for every later `identify` / `track`.

If resolve finds no match (or the key is unknown, returning a silent `204`), the
SDK mints a local fallback `visitor_id` (`v_…`) so tracking still works.

> The SDK does **not** prompt for App Tracking Transparency (ATT) or read the
> IDFA in v1. `madid` is attached to event metadata only if already available
> without a prompt.

---

## Decisa ecosystem & MCP

Decisa is more than a mobile SDK. The **[Decisa MCP](https://github.com/decisa-ai)**
(Model Context Protocol) server exposes campaign and attribution operations to AI
agents and automation tools — launch UTM links, inspect match rates, manage
conversion events — while this SDK handles the **in-app** side of the same
pipeline.

Typical stack:

- **Web / funnel** — `pixel.js` on landing pages and checkout flows
- **Mobile** — **DecisaSDK** (Swift) or [decisa-flutter](https://github.com/decisa-ai/decisa-flutter) for cross-platform
- **Ops & agents** — Decisa MCP tools for campaign setup and attribution QA

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

## FAQ

**How is this different from an MMP (Adjust, AppsFlyer, Branch)?**
DecisaSDK is a lightweight, first-party **native pixel** tied to Decisa's
attribution ingest — not a full MMP. It excels at **web2app** / **funnel2app**
flows where you already use Decisa UTM links and want the same visitor model
across web and iOS without a third-party SDK tax.

**Do I need ATT or IDFA?**
No in v1. Matching is probabilistic (IP + timestamp) plus AdServices for Apple
Search Ads. No ATT prompt is shown.

**SwiftUI or UIKit?**
Both. Import `DecisaSDK` and call `Decisa.initialize` from your `@main` App
init or `AppDelegate`.

**Cross-platform app?**
Use [decisa-flutter](https://github.com/decisa-ai/decisa-flutter) for shared
Dart code on iOS and Android. Use **decisa-swift** when you want a native Swift
dependency with no Flutter bridge.

**Where do conversions go after `/v1/track`?**
Through Decisa's server-side pipeline — same event taxonomy as the web pixel —
including **CAPI** fanout to ad platforms configured in your Decisa workspace.

---

## License

MIT. See [LICENSE](LICENSE).

